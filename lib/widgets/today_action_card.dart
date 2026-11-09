import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/today_workout_state.dart';
import '../models/workout_plan_snapshot.dart';
import '../state/providers.dart';

final todayActionProvider = FutureProvider.autoDispose<TodayWorkoutState?>((
  ref,
) async {
  final doc = await ref.watch(latestWorkoutTemplateProvider.future);
  if (doc == null) return null;
  final profile = await ref.watch(userProfileProvider.future);
  final plan = WorkoutPlanSnapshot.capture(doc);
  final last = await ref
      .watch(lyvaRepoProvider)
      .getLatestWorkoutSession(planId: plan.planId);
  return TodayWorkoutState.resolve(
    plan: plan,
    last: last,
    now: DateTime.now(),
    scheduledDays: profile?.scheduledDaysList ?? const [],
  );
});

class TodayActionCard extends ConsumerStatefulWidget {
  const TodayActionCard({super.key});
  @override
  ConsumerState<TodayActionCard> createState() => _TodayActionCardState();
}

class _TodayActionCardState extends ConsumerState<TodayActionCard> {
  bool busy = false;
  String? failure;
  Future<void> open(TodayWorkoutState state, {bool start = false}) async {
    setState(() {
      busy = true;
      failure = null;
    });
    try {
      final repo = ref.read(lyvaRepoProvider);
      final current = await repo.getLatestWorkoutTemplate();
      if (current == null ||
          WorkoutPlanSnapshot.capture(current).planId != state.plan.planId) {
        throw StateError('Plan changed');
      }
      final session = start
          ? await repo.beginGuidedSession(
              dayIndex: state.dayIndex,
              plan: state.plan,
            )
          : null;
      if (!mounted) return;
      ref.invalidate(todayWorkoutDayProvider);
      await Navigator.pushNamed(
        context,
        start ? '/guided-workout' : '/today-workout',
        arguments: session?.id,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          failure = 'Could not open the saved session. Refresh and try again.';
        });
      }
    } finally {
      if (mounted) {
        ref.invalidate(todayActionProvider);
        ref.invalidate(thisWeekSessionsProvider);
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ref
          .watch(todayActionProvider)
          .when(
            loading: () => const Column(
              children: [
                Text('Loading your saved workout'),
                LinearProgressIndicator(),
              ],
            ),
            error: (_, _) => Column(
              children: [
                const Text('Your saved workout could not be loaded.'),
                TextButton(
                  onPressed: () {
                    ref.invalidate(latestWorkoutTemplateProvider);
                    ref.invalidate(userProfileProvider);
                    ref.invalidate(todayActionProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (state) {
              if (state == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No workout plan saved'),
                    const Text(
                      'You can still log a check-in or nutrition below.',
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/setup-guide'),
                      child: const Text('Explore plan setup'),
                    ),
                  ],
                );
              }
              final status = state.status;
              final heading = switch (status) {
                TodayWorkoutStatus.ready => 'Your next session',
                TodayWorkoutStatus.resume => 'Session started',
                TodayWorkoutStatus.completed => 'Workout completed today',
                TodayWorkoutStatus.rest => 'Rest day',
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '${state.plan.name} · Day ${state.dayIndex}: ${state.title}',
                  ),
                  Text('${state.exerciseCount} saved exercises'),
                  if (status == TodayWorkoutStatus.resume)
                    const Text(
                      'Guided sets and actual reps are saved as you log them.',
                    ),
                  if (status == TodayWorkoutStatus.rest)
                    const Text(
                      'Based on your saved schedule or skipped session. Logging is still available.',
                    ),
                  if (failure != null) Text(failure!),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => open(
                            state,
                            start:
                                status == TodayWorkoutStatus.ready ||
                                status == TodayWorkoutStatus.resume,
                          ),
                    child: Text(
                      busy
                          ? 'Opening…'
                          : switch (status) {
                              TodayWorkoutStatus.ready => 'Start session',
                              TodayWorkoutStatus.resume => 'Resume session',
                              _ => 'View next session',
                            },
                    ),
                  ),
                ],
              );
            },
          ),
    ),
  );
}
