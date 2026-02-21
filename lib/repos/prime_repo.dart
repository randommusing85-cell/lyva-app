import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:isar/isar.dart';

import 'package:primeform_app/db/isar_db.dart';
import 'package:primeform_app/models/checkin.dart';
import 'package:primeform_app/models/prime_plan.dart';
import 'package:primeform_app/models/workout_template_doc.dart';
import 'package:primeform_app/models/workout_session_doc.dart';
import 'package:primeform_app/models/meal_log.dart';
import 'package:primeform_app/models/food_item.dart';
import 'package:primeform_app/models/coach_message.dart';
import 'package:primeform_app/models/ai_insight.dart';
import 'package:primeform_app/models/progress_photo.dart';
import 'package:primeform_app/models/cycle_prediction.dart';
import 'package:primeform_app/models/cycle_log.dart';
import 'package:primeform_app/models/user_profile.dart';

class PrimeRepo {
  /* =========================
   * CHECK-INS
   * ========================= */

  Future<void> addCheckIn(CheckIn c) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.checkIns.put(c);
    });
  }

  Future<List<CheckIn>> latestCheckIns({int limit = 30}) async {
    final isar = await IsarDb.instance();
    return isar.checkIns.where().sortByTsDesc().limit(limit).findAll();
  }

  Stream<List<CheckIn>> watchLatestCheckIns({int limit = 30}) async* {
    final isar = await IsarDb.instance();
    yield* isar.checkIns
        .where()
        .sortByTsDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  /* =========================
   * MEAL LOGS
   * ========================= */

  Future<void> addMealLog(MealLog meal) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.mealLogs.put(meal);
    });
  }

  Future<void> deleteMealLog(Id mealId) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.mealLogs.delete(mealId);
    });
  }

  /// Update an existing meal log
  Future<void> updateMealLog(MealLog meal) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.mealLogs.put(meal);
    });
  }

  /// Get all meals for today
  Future<List<MealLog>> getTodayMeals() async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .findAll();
  }

  /// Watch today's meals (reactive)
  Stream<List<MealLog>> watchTodayMeals() async* {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield* isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .watch(fireImmediately: true);
  }

  /// Get meals for a specific date
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final isar = await IsarDb.instance();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .findAll();
  }

  /// Get meals for the last N days (for adherence calculation)
  Future<List<MealLog>> getMealsForLastDays(int days) async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final endDate = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startDate, endDate)
        .sortByTsDesc()
        .findAll();
  }

  /// Get daily macro totals for the last N days
  Future<List<DailyMacroTotal>> getDailyMacroTotals(int days) async {
    final meals = await getMealsForLastDays(days);
    
    // Group by date
    final Map<String, List<MealLog>> byDate = {};
    for (final meal in meals) {
      final dateKey = '${meal.ts.year}-${meal.ts.month.toString().padLeft(2, '0')}-${meal.ts.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(dateKey, () => []).add(meal);
    }
    
    // Calculate totals per day
    final List<DailyMacroTotal> totals = [];
    byDate.forEach((dateKey, dayMeals) {
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      
      int protein = 0;
      int carbs = 0;
      int fat = 0;
      
      for (final meal in dayMeals) {
        protein += meal.proteinG;
        carbs += meal.carbsG;
        fat += meal.fatG;
      }
      
      totals.add(DailyMacroTotal(
        date: date,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        mealCount: dayMeals.length,
      ));
    });
    
    // Sort by date descending
    totals.sort((a, b) => b.date.compareTo(a.date));
    
    return totals;
  }

  /* =========================
   * FOOD ITEM DATABASE
   * ========================= */

  /// Search food items by name (case-insensitive contains)
  Future<List<FoodItem>> searchFoodItems(String query) async {
    final isar = await IsarDb.instance();
    return isar.foodItems
        .filter()
        .nameContains(query, caseSensitive: false)
        .sortByName()
        .limit(20)
        .findAll();
  }

  /// Look up a food item by barcode
  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    final isar = await IsarDb.instance();
    return isar.foodItems.filter().barcodeEqualTo(barcode).findFirst();
  }

  /// Save or update a food item (upserts on barcode uniqueness)
  Future<void> saveFoodItem(FoodItem item) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.foodItems.put(item);
    });
  }

  /* =========================
   * NUTRITION / PRIME PLAN
   * ========================= */

  Future<void> upsertPlan(PrimePlan plan) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.primePlans.put(plan);
    });
  }

  Future<PrimePlan?> getActivePlan() async {
    final isar = await IsarDb.instance();
    return isar.primePlans.where().sortByCreatedAtDesc().findFirst();
  }

  /* =========================
   * WORKOUT TEMPLATES
   * ========================= */

  /// Low-level save (if you already have a doc)
  Future<void> saveWorkoutTemplate(WorkoutTemplateDoc doc) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.workoutTemplateDocs.put(doc);
    });
  }

  /// High-level save (from Firebase callable response)
  Future<void> saveWorkoutTemplateFromResponse({
    required Map<String, dynamic> response,
    required String sex,
  }) async {
    final ok = response['ok'] == true;
    if (!ok) {
      throw Exception('Workout template generation failed');
    }

    final template = Map<String, dynamic>.from(response['template'] as Map);

    final doc = WorkoutTemplateDoc()
      ..createdAt = DateTime.now()
      ..planName = (template['planName'] ?? 'Workout Plan').toString()
      ..sex = sex
      ..level = template['level'].toString()
      ..equipment = template['equipment'].toString()
      ..daysPerWeek = (template['daysPerWeek'] as num).toInt()
      ..json = jsonEncode(template);

    await saveWorkoutTemplate(doc);
  }

  Future<WorkoutTemplateDoc?> getLatestWorkoutTemplate() async {
    final isar = await IsarDb.instance();
    return isar.workoutTemplateDocs.where().sortByCreatedAtDesc().findFirst();
  }

  /// Update an existing workout template's JSON (for exercise customization)
  Future<void> updateWorkoutTemplateJson(Id templateId, String newJson) async {
    final isar = await IsarDb.instance();
    final doc = await isar.workoutTemplateDocs.get(templateId);
    if (doc == null) return;

    doc.json = newJson;

    await isar.writeTxn(() async {
      await isar.workoutTemplateDocs.put(doc);
    });
  }

  /* =========================
   * CLOUD FUNCTIONS
   * ========================= */

  Future<Map<String, dynamic>> generateWorkoutTemplate({
    required String sex,
    required String level,
    required String equipment,
    required int daysPerWeek,
    int sessionDurationMin = 60,
    String? constraints,
    List<String>? injuries,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('generateWorkoutTemplate');

    // Build constraints string including injuries
    String finalConstraints = constraints ?? 'none';
    if (injuries != null && injuries.isNotEmpty) {
      final injuryText = injuries.map((i) => i.replaceAll('_', ' ')).join(', ');
      if (finalConstraints == 'none') {
        finalConstraints = 'User has injuries/limitations: $injuryText. Avoid exercises that aggravate these areas and provide safe alternatives.';
      } else {
        finalConstraints += ' Additionally, user has injuries/limitations: $injuryText. Avoid exercises that aggravate these areas.';
      }
    }

    final res = await callable.call({
      'sex': sex,
      'level': level,
      'equipment': equipment,
      'daysPerWeek': daysPerWeek,
      'sessionDurationMin': sessionDurationMin,
      'constraints': finalConstraints,
    });

    if (res.data is! Map) {
      throw Exception('Invalid response format from workout generation');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  /* =========================
   * WORKOUT SESSIONS (PHASE 1.5)
   * ========================= */

  Future<WorkoutSessionDoc?> getLatestWorkoutSession() async {
    final isar = await IsarDb.instance();
    return isar.workoutSessionDocs.where().sortByDateDesc().findFirst();
  }

  /// NEW: Get all sessions (completed or not) in a date range
  Future<List<WorkoutSessionDoc>> getSessionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final isar = await IsarDb.instance();
  
    return isar.workoutSessionDocs
        .filter()
        .dateBetween(startDate, endDate)
        .sortByDate()
        .findAll();
  }

  Future<WorkoutSessionDoc> startTodaySession({required int dayIndex}) async {
    final isar = await IsarDb.instance();

    final session = WorkoutSessionDoc()
      ..date = DateTime.now()
      ..dayIndex = dayIndex
      ..completed = false;

    await isar.writeTxn(() async {
      await isar.workoutSessionDocs.put(session);
    });

    return session;
  }

  Future<void> completeSession(Id sessionId, {String? notes}) async {
    final isar = await IsarDb.instance();
    final session = await isar.workoutSessionDocs.get(sessionId);
    if (session == null) return;

    session.completed = true;
    if (notes != null && notes.isNotEmpty) {
      session.notes = notes;
    }

    await isar.writeTxn(() async {
      await isar.workoutSessionDocs.put(session);
    });
  }

  /// Skip a workout session with a reason
  Future<void> skipSession({
    required int dayIndex,
    required String reason,
  }) async {
    final isar = await IsarDb.instance();

    final session = WorkoutSessionDoc()
      ..date = DateTime.now()
      ..dayIndex = dayIndex
      ..completed = false
      ..skipped = true
      ..skipReason = reason;

    await isar.writeTxn(() async {
      await isar.workoutSessionDocs.put(session);
    });
  }

  /// Update notes for an existing session
  Future<void> updateSessionNotes(Id sessionId, String notes) async {
    final isar = await IsarDb.instance();
    final session = await isar.workoutSessionDocs.get(sessionId);
    if (session == null) return;

    session.notes = notes;

    await isar.writeTxn(() async {
      await isar.workoutSessionDocs.put(session);
    });
  }

  /// Get completed sessions for this week
  Future<List<WorkoutSessionDoc>> getThisWeekSessions() async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return isar.workoutSessionDocs
        .filter()
        .dateGreaterThan(weekStartMidnight)
        .and()
        .completedEqualTo(true)
        .findAll();
  }

  /* =========================
   * WORKOUT CALENDAR & HISTORY (v1.0)
   * ========================= */

  /// Get all workout sessions for a specific month (for calendar view)
  Future<List<WorkoutSessionDoc>> getWorkoutSessionsForMonth(
    DateTime month,
  ) async {
    final isar = await IsarDb.instance();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    return isar.workoutSessionDocs
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Get workout session for a specific date (for day detail view)
  Future<WorkoutSessionDoc?> getWorkoutSessionForDate(DateTime date) async {
    final isar = await IsarDb.instance();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return isar.workoutSessionDocs
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findFirst();
  }

  /// Get missed workouts count (smart miss tracking - only counts scheduled days)
  Future<int> getMissedWorkoutsCount({
    required DateTime startDate,
    required int scheduledDaysPerWeek,
  }) async {
    final isar = await IsarDb.instance();
    final now = DateTime.now();
    
    // Get all sessions since startDate
    final sessions = await isar.workoutSessionDocs
        .filter()
        .dateBetween(startDate, now)
        .findAll();
    
    // Count completed sessions
    final completedCount = sessions.where((s) => s.completed == true).length;
    
    // Calculate expected sessions (days elapsed * scheduled frequency / 7)
    final daysElapsed = now.difference(startDate).inDays;
    final weeksElapsed = daysElapsed / 7;
    final expectedSessions = (weeksElapsed * scheduledDaysPerWeek).ceil();
    
    // Missed = expected - completed (clamped to 0)
    return (expectedSessions - completedCount).clamp(0, expectedSessions);
  }

  /* =========================
   * AI COACHING (PREMIUM)
   * ========================= */

  Future<void> addCoachMessage(CoachMessage msg) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.coachMessages.put(msg);
    });
  }

  Stream<List<CoachMessage>> watchCoachMessages({int limit = 100}) async* {
    final isar = await IsarDb.instance();
    yield* isar.coachMessages
        .where()
        .sortByTsDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<List<CoachMessage>> getRecentCoachMessages({int limit = 20}) async {
    final isar = await IsarDb.instance();
    return isar.coachMessages.where().sortByTsDesc().limit(limit).findAll();
  }

  Future<void> clearCoachMessages() async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.coachMessages.clear();
    });
  }

  /// Build the context snapshot for AI coaching
  Future<Map<String, dynamic>> buildCoachingContext() async {
    final isar = await IsarDb.instance();
    final profile = await isar.userProfiles.where().findFirst();
    final plan = await getActivePlan();
    final recentCheckIns = await latestCheckIns(limit: 7);
    final template = await getLatestWorkoutTemplate();
    final weekSessions = await getThisWeekSessions();

    return {
      'profile': {
        'age': profile?.age,
        'sex': profile?.sex,
        'goal': profile?.goal,
        'level': profile?.level,
        'weightKg': profile?.weightKg,
        'heightCm': profile?.heightCm,
        'tracksCycle': profile?.trackCycle,
        'cycleLength': profile?.cycleLength,
        'injuries': profile?.injuryList,
      },
      'plan': plan != null
          ? {
              'calories': plan.calories,
              'proteinG': plan.proteinG,
              'carbsG': plan.carbsG,
              'fatG': plan.fatG,
              'stepTarget': plan.stepTarget,
            }
          : null,
      'recentCheckIns': recentCheckIns
          .map((c) => {
                'date': c.ts.toIso8601String(),
                'weightKg': c.weightKg,
                'waistCm': c.waistCm,
                'steps': c.stepsToday,
                'mood': c.moodScore,
                'energy': c.energyScore,
              })
          .toList(),
      'workoutsThisWeek': weekSessions.length,
      'hasWorkoutPlan': template != null,
    };
  }

  /// Call the AI coaching Cloud Function
  Future<String> sendCoachMessage({
    required String userMessage,
    required Map<String, dynamic> context,
    required List<Map<String, String>> recentHistory,
    List<Map<String, dynamic>>? insights,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('aiCoachChat');
    final res = await callable.call({
      'message': userMessage,
      'context': context,
      'history': recentHistory,
      'insights': insights ?? [],
    });

    if (res.data is! Map || res.data['ok'] != true) {
      throw Exception('AI coaching request failed');
    }
    return res.data['response'] as String;
  }

  /* =========================
   * AI MEMORY / INSIGHTS (PREMIUM)
   * ========================= */

  Future<void> saveAiInsight(AiInsight insight) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.aiInsights.put(insight);
    });
  }

  Future<List<AiInsight>> getActiveInsights() async {
    final isar = await IsarDb.instance();
    return isar.aiInsights
        .filter()
        .dismissedEqualTo(false)
        .sortByTsDesc()
        .findAll();
  }

  Future<List<AiInsight>> getInsightsByCategory(String category) async {
    final isar = await IsarDb.instance();
    return isar.aiInsights
        .filter()
        .categoryEqualTo(category)
        .and()
        .dismissedEqualTo(false)
        .sortByTsDesc()
        .findAll();
  }

  Future<void> dismissInsight(Id insightId) async {
    final isar = await IsarDb.instance();
    final insight = await isar.aiInsights.get(insightId);
    if (insight == null) return;
    insight.dismissed = true;
    await isar.writeTxn(() async {
      await isar.aiInsights.put(insight);
    });
  }

  /// Extract insights from AI coaching conversation via Cloud Function
  Future<List<Map<String, dynamic>>> extractInsights({
    required List<Map<String, String>> conversationHistory,
    required List<Map<String, dynamic>> existingInsights,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('extractAiInsights');
    final res = await callable.call({
      'conversation': conversationHistory,
      'existingInsights': existingInsights,
    });

    if (res.data is! Map || res.data['ok'] != true) {
      return [];
    }
    return List<Map<String, dynamic>>.from(res.data['insights'] as List);
  }

  /* =========================
   * PROGRESS PHOTOS (PREMIUM)
   * ========================= */

  Future<void> saveProgressPhoto(ProgressPhoto photo) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.progressPhotos.put(photo);
    });
  }

  Future<List<ProgressPhoto>> getAllProgressPhotos() async {
    final isar = await IsarDb.instance();
    return isar.progressPhotos.where().sortByTsDesc().findAll();
  }

  Stream<List<ProgressPhoto>> watchProgressPhotos() async* {
    final isar = await IsarDb.instance();
    yield* isar.progressPhotos
        .where()
        .sortByTsDesc()
        .watch(fireImmediately: true);
  }

  Future<void> deleteProgressPhoto(Id photoId) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.progressPhotos.delete(photoId);
    });
  }

  /// Send photo to Cloud Function for AI analysis
  Future<Map<String, dynamic>> analyzeProgressPhoto({
    required String base64Image,
    required Map<String, dynamic> userContext,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'analyzeProgressPhoto',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final res = await callable.call({
      'image': base64Image,
      'context': userContext,
    });

    if (res.data is! Map || res.data['ok'] != true) {
      throw Exception('Photo analysis failed');
    }
    return Map<String, dynamic>.from(res.data['analysis'] as Map);
  }

  /* =========================
   * CYCLE PREDICTIONS (PREMIUM)
   * ========================= */

  Future<void> saveCyclePrediction(CyclePrediction pred) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.cyclePredictions.put(pred);
    });
  }

  Future<CyclePrediction?> getLatestPrediction() async {
    final isar = await IsarDb.instance();
    return isar.cyclePredictions.where().sortByTsDesc().findFirst();
  }

  Future<void> saveCycleLog(CycleLog log) async {
    final isar = await IsarDb.instance();
    await isar.writeTxn(() async {
      await isar.cycleLogs.put(log);
    });
  }

  Future<List<CycleLog>> getCycleLogs({int limit = 90}) async {
    final isar = await IsarDb.instance();
    return isar.cycleLogs.where().sortByTsDesc().limit(limit).findAll();
  }

  Stream<List<CycleLog>> watchCycleLogs() async* {
    final isar = await IsarDb.instance();
    yield* isar.cycleLogs
        .where()
        .sortByTsDesc()
        .watch(fireImmediately: true);
  }

  /// Call Cloud Function for ML-based cycle prediction
  Future<Map<String, dynamic>> predictCycle({
    required List<Map<String, dynamic>> cycleHistory,
    required List<Map<String, dynamic>> checkInData,
    required List<Map<String, dynamic>> workoutData,
    required Map<String, dynamic> profileData,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('predictCycle');
    final res = await callable.call({
      'cycleHistory': cycleHistory,
      'checkIns': checkInData,
      'workouts': workoutData,
      'profile': profileData,
    });

    if (res.data is! Map || res.data['ok'] != true) {
      throw Exception('Cycle prediction failed');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Confirm period started (for improving predictions)
  Future<void> confirmPeriodStarted(DateTime date) async {
    final isar = await IsarDb.instance();

    // Save period start log
    final log = CycleLog()
      ..ts = date
      ..eventType = 'period_start';
    await isar.writeTxn(() async {
      await isar.cycleLogs.put(log);
    });

    // Update latest prediction with actual date
    final pred = await getLatestPrediction();
    if (pred != null && !pred.verified) {
      pred.verified = true;
      pred.actualPeriodDate = date;
      await isar.writeTxn(() async {
        await isar.cyclePredictions.put(pred);
      });
    }

    // Update UserProfile.lastPeriodDate
    final profile = await isar.userProfiles.where().findFirst();
    if (profile != null) {
      profile.lastPeriodDate = date;
      profile.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });
    }
  }

}

/// Helper class for daily macro totals
class DailyMacroTotal {
  final DateTime date;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int mealCount;

  DailyMacroTotal({
    required this.date,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
  });

  int get calories => (proteinG * 4) + (carbsG * 4) + (fatG * 9);
}