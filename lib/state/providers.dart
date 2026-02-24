import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../repos/prime_repo.dart';
import '../repos/user_profile_repo.dart';
import '../models/checkin.dart';
import '../models/prime_plan.dart';
import '../models/workout_template_doc.dart';
import '../models/workout_session_doc.dart';
import '../models/user_profile.dart';
import '../models/meal_log.dart';
import '../models/coach_message.dart';
import '../models/ai_insight.dart';
import '../models/progress_photo.dart';
import '../models/cycle_prediction.dart';
import '../models/cycle_log.dart';
import '../services/analytics_service.dart';
import '../services/food_api_service.dart';
import '../services/step_tracking_service.dart';
import '../services/premium_service.dart';
import '../services/export_service.dart';
import '../models/food_item.dart';

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

final primeRepoProvider = Provider<PrimeRepo>((ref) => PrimeRepo());

final userProfileRepoProvider = Provider<UserProfileRepo>(
  (ref) => UserProfileRepo(),
);

// ============================================================================
// USER PROFILE & SETTINGS
// ============================================================================

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(userProfileRepoProvider);
  return repo.getProfile();
});

// Active injuries stream (safety feature)
final activeInjuriesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final repo = ref.watch(userProfileRepoProvider);
  return repo.watchActiveInjuries();
});

// ============================================================================
// CHECK-INS & DAILY DATA
// ============================================================================

final latestCheckInsStreamProvider = StreamProvider.autoDispose<List<CheckIn>>((ref) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchLatestCheckIns(limit: 30);
});

// ============================================================================
// NUTRITION & MEALS
// ============================================================================

// Today's meals stream provider
final todayMealsStreamProvider = StreamProvider.autoDispose<List<MealLog>>((ref) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchTodayMeals();
});

// Weekly macro totals provider (for MacroAdherenceCard)
final weeklyMacroTotalsProvider = FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getDailyMacroTotals(7); // Last 7 days
});

// ============================================================================
// WORKOUT PLANS & TEMPLATES
// ============================================================================

final activePlanProvider = FutureProvider.autoDispose<PrimePlan?>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getActivePlan();
});

final latestWorkoutTemplateProvider = FutureProvider<WorkoutTemplateDoc?>((ref) async {
  final repo = ref.read(primeRepoProvider);
  return repo.getLatestWorkoutTemplate();
});

// ============================================================================
// TODAY'S WORKOUT SESSION
// ============================================================================

final todayWorkoutDayProvider = FutureProvider<int?>((ref) async {
  final repo = ref.read(primeRepoProvider);
  final template = await repo.getLatestWorkoutTemplate();
  if (template == null) return null;
  
  final daysPerWeek = template.daysPerWeek;
  final last = await repo.getLatestWorkoutSession();
  if (last == null) return 1;
  
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  
  final now = DateTime.now();
  
  // If today's session already exists and isn't completed, keep the same dayIndex.
  if (isSameDay(last.date, now) && last.completed == false) {
    return last.dayIndex;
  }
  
  // If the last session is completed (today or earlier), advance to next day.
  if (last.completed == true) {
    final next = last.dayIndex + 1;
    return next > daysPerWeek ? 1 : next;
  }
  
  // If last session isn't completed and it's from a previous day, keep it (carry forward).
  return last.dayIndex;
});

// This week's completed sessions provider
final thisWeekSessionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getThisWeekSessions();
});

// ============================================================================
// WORKOUT CALENDAR & HISTORY
// ============================================================================

// Calendar month navigation state
final selectedCalendarMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Monthly workout sessions (for calendar grid)
final monthlyWorkoutSessionsProvider = FutureProvider.autoDispose.family<List<WorkoutSessionDoc>, DateTime>((ref, month) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getWorkoutSessionsForMonth(month);
});

// Specific day's workout session
final dayWorkoutSessionProvider = FutureProvider.autoDispose.family<WorkoutSessionDoc?, DateTime>((ref, date) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getWorkoutSessionForDate(date);
});

// Missed workouts count (this week) - smart miss tracking
final missedWorkoutsThisWeekProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  final template = await repo.getLatestWorkoutTemplate();
  if (template == null) return 0;
  
  final startOfWeek = _getStartOfWeek(DateTime.now());
  return repo.getMissedWorkoutsCount(
    startDate: startOfWeek,
    scheduledDaysPerWeek: template.daysPerWeek,
  );
});

DateTime _getStartOfWeek(DateTime date) {
  return DateTime(date.year, date.month, date.day).subtract(
    Duration(days: date.weekday - 1),
  );
}

// ============================================================================
// WOMEN'S HEALTH (KEY DIFFERENTIATOR)
// ============================================================================

// Current cycle phase (for cycle-aware training)
final currentCyclePhaseProvider = FutureProvider.autoDispose<CyclePhase?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  final lastPeriod = profile.lastPeriodDate;
  if (lastPeriod == null || profile.cycleLength == null) {
    return null;
  }

  return _calculateCyclePhase(
    lastPeriod,
    profile.cycleLength,
  );
});

CyclePhase? _calculateCyclePhase(DateTime lastPeriodDate, int avgCycleLength) {
  final now = DateTime.now();
  final daysSinceLastPeriod = now.difference(lastPeriodDate).inDays;
  final currentDay = (daysSinceLastPeriod % avgCycleLength) + 1;
  
  if (currentDay <= 5) {
    return CyclePhase.menstrual;
  } else if (currentDay <= avgCycleLength ~/ 2 - 3) {
    return CyclePhase.follicular;
  } else if (currentDay <= avgCycleLength ~/ 2 + 3) {
    return CyclePhase.ovulation;
  } else {
    return CyclePhase.luteal;
  }
}

enum CyclePhase { menstrual, follicular, ovulation, luteal }

// Post-partum status (for post-partum guidance)
final postpartumStatusProvider = FutureProvider.autoDispose<PostpartumStatus?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  final deliveryDate = profile.deliveryDate;
  if (deliveryDate == null) return null;

  final weeksPostpartum = DateTime.now().difference(deliveryDate).inDays ~/ 7;

  return PostpartumStatus(
    weeksPostpartum: weeksPostpartum,
    medicalClearance: profile.medicalClearance ?? false,
    deliveryDate: deliveryDate,
  );
});

class PostpartumStatus {
  final int weeksPostpartum;
  final bool medicalClearance;
  final DateTime deliveryDate;
  
  PostpartumStatus({
    required this.weeksPostpartum,
    required this.medicalClearance,
    required this.deliveryDate,
  });
  
  bool get needsClearance => weeksPostpartum >= 6 && !medicalClearance;
  String get phaseDescription {
    if (weeksPostpartum < 6) return "Early recovery (0-6 weeks)";
    if (weeksPostpartum < 12) return "Gradual return (6-12 weeks)";
    if (weeksPostpartum < 24) return "Rebuilding phase (3-6 months)";
    return "Long-term recovery (6+ months)";
  }
}

// ============================================================================
// ANALYTICS & TRACKING
// ============================================================================

final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

// ============================================================================
// FOOD DATABASE & API
// ============================================================================

final foodApiServiceProvider = Provider<FoodApiService>((ref) => FoodApiService());

/// Search local DB first, then fall back to API. Caches API results locally.
final foodSearchProvider = FutureProvider.autoDispose.family<List<FoodItem>, String>((ref, query) async {
  if (query.trim().length < 2) return [];

  final repo = ref.read(primeRepoProvider);

  // 1. Search local database
  final localResults = await repo.searchFoodItems(query);
  if (localResults.isNotEmpty) return localResults;

  // 2. Fall back to API
  final api = ref.read(foodApiServiceProvider);
  final apiResults = await api.searchFoods(query);

  // 3. Cache API results locally
  for (final item in apiResults) {
    await repo.saveFoodItem(item);
  }

  return apiResults;
});

// ============================================================================
// STEP TRACKING (Health Platform)
// ============================================================================

final stepTrackingServiceProvider = Provider<StepTrackingService>(
  (ref) => StepTrackingService(),
);

/// Today's step count from Apple Health / Health Connect.
/// Falls back to 0 if not authorized.
final todayStepsProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.read(stepTrackingServiceProvider);
  final authorized = await service.isAuthorized();
  if (!authorized) return 0;
  return service.getTodaySteps();
});

/// Last 7 days of step data for the trend chart.
final weeklyStepsProvider = FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  final service = ref.read(stepTrackingServiceProvider);
  final authorized = await service.isAuthorized();
  if (!authorized) return {};
  return service.getWeeklySteps();
});

// ============================================================================
// PREMIUM ACCESS
// ============================================================================

final premiumServiceProvider = Provider<PremiumService>((ref) => PremiumService());

/// Premium access status — checks RevenueCat subscription first, then local trial
final premiumAccessProvider = FutureProvider.autoDispose<PremiumAccessStatus>((ref) async {
  // Watch for real-time subscription changes from RevenueCat
  ref.watch(customerInfoStreamProvider);
  final profile = await ref.watch(userProfileProvider.future);
  final service = ref.watch(premiumServiceProvider);
  return service.getAccessStatusAsync(profile);
});

/// RevenueCat offerings (for paywall display)
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  final service = ref.watch(premiumServiceProvider);
  return service.getOfferings();
});

/// Real-time subscription updates from RevenueCat
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  final controller = StreamController<CustomerInfo>();
  void listener(CustomerInfo info) => controller.add(info);
  Purchases.addCustomerInfoUpdateListener(listener);
  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(listener);
    controller.close();
  });
  return controller.stream;
});

// ============================================================================
// AI COACHING (PREMIUM)
// ============================================================================

/// Stream of coaching messages (most recent first)
final coachMessagesProvider = StreamProvider.autoDispose<List<CoachMessage>>((ref) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchCoachMessages(limit: 100);
});

// ============================================================================
// AI MEMORY / INSIGHTS (PREMIUM)
// ============================================================================

/// All active (non-dismissed) AI insights
final aiInsightsProvider = FutureProvider.autoDispose<List<AiInsight>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getActiveInsights();
});

// ============================================================================
// PROGRESS PHOTOS (PREMIUM)
// ============================================================================

/// Stream of all progress photos
final progressPhotosProvider = StreamProvider.autoDispose<List<ProgressPhoto>>((ref) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchProgressPhotos();
});

// ============================================================================
// CYCLE PREDICTIONS (PREMIUM)
// ============================================================================

/// Latest cycle prediction
final latestCyclePredictionProvider = FutureProvider.autoDispose<CyclePrediction?>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getLatestPrediction();
});

/// Cycle symptom log stream
final cycleLogsProvider = StreamProvider.autoDispose<List<CycleLog>>((ref) {
  final repo = ref.watch(primeRepoProvider);
  return repo.watchCycleLogs();
});

// ============================================================================
// ADVANCED ANALYTICS PROVIDERS
// ============================================================================

/// Extended check-ins by limit (for 90-day analytics)
final extendedCheckInsProvider =
    FutureProvider.autoDispose.family<List<CheckIn>, int>((ref, limit) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.latestCheckIns(limit: limit);
});

/// Monthly macro totals (30 days)
final monthlyMacroTotalsProvider =
    FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getDailyMacroTotals(30);
});

/// Quarterly macro totals (90 days)
final quarterlyMacroTotalsProvider =
    FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getDailyMacroTotals(90);
});

// ============================================================================
// CUSTOM WORKOUT TEMPLATES
// ============================================================================

/// Custom (user-created) workout templates
final customTemplatesProvider =
    FutureProvider.autoDispose<List<WorkoutTemplateDoc>>((ref) async {
  final repo = ref.watch(primeRepoProvider);
  return repo.getCustomTemplates();
});

// ============================================================================
// EXPORT SERVICE
// ============================================================================

final exportServiceProvider = Provider<ExportService>((ref) {
  final repo = ref.watch(primeRepoProvider);
  return ExportService(repo);
});