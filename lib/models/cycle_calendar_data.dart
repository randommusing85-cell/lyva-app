import 'cycle_log.dart';
import 'user_profile.dart';

/// Local calendar presentation, not a phase, fertility or diagnostic model.
class CycleCalendarData {
  CycleCalendarData({
    required this.profile,
    required List<CycleLog> logs,
    required DateTime today,
    this.showEstimate = false,
  }) : today = day(today),
       logs = List.unmodifiable(logs);
  final UserProfile profile;
  final List<CycleLog> logs;
  final DateTime today;
  final bool showEstimate;
  static DateTime day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  List<CycleLog> events(DateTime date) => profile.trackCycle
      ? (logs.where((log) => day(log.ts) == day(date)).toList()
          ..sort((a, b) => a.ts.compareTo(b.ts)))
      : [];
  List<DateTime> get _starts =>
      (logs
          .where(
            (log) =>
                log.eventType == 'period_start' && !day(log.ts).isAfter(today),
          )
          .map((log) => day(log.ts))
          .toSet()
          .toList()
        ..sort());
  int? get intervalDays {
    final starts = _starts;
    // Product minimum, not a clinical validation threshold: two observed intervals.
    if (starts.length < 3) {
      return null;
    }
    final first = starts[starts.length - 3], last = starts.last;
    return (DateTime.utc(last.year, last.month, last.day)
                .difference(DateTime.utc(first.year, first.month, first.day))
                .inDays /
            2)
        .round();
  }

  DateTime? get projectedStart {
    if (!showEstimate ||
        !profile.trackCycle ||
        profile.postPartumStatus != 'no') {
      return null;
    }
    final interval = intervalDays;
    if (interval == null || interval <= 0) {
      return null;
    }
    final last = _starts.last;
    // One arithmetic projection only. Never roll missed logs into invented cycles.
    final next = DateTime(last.year, last.month, last.day + interval);
    return next.isBefore(today) ? null : next;
  }

  String get estimateExplanation {
    if (!showEstimate) {
      return 'Recorded events only. Calendar estimates are off.';
    }
    if (projectedStart == null) {
      return 'No current estimate. At least three distinct logged starts are needed; a previous estimate may have passed or this context may not support estimates. Missing logs are not assumed to be new cycles.';
    }
    return 'Calendar estimate: latest logged start plus the rounded average of the last two logged intervals ($intervalDays days). Missing logs can distort this simple calculation. Timing varies; this is not a measured phase, a validated forecast or a confidence interval.';
  }

  static String eventLabel(CycleLog log) => switch (log.eventType) {
    'period_start' => 'Period start logged',
    'period_end' => 'Period end logged',
    'spotting' => 'Spotting logged',
    'symptom' => '${log.symptomType?.replaceAll('_', ' ') ?? 'Symptom'} logged',
    _ => 'Other recorded event',
  };
  String summary(DateTime date) {
    final records = events(date);
    final fact = records.isEmpty
        ? 'No events logged'
        : records.map(eventLabel).toSet().join(', ');
    return projectedStart == day(date)
        ? '$fact; estimated period start, not confirmed'
        : fact;
  }
}
