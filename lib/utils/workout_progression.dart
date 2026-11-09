import '../models/workout_session_doc.dart';

/// Existing progression policy, shared by Today and local factual answers.
int workoutDayIndex(int days, WorkoutSessionDoc? last) {
  if (days < 1) throw ArgumentError('Plan has no days');
  if (last == null || last.dayIndex < 1 || last.dayIndex > days) return 1;
  if (!last.completed) return last.dayIndex;
  return last.dayIndex == days ? 1 : last.dayIndex + 1;
}
