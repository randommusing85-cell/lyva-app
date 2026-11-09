import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional, coarse product analytics. Health events, user properties, free text,
/// screen names and event parameters are intentionally never sent.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal() : _override = null;
  AnalyticsService.forTesting(FirebaseAnalytics analytics)
    : _override = analytics;
  final FirebaseAnalytics? _override;
  FirebaseAnalytics get _analytics => _override ?? FirebaseAnalytics.instance;
  static const preferenceKey = 'optional_analytics_enabled_v1';
  final enabled = ValueNotifier<bool>(false);
  static const _legacyProperties = [
    'age_group',
    'sex',
    'goal',
    'level',
    'equipment',
    'training_days',
    'tracks_cycle',
    'postpartum_status',
    'premium_waitlist',
    'premium_status',
  ];

  Future<void> initialize() async {
    enabled.value = false;
    try {
      await _analytics.setAnalyticsCollectionEnabled(false);
      if (const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD')) return;
      for (final name in _legacyProperties) {
        await _analytics.setUserProperty(name: name, value: null);
      }
      final preferences = await SharedPreferences.getInstance();
      final consent = preferences.getBool(preferenceKey) ?? false;
      if (consent) await _analytics.setAnalyticsCollectionEnabled(true);
      enabled.value = consent;
    } catch (_) {
      // Optional telemetry must never block startup; default to no app events.
      enabled.value = false;
    }
  }

  Future<void> _consentUpdate = Future<void>.value();
  Future<void> setCollectionEnabled(bool value) {
    enabled.value = false;
    _consentUpdate = _consentUpdate
        .catchError((Object _) {})
        .then((_) => _setCollectionEnabled(value));
    return _consentUpdate;
  }

  Future<void> _setCollectionEnabled(bool value) async {
    enabled.value = false;
    await _analytics.setAnalyticsCollectionEnabled(false);
    if (const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD')) return;
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(preferenceKey, value)) {
      throw StateError('Could not save analytics preference');
    }
    await _analytics.setAnalyticsCollectionEnabled(value);
    enabled.value = value;
  }

  Future<void> _record(String event) async {
    if (!enabled.value) return;
    try {
      await _analytics.logEvent(name: event);
    } catch (_) {
      // Analytics failures do not fail the user's save or purchase action.
    }
  }

  Future<void> setUserDemographics({
    required int age,
    required String sex,
    required String goal,
    required String level,
    required String equipment,
    required int trainingDaysPerWeek,
    required bool tracksCycle,
    required String postPartumStatus,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logOnboardingStarted() async {
    await _record('onboarding_started');
  }

  Future<void> logOnboardingCompleted({
    required int age,
    required String sex,
    required String goal,
    required bool tracksCycle,
    required bool isPostPartum,
  }) async {
    await _record('onboarding_completed');
  }

  Future<void> logSetupGuideViewed() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logSetupGuideSkipped() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logNutritionPlanGenerated({
    required String goal,
    required int calories,
    required int trainingDays,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logNutritionPlanSaved({
    required String planName,
    required int calories,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logNutritionPlanRegenerated({
    required int daysSinceLastPlan,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logMealLogged({
    required String mealType,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required bool hasDescription,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logMealDeleted({required String mealType}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logDailyMacrosCompleted({
    required int totalCalories,
    required int targetCalories,
    required double adherencePercent,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logWorkoutPlanGenerated({
    required String level,
    required String equipment,
    required int daysPerWeek,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logWorkoutPlanSaved({
    required String planName,
    required int daysPerWeek,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logWorkoutPlanRegenerated({
    required int daysSinceLastPlan,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logWorkoutStarted({
    required int dayIndex,
    required int totalDays,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logWorkoutCompleted({
    required int dayIndex,
    required int totalDays,
    required int exercisesCompleted,
    required int totalExercises,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logWeeklyWorkoutCompleted({
    required int weekNumber,
    required int completedDays,
    required int totalDays,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCheckInCompleted({
    required double weightKg,
    required double waistCm,
    required int stepsToday,
    required bool hasNote,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCheckInStreak({required int consecutiveDays}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAiCoachQueried({
    required String type, // 'nutrition' or 'workout'
    required int daysSincePlanCreated,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAiCoachAdjustmentApplied({
    required String type,
    required String action, // 'adjust', 'hold', 'reassess'
    required int calorieDelta,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAiCoachLockEncountered({
    required String type,
    required int daysRemaining,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logScreenView(String screenName) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logTrendsViewed() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logSettingsViewed() async {
    await _record('settings_viewed');
  }

  Future<void> logCyclePhaseViewed({
    required String phase,
    required int cycleDay,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCycleEducationViewed({required String phase}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPostPartumGuidanceViewed({
    required String phase,
    required int weeksPostPartum,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPostPartumRedFlagsViewed() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logProfileEditStarted() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logProfileUpdated({required List<String> fieldsChanged}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAppOpened() async {
    await _record('app_opened');
  }

  Future<void> logSessionStart() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logSessionEnd({required int durationSeconds}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logError({
    required String errorType,
    required String screen,
    String? details,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logFeatureUsed({required String featureName}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logHelpViewed({required String topic}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logFeedbackSubmitted() async {
    await _record('feedback_submitted');
  }

  Future<void> logMedicalDisclaimerViewed() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPremiumFeatureTapped({required String featureId}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPremiumWaitlistViewed({required String featureId}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPremiumWaitlistJoined({
    required String email,
    required List<String> features,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPremiumGateEncountered({
    required String featureId,
    required String screen,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPremiumTrialStarted() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPremiumTrialExpired() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAiCoachSessionStarted() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAiCoachMessageSent() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logProgressPhotoTaken() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logProgressPhotoAnalyzed() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCyclePredictionGenerated() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCycleSymptomLogged({
    required String symptomType,
    required int severity,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logAdvancedAnalyticsViewed({required String dateRange}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logDataExported({
    required String format,
    required List<String> dataTypes,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCustomWorkoutCreated({
    required int daysPerWeek,
    required int totalExercises,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logCustomWorkoutActivated() async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPaywallViewed({String? source}) async {
    await _record('paywall_viewed');
  }

  Future<void> logSubscriptionStarted({
    required String tier,
    required String period,
  }) async {
    await _record('subscription_started');
  }

  Future<void> logSubscriptionRestored({required String tier}) async {
    await _record('subscription_restored');
  }

  Future<void> logSubscriptionUpgraded({
    required String fromTier,
    required String toTier,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logPaywallDismissed() async {
    await _record('paywall_dismissed');
  }

  Future<void> logPlateauDetected({
    required double? weightChangeKg,
    required int daysInDeficit,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logRefeedStarted({
    required int maintenanceCalories,
    required int previousCalories,
  }) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logRefeedCompleted({required int refeedDurationDays}) async {
    // Deliberately excluded from optional analytics.
  }

  Future<void> logDeficitResumed({required int resumedCalories}) async {
    // Deliberately excluded from optional analytics.
  }
}
