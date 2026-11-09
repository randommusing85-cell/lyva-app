import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/recorded_week.dart';
import '../models/checkin.dart';
import '../models/workout_session_doc.dart';
import '../state/providers.dart';

final recordedWeekProvider = FutureProvider.autoDispose.family<RecordedWeek, DateTime>((ref, anchor) async {
  ref.watch(latestCheckInsStreamProvider);
  ref.watch(thisWeekSessionsProvider);
  final repo = ref.watch(lyvaRepoProvider), now = DateTime.now();
  final start = RecordedWeek.start(anchor);
  final end = DateTime(start.year, start.month, start.day + 7).subtract(const Duration(microseconds: 1));
  if (start.isAfter(now)) return RecordedWeek.resolve(anchor: anchor, now: now, sessions: [], checkIns: []);
  final results = await Future.wait([
    repo.getSessionsInDateRange(start, end.isAfter(now) ? now : end),
    repo.getCheckInsInDateRange(start, end.isAfter(now) ? now : end),
  ]);
  return RecordedWeek.resolve(anchor: anchor, now: now,
    sessions: results[0].cast<WorkoutSessionDoc>(), checkIns: results[1].cast<CheckIn>());
});

class RecordedWeekCard extends ConsumerWidget {
  final DateTime anchor;
  const RecordedWeekCard({super.key, required this.anchor});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(child: Padding(padding: const EdgeInsets.all(16),
    child: ref.watch(recordedWeekProvider(anchor)).when(
      loading: () => const Column(children: [Text('Loading recorded activity'), LinearProgressIndicator()]),
      error: (_, _) => Column(children: [const Text('Recorded activity could not be loaded.'),
        TextButton(onPressed: () => ref.invalidate(recordedWeekProvider(anchor)), child: const Text('Retry'))]),
      data: (week) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Week of ${DateFormat('MMM d').format(week.days.first.date)}', style: Theme.of(context).textTheme.titleLarge),
        Text('${week.workoutDays} day(s) with completed workouts · ${week.checkInDays} check-in day(s)'),
        const Text('These are your recorded entries. An unlogged day does not mean you were inactive. Rest counts only when explicitly recorded.'),
        for (final day in week.days) Padding(padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('${DateFormat('EEE, MMM d').format(day.date)}: ${day.label}')),
        const Text('Session duration, calories burned and total exercises are not inferred from workout counts.'),
        TextButton(onPressed: () => ref.invalidate(recordedWeekProvider(anchor)), child: const Text('Refresh records')),
      ]),
    )));
}
