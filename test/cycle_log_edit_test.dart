import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/cycle_log.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/models/cycle_prediction.dart';
import 'package:lyva_app/repos/lyva_repo.dart';

void main() {
  late Directory dir;
  late Isar db;
  late LyvaRepo repo;
  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.macosArm64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
        Abi.macosX64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
        Abi.linuxX64: File('vendor/isar_flutter_libs/linux/libisar.so').absolute.path,
        Abi.windowsX64: File(
          'vendor/isar_flutter_libs/windows/isar.dll',
        ).absolute.path,
      },
      download: false,
    );
  });
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lyva_cycle_edit_synthetic_');
    db = await Isar.open(
      [
        CycleLogSchema,
        UserProfileSchema,
        CyclePredictionSchema,
        PrimePlanSchema,
        CheckInSchema,
        WorkoutTemplateDocSchema,
        WorkoutSessionDocSchema,
      ],
      directory: dir.path,
      name: 'cycle_edit',
      inspector: false,
    );
    repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => db);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<UserProfile> seedProfile({bool tracking = true}) async {
    final p = UserProfile()
      ..age = 30
      ..sex = 'female'
      ..heightCm = 160
      ..weightKg = 60
      ..goal = 'recomp'
      ..level = 'beginner'
      ..equipment = 'gym'
      ..trainingDaysPerWeek = 3
      ..createdAt = DateTime(2026)
      ..updatedAt = DateTime(2026)
      ..trackCycle = tracking;
    await db.writeTxn(() async {
      await db.userProfiles.put(p);
    });
    return p;
  }

  Future<CycleLog> seed() async {
    await seedProfile();
    final log = CycleLog()
      ..ts = DateTime(2026, 1, 2)
      ..eventType = 'symptom'
      ..symptomType = 'cramps'
      ..severity = 3
      ..notes = 'original';
    await repo.saveCycleLog(log);
    return log;
  }

  test('details persist without changing ID date type or symptom', () async {
    final log = await seed();
    expect(
      await repo.updateCycleLogDetails(log, notes: 'corrected', severity: null),
      true,
    );
    final saved = (await db.cycleLogs.get(log.id))!;
    expect(saved.ts, log.ts);
    expect(saved.eventType, log.eventType);
    expect(saved.symptomType, log.symptomType);
    expect(saved.notes, 'corrected');
    expect(saved.severity, isNull);
  });
  test('stale edit cannot overwrite newer details', () async {
    final log = await seed();
    expect(
      await repo.updateCycleLogDetails(log, notes: 'first', severity: 2),
      true,
    );
    expect(
      await repo.updateCycleLogDetails(log, notes: 'stale', severity: 5),
      false,
    );
    expect((await db.cycleLogs.get(log.id))!.notes, 'first');
  });
  test('deleted record is never resurrected by edit', () async {
    final log = await seed();
    await db.writeTxn(() async {
      await db.cycleLogs.delete(log.id);
    });
    expect(
      await repo.updateCycleLogDetails(log, notes: 'stale', severity: 2),
      false,
    );
    expect(await db.cycleLogs.count(), 0);
  });
  test('invalid severity does not change stored data', () async {
    final log = await seed();
    await expectLater(
      repo.updateCycleLogDetails(log, notes: 'bad', severity: 6),
      throwsArgumentError,
    );
    expect((await db.cycleLogs.get(log.id))!.notes, 'original');
  });
  test('period start retry is idempotent and preserves newer anchor', () async {
    final p = await seedProfile();
    await repo.confirmPeriodStarted(DateTime(2026, 2, 3, 9));
    await repo.confirmPeriodStarted(DateTime(2026, 2, 3, 10));
    expect(await db.cycleLogs.count(), 1);
    await repo.confirmPeriodStarted(DateTime(2026, 1, 3));
    expect(
      (await db.userProfiles.get(p.id))!.lastPeriodDate,
      DateTime(2026, 2, 3, 10),
    );
  });
  test('persisted opt-out blocks period start before any writes', () async {
    await seedProfile(tracking: false);
    await expectLater(
      repo.confirmPeriodStarted(DateTime(2026, 2, 3)),
      throwsStateError,
    );
    expect(await db.cycleLogs.count(), 0);
  });

  test(
    'transaction failure after log insertion rolls back every change',
    () async {
      await db.close();
      db = await Isar.open(
        [CycleLogSchema, UserProfileSchema],
        directory: dir.path,
        name: 'missing_prediction_fixture',
        inspector: false,
      );
      repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => db);
      final p = await seedProfile();
      await expectLater(
        repo.confirmPeriodStarted(DateTime(2026, 2, 3)),
        throwsA(anything),
      );
      expect(await db.cycleLogs.count(), 0);
      expect((await db.userProfiles.get(p.id))!.lastPeriodDate, isNull);
    },
  );
  test('persisted opt-out blocks symptom saves and edits', () async {
    final log = await seed();
    final p = (await db.userProfiles.where().findFirst())!..trackCycle = false;
    await db.writeTxn(() async {
      await db.userProfiles.put(p);
    });
    expect(
      await repo.updateCycleLogDetails(log, notes: 'blocked', severity: 1),
      false,
    );
    await expectLater(
      repo.saveTrackedCycleLog(
        CycleLog()
          ..ts = DateTime(2026)
          ..eventType = 'symptom',
      ),
      throwsStateError,
    );
    expect(await db.cycleLogs.count(), 1);
    expect((await db.cycleLogs.get(log.id))!.notes, 'original');
  });
  test(
    'coaching context omits cycle preference and timing without changing stored profile',
    () async {
      final p = await seedProfile();
      p.lastPeriodDate = DateTime(2026, 1, 1);
      p.cycleLength = 35;
      await db.writeTxn(() async {
        await db.userProfiles.put(p);
      });
      final context = await repo.buildCoachingContext();
      final sent = context['profile'] as Map;
      for (final key in [
        'tracksCycle',
        'cycleLength',
        'lastPeriodDate',
        'periodDuration',
        'phase',
      ]) {
        expect(sent.containsKey(key), false);
      }
      final stored = (await db.userProfiles.get(p.id))!;
      expect(stored.cycleLength, 35);
      expect(stored.lastPeriodDate, DateTime(2026, 1, 1));
    },
  );
  test(
    'legacy AI cycle prediction fails locally before database or network work',
    () async {
      final isolated = LyvaRepo(
        openDatabase: () async => throw StateError('Must not open'),
      );
      await expectLater(
        isolated.predictCycle(
          cycleHistory: [],
          checkInData: [],
          workoutData: [],
          profileData: {},
        ),
        throwsUnsupportedError,
      );
    },
  );
}
