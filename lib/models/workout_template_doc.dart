import 'package:isar/isar.dart';

part 'workout_template_doc.g.dart';

@collection
class WorkoutTemplateDoc {
  Id id = Isar.autoIncrement;

  late DateTime createdAt;

  // filtering + display
  late String planName;
  late String level;      // beginner/intermediate/advanced
  late String equipment;  // gym/home_dumbbells/calisthenics
  late int daysPerWeek;
  late String sex;

  // Whether this is a user-created custom workout
  bool isCustom = false;

  // store full JSON for v1 (fast shipping)
  late String json;
}
