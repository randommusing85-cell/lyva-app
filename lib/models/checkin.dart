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
  
  // Macros removed - now tracked in MealLog
  // Daily macro totals calculated from MealLog entries
}