import 'package:lyva_app/services/personalization_safety.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/guided_progress.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/screens/guided_workout_screen.dart';
import 'package:lyva_app/state/providers.dart';
import 'routine_workout_answers_test.dart' show fixture;

class RunnerRepo extends LyvaRepo {
  final plan = WorkoutPlanSnapshot.capture(fixture());
  late WorkoutSessionDoc? record = WorkoutSessionDoc()
    ..id = 17
    ..date = DateTime.now()
    ..dayIndex = 1
    ..completed = false
    ..planId = plan.planId
    ..templateSnapshotJson = plan.json;
  bool fail = false;
  Completer<void>? delay;
  int saves = 0;
  @override
  Future<WorkoutSessionDoc?> getWorkoutSession(int id) async => record;
  @override
  Future<WorkoutSessionDoc> saveGuidedProgress({
    required int sessionId,
    required String planId,
    required GuidedProgress progress,
    bool finish = false,
    String? notes,
  }) async {
    saves++;
    if (delay != null) await delay!.future;
    if (fail) throw StateError('write failed');
    final r = record!;
    r.progressJson = progress
        .change(
          GuidedProgress.exercises(plan, 1),
          revision: progress.revision + 1,
        )
        .json;
    r.completed = finish && !progress.endedEarly;
    r.skipped = finish && progress.endedEarly;
    r.notes = notes;
    return r;
  }
}

class DelayedLoadRepo extends RunnerRepo {
  final loaded = Completer<WorkoutSessionDoc?>();
  @override
  Future<WorkoutSessionDoc?> getWorkoutSession(int id) => loaded.future;
}

void main() {
  Future<void> render(WidgetTester tester, RunnerRepo repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),lyvaRepoProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: GuidedWorkoutScreen(sessionId: 17)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'reads pinned prescription, records sets, and restores after navigation',
    (tester) async {
      final repo = RunnerRepo();
      await render(tester, repo);
      expect(find.text('Fixture move'), findsOneWidget);
      expect(find.textContaining('90s rest'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('1/3 sets saved'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await render(tester, repo);
      expect(find.text('1/3 sets saved'), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isTrue,
      );
    },
  );
  testWidgets('failed save does not check the set; retry succeeds', (
    tester,
  ) async {
    final repo = RunnerRepo()..fail = true;
    await render(tester, repo);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Progress was not saved'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
    repo.fail = false;
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1/3 sets saved'), findsOneWidget);
  });
  testWidgets(
    'delayed writes disable repeat actions and safely finish after disposal',
    (tester) async {
      final repo = RunnerRepo()..delay = Completer<void>();
      await render(tester, repo);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged,
        isNull,
      );
      expect(repo.saves, 1);
      await tester.pumpWidget(const SizedBox());
      repo.delay!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('missing session is honest and never starts a replacement', (
    tester,
  ) async {
    final repo = RunnerRepo()..record = null;
    await render(tester, repo);
    expect(find.textContaining('Saved session unavailable'), findsOneWidget);
    expect(repo.saves, 0);
    expect(find.byType(Checkbox), findsNothing);
  });
  testWidgets('actual reps validated and saved independently of completion', (
    tester,
  ) async {
    final repo = RunnerRepo();
    await render(tester, repo);
    await tester.tap(find.text('Log reps for set 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-1');
    await tester.tap(find.text('Save reps'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number from 0 to 1000.'), findsOneWidget);
    expect(repo.saves, 0);
    await tester.enterText(find.byType(TextFormField), '7');
    await tester.tap(find.text('Save reps'));
    await tester.pumpAndSettle();
    expect(find.text('7 actual reps'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
  });
  testWidgets(
    'end early requires confirmation and produces saved partial summary',
    (tester) async {
      final repo = RunnerRepo();
      await render(tester, repo);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('End early and save'), 300);
      await tester.tap(find.text('End early and save'));
      await tester.pumpAndSettle();
      expect(repo.record!.skipped, isFalse);
      await tester.tap(find.text('Save summary'));
      await tester.pumpAndSettle();
      expect(find.text('Session ended early'), findsOneWidget);
      expect(find.text('1/3 sets recorded'), findsOneWidget);
      expect(repo.record!.completed, isFalse);
      expect(repo.record!.skipped, isTrue);
    },
  );
  testWidgets(
    'finish stays disabled until all prescribed sets are saved and summary survives reload',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = RunnerRepo();
      await render(tester, repo);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Finish session'),
            )
            .onPressed,
        isNull,
      );
      for (var i = 0; i < 3; i++) {
        final tile = find.widgetWithText(CheckboxListTile, 'Set ${i + 1}');
        await tester.tap(
          find.descendant(of: tile, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save summary'));
      await tester.pumpAndSettle();
      expect(find.text('Session completed'), findsOneWidget);
      expect(find.text('3/3 sets recorded'), findsOneWidget);
      expect(
        find.textContaining('Next in this saved plan: Day 2'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await render(tester, repo);
      expect(find.text('Session completed'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    },
  );

  testWidgets(
    'unsaved notes survive failed save and reload and require explicit discard on back',
    (tester) async {
      final repo = RunnerRepo();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),lyvaRepoProvider.overrideWithValue(repo)],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const GuidedWorkoutScreen(sessionId: 17),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'Keep my draft');
      await tester.pump();
      repo.fail = true;
      await tester.scrollUntilVisible(
        find.text('Set 1'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Set 1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Reload saved session'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reload saved session'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Keep my draft',
      );
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving notes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Keep my draft',
      );
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard notes and leave'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(repo.record!.notes, isNull);
    },
  );

  testWidgets(
    'pending session load can be left and late result does not reopen it',
    (tester) async {
      final repo = DelayedLoadRepo(), navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),lyvaRepoProvider.overrideWithValue(repo)],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const GuidedWorkoutScreen(sessionId: 17),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      repo.loaded.complete(repo.record);
      await tester.pumpAndSettle();
      expect(find.byType(GuidedWorkoutScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
