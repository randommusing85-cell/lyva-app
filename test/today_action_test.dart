import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/today_workout_state.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/widgets/today_action_card.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/state/providers.dart';
import 'routine_workout_answers_test.dart' show fixture;

class ActionRepo extends LyvaRepo {
  bool fail = false;
  bool changed = false;
  int starts = 0;
  @override
  Future<WorkoutTemplateDoc?> getLatestWorkoutTemplate() async =>
      fixture(sets: changed ? 8 : 3);
  @override
  Future<WorkoutSessionDoc> beginGuidedSession({
    required int dayIndex,
    required WorkoutPlanSnapshot plan,
  }) async {
    starts++;
    if (fail) throw StateError('write failed');
    return WorkoutSessionDoc()
      ..date = DateTime.now()
      ..dayIndex = dayIndex
      ..completed = false
      ..planId = plan.planId;
  }
}

void main() {
  final now = DateTime(2026, 11, 3, 12);
  final plan = WorkoutPlanSnapshot.capture(fixture());
  WorkoutSessionDoc session({
    bool completed = false,
    bool skipped = false,
    int day = 1,
  }) => WorkoutSessionDoc()
    ..date = now
    ..dayIndex = day
    ..completed = completed
    ..skipped = skipped
    ..planId = plan.planId;
  TodayWorkoutState resolve({
    WorkoutSessionDoc? last,
    List<int> days = const [],
  }) => TodayWorkoutState.resolve(
    plan: plan,
    last: last,
    now: now,
    scheduledDays: days,
  );
  test('flexible schedule is ready; actual next day follows completion', () {
    expect(resolve().status, TodayWorkoutStatus.ready);
    final state = resolve(last: session(completed: true));
    expect(state.status, TodayWorkoutStatus.completed);
    expect(state.dayIndex, 2);
    expect(state.title, 'Second day');
    expect(state.exerciseCount, 1);
  });
  test(
    'started session wins over schedule; skip and explicit schedule are rest',
    () {
      expect(
        resolve(last: session(), days: [1]).status,
        TodayWorkoutStatus.resume,
      );
      expect(
        resolve(last: session(skipped: true)).status,
        TodayWorkoutStatus.rest,
      );
      expect(resolve(days: [1]).status, TodayWorkoutStatus.rest);
      expect(resolve(days: [2]).status, TodayWorkoutStatus.ready);
    },
  );
  test('other plans and future records do not control today', () {
    expect(resolve(last: session(completed: true)..planId = 'old').dayIndex, 1);
    expect(
      resolve(
        last: session(completed: true)..date = now.add(const Duration(days: 1)),
      ).status,
      TodayWorkoutStatus.ready,
    );
  });
  test('yesterday completion advances without claiming completion today', () {
    final state = resolve(
      last: session(completed: true)
        ..date = now.subtract(const Duration(days: 1)),
    );
    expect(state.dayIndex, 2);
    expect(state.status, TodayWorkoutStatus.ready);
  });
  test('incomplete saved day fails honestly', () {
    final doc = fixture()..json = '{"days":[]}';
    expect(
      () => TodayWorkoutState.resolve(
        plan: WorkoutPlanSnapshot.capture(doc),
        now: now,
      ),
      throwsFormatException,
    );
  });
  Future<void> render(
    WidgetTester tester,
    Future<TodayWorkoutState?> Function() load,
  ) => tester.pumpWidget(
    ProviderScope(
      overrides: [todayActionProvider.overrideWith((ref) => load())],
      child: const MaterialApp(home: Scaffold(body: TodayActionCard())),
    ),
  );
  testWidgets('loading then empty keeps guest tracking guidance', (
    tester,
  ) async {
    final pending = Completer<TodayWorkoutState?>();
    await render(tester, () => pending.future);
    expect(find.text('Loading your saved workout'), findsOneWidget);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('No workout plan saved'), findsOneWidget);
    expect(find.text('Explore plan setup'), findsOneWidget);
    expect(find.textContaining('45'), findsNothing);
  });
  testWidgets('failed load exposes retry instead of hiding card', (
    tester,
  ) async {
    var attempts = 0;
    await render(tester, () async {
      if (attempts++ == 0) throw StateError('offline');
      return null;
    });
    await tester.pumpAndSettle();
    expect(
      find.text('Your saved workout could not be loaded.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No workout plan saved'), findsOneWidget);
  });
  testWidgets('completed state displays next saved day without starting it', (
    tester,
  ) async {
    await render(tester, () async => resolve(last: session(completed: true)));
    await tester.pumpAndSettle();
    expect(find.text('Workout completed today'), findsOneWidget);
    expect(find.textContaining('Day 2: Second day'), findsOneWidget);
    expect(find.text('View next session'), findsOneWidget);
    expect(find.text('Start session'), findsNothing);
  });
  for (final scenario in ['success', 'failure', 'changed']) {
    testWidgets('start $scenario saves before navigation or shows failure', (
      tester,
    ) async {
      final repo = ActionRepo()
        ..fail = scenario == 'failure'
        ..changed = scenario == 'changed';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayActionProvider.overrideWith((ref) async => resolve()),
            lyvaRepoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: const Scaffold(body: TodayActionCard()),
            routes: {
              '/guided-workout': (_) =>
                  const Scaffold(body: Text('Runner fixture')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.starts, 0);
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();
      expect(repo.starts, scenario == 'changed' ? 0 : 1);
      expect(
        find.text('Runner fixture'),
        scenario == 'success' ? findsOneWidget : findsNothing,
      );
      if (scenario != 'success') {
        expect(find.textContaining('Could not open'), findsOneWidget);
      }
    });
  }
}
