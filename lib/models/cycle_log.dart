import 'package:isar/isar.dart';

part 'cycle_log.g.dart';

@collection
class CycleLog {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;

  /// 'period_start', 'period_end', 'spotting', 'symptom'
  late String eventType;

  /// For symptoms: 'cramps', 'bloating', 'headache', 'mood_change', etc.
  String? symptomType;

  /// Severity 1-5 for symptoms
  int? severity;

  /// Optional notes
  String? notes;
}
