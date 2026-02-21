import 'package:firebase_analytics/firebase_analytics.dart';

/// Central analytics service for tracking user behavior and events
/// Uses Firebase Analytics for free, comprehensive tracking
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ===== USER PROPERTIES (Demographics) =====

  /// Set user demographics - call once during onboarding
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
    await _analytics.setUserProperty(name: 'age_group', value: _getAgeGroup(age));
    await _analytics.setUserProperty(name: 'sex', value: sex);
    await _analytics.setUserProperty(name: 'goal', value: goal);
    await _analytics.setUserProperty(name: 'level', value: level);
    await _analytics.setUserProperty(name: 'equipment', value: equipment);
    await _analytics.setUserProperty(
      name: 'training_days',
      value: trainingDaysPerWeek.toString(),
    );
    await _analytics.setUserProperty(
      name: 'tracks_cycle',
      value: tracksCycle ? 'yes' : 'no',
    );
    await _analytics.setUserProperty(
      name: 'postpartum_status',
      value: postPartumStatus,
    );
  }

  String _getAgeGroup(int age) {
    if (age < 20) return 'under_20';
    if (age < 25) return '20_24';
    if (age < 30) return '25_29';
    if (age < 35) return '30_34';
    if (age < 40) return '35_39';
    if (age < 45) return '40_44';
    if (age < 50) return '45_49';
    return '50_plus';
  }

  // ===== ONBOARDING & SETUP =====

  Future<void> logOnboardingStarted() async {
    await _analytics.logEvent(name: 'onboarding_started');
  }

  Future<void> logOnboardingCompleted({
    required int age,
    required String sex,
    required String goal,
    required bool tracksCycle,
    required bool isPostPartum,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {
        'age_group': _getAgeGroup(age),
        'sex': sex,
        'goal': goal,
        'tracks_cycle': tracksCycle ? 'yes' : 'no',
        'is_postpartum': isPostPartum ? 'yes' : 'no',
      },
    );
  }

  Future<void> logSetupGuideViewed() async {
    await _analytics.logEvent(name: 'setup_guide_viewed');
  }

  Future<void> logSetupGuideSkipped() async {
    await _analytics.logEvent(name: 'setup_guide_skipped');
  }

  // ===== NUTRITION PLAN =====

  Future<void> logNutritionPlanGenerated({
    required String goal,
    required int calories,
    required int trainingDays,
  }) async {
    await _analytics.logEvent(
      name: 'nutrition_plan_generated',
      parameters: {
        'goal': goal,
        'calories': calories,
        'training_days': trainingDays,
      },
    );
  }

  Future<void> logNutritionPlanSaved({
    required String planName,
    required int calories,
  }) async {
    await _analytics.logEvent(
      name: 'nutrition_plan_saved',
      parameters: {
        'plan_name': planName,
        'calories': calories,
      },
    );
  }

  Future<void> logNutritionPlanRegenerated({
    required int daysSinceLastPlan,
  }) async {
    await _analytics.logEvent(
      name: 'nutrition_plan_regenerated',
      parameters: {
        'days_since_last': daysSinceLastPlan,
      },
    );
  }

  // ===== MEAL LOGGING =====

  Future<void> logMealLogged({
    required String mealType,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required bool hasDescription,
  }) async {
    await _analytics.logEvent(
      name: 'meal_logged',
      parameters: {
        'meal_type': mealType,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'has_description': hasDescription ? 'yes' : 'no',
        'total_calories': (proteinG * 4) + (carbsG * 4) + (fatG * 9),
      },
    );
  }

  Future<void> logMealDeleted({
    required String mealType,
  }) async {
    await _analytics.logEvent(
      name: 'meal_deleted',
      parameters: {
        'meal_type': mealType,
      },
    );
  }

  Future<void> logDailyMacrosCompleted({
    required int totalCalories,
    required int targetCalories,
    required double adherencePercent,
  }) async {
    await _analytics.logEvent(
      name: 'daily_macros_completed',
      parameters: {
        'total_calories': totalCalories,
        'target_calories': targetCalories,
        'adherence_percent': adherencePercent.round(),
      },
    );
  }

  // ===== WORKOUT PLAN =====

  Future<void> logWorkoutPlanGenerated({
    required String level,
    required String equipment,
    required int daysPerWeek,
  }) async {
    await _analytics.logEvent(
      name: 'workout_plan_generated',
      parameters: {
        'level': level,
        'equipment': equipment,
        'days_per_week': daysPerWeek,
      },
    );
  }

  Future<void> logWorkoutPlanSaved({
    required String planName,
    required int daysPerWeek,
  }) async {
    await _analytics.logEvent(
      name: 'workout_plan_saved',
      parameters: {
        'plan_name': planName,
        'days_per_week': daysPerWeek,
      },
    );
  }

  Future<void> logWorkoutPlanRegenerated({
    required int daysSinceLastPlan,
  }) async {
    await _analytics.logEvent(
      name: 'workout_plan_regenerated',
      parameters: {
        'days_since_last': daysSinceLastPlan,
      },
    );
  }

  // ===== WORKOUT SESSIONS =====

  Future<void> logWorkoutStarted({
    required int dayIndex,
    required int totalDays,
  }) async {
    await _analytics.logEvent(
      name: 'workout_started',
      parameters: {
        'day_index': dayIndex,
        'total_days': totalDays,
      },
    );
  }

  Future<void> logWorkoutCompleted({
    required int dayIndex,
    required int totalDays,
    required int exercisesCompleted,
    required int totalExercises,
  }) async {
    await _analytics.logEvent(
      name: 'workout_completed',
      parameters: {
        'day_index': dayIndex,
        'total_days': totalDays,
        'exercises_completed': exercisesCompleted,
        'total_exercises': totalExercises,
        'completion_rate': ((exercisesCompleted / totalExercises) * 100).round(),
      },
    );
  }

  Future<void> logWeeklyWorkoutCompleted({
    required int weekNumber,
    required int completedDays,
    required int totalDays,
  }) async {
    await _analytics.logEvent(
      name: 'weekly_workout_completed',
      parameters: {
        'week_number': weekNumber,
        'completed_days': completedDays,
        'total_days': totalDays,
        'completion_rate': ((completedDays / totalDays) * 100).round(),
      },
    );
  }

  // ===== CHECK-INS =====

  Future<void> logCheckInCompleted({
    required double weightKg,
    required double waistCm,
    required int stepsToday,
    required bool hasNote,
  }) async {
    await _analytics.logEvent(
      name: 'checkin_completed',
      parameters: {
        'weight_kg': weightKg.round(),
        'waist_cm': waistCm.round(),
        'steps_today': stepsToday,
        'has_note': hasNote ? 'yes' : 'no',
      },
    );
  }

  Future<void> logCheckInStreak({
    required int consecutiveDays,
  }) async {
    await _analytics.logEvent(
      name: 'checkin_streak',
      parameters: {
        'consecutive_days': consecutiveDays,
      },
    );
  }

  // ===== AI COACH =====

  Future<void> logAiCoachQueried({
    required String type, // 'nutrition' or 'workout'
    required int daysSincePlanCreated,
  }) async {
    await _analytics.logEvent(
      name: 'ai_coach_queried',
      parameters: {
        'type': type,
        'days_since_plan': daysSincePlanCreated,
      },
    );
  }

  Future<void> logAiCoachAdjustmentApplied({
    required String type,
    required String action, // 'adjust', 'hold', 'reassess'
    required int calorieDelta,
  }) async {
    await _analytics.logEvent(
      name: 'ai_coach_adjustment_applied',
      parameters: {
        'type': type,
        'action': action,
        'calorie_delta': calorieDelta,
      },
    );
  }

  Future<void> logAiCoachLockEncountered({
    required String type,
    required int daysRemaining,
  }) async {
    await _analytics.logEvent(
      name: 'ai_coach_lock_encountered',
      parameters: {
        'type': type,
        'days_remaining': daysRemaining,
      },
    );
  }

  // ===== NAVIGATION & SCREENS =====

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logTrendsViewed() async {
    await _analytics.logEvent(name: 'trends_viewed');
  }

  Future<void> logSettingsViewed() async {
    await _analytics.logEvent(name: 'settings_viewed');
  }

  // ===== CYCLE TRACKING (Women) =====

  Future<void> logCyclePhaseViewed({
    required String phase,
    required int cycleDay,
  }) async {
    await _analytics.logEvent(
      name: 'cycle_phase_viewed',
      parameters: {
        'phase': phase,
        'cycle_day': cycleDay,
      },
    );
  }

  Future<void> logCycleEducationViewed({
    required String phase,
  }) async {
    await _analytics.logEvent(
      name: 'cycle_education_viewed',
      parameters: {
        'phase': phase,
      },
    );
  }

  // ===== POST-PARTUM (Women) =====

  Future<void> logPostPartumGuidanceViewed({
    required String phase,
    required int weeksPostPartum,
  }) async {
    await _analytics.logEvent(
      name: 'postpartum_guidance_viewed',
      parameters: {
        'phase': phase,
        'weeks_postpartum': weeksPostPartum,
      },
    );
  }

  Future<void> logPostPartumRedFlagsViewed() async {
    await _analytics.logEvent(name: 'postpartum_red_flags_viewed');
  }

  // ===== PROFILE EDITING =====

  Future<void> logProfileEditStarted() async {
    await _analytics.logEvent(name: 'profile_edit_started');
  }

  Future<void> logProfileUpdated({
    required List<String> fieldsChanged,
  }) async {
    await _analytics.logEvent(
      name: 'profile_updated',
      parameters: {
        'fields_changed': fieldsChanged.join(','),
        'num_fields': fieldsChanged.length,
      },
    );
  }

  // ===== RETENTION & ENGAGEMENT =====

  Future<void> logAppOpened() async {
    await _analytics.logEvent(name: 'app_opened');
  }

  Future<void> logSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
  }

  Future<void> logSessionEnd({
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {
        'duration_seconds': durationSeconds,
        'duration_minutes': (durationSeconds / 60).round(),
      },
    );
  }

  // ===== ERRORS & ISSUES =====

  Future<void> logError({
    required String errorType,
    required String screen,
    String? details,
  }) async {
    await _analytics.logEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'screen': screen,
        if (details != null) 'details': details,
      },
    );
  }

  // ===== FEATURE FLAGS & A/B TESTING =====

  Future<void> logFeatureUsed({
    required String featureName,
  }) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature': featureName,
      },
    );
  }

  // ===== HELP & SUPPORT =====

  Future<void> logHelpViewed({
    required String topic,
  }) async {
    await _analytics.logEvent(
      name: 'help_viewed',
      parameters: {
        'topic': topic,
      },
    );
  }

  Future<void> logFeedbackSubmitted() async {
    await _analytics.logEvent(name: 'feedback_submitted');
  }

  Future<void> logMedicalDisclaimerViewed() async {
    await _analytics.logEvent(name: 'medical_disclaimer_viewed');
  }

  // ===== PREMIUM & WAITLIST =====

  Future<void> logPremiumFeatureTapped({
    required String featureId,
  }) async {
    await _analytics.logEvent(
      name: 'premium_feature_tapped',
      parameters: {
        'feature_id': featureId,
      },
    );
  }

  Future<void> logPremiumWaitlistViewed({
    required String featureId,
  }) async {
    await _analytics.logEvent(
      name: 'premium_waitlist_viewed',
      parameters: {
        'trigger_feature': featureId,
      },
    );
  }

  Future<void> logPremiumWaitlistJoined({
    required String email,
    required List<String> features,
  }) async {
    await _analytics.logEvent(
      name: 'premium_waitlist_joined',
      parameters: {
        'num_features_selected': features.length,
        'features': features.join(','),
      },
    );
    // Also set user property
    await _analytics.setUserProperty(
      name: 'premium_waitlist',
      value: 'joined',
    );
  }

  Future<void> logPremiumGateEncountered({
    required String featureId,
    required String screen,
  }) async {
    await _analytics.logEvent(
      name: 'premium_gate_encountered',
      parameters: {
        'feature_id': featureId,
        'screen': screen,
      },
    );
  }

  // ===== PREMIUM TRIAL =====

  Future<void> logPremiumTrialStarted() async {
    await _analytics.logEvent(name: 'premium_trial_started');
    await _analytics.setUserProperty(name: 'premium_status', value: 'trial');
  }

  Future<void> logPremiumTrialExpired() async {
    await _analytics.logEvent(name: 'premium_trial_expired');
    await _analytics.setUserProperty(name: 'premium_status', value: 'expired');
  }

  // ===== AI COACHING (Premium) =====

  Future<void> logAiCoachSessionStarted() async {
    await _analytics.logEvent(name: 'ai_coach_session_started');
  }

  Future<void> logAiCoachMessageSent() async {
    await _analytics.logEvent(name: 'ai_coach_message_sent');
  }

  // ===== PROGRESS PHOTOS (Premium) =====

  Future<void> logProgressPhotoTaken() async {
    await _analytics.logEvent(name: 'progress_photo_taken');
  }

  Future<void> logProgressPhotoAnalyzed() async {
    await _analytics.logEvent(name: 'progress_photo_analyzed');
  }

  // ===== CYCLE PREDICTIONS (Premium) =====

  Future<void> logCyclePredictionGenerated() async {
    await _analytics.logEvent(name: 'cycle_prediction_generated');
  }

  Future<void> logCycleSymptomLogged({
    required String symptomType,
    required int severity,
  }) async {
    await _analytics.logEvent(
      name: 'cycle_symptom_logged',
      parameters: {
        'symptom_type': symptomType,
        'severity': severity,
      },
    );
  }
}
