import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:primeform_app/models/checkin.dart';
import 'package:primeform_app/models/prime_plan.dart';
import 'package:primeform_app/models/workout_template_doc.dart';
import 'package:primeform_app/models/workout_session_doc.dart';
import 'package:primeform_app/models/user_profile.dart';
import 'package:primeform_app/models/meal_log.dart';
import 'package:primeform_app/models/food_item.dart';
import 'package:primeform_app/models/coach_message.dart';
import 'package:primeform_app/models/ai_insight.dart';
import 'package:primeform_app/models/progress_photo.dart';
import 'package:primeform_app/models/cycle_prediction.dart';
import 'package:primeform_app/models/cycle_log.dart';

class IsarDb {
  static Isar? _isar;

  static Future<Isar> instance() async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      CheckInSchema,
      PrimePlanSchema,
      WorkoutTemplateDocSchema,
      WorkoutSessionDocSchema,
      UserProfileSchema,
      MealLogSchema,
      FoodItemSchema,
      CoachMessageSchema,
      AiInsightSchema,
      ProgressPhotoSchema,
      CyclePredictionSchema,
      CycleLogSchema,
    ], directory: dir.path);

    return _isar!;
  }
}