import '../models/workout_plan_snapshot.dart';
import '../models/workout_session_doc.dart';
import '../utils/workout_progression.dart';

enum TodayWorkoutStatus { ready, resume, completed, rest }

class TodayWorkoutState {
  final WorkoutPlanSnapshot plan;
  final int dayIndex;
  final TodayWorkoutStatus status;
  final String title;
  final int exerciseCount;
  TodayWorkoutState._(
    this.plan,
    this.dayIndex,
    this.status,
    this.title,
    this.exerciseCount,
  );

  factory TodayWorkoutState.resolve({
    required WorkoutPlanSnapshot plan,
    WorkoutSessionDoc? last,
    required DateTime now,
    List<int> scheduledDays = const [],
  }) {
    if (last?.planId != plan.planId || (last != null && last.date.isAfter(now))) {
      last = null;
    }
    final index = workoutDayIndex(plan.daysPerWeek, last);
    final day = plan.day(index);
    final exercises = day?['exercises'];
    if (exercises is! List || exercises.isEmpty) {
      throw const FormatException('Saved workout day is incomplete');
    }
    final sameDay =
        last != null &&
        last.date.year == now.year &&
        last.date.month == now.month &&
        last.date.day == now.day;
    final status = sameDay && last.completed
        ? TodayWorkoutStatus.completed
        : sameDay && last.skipped
        ? TodayWorkoutStatus.rest
        : last != null && !last.completed && !last.skipped
        ? TodayWorkoutStatus.resume
        : scheduledDays.isNotEmpty && !scheduledDays.contains(now.weekday)
        ? TodayWorkoutStatus.rest
        : TodayWorkoutStatus.ready;
    return TodayWorkoutState._(
      plan,
      index,
      status,
      day?['title']?.toString() ?? 'Day $index',
      exercises.length,
    );
  }
}
