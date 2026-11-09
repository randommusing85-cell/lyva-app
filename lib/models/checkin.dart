import 'package:isar/isar.dart';

part 'checkin.g.dart';

@collection
class CheckIn {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;
  double? weightKg;
  double? waistCm;
  int? stepsToday;

  String? note;

  /// Mood score 1-5 (for cycle prediction integration)
  int? moodScore;

  /// Energy score 1-5 (for cycle prediction integration)
  int? energyScore;

  /// Optional self-reported recovery signals, each scored 1-5.
  int? sleepScore;
  int? stressScore;
  int? sorenessScore;
  int? hungerScore;
}