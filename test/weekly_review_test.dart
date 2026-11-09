import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/models/weekly_review.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/services/weekly_review_service.dart';

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
  late WeeklyReviewService service;
  late DateTime time;
  Future<Isar> open() => Isar.open(
    [
      PrimePlanSchema,
      WeeklyReviewSchema,
      CheckInSchema,
      WorkoutSessionDocSchema,
      WorkoutTemplateDocSchema,
    ],
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
    time = DateTime(2026, 11, 3, 12);
    service = WeeklyReviewService(
      openDatabase: () async => database,
      clock: () => time,
    );
  });
  tearDown(() async {
    if (database.isOpen) await database.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  test(
    'missing evidence remains no-change and explicit acceptance is durable',
    () async {
      final draft = await service.prepare();
      expect(draft.week.workoutDays, 0);
      expect(draft.targets, 'No nutrition targets saved.');
      expect(draft.review.status, 'draft');
      final accepted = await service.decide(
        draft.review.id,
        draft.review.decisionToken,
        accept: true,
      );
      expect(accepted.review.status, 'accepted');
      expect(await database.primePlans.count(), 0);
      await database.close();
      database = await open();
      expect((await service.prepare()).review.id, draft.review.id);
      expect((await service.prepare()).review.status, 'accepted');
      await expectLater(
        service.decide(
          draft.review.id,
          draft.review.decisionToken,
          accept: true,
        ),
        throwsStateError,
      );
    },
  );
  test(
    'concurrent prepare deduplicates and concurrent accept applies once',
    () async {
      final drafts = await Future.wait([service.prepare(), service.prepare()]);
      expect(drafts[0].review.id, drafts[1].review.id);
      final d = drafts.first.review;
      Future<bool> accept() async {
        try {
          await service.decide(d.id, d.decisionToken, accept: true);
          return true;
        } on StateError {
          return false;
        }
      }

      expect(
        (await Future.wait([accept(), accept()])).where((r) => r).length,
        1,
      );
      expect(await database.weeklyReviews.count(), 1);
    },
  );
  test(
    'plan edits invalidate draft without touching source or phase',
    () async {
      final p = fixture('refeed');
      await repo.upsertPlan(p);
      final draft = await service.prepare();
      p.stepTarget = 9000;
      await repo.upsertPlan(p);
      final result = await service.decide(
        draft.review.id,
        draft.review.decisionToken,
        accept: true,
      );
      expect(result.stale, true);
      expect(result.review.status, 'stale');
      final actual = (await repo.getActivePlan())!;
      expect(actual.stepTarget, 9000);
      expect(actual.preRefeedCalories, 1700);
      expect(await database.primePlans.count(), 1);
      expect((await service.prepare()).review.id, isNot(draft.review.id));
    },
  );
  test(
    'record corrections and deletions invalidate evidence, not zero-fill it',
    () async {
      final check = CheckIn()
        ..ts = time
        ..stepsToday = 0
        ..note = 'private source';
      await database.writeTxn(() => database.checkIns.put(check));
      final draft = await service.prepare();
      expect(draft.week.days[1].steps, 0);
      check.stepsToday = null;
      await database.writeTxn(() => database.checkIns.put(check));
      expect(
        (await service.decide(
          draft.review.id,
          draft.review.decisionToken,
          accept: true,
        )).stale,
        true,
      );
      final next = await service.prepare();
      expect(next.week.days[1].steps, isNull);
      await database.writeTxn(() => database.checkIns.delete(check.id));
      expect(
        (await service.decide(
          next.review.id,
          next.review.decisionToken,
          accept: true,
        )).stale,
        true,
      );
    },
  );
  test(
    'session progress changes invalidate and skipped weeks require fresh review',
    () async {
      final session = WorkoutSessionDoc()
        ..date = time
        ..dayIndex = 1
        ..completed = false;
      await database.writeTxn(() => database.workoutSessionDocs.put(session));
      final draft = await service.prepare();
      session.completed = true;
      await database.writeTxn(() => database.workoutSessionDocs.put(session));
      expect(
        (await service.decide(
          draft.review.id,
          draft.review.decisionToken,
          accept: true,
        )).stale,
        true,
      );
      final next = await service.prepare();
      time = time.add(const Duration(days: 15));
      expect(
        (await service.decide(
          next.review.id,
          next.review.decisionToken,
          accept: true,
        )).stale,
        true,
      );
      expect((await service.prepare()).week.workoutDays, 0);
    },
  );
  test(
    'decline remains declined, withdrawal preserves plans, deletion cannot resurrect',
    () async {
      final p = fixture('refeed');
      await repo.upsertPlan(p);
      final draft = await service.prepare();
      final d = draft.review;
      await service.decide(d.id, d.decisionToken, accept: false);
      expect((await service.prepare()).review.status, 'declined');
      await expectLater(
        service.decide(d.id, d.decisionToken, accept: true),
        throwsStateError,
      );
      await service.delete(d.id);
      await expectLater(
        service.decide(d.id, d.decisionToken, accept: true),
        throwsStateError,
      );
      expect(await database.weeklyReviews.count(), 0);
      final newDraft = (await service.prepare()).review;
      await service.decide(newDraft.id, newDraft.decisionToken, accept: true);
      await service.withdraw(newDraft.id, newDraft.decisionToken);
      expect((await service.prepare()).review.status, 'withdrawn');
      expect((await repo.getActivePlan())!.id, p.id);
      expect(await database.primePlans.count(), 1);
    },
  );
  test(
    'unknown schema cannot be accepted and source fingerprint does not expose notes',
    () async {
      final check = CheckIn()
        ..ts = time
        ..note = 'private source';
      await database.writeTxn(() => database.checkIns.put(check));
      final d = (await service.prepare()).review;
      expect(d.decisionToken.length, 64);
      expect(d.decisionToken, isNot(contains('private')));
      d.schemaVersion = 999;
      await database.writeTxn(() => database.weeklyReviews.put(d));
      await expectLater(
        service.decide(d.id, d.decisionToken, accept: true),
        throwsStateError,
      );
    },
  );
  test(
    'future record becoming visible invalidates the same-day review',
    () async {
      final c = CheckIn()
        ..ts = time.add(const Duration(hours: 1))
        ..stepsToday = 0;
      await database.writeTxn(() => database.checkIns.put(c));
      final d = (await service.prepare()).review;
      time = time.add(const Duration(hours: 2));
      expect(
        (await service.decide(d.id, d.decisionToken, accept: true)).stale,
        true,
      );
    },
  );
  test('additive review schema preserves old health plan data', () async {
    await database.close(deleteFromDisk: true);
    database = await Isar.open(
      [PrimePlanSchema],
      directory: directory.path,
      name: 'history',
      inspector: false,
    );
    final p = fixture('refeed');
    await repo.upsertPlan(p);
    await database.close();
    database = await open();
    expect((await repo.getActivePlan())!.preRefeedCalories, 1700);
    expect((await service.prepare()).review.status, 'draft');
    expect((await repo.getActivePlan())!.id, p.id);
  });
  test(
    'old decision cannot act on replacement even with reused database id',
    () async {
      final old = (await service.prepare()).review;
      await service.delete(old.id);
      final replacement = (await service.prepare()).review;
      await database.writeTxn(() async {
        await database.weeklyReviews.delete(replacement.id);
        replacement.id = old.id;
        await database.weeklyReviews.put(replacement);
      });
      expect(replacement.decisionToken, isNot(old.decisionToken));
      await expectLater(
        service.decide(old.id, old.decisionToken, accept: true),
        throwsStateError,
      );
      expect((await database.weeklyReviews.get(old.id))!.status, 'draft');
    },
  );
}
