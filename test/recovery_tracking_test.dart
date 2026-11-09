import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/services/export_service.dart';
import 'package:lyva_app/utils/checkin_input.dart';

void main() {
  test(
    'recovery-only check-ins remain optional and preserve missing measurements',
    () {
      final c = CheckInInput.parse(
        now: DateTime(2026),
        sleep: 4,
        stress: 2,
        soreness: 1,
        hunger: 5,
      );
      expect(
        [c.sleepScore, c.stressScore, c.sorenessScore, c.hungerScore],
        [4, 2, 1, 5],
      );
      expect(c.weightKg, isNull);
      expect(c.stepsToday, isNull);
      expect(c.moodScore, isNull);
      for (final bad in [0, 6]) {
        expect(
          () => CheckInInput.parse(now: DateTime(2026), sleep: bad),
          throwsFormatException,
        );
        expect(
          () => CheckInInput.parse(now: DateTime(2026), stress: bad),
          throwsFormatException,
        );
        expect(
          () => CheckInInput.parse(now: DateTime(2026), soreness: bad),
          throwsFormatException,
        );
        expect(
          () => CheckInInput.parse(now: DateTime(2026), hunger: bad),
          throwsFormatException,
        );
      }
      expect(
        () => CheckInInput.parse(now: DateTime(2026)),
        throwsFormatException,
      );
    },
  );
  group('persisted recovery and effort', () {
    late Directory dir;
    late Isar db;
    late LyvaRepo repo;
    Future<Isar> open() => Isar.open(
      [CheckInSchema, WorkoutSessionDocSchema],
      directory: dir.path,
      name: 'recovery',
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
      dir = await Directory.systemTemp.createTemp('lyva_recovery_test_');
      db = await open();
      repo = LyvaRepo(
        openDatabase: () async => db,
        checkPersonalization: (_) async {},
      );
    });
    tearDown(() async {
      if (db.isOpen) await db.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    });
    test(
      'nullable signals and exertion survive reopen and export without null strings',
      () async {
        final c = CheckInInput.parse(
          now: DateTime(2026, 1, 1),
          sleep: 4,
          hunger: 2,
        );
        await repo.addCheckIn(c);
        final session = WorkoutSessionDoc()
          ..date = DateTime(2026, 1, 1)
          ..dayIndex = 1
        ..completed = false;
        await db.writeTxn(() async {
          await db.workoutSessionDocs.put(session);
        });
        await repo.completeSession(session.id, perceivedExertion: 3);
        await db.close();
        db = await open();
        final stored = (await db.checkIns.get(c.id))!;
        expect(stored.sleepScore, 4);
        expect(stored.stressScore, isNull);
        expect(
          (await db.workoutSessionDocs.get(session.id))!.perceivedExertion,
          3,
        );
        final file =
            await ExportService(
              repo,
              temporaryDirectory: () async => dir,
            ).exportCsv(
              startDate: DateTime(2026),
              endDate: DateTime(2026, 1, 2),
              includeCheckIns: true,
              includeMeals: false,
              includeWorkouts: true,
            );
        final csv = await file.readAsString();
        expect(
          csv,
          contains('Sleep (1-5),Stress (1-5),Soreness (1-5),Hunger (1-5)'),
        );
        expect(csv, contains(',4,,,2'));
        expect(csv, contains('Perceived exertion (1-5)'));
        expect(csv, contains('Day 1,Yes,No,,,3'));
        expect(csv, isNot(contains('null')));
      },
    );
    test(
      'invalid input does not persist and skipped sessions stay skipped',
      () async {
        final c = CheckInInput.parse(now: DateTime(2026), mood: 3)
          ..sleepScore = 6;
        await expectLater(repo.addCheckIn(c), throwsArgumentError);
        expect(await db.checkIns.count(), 0);
        final skipped = WorkoutSessionDoc()
          ..date = DateTime(2026)
          ..dayIndex = 1
        ..completed = false
          ..skipped = true;
        await db.writeTxn(() async {
          await db.workoutSessionDocs.put(skipped);
        });
        await expectLater(
          repo.completeSession(skipped.id, perceivedExertion: 0),
          throwsArgumentError,
        );
        await repo.completeSession(skipped.id, perceivedExertion: 4);
        final stored = (await db.workoutSessionDocs.get(skipped.id))!;
        expect(stored.skipped, isTrue);
        expect(stored.completed, isFalse);
        expect(stored.perceivedExertion, isNull);
      },
    );
  });
}
