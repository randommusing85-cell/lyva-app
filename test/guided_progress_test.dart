import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/guided_progress.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'workout_history_test.dart' show fixture;

void main() {
  late Directory directory;
  late Isar database;
  late LyvaRepo repo;
  late WorkoutPlanSnapshot plan;
  Future<Isar> open() => Isar.open(
    [WorkoutSessionDocSchema, WorkoutTemplateDocSchema],
    directory: directory.path,
    name: 'guided',
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
    directory = await Directory.systemTemp.createTemp('lyva_guided_');
    database = await open();
    repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => database);
    final doc = fixture('Saved');
    await repo.saveWorkoutTemplate(doc);
    plan = WorkoutPlanSnapshot.capture(doc);
  });
  tearDown(() async {
    if (database.isOpen) await database.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });
  Future<WorkoutSessionDoc> start() =>
      repo.beginGuidedSession(plan: plan, dayIndex: 1);
  GuidedProgress progress(WorkoutSessionDoc s) => GuidedProgress.read(
    s.progressJson,
    GuidedProgress.exercises(plan, s.dayIndex),
  );
  Future<WorkoutSessionDoc> save(
    WorkoutSessionDoc s,
    GuidedProgress p, {
    bool finish = false,
  }) => repo.saveGuidedProgress(
    sessionId: s.id,
    planId: plan.planId,
    progress: p,
    finish: finish,
  );

  test(
    'start is idempotent; progress and rest survive reopen and midnight resume',
    () async {
      final s = await start();
      final e = GuidedProgress.exercises(plan, 1);
      expect((await start()).id, s.id);
      final deadline = DateTime.utc(2026, 11, 3, 12, 2);
      final updated = await save(
        s,
        progress(s).change(
          e,
          exerciseId: 'squat',
          setIndex: 0,
          checked: true,
          actualReps: 7,
          restUntil: deadline,
        ),
      );
      updated.date = DateTime.now().subtract(const Duration(days: 1));
      await database.writeTxn(() async {
        await database.workoutSessionDocs.put(updated);
      });
      await database.close();
      database = await open();
      final resumed = await start();
      expect(resumed.id, s.id);
      expect(progress(resumed).completedSets, 1);
      expect(progress(resumed).reps['squat']![0], 7);
      expect(
        progress(
          resumed,
        ).remainingRest(deadline.subtract(const Duration(seconds: 50))),
        50,
      );
      expect(
        progress(
          resumed,
        ).remainingRest(deadline.add(const Duration(seconds: 1))),
        0,
      );
    },
  );
  test(
    'stale concurrent writes, wrong identity and deleted records cannot overwrite or resurrect',
    () async {
      final s = await start(), e = GuidedProgress.exercises(plan, 1);
      final old = progress(s);
      await save(
        s,
        old.change(e, exerciseId: 'squat', setIndex: 0, checked: true),
      );
      await expectLater(
        save(s, old.change(e, exerciseId: 'squat', setIndex: 1, checked: true)),
        throwsStateError,
      );
      expect(progress((await repo.getWorkoutSession(s.id))!).completedSets, 1);
      await expectLater(
        repo.saveGuidedProgress(
          sessionId: s.id,
          planId: 'wrong',
          progress: old,
        ),
        throwsStateError,
      );
      await database.writeTxn(() async {
        await database.workoutSessionDocs.delete(s.id);
      });
      await expectLater(save(s, old), throwsStateError);
      expect(await repo.getWorkoutSession(s.id), isNull);
    },
  );
  test(
    'changed plan blocks stale starts while exact existing session remains editable',
    () async {
      final s = await start();
      final doc = (await repo.getLatestWorkoutTemplate())!;
      final data = jsonDecode(doc.json);
      data['days'][0]['exercises'][0]['workingSets'] = 8;
      await repo.updateWorkoutTemplateJson(doc.id, jsonEncode(data));
      await expectLater(start(), throwsStateError);
      final updated = await save(
        s,
        progress(s).change(
          GuidedProgress.exercises(plan, 1),
          exerciseId: 'squat',
          setIndex: 0,
          checked: true,
        ),
      );
      expect(
        GuidedProgress.exercises(
          WorkoutPlanSnapshot.fromSession(updated)!,
          1,
        ).single.sets,
        4,
      );
    },
  );
  test(
    'finish requires all sets, closes exact ID once, and rejects late writes',
    () async {
      final s = await start(), e = GuidedProgress.exercises(plan, 1);
      var p = progress(s);
      await expectLater(save(s, p, finish: true), throwsStateError);
      for (var i = 0; i < 4; i++) {
        p = p.change(e, exerciseId: 'squat', setIndex: i, checked: true);
      }
      final closed = await save(s, p, finish: true);
      expect(closed.completed, isTrue);
      expect(progress(closed).completedSets, 4);
      await expectLater(save(s, p, finish: true), throwsStateError);
      await expectLater(
        start(),
        throwsStateError,
      ); // stale Day 1 must not start again
      final next = await repo.beginGuidedSession(plan: plan, dayIndex: 2);
      expect(next.id, isNot(s.id));
    },
  );
  test(
    'ending early preserves performed sets without marking full completion or advancing',
    () async {
      final s = await start(), e = GuidedProgress.exercises(plan, 1);
      final p = progress(s).change(
        e,
        exerciseId: 'squat',
        setIndex: 0,
        checked: true,
        endedEarly: true,
      );
      await expectLater(save(s, p), throwsStateError);
      final closed = await save(s, p, finish: true);
      expect(closed.completed, isFalse);
      expect(closed.skipped, isTrue);
      expect(progress(closed).completedSets, 1);
      expect(closed.skipReason, contains('1/4'));
      final next = await start();
      expect(next.id, isNot(closed.id));
      expect(next.dayIndex, 1);
    },
  );
  test('malformed progress is rejected without replacing saved data', () async {
    final s = await start(), e = GuidedProgress.exercises(plan, 1);
    final original = s.progressJson;
    expect(
      () => progress(
        s,
      ).change(e, exerciseId: 'squat', setIndex: 0, actualReps: -1),
      throwsFormatException,
    );
    expect(() => progress(s).change(e, current: 8), throwsFormatException);
    final raw = progress(s).toJson()..['version'] = 2;
    expect(
      () => GuidedProgress.read(jsonEncode(raw), e),
      throwsFormatException,
    );
    expect((await repo.getWorkoutSession(s.id))!.progressJson, original);
  });
  test(
    'legacy null progress initializes only unchecked prescribed sets',
    () async {
      final legacy = await repo.startTodaySession(dayIndex: 1, plan: plan);
      expect(legacy.progressJson, isNull);
      final resumed = await start();
      expect(resumed.id, legacy.id);
      expect(progress(resumed).completedSets, 0);
      expect(progress(resumed).totalSets, 4);
    },
  );
  test('undo and clearing actual reps persist independently without changing prescription', () async {
    final s = await start(), e = GuidedProgress.exercises(plan, 1);
    final first = await save(s, progress(s).change(e, exerciseId: 'squat', setIndex: 0, checked: true, actualReps: 7));
    final undone = await save(first, progress(first).change(e, exerciseId: 'squat', setIndex: 0, checked: false, clearReps: true));
    expect(progress(undone).completedSets, 0);
    expect(progress(undone).reps['squat']![0], isNull);
    expect(WorkoutPlanSnapshot.fromSession(undone)!.json, plan.json);
  });

}
