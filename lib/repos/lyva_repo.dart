import '../services/personalization_safety.dart';
import '../utils/nutrition_adjustment.dart';
import 'dart:convert';
import '../models/workout_exercise.dart';
import '../models/guided_progress.dart';
import '../utils/workout_progression.dart';
import '../models/workout_plan_snapshot.dart';
import '../utils/workout_constraints.dart';

import '../services/safety_callable.dart';
import 'package:isar/isar.dart';

import 'package:lyva_app/db/isar_db.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/models/meal_log.dart';
import 'package:lyva_app/models/food_item.dart';
import 'package:lyva_app/models/coach_message.dart';
import 'package:lyva_app/models/ai_insight.dart';
import 'package:lyva_app/models/progress_photo.dart';
import 'package:lyva_app/models/cycle_prediction.dart';
import 'package:lyva_app/models/cycle_log.dart';
import 'package:lyva_app/models/user_profile.dart';

class LyvaRepo {
  LyvaRepo({Future<Isar> Function()? openDatabase,
      Future<void> Function(Isar)? checkPersonalization})
      : _openDatabase = openDatabase ?? IsarDb.instance,
        _checkPersonalization = checkPersonalization ?? _requirePersonalization;
  final Future<void> Function(Isar) _checkPersonalization;
  static Future<void> _requirePersonalization(Isar isar) async {
    PersonalizationDecision.evaluate(await isar.userProfiles.where().findFirst()).requireAllowed();
  }
  final Future<Isar> Function() _openDatabase;
  int _chatGeneration = 0;
  int get chatGeneration => _chatGeneration;
  final Map<Id, int> _photoOperations = {};
  int beginPhotoAnalysis(Id id) =>
      _photoOperations.update(id, (value) => value + 1, ifAbsent: () => 1);

  Future<bool> completePhotoAnalysis(Id id, int operation, String analysis) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      if (_photoOperations[id] != operation) return false;
      final photo = await isar.progressPhotos.get(id);
      if (photo == null || _photoOperations[id] != operation) return false;
      photo.analysisJson = analysis;
      photo.analysisComplete = true;
      photo.analysisRequested = true;
      await isar.progressPhotos.put(photo);
      return true;
    });
  }

  Future<bool> beginCoachTurn(CoachMessage user, CoachMessage placeholder, int generation) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      if (generation != _chatGeneration) return false;
      await isar.coachMessages.putAll([user, placeholder]);
      return true;
    });
  }

  Future<bool> completeCoachTurn(CoachMessage message, int generation) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      try { await _checkPersonalization(isar); } catch (_) { return false; }
      if (generation != _chatGeneration) return false;
      final existing = await isar.coachMessages.get(message.id);
      if (existing == null || !existing.isLoading || generation != _chatGeneration) return false;
      await isar.coachMessages.put(message);
      return true;
    });
  }

  Future<void> saveChatInsights(List<AiInsight> insights, int generation) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await _checkPersonalization(isar);
      if (generation == _chatGeneration) await isar.aiInsights.putAll(insights);
    });
  }

  /* =========================
   * CHECK-INS
   * ========================= */

  Future<void> addCheckIn(CheckIn c) async {
    if ([c.sleepScore, c.stressScore, c.sorenessScore, c.hungerScore].any((v) => v != null && (v < 1 || v > 5))) {
      throw ArgumentError('Recovery scores must be between 1 and 5.');
    }
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.checkIns.put(c);
    });
  }

  Future<DateTime?> latestMeasurementDate() async {
    final isar = await _openDatabase();
    final record = await isar.checkIns.filter().tsLessThan(DateTime.now(), include: true)
      .and().group((q) => q.weightKgGreaterThan(0).or().waistCmGreaterThan(0)).sortByTsDesc().findFirst();
    return record?.ts;
  }

  Future<List<CheckIn>> latestCheckIns({int limit = 30}) async {
    final isar = await _openDatabase();
    return isar.checkIns.where().sortByTsDesc().limit(limit).findAll();
  }

  Stream<List<CheckIn>> watchLatestCheckIns({int limit = 30}) async* {
    final isar = await _openDatabase();
    yield* isar.checkIns
        .where()
        .sortByTsDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  /// Get check-ins within a date range (for analytics/export)
  Future<List<CheckIn>> getCheckInsInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final isar = await _openDatabase();
    return isar.checkIns
        .filter()
        .tsBetween(start, end)
        .sortByTsDesc()
        .findAll();
  }

  /// Get check-ins for the last N days (most recent first).
  /// Used by plateau detection to analyze 21-day weight trends.
  Future<List<CheckIn>> getCheckInsForLastDays(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
    return getCheckInsInDateRange(start, now);
  }

  /* =========================
   * MEAL LOGS
   * ========================= */

  Future<void> addMealLog(MealLog meal) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.mealLogs.put(meal);
    });
  }

  Future<List<MealLog>> getRecentMeals({int limit = 30}) async {
    final isar = await _openDatabase();
    return isar.mealLogs.filter().tsLessThan(DateTime.now(), include: true).sortByTsDesc().limit(limit.clamp(1, 100)).findAll();
  }

  Future<void> deleteMealLog(Id mealId) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.mealLogs.delete(mealId);
    });
  }

  /// Update an existing meal log
  Future<void> updateMealLog(MealLog meal) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.mealLogs.put(meal);
    });
  }

  /// Get all meals for today
  Future<List<MealLog>> getTodayMeals() async {
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return isar.mealLogs
        .filter()
        .tsBetween(startOfDay, endOfDay)
        .sortByTs()
        .findAll();
  }

  /// Exact inclusive date range, matching check-in and workout export queries.
  Future<List<MealLog>> getMealsInDateRange(DateTime start, DateTime end) async {
    final isar = await _openDatabase();
    return isar.mealLogs.filter().tsBetween(start, end).sortByTsDesc().findAll();
  }

  /// Get meals for the last N days (for adherence calculation)
  Future<List<MealLog>> getMealsForLastDays(int days) async {
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
    return isar.foodItems
        .filter()
        .nameContains(query, caseSensitive: false)
        .sortByName()
        .limit(20)
        .findAll();
  }

  /// Look up a food item by barcode
  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    final isar = await _openDatabase();
    return isar.foodItems.filter().barcodeEqualTo(barcode).findFirst();
  }

  /// Save or update a food item (upserts on barcode uniqueness)
  Future<void> saveFoodItem(FoodItem item) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.foodItems.put(item);
    });
  }

  /* =========================
   * NUTRITION / PRIME PLAN
   * ========================= */

  Future<void> upsertPlan(PrimePlan plan) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await _checkPersonalization(isar);
      await isar.primePlans.put(plan);
    });
  }

  /// Apply exactly the reviewed source revision once, retaining previous plans.
  Future<PrimePlan> applyReviewedNutritionAdjustment({required String expectedRevision,
      required int calorieDelta, required int stepDelta}) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      final current = await isar.primePlans.where().sortByCreatedAtDesc().findFirst();
      if (current == null || nutritionPlanRevision(current) != expectedRevision) {
        throw StateError('The reviewed plan is no longer current.');
      }
      final next = adjustedNutritionPlan(current: current, calorieDelta: calorieDelta,
        stepDelta: stepDelta, createdAt: DateTime.now());
      // Do not fabricate a save time for a source dated ahead of this clock.
      if (!next.createdAt.isAfter(current.createdAt)) {
        throw StateError('The source plan timestamp must precede this revision.');
      }
      await isar.primePlans.put(next);
      return next;
    });
  }

  Future<PrimePlan?> getActivePlan() async {
    final isar = await _openDatabase();
    return isar.primePlans.where().sortByCreatedAtDesc().findFirst();
  }

  /* =========================
   * WORKOUT TEMPLATES
   * ========================= */

  /// Low-level save (if you already have a doc)
  Future<void> saveWorkoutTemplate(WorkoutTemplateDoc doc) async {
    doc.json = jsonEncode(WorkoutExercise.normalizeTemplate(
      Map<String, dynamic>.from(jsonDecode(doc.json) as Map)));
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await _checkPersonalization(isar);
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
    final isar = await _openDatabase();
    return isar.workoutTemplateDocs.where().sortByCreatedAtDesc().findFirst();
  }

  /// Get all custom workout templates.
  Future<List<WorkoutTemplateDoc>> getCustomTemplates() async {
    final isar = await _openDatabase();
    return isar.workoutTemplateDocs
        .filter()
        .isCustomEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get all workout templates.
  Future<List<WorkoutTemplateDoc>> getAllWorkoutTemplates() async {
    final isar = await _openDatabase();
    return isar.workoutTemplateDocs.where().sortByCreatedAtDesc().findAll();
  }

  /// Delete a workout template by ID.
  Future<void> deleteWorkoutTemplate(Id templateId) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.workoutTemplateDocs.delete(templateId);
    });
  }

  /// Update an existing workout template's JSON (for exercise customization)
  Future<void> updateWorkoutTemplateJson(Id templateId, String newJson) async {
    final isar = await _openDatabase();
    final doc = await isar.workoutTemplateDocs.get(templateId);
    if (doc == null) return;

    doc.json = jsonEncode(WorkoutExercise.normalizeTemplate(
      Map<String, dynamic>.from(jsonDecode(newJson) as Map)));

    await isar.writeTxn(() async {
      await _checkPersonalization(isar);
      await isar.workoutTemplateDocs.put(doc);
    });
  }

  /* =========================
   * CLOUD FUNCTIONS
   * ========================= */

  Future<Map<String, dynamic>> generateWorkoutTemplate({
    required UserProfile profile,
    required String sex,
    required String level,
    required String equipment,
    required int daysPerWeek,
    int sessionDurationMin = 60,
    String? constraints,
    List<String>? injuries,
  }) async {
    final callable =
        SafetyCallable('generateWorkoutTemplate');

    final finalConstraints = WorkoutConstraints.fromProfile(
      profile,
      additionalConstraints: constraints,
      additionalInjuries: injuries,
    );

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

  Future<WorkoutSessionDoc?> getLatestWorkoutSession({String? planId}) async {
    final isar = await _openDatabase();
    if (planId != null) {
      return isar.workoutSessionDocs.filter().planIdEqualTo(planId).sortByDateDesc().findFirst();
    }
    return isar.workoutSessionDocs.where().sortByDateDesc().findFirst();
  }

  /// NEW: Get all sessions (completed or not) in a date range
  Future<List<WorkoutSessionDoc>> getSessionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final isar = await _openDatabase();
  
    return isar.workoutSessionDocs
        .filter()
        .dateBetween(startDate, endDate)
        .sortByDate()
        .findAll();
  }

  WorkoutSessionDoc _newWorkoutSession(WorkoutPlanSnapshot plan, int dayIndex) {
    if (plan.sourceTemplateId <= 0 || plan.day(dayIndex) == null) {
      throw ArgumentError('A saved plan and valid workout day are required.');
    }
    return WorkoutSessionDoc()
      ..date = DateTime.now()
      ..dayIndex = dayIndex
      ..completed = false
      ..planId = plan.planId
      ..templateSnapshotJson = plan.json;
  }

  Future<WorkoutSessionDoc> _openSession(Isar isar, WorkoutPlanSnapshot plan, int dayIndex) async {
    final candidate = _newWorkoutSession(plan, dayIndex);
    final now = candidate.date;
    final existing = await isar.workoutSessionDocs.filter()
        .planIdEqualTo(plan.planId).and().dayIndexEqualTo(dayIndex)
        .and().completedEqualTo(false).and().skippedEqualTo(false)
        .and().dateBetween(DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day + 1), includeUpper: false)
        .sortByDateDesc().findFirst();
    return existing ?? candidate;
  }

  Future<WorkoutSessionDoc> startTodaySession({required int dayIndex, required WorkoutPlanSnapshot plan}) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      final session = await _openSession(isar, plan, dayIndex);
      await isar.workoutSessionDocs.put(session);
      return session;
    });
  }

  /// Check current revision and progression in the same transaction as start.
  /// Resume the exact existing open session, including after midnight.
  Future<WorkoutSessionDoc> beginGuidedSession({required WorkoutPlanSnapshot plan, required int dayIndex}) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      final doc = await isar.workoutTemplateDocs.where().sortByCreatedAtDesc().findFirst();
      if (doc == null || WorkoutPlanSnapshot.capture(doc).planId != plan.planId) {
        throw StateError('The selected plan changed. Reload before starting.');
      }
      final last = await isar.workoutSessionDocs.filter().planIdEqualTo(plan.planId).sortByDateDesc().findFirst();
      if (last != null && (last.dayIndex < 1 || last.dayIndex > plan.daysPerWeek || last.date.isAfter(DateTime.now()))) {
        throw StateError('Saved session ordering is invalid.');
      }
      if (workoutDayIndex(plan.daysPerWeek, last) != dayIndex) {
        throw StateError('Session progression changed. Reload before starting.');
      }
      final session = last != null && !last.completed && !last.skipped
          ? last : _newWorkoutSession(plan, dayIndex);
      final progress = GuidedProgress.read(session.progressJson, GuidedProgress.exercises(plan, dayIndex));
      session.progressJson = progress.json;
      await isar.workoutSessionDocs.put(session);
      return session;
    });
  }

  Future<WorkoutSessionDoc?> getWorkoutSession(int id) async => (await _openDatabase()).workoutSessionDocs.get(id);

  /// Compare-and-save prevents stale screens overwriting newer progress, closed
  /// sessions, or deleted records. No missing session is ever recreated.
  Future<WorkoutSessionDoc> saveGuidedProgress({required int sessionId, required String planId,
      required GuidedProgress progress, bool finish = false, String? notes}) async {
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      final session = await isar.workoutSessionDocs.get(sessionId);
      if (session == null || session.planId != planId || session.completed || session.skipped) {
        throw StateError('Session is missing or closed.');
      }
      final snapshot = WorkoutPlanSnapshot.fromSession(session);
      if (snapshot == null) throw StateError('Session prescription unavailable.');
      final exercises = GuidedProgress.exercises(snapshot, session.dayIndex);
      final old = GuidedProgress.read(session.progressJson, exercises);
      final validated = GuidedProgress.read(progress.json, exercises);
      if (old.revision != validated.revision || (!finish && validated.endedEarly)) {
        throw StateError('Progress changed. Reload before saving.');
      }
      if (notes != null && notes.length > 2000) throw ArgumentError('Notes too long');
      if (finish && !validated.endedEarly && validated.completedSets != validated.totalSets) {
        throw StateError('Unrecorded sets remain. Use end early instead.');
      }
      session.progressJson = validated.change(exercises, revision: old.revision + 1, clearRest: finish).json;
      if (finish) {
        session.completed = !validated.endedEarly;
        session.skipped = validated.endedEarly;
        if (validated.endedEarly) session.skipReason = 'Ended early: ${validated.completedSets}/${validated.totalSets} sets recorded';
        if (notes != null) session.notes = notes;
      }
      await isar.workoutSessionDocs.put(session);
      return session;
    });
  }

  static void _validateExertion(int? value) {
    if (value != null && (value < 1 || value > 5)) {
      throw ArgumentError.value(value, 'perceivedExertion', 'Must be between 1 and 5');
    }
  }

  /// One transaction: never complete a skipped, legacy or other-plan session.
  Future<WorkoutSessionDoc> completeWorkout({required WorkoutPlanSnapshot plan,
    required int dayIndex, String? notes, int? perceivedExertion}) async {
    _validateExertion(perceivedExertion);
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      await _checkPersonalization(isar);
      final session = await _openSession(isar, plan, dayIndex);
      session.completed = true;
      if (perceivedExertion != null) session.perceivedExertion = perceivedExertion;
      if (notes != null && notes.isNotEmpty) session.notes = notes;
      await isar.workoutSessionDocs.put(session);
      return session;
    });
  }

  Future<void> completeSession(Id sessionId, {String? notes, int? perceivedExertion}) async {
    _validateExertion(perceivedExertion);
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      final session = await isar.workoutSessionDocs.get(sessionId);
      if (session == null || session.skipped) return;
      session.completed = true;
      if (perceivedExertion != null) session.perceivedExertion = perceivedExertion;
      if (notes != null && notes.isNotEmpty) session.notes = notes;
      await isar.workoutSessionDocs.put(session);
    });
  }

  Future<void> skipSession({required int dayIndex, required String reason,
    required WorkoutPlanSnapshot plan}) async {
    final isar = await _openDatabase();
    final session = _newWorkoutSession(plan, dayIndex)
      ..skipped = true
      ..skipReason = reason;
    await isar.writeTxn(() async { await isar.workoutSessionDocs.put(session); });
  }

  Future<void> updateSessionNotes(Id sessionId, String notes) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      final session = await isar.workoutSessionDocs.get(sessionId);
      if (session == null) return;
      session.notes = notes;
      await isar.workoutSessionDocs.put(session);
    });
  }

  /// Get completed sessions for this week
  Future<List<WorkoutSessionDoc>> getThisWeekSessions() async {
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
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
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await _checkPersonalization(isar);
      await isar.coachMessages.put(msg);
    });
  }

  Stream<List<CoachMessage>> watchCoachMessages({int limit = 100}) async* {
    final isar = await _openDatabase();
    yield* isar.coachMessages
        .where()
        .sortByTsDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<List<CoachMessage>> getRecentCoachMessages({int limit = 20}) async {
    final isar = await _openDatabase();
    return isar.coachMessages.where().sortByTsDesc().limit(limit).findAll();
  }

  Future<void> clearCoachMessages() async {
    _chatGeneration++;
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.coachMessages.clear();
    });
  }

  /// Build the context snapshot for AI coaching
  Future<Map<String, dynamic>> buildCoachingContext() async {
    final isar = await _openDatabase();
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
    final callable = SafetyCallable('aiCoachChat');
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
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await _checkPersonalization(isar);
      await isar.aiInsights.put(insight);
    });
  }

  Future<List<AiInsight>> getActiveInsights() async {
    final isar = await _openDatabase();
    return isar.aiInsights
        .filter()
        .dismissedEqualTo(false)
        .sortByTsDesc()
        .findAll();
  }

  Future<List<AiInsight>> getInsightsByCategory(String category) async {
    final isar = await _openDatabase();
    return isar.aiInsights
        .filter()
        .categoryEqualTo(category)
        .and()
        .dismissedEqualTo(false)
        .sortByTsDesc()
        .findAll();
  }

  Future<void> dismissInsight(Id insightId) async {
    final isar = await _openDatabase();
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
        SafetyCallable('extractAiInsights');
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
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.progressPhotos.put(photo);
    });
  }

  Future<List<ProgressPhoto>> getAllProgressPhotos() async {
    final isar = await _openDatabase();
    return isar.progressPhotos.where().sortByTsDesc().findAll();
  }

  Stream<List<ProgressPhoto>> watchProgressPhotos() async* {
    final isar = await _openDatabase();
    yield* isar.progressPhotos
        .where()
        .sortByTsDesc()
        .watch(fireImmediately: true);
  }

  Future<void> deleteProgressPhoto(Id photoId) async {
    beginPhotoAnalysis(photoId); // Invalidate before awaiting database access.
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.progressPhotos.delete(photoId);
    });
  }

  /// Send photo to Cloud Function for AI analysis
  Future<Map<String, dynamic>> analyzeProgressPhoto({
    required String base64Image,
    required Map<String, dynamic> userContext,
  }) async {
    final callable = SafetyCallable(
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
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.cyclePredictions.put(pred);
    });
  }

  Future<CyclePrediction?> getLatestPrediction() async {
    final isar = await _openDatabase();
    return isar.cyclePredictions.where().sortByTsDesc().findFirst();
  }

  Future<void> saveCycleLog(CycleLog log) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      await isar.cycleLogs.put(log);
    });
  }

  /// User-facing tracker writes recheck persisted opt-out inside the transaction.
  Future<void> saveTrackedCycleLog(CycleLog log) async {
    final isar = await _openDatabase();
    await isar.writeTxn(() async {
      final profile = await isar.userProfiles.where().findFirst();
      if (profile == null || !profile.trackCycle) {
        throw StateError('Cycle tracking is unavailable');
      }
      await isar.cycleLogs.put(log);
    });
  }

  /// Edit details only; never recreate deleted records or move a period anchor.
  Future<bool> updateCycleLogDetails(CycleLog original, {
    required String? notes, required int? severity,
  }) async {
    if (severity != null && (severity < 1 || severity > 5)) {
      throw ArgumentError('Severity must be 1 to 5 or not logged');
    }
    final isar = await _openDatabase();
    return isar.writeTxn(() async {
      final profile = await isar.userProfiles.where().findFirst();
      if (profile == null || !profile.trackCycle) return false;
      final current = await isar.cycleLogs.get(original.id);
      if (current == null || current.ts != original.ts ||
          current.eventType != original.eventType ||
          current.symptomType != original.symptomType ||
          current.notes != original.notes || current.severity != original.severity) {
        return false;
      }
      current.notes = notes;
      if (current.eventType == 'symptom') current.severity = severity;
      await isar.cycleLogs.put(current);
      return true;
    });
  }

  Future<List<CycleLog>> getCycleLogs({int limit = 90}) async {
    final isar = await _openDatabase();
    return isar.cycleLogs.where().sortByTsDesc().limit(limit).findAll();
  }

  Stream<List<CycleLog>> watchCycleLogs() async* {
    final isar = await _openDatabase();
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
    throw UnsupportedError('Legacy AI cycle predictions are disabled. Use recorded events and clearly labeled calendar estimates.');
  }

  /// Confirm period started (for improving predictions)
  Future<void> confirmPeriodStarted(DateTime date) async {
    final isar = await _openDatabase();
    final local = date.toLocal();
    final start = DateTime(local.year, local.month, local.day);
    final end = DateTime(local.year, local.month, local.day + 1);
    await isar.writeTxn(() async {
      final profile = await isar.userProfiles.where().findFirst();
      if (profile == null || !profile.trackCycle) {
        throw StateError('Cycle tracking is unavailable');
      }
      final existing = await isar.cycleLogs.where().tsBetween(start, end, includeUpper: false)
          .filter().eventTypeEqualTo('period_start').findFirst();
      if (existing == null) {
        await isar.cycleLogs.put(CycleLog()..ts = date..eventType = 'period_start');
      }
      // Preserve the existing prediction-link behavior, inside the same transaction.
      final pred = await isar.cyclePredictions.where().sortByTsDesc().findFirst();
      if (pred != null && !pred.verified) {
        pred.verified = true;
        pred.actualPeriodDate = date;
        await isar.cyclePredictions.put(pred);
      }
      if (profile.lastPeriodDate == null || !date.isBefore(profile.lastPeriodDate!)) {
        profile.lastPeriodDate = date;
        profile.updatedAt = DateTime.now();
        await isar.userProfiles.put(profile);
      }
    });
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
