import 'package:isar/isar.dart';

part 'checkin.g.dart';

@collection
class CheckIn {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;
  late double weightKg;
  late double waistCm;
  late int stepsToday;

  String? note;

  /// Mood score 1-5 (for cycle prediction integration)
  int? moodScore;

  /// Energy score 1-5 (for cycle prediction integration)
  int? energyScore;
}