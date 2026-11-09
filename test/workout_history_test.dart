import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/widgets/workout_calendar.dart';
import 'fixtures/legacy_workout_session.dart';

WorkoutTemplateDoc fixture(String name, {int days = 3}) => WorkoutTemplateDoc()
  ..createdAt = DateTime.now()
  ..planName = name
  ..level = 'beginner'
  ..equipment = 'gym'
  ..daysPerWeek = days
  ..sex = 'female'
  ..json = jsonEncode({
    'days': List.generate(
      days,
      (i) => {
        'dayIndex': i + 1,
        'title': '$name day ${i + 1}',
        'exercises': [
          {
            'exerciseId': 'squat',
            'name': '$name squat',
            'sets': 4,
            'reps': '8',
            'rest': '120s',
          },
        ],
      },
    ),
  });

void main() {
  late Directory directory;
  late Isar database;
  late LyvaRepo repo;
  Future<Isar> open() => Isar.open(
    [WorkoutSessionDocSchema, WorkoutTemplateDocSchema],
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
    'session snapshot survives edit, restart and template deletion',
    () async {
      final doc = fixture('Original');
      await repo.saveWorkoutTemplate(doc);
      final original = WorkoutPlanSnapshot.capture(doc);
      final session = await repo.completeWorkout(
        plan: original,
        dayIndex: 1,
        notes: 'Felt steady',
      );
      final edited = jsonDecode(doc.json) as Map<String, dynamic>;
      edited['days'][0]['exercises'][0]['workingSets'] = 9;
      await repo.updateWorkoutTemplateJson(doc.id, jsonEncode(edited));
      final current = (await repo.getLatestWorkoutTemplate())!;
      expect(
        WorkoutPlanSnapshot.capture(current).planId,
        isNot(original.planId),
      );
      expect(
        await repo.getLatestWorkoutSession(
          planId: WorkoutPlanSnapshot.capture(current).planId,
        ),
        isNull,
      );
      await repo.deleteWorkoutTemplate(doc.id);
      await database.close();
      database = await open();
      final stored = (await database.workoutSessionDocs.get(session.id))!;
      final snapshot = WorkoutPlanSnapshot.fromSession(stored)!;
      expect(snapshot.name, 'Original');
      expect(snapshot.day(1)!['exercises'][0]['workingSets'], 4);
      expect(snapshot.day(1)!['exercises'][0]['restSeconds'], 120);
      expect(stored.notes, 'Felt steady');
    },
  );
  test('completing A never completes B or a skipped session', () async {
    final a = fixture('A'), b = fixture('B');
    await repo.saveWorkoutTemplate(a);
    await repo.saveWorkoutTemplate(b);
    final pa = WorkoutPlanSnapshot.capture(a),
        pb = WorkoutPlanSnapshot.capture(b);
    final openB = await repo.startTodaySession(dayIndex: 1, plan: pb);
    await repo.skipSession(dayIndex: 1, reason: 'Rest', plan: pa);
    final doneA = await repo.completeWorkout(plan: pa, dayIndex: 1);
    expect(
      (await database.workoutSessionDocs.get(openB.id))!.completed,
      isFalse,
    );
    final all = await database.workoutSessionDocs.where().findAll();
    expect(all.where((s) => s.skipped && !s.completed).length, 1);
    expect(doneA.planId, pa.planId);
  });
  test(
    'start reuses only same plan, revision and day under concurrent calls',
    () async {
      final a = fixture('A');
      await repo.saveWorkoutTemplate(a);
      final plan = WorkoutPlanSnapshot.capture(a);
      final sessions = await Future.wait(
        List.generate(
          4,
          (_) => repo.startTodaySession(dayIndex: 1, plan: plan),
        ),
      );
      expect(sessions.map((s) => s.id).toSet().length, 1);
      final day2 = await repo.startTodaySession(dayIndex: 2, plan: plan);
      expect(day2.id, isNot(sessions.first.id));
      await repo.updateSessionNotes(day2.id, 'Updated note');
      expect(
        (await database.workoutSessionDocs.get(day2.id))!.templateSnapshotJson,
        plan.json,
      );
    },
  );
  test(
    'progression resets for another plan and edits, preserving original progress',
    () async {
      final a = fixture('A'), b = fixture('B', days: 2);
      await repo.saveWorkoutTemplate(a);
      await repo.saveWorkoutTemplate(b);
      await repo.completeWorkout(
        plan: WorkoutPlanSnapshot.capture(a),
        dayIndex: 2,
      );
      final active = StateProvider<WorkoutTemplateDoc>((ref) => a);
      final container = ProviderContainer(
        overrides: [
          lyvaRepoProvider.overrideWithValue(repo),
          latestWorkoutTemplateProvider.overrideWith(
            (ref) async => ref.watch(active),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(todayWorkoutDayProvider.future), 3);
      container.read(active.notifier).state = b;
      expect(await container.read(todayWorkoutDayProvider.future), 1);
      final editedA = fixture('A edited')..id = a.id;
      container.read(active.notifier).state = editedA;
      expect(await container.read(todayWorkoutDayProvider.future), 1);
      container.read(active.notifier).state = a;
      expect(await container.read(todayWorkoutDayProvider.future), 3);
    },
  );
  test(
    'real old-schema upgrade preserves records without guessing origin',
    () async {
      await database.close();
      final old = await Isar.open(
        [legacyWorkoutSessionSchema],
        directory: directory.path,
        name: 'history',
        inspector: false,
      );
      final legacy = LegacyWorkoutSession()
        ..date = DateTime(2026, 1, 2)
        ..dayIndex = 3
        ..completed = true
        ..notes = 'Old note';
      await old.writeTxn(() async {
        await old.collection<LegacyWorkoutSession>().put(legacy);
      });
      await old.close();
      database = await open();
      final restored = (await database.workoutSessionDocs.get(legacy.id))!;
      expect(restored.date, DateTime(2026, 1, 2));
      expect(restored.notes, 'Old note');
      expect(restored.completed, isTrue);
      expect(restored.planId, isNull);
      expect(restored.templateSnapshotJson, isNull);
      expect(restored.progressJson, isNull);
      expect(WorkoutPlanSnapshot.fromSession(restored), isNull);
      final doc = fixture('New');
      await repo.saveWorkoutTemplate(doc);
      expect(
        await repo.getLatestWorkoutSession(
          planId: WorkoutPlanSnapshot.capture(doc).planId,
        ),
        isNull,
      );
    },
  );
  test(
    'identity survives JSON key order but changes with a prescription',
    () async {
      final a = fixture('A')..id = 1;
      final first = WorkoutPlanSnapshot.capture(a);
      final map = jsonDecode(a.json) as Map<String, dynamic>;
      final exercise = map['days'][0]['exercises'][0] as Map<String, dynamic>;
      map['days'][0]['exercises'][0] = Map.fromEntries(
        exercise.entries.toList().reversed,
      );
      a.json = jsonEncode(map);
      expect(WorkoutPlanSnapshot.capture(a).planId, first.planId);
      map['days'][0]['exercises'][0]['sets'] = 5;
      a.json = jsonEncode(map);
      expect(WorkoutPlanSnapshot.capture(a).planId, isNot(first.planId));
    },
  );
  test(
    'corrupt or future history snapshots do not fall back to current plan',
    () {
      final session = WorkoutSessionDoc()
        ..dayIndex = 1
        ..planId = 'unknown'
        ..templateSnapshotJson = '{broken';
      expect(WorkoutPlanSnapshot.fromSession(session), isNull);
      session.templateSnapshotJson = jsonEncode({'schemaVersion': 2});
      expect(WorkoutPlanSnapshot.fromSession(session), isNull);
    },
  );
  testWidgets(
    'history renders original prescriptions without current-plan lookup',
    (tester) async {
      final snapshot = WorkoutPlanSnapshot.capture(
        fixture('Historical')..id = 12,
      );
      final session = WorkoutSessionDoc()
        ..date = DateTime(2026)
        ..dayIndex = 1
        ..completed = true
        ..planId = snapshot.planId
        ..templateSnapshotJson = snapshot.json;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutSessionDetailDialog(
              date: session.date,
              session: session,
            ),
          ),
        ),
      );
      expect(find.text('Historical squat'), findsOneWidget);
      expect(find.text('4 sets x 8-8 reps | 120s rest'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('legacy history labels missing detail while retaining notes', (
    tester,
  ) async {
    final session = WorkoutSessionDoc()
      ..date = DateTime(2026)
      ..dayIndex = 2
      ..completed = true
      ..notes = 'Preserved';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutSessionDetailDialog(
            date: session.date,
            session: session,
          ),
        ),
      ),
    );
    expect(
      find.text('Original workout details were not saved for this session.'),
      findsOneWidget,
    );
    expect(find.text('Preserved'), findsOneWidget);
  });
}
