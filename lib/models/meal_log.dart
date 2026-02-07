import 'package:isar/isar.dart';

part 'meal_log.g.dart';

@collection
class MealLog {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;
  
  /// Which meal: 'breakfast', 'lunch', 'dinner', 'snack'
  late String mealType;
  
  /// Macros for this meal
  late int proteinG;
  late int carbsG;
  late int fatG;
  
  /// Optional meal description
  String? description;
  
  /// Calculated calories (for display)
  int get calories => (proteinG * 4) + (carbsG * 4) + (fatG * 9);
}
