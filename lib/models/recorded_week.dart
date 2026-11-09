import '../models/checkin.dart';
import '../models/workout_session_doc.dart';

class RecordedDay {
  final DateTime date;
  final bool upcoming;
  final int? steps;
  final bool completed, started, rest, skipped, checkIn;
  const RecordedDay(this.date, {required this.upcoming, required this.steps, required this.completed,
    required this.started, required this.rest, required this.skipped, required this.checkIn});
  String get label {
    if (upcoming) return 'Upcoming';
    final labels = [if (completed) 'Workout completed', if (started) 'Session started',
      if (rest) 'Rest recorded', if (skipped) 'Session skipped or ended early', if (checkIn) 'Check-in recorded'];
    return labels.isEmpty ? 'No workout or check-in logged' : labels.join(' · ');
  }
}
class RecordedWeek {
  final List<RecordedDay> days;
  const RecordedWeek(this.days);
  int get workoutDays => days.where((d) => d.completed).length;
  int get checkInDays => days.where((d) => d.checkIn).length;
  static DateTime start(DateTime anchor) {
    final local = anchor.toLocal();
    return DateTime(local.year, local.month, local.day - local.weekday + 1);
  }
  factory RecordedWeek.resolve({required DateTime anchor, required DateTime now,
      required List<WorkoutSessionDoc> sessions, required List<CheckIn> checkIns}) {
    final beginning = start(anchor), today = now.toLocal();
    bool sameDay(DateTime value, DateTime day) {
      final local = value.toLocal();
      return !value.isAfter(now) && local.year == day.year && local.month == day.month && local.day == day.day;
    }
    return RecordedWeek(List.unmodifiable(List.generate(7, (i) {
      final date = DateTime(beginning.year, beginning.month, beginning.day + i);
      final records = sessions.where((s) => sameDay(s.date, date)).toList();
      final stepRecords = checkIns.where((c) => sameDay(c.ts, date) && c.stepsToday != null && c.stepsToday! >= 0).toList()
        ..sort((a, b) { final time = b.ts.compareTo(a.ts); return time != 0 ? time : b.id.compareTo(a.id); });
      return RecordedDay(date, steps: stepRecords.isEmpty ? null : stepRecords.first.stepsToday, upcoming: date.isAfter(DateTime(today.year, today.month, today.day)),
        completed: records.any((s) => s.completed && !s.skipped),
        started: records.any((s) => !s.completed && !s.skipped),
        rest: records.any((s) => s.skipped && ['rest', 'Rest day'].contains(s.skipReason)),
        skipped: records.any((s) => s.skipped && !['rest', 'Rest day'].contains(s.skipReason)),
        checkIn: checkIns.any((c) => sameDay(c.ts, date)));
    })));
  }
}
