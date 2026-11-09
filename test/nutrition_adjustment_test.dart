import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/utils/nutrition_adjustment.dart';
import 'package:lyva_app/utils/plateau_detector.dart';

PrimePlan fixture(String phase) => PrimePlan()
  ..createdAt = DateTime(2026, 1, 1)
  ..planName = 'Original'
  ..trainingDays = 3
  ..calories = 2200
  ..proteinG = 120
  ..carbsG = 280
  ..fatG = 60
  ..stepTarget = 8000
  ..phase = phase
  ..phaseStartedAt = DateTime.now().subtract(const Duration(days: 5))
  ..preRefeedCalories = 1700;

void main() {
  late Directory directory;
  late Isar database;
  late LyvaRepo repo;
  Future<Isar> open() => Isar.open(
    [PrimePlanSchema],
    directory: directory.path,
    name: 'history',
    inspector: false,
  );
  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.windowsX64: File(
          'vendor/isar_flutter_libs/windows/isar.dll',
        ).absolute.path,
        Abi.linuxX64: File(
          'vendor/isar_flutter_libs/linux/libisar.so',
        ).absolute.path,
        Abi.macosX64: File(
          'vendor/isar_flutter_libs/macos/libisar.dylib',
        ).absolute.path,
        Abi.macosArm64: File(
          'vendor/isar_flutter_libs/macos/libisar.dylib',
        ).absolute.path,
      },
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lyva_history_');
    database = await open();
    repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => database);
  });
  tearDown(() async {
    if (database.isOpen) await database.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  test(
    'reviewed revision applies once and retains source and phase after restart',
    () async {
      final original = fixture('refeed');
      await repo.upsertPlan(original);
      final revision = nutritionPlanRevision(original);
      final next = await repo.applyReviewedNutritionAdjustment(
        expectedRevision: revision,
        calorieDelta: 0,
        stepDelta: 100,
      );
      expect(next.preRefeedCalories, original.preRefeedCalories);
      expect(next.phaseStartedAt, original.phaseStartedAt);
      expect(next.stepTarget, 8100);
      await expectLater(
        repo.applyReviewedNutritionAdjustment(
          expectedRevision: revision,
          calorieDelta: 0,
          stepDelta: 100,
        ),
        throwsStateError,
      );
      await database.close();
      database = await open();
      expect((await repo.getActivePlan())!.id, next.id);
      expect((await database.primePlans.get(original.id))!.stepTarget, 8000);
    },
  );
  test(
    'newer plan and in-place corrections invalidate reviewed proposals',
    () async {
      final original = fixture('refeed');
      await repo.upsertPlan(original);
      final revision = nutritionPlanRevision(original);
      original.preRefeedCalories = 1800;
      await repo.upsertPlan(original);
      await expectLater(
        repo.applyReviewedNutritionAdjustment(
          expectedRevision: revision,
          calorieDelta: -100,
          stepDelta: 0,
        ),
        throwsStateError,
      );
      final corrected = nutritionPlanRevision(original);
      await repo.upsertPlan(fixture('deficit')..createdAt = DateTime(2026, 2));
      await expectLater(
        repo.applyReviewedNutritionAdjustment(
          expectedRevision: corrected,
          calorieDelta: -100,
          stepDelta: 0,
        ),
        throwsStateError,
      );
      expect((await repo.getActivePlan())!.calories, 2200);
    },
  );
  test('concurrent confirmation permits exactly one application', () async {
    final original = fixture('deficit');
    await repo.upsertPlan(original);
    final revision = nutritionPlanRevision(original);
    Future<bool> apply() async {
      try {
        await repo.applyReviewedNutritionAdjustment(
          expectedRevision: revision,
          calorieDelta: 0,
          stepDelta: 100,
        );
        return true;
      } on StateError {
        return false;
      }
    }

    expect((await Future.wait([apply(), apply()])).where((ok) => ok).length, 1);
    expect((await repo.getActivePlan())!.stepTarget, 8100);
  });

  test('future-dated source fails without inventing a timestamp', () async {
    final original = fixture('deficit')
      ..createdAt = DateTime.now().add(const Duration(days: 1));
    await repo.upsertPlan(original);
    await expectLater(
      repo.applyReviewedNutritionAdjustment(
        expectedRevision: nutritionPlanRevision(original),
        calorieDelta: 0,
        stepDelta: 100,
      ),
      throwsStateError,
    );
    expect((await repo.getActivePlan())!.id, original.id);
  });
  for (final phase in ['deficit', 'refeed', 'resumed_deficit']) {
    for (final calorieDelta in [0, -100, 100]) {
      test(
        '$phase persists metadata through delta $calorieDelta and restart',
        () async {
          final original = fixture(phase);
          await repo.upsertPlan(original);
          final remaining = PlateauDetector.daysRemainingInRefeed(original);
          final updated = adjustedNutritionPlan(
            current: original,
            calorieDelta: calorieDelta,
            stepDelta: 500,
            createdAt: DateTime(2026, 2, 1),
          );
          expect(updated.id, Isar.autoIncrement);
          await repo.upsertPlan(updated);
          expect(updated.id, isNot(original.id));
          await database.close();
          database = await open();
          final stored = (await repo.getActivePlan())!;
          expect(stored.phase, phase);
          expect(stored.phaseStartedAt, original.phaseStartedAt);
          expect(stored.preRefeedCalories, 1700);
          expect(PlateauDetector.daysRemainingInRefeed(stored), remaining);
          expect(stored.calories, 2200 + calorieDelta);
          expect(stored.carbsG, 280 + calorieDelta ~/ 4);
          expect(stored.proteinG, 120);
          expect(stored.fatG, 60);
          expect(stored.trainingDays, 3);
          expect(stored.stepTarget, 8500);
          expect(stored.createdAt, DateTime(2026, 2, 1));
          expect(stored.planName, 'Original (Adjusted)');
          final old = (await database.primePlans.get(original.id))!;
          expect(old.calories, 2200);
          expect(old.stepTarget, 8000);
          expect(old.phase, phase);
          expect(old.phaseStartedAt, original.phaseStartedAt);
          expect(old.preRefeedCalories, 1700);
        },
      );
    }
  }
  test('legacy null phase metadata stays null, not invented', () {
    final current = fixture('deficit')
      ..phaseStartedAt = null
      ..preRefeedCalories = null;
    final updated = adjustedNutritionPlan(
      current: current,
      calorieDelta: 0,
      stepDelta: 1000,
      createdAt: DateTime(2026),
    );
    expect(updated.phaseStartedAt, isNull);
    expect(updated.preRefeedCalories, isNull);
    expect(updated.phase, 'deficit');
  });
  test('steps-only adjustment does not clamp existing nutrition', () {
    final current = fixture('refeed')
      ..calories = 1100
      ..carbsG = 10000;
    final updated = adjustedNutritionPlan(
      current: current,
      calorieDelta: 0,
      stepDelta: 1000,
      createdAt: DateTime(2026),
    );
    expect(updated.calories, 1100);
    expect(updated.carbsG, 10000);
    expect(updated.preRefeedCalories, 1700);
  });
  test('carbs follow applied calorie delta at both existing limits', () {
    for (final pair in [(4400, 200, 4500, 305), (1300, -200, 1200, 255)]) {
      final current = fixture('refeed')..calories = pair.$1;
      final updated = adjustedNutritionPlan(
        current: current,
        calorieDelta: pair.$2,
        stepDelta: 0,
        createdAt: DateTime(2026),
      );
      expect(updated.calories, pair.$3);
      expect(updated.carbsG, pair.$4);
      expect(updated.stepTarget, current.stepTarget);
      expect(updated.preRefeedCalories, 1700);
    }
  });
}
