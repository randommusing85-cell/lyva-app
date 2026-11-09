import 'package:isar/isar.dart';

part 'workout_session_doc.g.dart';

@collection
class WorkoutSessionDoc {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // local date/time when started/completed

  late int dayIndex; // 1..daysPerWeek
  late bool completed;

  // Skip tracking
  bool skipped = false;
  String? skipReason;

  // Notes/feedback from the workout
  String? notes;

  /// How hard the completed session felt: 1 (easy) to 5 (maximal).
  int? perceivedExertion;

  // optional, but handy
  String? planId; // template identity plus immutable prescription revision

  // Null on legacy sessions. Never infer historical prescriptions from today's plan.
  String? templateSnapshotJson;

  // Versioned optional guided set progress; null for existing sessions.
  String? progressJson;
}
