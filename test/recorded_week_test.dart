import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/models/recorded_week.dart';
import 'package:lyva_app/widgets/recorded_week_card.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/state/providers.dart';

class WeekRepo extends LyvaRepo {
  DateTime? start, end;
  final List<WorkoutSessionDoc> sessions;
  final List<CheckIn> checkIns;
  WeekRepo(this.sessions, this.checkIns);
  @override Future<List<WorkoutSessionDoc>> getSessionsInDateRange(DateTime from, DateTime to) async { start = from; end = to; return sessions; }
  @override Future<List<CheckIn>> getCheckInsInDateRange(DateTime from, DateTime to) async => checkIns;
}
void main() {
  final now = DateTime(2026, 11, 4, 12); // Wednesday
  WorkoutSessionDoc session(int day, {bool done = false, bool skipped = false, String? reason}) => WorkoutSessionDoc()
    ..id = day..date = DateTime(2026, 11, day, 10)..dayIndex = 1..completed = done..skipped = skipped..skipReason = reason;
  RecordedWeek week(List<WorkoutSessionDoc> sessions, {List<CheckIn> checkIns = const []}) => RecordedWeek.resolve(anchor: now, now: now, sessions: sessions, checkIns: checkIns);
  test('empty week distinguishes unlogged days from future days, with no claimed inactivity', () {
    final result = week([]);
    expect(result.days.first.date, DateTime(2026, 11, 2));
    expect(result.workoutDays, 0); expect(result.checkInDays, 0);
    expect(result.days.take(3).map((d) => d.label), everyElement('No workout or check-in logged'));
    expect(result.days.skip(3).map((d) => d.label), everyElement('Upcoming'));
  });
  test('counts unique recorded days, preserving multiple kinds of activity', () {
    final result = week([session(2, done: true), session(2, done: true)..id = 99, session(2), session(3, skipped: true, reason: 'rest')],
      checkIns: [CheckIn()..ts = DateTime(2026,11,2)..moodScore = 3, CheckIn()..ts = DateTime(2026,11,2,11)..energyScore = 4]);
    expect(result.workoutDays, 1); expect(result.checkInDays, 1);
    expect(result.days.first.label, contains('Workout completed')); expect(result.days.first.label, contains('Session started'));
    expect(result.days[1].label, 'Rest recorded');
  });
  test('generic skips and early endings do not imply rest or full completion', () {
    final result = week([session(2, skipped: true, reason: 'busy'), session(3, skipped: true, reason: 'Ended early: 1/4 sets recorded')]);
    expect(result.workoutDays, 0); expect(result.days.first.rest, isFalse);
    expect(result.days.first.label, 'Session skipped or ended early');
  });
  test('wrong-week and future timestamps are excluded even if supplied by a reader', () {
    final result = week([session(1, done: true), session(4, done: true)..date = now.add(const Duration(hours: 1)), session(5, done: true)]);
    expect(result.workoutDays, 0);
    expect(result.days[2].label, 'No workout or check-in logged');
  });
  test('calendar week crosses month/year boundaries without day-label guessing', () {
    final anchor = DateTime(2027, 1, 1, 12);
    final result = RecordedWeek.resolve(anchor: anchor, now: anchor, sessions: [], checkIns: []);
    expect(result.days.first.date, DateTime(2026, 12, 28)); expect(result.days.last.date, DateTime(2027, 1, 3));
  });
  test('provider queries complete chosen week rather than latest N records', () async {
    final anchor = DateTime(2025, 2, 5);
    final repo = WeekRepo([], []);
    final container = ProviderContainer(overrides: [lyvaRepoProvider.overrideWithValue(repo),
      latestCheckInsStreamProvider.overrideWith((ref) => Stream.value([])), thisWeekSessionsProvider.overrideWith((ref) async => [])]);
    addTearDown(container.dispose);
    final subscription = container.listen(recordedWeekProvider(anchor), (_, _) {});
    addTearDown(subscription.close);
    await container.read(recordedWeekProvider(anchor).future);
    expect(repo.start, DateTime(2025, 2, 3)); expect(repo.end, DateTime(2025, 2, 10).subtract(const Duration(microseconds: 1)));
  });
  testWidgets('loading/error/retry never displays missing records as zero successes', (tester) async {
    final pending = Completer<RecordedWeek>(); var calls = 0;
    await tester.pumpWidget(ProviderScope(overrides: [recordedWeekProvider(now).overrideWith((ref) async {
      if (calls++ == 0) return pending.future; return week([]);
    })], child: MaterialApp(home: Scaffold(body: RecordedWeekCard(anchor: now)))));
    expect(find.text('Loading recorded activity'), findsOneWidget);
    pending.completeError(StateError('read failed')); await tester.pumpAndSettle();
    expect(find.text('Recorded activity could not be loaded.'), findsOneWidget);
    expect(find.textContaining('0 day(s)'), findsNothing);
    await tester.tap(find.text('Retry')); await tester.pumpAndSettle();
    expect(find.textContaining('0 day(s) with completed workouts'), findsOneWidget);
  });
  testWidgets('recorded state has no invented streak goal, duration or calories', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [recordedWeekProvider(now).overrideWith((ref) async => week([session(2, done: true), session(3, skipped: true, reason: 'rest')]))],
      child: MaterialApp(home: Scaffold(body: RecordedWeekCard(anchor: now)))));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 day(s) with completed workouts'), findsOneWidget);
    expect(find.textContaining('Rest recorded'), findsOneWidget);
    expect(find.textContaining('No workout or check-in logged'), findsOneWidget);
    expect(find.textContaining('45'), findsNothing);
    expect(find.textContaining('unlogged day does not mean'), findsOneWidget);
  });
  test('steps use latest recorded daily total without summing duplicates or filling missing days', () {
    final result = week([], checkIns: [
      CheckIn()..id = 1..ts = DateTime(2026,11,2,8)..stepsToday = 500,
      CheckIn()..id = 2..ts = DateTime(2026,11,2,10)..stepsToday = 800,
      CheckIn()..id = 3..ts = DateTime(2026,11,2,11)..moodScore = 3,
      CheckIn()..ts = DateTime(2026,11,3)..stepsToday = 0,
    ]);
    expect(result.days[0].steps, 800); expect(result.days[1].steps, 0); expect(result.days[2].steps, isNull);
  });

}
