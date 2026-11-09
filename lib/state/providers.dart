import 'package:firebase_auth/firebase_auth.dart';
import '../repos/community_repo.dart';
import '../models/circle_comment.dart';
import '../models/circle_post.dart';
import '../models/circle_profile.dart';
import '../models/community_report.dart';
import '../services/personalization_safety.dart';
import '../services/local_memory_service.dart';
import '../services/checkin_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../repos/lyva_repo.dart';
import '../repos/user_profile_repo.dart';
import '../models/checkin.dart';
import '../models/prime_plan.dart';
import '../models/workout_template_doc.dart';
import '../models/workout_session_doc.dart';
import '../models/workout_plan_snapshot.dart';
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
import '../services/account_access_service.dart';
import '../services/firebase_account_backend.dart';
import '../services/social_auth_service.dart';
import '../services/firebase_social_auth_gateway.dart';
import '../services/export_service.dart';
import '../models/food_item.dart';
import '../utils/plateau_detector.dart';
import '../utils/workout_progression.dart';
import '../services/routine_workout_answers.dart';
import '../utils/cycle_calculator.dart';
export '../utils/cycle_calculator.dart' show CyclePhase;

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

final checkInPreferencesProvider = Provider<CheckInPreferences>((ref) => CheckInPreferences());

final lyvaRepoProvider = Provider<LyvaRepo>((ref) => LyvaRepo());
final routineWorkoutAnswersProvider = Provider<RoutineWorkoutAnswers>(
  (ref) => RoutineWorkoutAnswers.fromRepo(ref.watch(lyvaRepoProvider)),
);

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

final personalizationDecisionProvider = StreamProvider.autoDispose<PersonalizationDecision>((ref) =>
  ref.watch(userProfileRepoProvider).watchProfile().map(PersonalizationDecision.evaluate));

// Active injuries stream (safety feature)
final activeInjuriesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final repo = ref.watch(userProfileRepoProvider);
  return repo.watchActiveInjuries();
});

// ============================================================================
// CHECK-INS & DAILY DATA
// ============================================================================

final latestCheckInsStreamProvider = StreamProvider.autoDispose<List<CheckIn>>((
  ref,
) {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.watchLatestCheckIns(limit: 30);
});

// ============================================================================
// NUTRITION & MEALS
// ============================================================================

// Today's meals stream provider
final todayMealsStreamProvider = StreamProvider.autoDispose<List<MealLog>>((
  ref,
) {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.watchTodayMeals();
});

// Weekly macro totals provider (for MacroAdherenceCard)
final weeklyMacroTotalsProvider =
    FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getDailyMacroTotals(7); // Last 7 days
    });

// ============================================================================
// WORKOUT PLANS & TEMPLATES
// ============================================================================

final activePlanProvider = FutureProvider.autoDispose<PrimePlan?>((ref) async {
  final repo = ref.watch(lyvaRepoProvider);
  if (ref.watch(personalizationDecisionProvider).asData?.value.allowed != true) return null;
  return repo.getActivePlan();
});

final latestWorkoutTemplateProvider = FutureProvider<WorkoutTemplateDoc?>((
  ref,
) async {
  final repo = ref.read(lyvaRepoProvider);
  if (ref.watch(personalizationDecisionProvider).asData?.value.allowed != true) return null;
  return repo.getLatestWorkoutTemplate();
});

// ============================================================================
// TODAY'S WORKOUT SESSION
// ============================================================================

final todayWorkoutDayProvider = FutureProvider<int?>((ref) async {
  final repo = ref.watch(lyvaRepoProvider);
  final template = await ref.watch(latestWorkoutTemplateProvider.future);
  if (template == null) return null;

  final daysPerWeek = template.daysPerWeek;
  if (daysPerWeek < 1) return null;
  final plan = WorkoutPlanSnapshot.capture(template);
  final last = await repo.getLatestWorkoutSession(planId: plan.planId);
  return workoutDayIndex(daysPerWeek, last);
});

// This week's completed sessions provider
final thisWeekSessionsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final repo = ref.watch(lyvaRepoProvider);
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
final monthlyWorkoutSessionsProvider = FutureProvider.autoDispose
    .family<List<WorkoutSessionDoc>, DateTime>((ref, month) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getWorkoutSessionsForMonth(month);
    });

// Specific day's workout session
final dayWorkoutSessionProvider = FutureProvider.autoDispose
    .family<WorkoutSessionDoc?, DateTime>((ref, date) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getWorkoutSessionForDate(date);
    });

// Missed workouts count (this week) - smart miss tracking
final missedWorkoutsThisWeekProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repo = ref.watch(lyvaRepoProvider);
  final template = await repo.getLatestWorkoutTemplate();
  if (template == null) return 0;

  final startOfWeek = _getStartOfWeek(DateTime.now());
  return repo.getMissedWorkoutsCount(
    startDate: startOfWeek,
    scheduledDaysPerWeek: template.daysPerWeek,
  );
});

DateTime _getStartOfWeek(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));
}

// ============================================================================
// WOMEN'S HEALTH (KEY DIFFERENTIATOR)
// ============================================================================

// Current cycle phase (for cycle-aware training)
final currentCyclePhaseProvider = FutureProvider.autoDispose<CyclePhase?>((
  ref,
) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  return CycleCalculator.getCurrentPhase(profile);
});

// Post-partum status (for post-partum guidance)
final postpartumStatusProvider = FutureProvider.autoDispose<PostpartumStatus?>((
  ref,
) async {
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

  bool get needsClearance => !medicalClearance;
  String get phaseDescription => 'Recovery timing is individual; tailored postpartum plans remain unavailable.';
}

// ============================================================================
// ANALYTICS & TRACKING
// ============================================================================

final analyticsProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

// ============================================================================
// FOOD DATABASE & API
// ============================================================================

final foodApiServiceProvider = Provider<FoodApiService>(
  (ref) => FoodApiService(),
);

/// Search local DB first, then fall back to API. Caches API results locally.
final foodSearchProvider = FutureProvider.autoDispose
    .family<List<FoodItem>, String>((ref, query) async {
      if (query.trim().length < 2) return [];

      final repo = ref.read(lyvaRepoProvider);

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
  final authorized = await service.canReadSteps();
  if (!authorized) return 0;
  return service.getTodaySteps();
});

/// Last 7 days of step data for the trend chart.
final weeklyStepsProvider = FutureProvider.autoDispose<Map<DateTime, int>>((
  ref,
) async {
  final service = ref.read(stepTrackingServiceProvider);
  final authorized = await service.canReadSteps();
  if (!authorized) return {};
  return service.getWeeklySteps();
});

// ============================================================================
// PREMIUM ACCESS
// ============================================================================

final accountSessionProvider = ChangeNotifierProvider<AccountSession>(
  (ref) => AccountSession(),
);
final accountBackendProvider = Provider<AccountBackend>(
  (ref) => createFirebaseAccountBackend(),
);
final accountAccessServiceProvider = Provider<AccountAccessService>(
  (ref) => AccountAccessService(
    session: ref.read(accountSessionProvider),
    backend: ref.watch(accountBackendProvider),
    currentRevenueCatId: () => Purchases.appUserID,
    initializeRevenueCat: (uid) async {
      const reviewed = bool.fromEnvironment('LYVA_BILLING_IDENTITY_REVIEWED');
      final key = defaultTargetPlatform == TargetPlatform.iOS
          ? const String.fromEnvironment('LYVA_REVENUECAT_IOS_KEY')
          : defaultTargetPlatform == TargetPlatform.android
              ? const String.fromEnvironment('LYVA_REVENUECAT_ANDROID_KEY')
              : '';
      if (!reviewed || !await PremiumService.initRevenueCat(apiKey: key, appUserId: uid)) {
        throw const AccountAccessException(
          'Billing setup needs verification or account recovery.',
        );
      }
    },
  ),
);
final socialAuthGatewayProvider = Provider<SocialAuthGateway>((ref) => FirebaseSocialAuthGateway());
final socialAuthControllerProvider = ChangeNotifierProvider<SocialAuthController>((ref) {
  final controller = SocialAuthController(
    gateway: ref.watch(socialAuthGatewayProvider),
    session: ref.read(accountSessionProvider),
    billingInFlight: () => ref.read(accountAccessServiceProvider).billingInFlight,
  );
  controller.start();
  return controller;
});

final premiumServiceProvider = Provider<PremiumService>(
  (ref) => PremiumService(account: ref.watch(accountAccessServiceProvider)),
);

/// Premium access requires fresh server verification for the current account.
final premiumAccessProvider = FutureProvider.autoDispose<PremiumAccessStatus>((
  ref,
) async {
  // Account changes immediately invalidate pending access and cached UI state.
  ref.watch(accountSessionProvider);
  // Watch for real-time subscription changes from RevenueCat
  ref.watch(customerInfoStreamProvider);
  final profile = await ref.watch(userProfileProvider.future);
  final service = ref.watch(premiumServiceProvider);
  Timer? expiryTimer;
  var disposed = false;
  ref.onDispose(() { disposed = true; expiryTimer?.cancel(); });
  final status = await service.getAccessStatusAsync(profile);
  if (disposed) return PremiumAccessStatus.none;
  final expiry = status.validUntil;
  if (expiry != null) {
    final remaining = expiry.difference(DateTime.now());
    if (remaining <= Duration.zero) return PremiumAccessStatus.none;
    expiryTimer = Timer(remaining, ref.invalidateSelf);
  }
  return status;
});

/// RevenueCat offerings (for paywall display)
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  ref.watch(accountSessionProvider);
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
final coachMessagesProvider = StreamProvider.autoDispose<List<CoachMessage>>((
  ref,
) {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.watchCoachMessages(limit: 100);
});

// ============================================================================
// AI MEMORY / INSIGHTS (PREMIUM)
// ============================================================================

/// All active (non-dismissed) AI insights
final aiInsightsProvider = FutureProvider.autoDispose<List<AiInsight>>((
  ref,
) async {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.getActiveInsights();
});

// ============================================================================
// PROGRESS PHOTOS (PREMIUM)
// ============================================================================

/// Stream of all progress photos
final progressPhotosProvider = StreamProvider.autoDispose<List<ProgressPhoto>>((
  ref,
) {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.watchProgressPhotos();
});

// ============================================================================
// CYCLE PREDICTIONS (PREMIUM)
// ============================================================================

/// Latest cycle prediction
final latestCyclePredictionProvider =
    FutureProvider.autoDispose<CyclePrediction?>((ref) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getLatestPrediction();
    });

/// Cycle symptom log stream
final cycleLogsProvider = StreamProvider.autoDispose<List<CycleLog>>((ref) {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.watchCycleLogs();
});

// ============================================================================
// ADVANCED ANALYTICS PROVIDERS
// ============================================================================

/// Extended check-ins by limit (for 90-day analytics)
final extendedCheckInsProvider = FutureProvider.autoDispose
    .family<List<CheckIn>, int>((ref, limit) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.latestCheckIns(limit: limit);
    });

/// Monthly macro totals (30 days)
final monthlyMacroTotalsProvider =
    FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getDailyMacroTotals(30);
    });

/// Quarterly macro totals (90 days)
final quarterlyMacroTotalsProvider =
    FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getDailyMacroTotals(90);
    });

// ============================================================================
// CUSTOM WORKOUT TEMPLATES
// ============================================================================

/// Custom (user-created) workout templates
final customTemplatesProvider =
    FutureProvider.autoDispose<List<WorkoutTemplateDoc>>((ref) async {
      final repo = ref.watch(lyvaRepoProvider);
      return repo.getCustomTemplates();
    });

// ============================================================================
// EXPORT SERVICE
// ============================================================================

final exportServiceProvider = Provider<ExportService>((ref) {
  final repo = ref.watch(lyvaRepoProvider);
  return ExportService(repo);
});

// ============================================================================
// PLATEAU DETECTION & REFEED SYSTEM
// ============================================================================

/// Plateau status derived from check-ins + current plan.
/// Only activates for users with goal == 'cut'.
final plateauStatusProvider = FutureProvider.autoDispose<PlateauStatus?>((
  ref,
) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null) return null;

  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null || profile.goal != 'cut') return null;

  final repo = ref.watch(lyvaRepoProvider);
  final checkIns = await repo.getCheckInsForLastDays(21);

  return PlateauDetector.analyze(checkIns: checkIns, currentPlan: plan);
});

/// Current diet phase from active plan (reactive shortcut)
final currentDietPhaseProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final plan = await ref.watch(activePlanProvider.future);
  return plan?.phase ?? 'deficit';
});

/// Days remaining in refeed phase (null if not in refeed)
final refeedDaysRemainingProvider = FutureProvider.autoDispose<int?>((
  ref,
) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null || plan.phase != 'refeed') return null;
  return PlateauDetector.daysRemainingInRefeed(plan);
});

final localMemoryServiceProvider = Provider<LocalMemoryService>((ref) => LocalMemoryService(ref.read(accountSessionProvider)));

// Circles uses the same verified account identity as billing and safety gates.
final communityRepoProvider = Provider<CommunityRepo>((ref) => CommunityRepo(
  verifiedUid: () {
    final session = ref.read(accountSessionProvider);
    return session.recoverable ? session.uid : null;
  },
));

final selectedCircleCategoryProvider = StateProvider.autoDispose<String>((ref) {
  return 'all';
});

final circleAuthUserProvider = StreamProvider.autoDispose<User?>((ref) {
  ref.watch(socialAuthControllerProvider);
  final session = ref.watch(accountSessionProvider);
  if (!session.recoverable || session.uid == null) return Stream.value(null);
  final repo = ref.watch(communityRepoProvider);
  return repo.watchAuthUser();
});

final currentCircleProfileProvider = FutureProvider.autoDispose<CircleProfile?>(
  (ref) async {
    final authUser = ref.watch(circleAuthUserProvider).valueOrNull;
    if (authUser == null) return null;

    final profile = await ref.watch(userProfileProvider.future);
    if (profile == null || profile.age < 18) return null;

    final repo = ref.watch(communityRepoProvider);
    return repo.ensureCurrentProfile(profile);
  },
);

final blockedCircleUsersProvider = StreamProvider.autoDispose<Set<String>>((
  ref,
) async* {
  final circleProfile = await ref.watch(currentCircleProfileProvider.future);
  if (circleProfile == null) {
    yield <String>{};
    return;
  }

  final repo = ref.watch(communityRepoProvider);
  yield* repo.watchBlockedUserIds();
});

final circlePostsProvider = StreamProvider.autoDispose<List<CirclePost>>((
  ref,
) async* {
  final circleProfile = await ref.watch(currentCircleProfileProvider.future);
  if (circleProfile == null) {
    yield <CirclePost>[];
    return;
  }

  final category = ref.watch(selectedCircleCategoryProvider);
  final repo = ref.watch(communityRepoProvider);
  yield* repo.watchPosts(category: category);
});

final circleCommentsProvider = StreamProvider.autoDispose
    .family<List<CircleComment>, String>((ref, postId) async* {
      final circleProfile = await ref.watch(
        currentCircleProfileProvider.future,
      );
      if (circleProfile == null) {
        yield <CircleComment>[];
        return;
      }

      final repo = ref.watch(communityRepoProvider);
      yield* repo.watchComments(postId);
    });

final circlePostSupportProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, postId) async* {
      final circleProfile = await ref.watch(
        currentCircleProfileProvider.future,
      );
      if (circleProfile == null) {
        yield false;
        return;
      }

      final repo = ref.watch(communityRepoProvider);
      yield* repo.watchPostSupport(postId);
    });

final circleProfileProvider = StreamProvider.autoDispose
    .family<CircleProfile?, String>((ref, uid) async* {
      final circleProfile = await ref.watch(
        currentCircleProfileProvider.future,
      );
      if (circleProfile == null) {
        yield null;
        return;
      }

      final repo = ref.watch(communityRepoProvider);
      yield* repo.watchProfile(uid);
    });

final circleProfilePostsProvider = StreamProvider.autoDispose
    .family<List<CirclePost>, String>((ref, uid) async* {
      final circleProfile = await ref.watch(
        currentCircleProfileProvider.future,
      );
      if (circleProfile == null) {
        yield <CirclePost>[];
        return;
      }

      final repo = ref.watch(communityRepoProvider);
      yield* repo.watchPostsByAuthor(uid);
    });

final circleFollowingProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, uid) async* {
    final circleProfile = await ref.watch(currentCircleProfileProvider.future);
    if (circleProfile == null || circleProfile.uid == uid) {
      yield false;
      return;
    }

    final repo = ref.watch(communityRepoProvider);
    yield* repo.watchIsFollowing(uid);
  },
);

final communityModeratorProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final user = ref.watch(circleAuthUserProvider).valueOrNull;
  if (user == null) return false;
  final repo = ref.watch(communityRepoProvider);
  return repo.isCurrentUserModerator();
});

final openCommunityReportsProvider =
    StreamProvider.autoDispose<List<CommunityReport>>((ref) async* {
      final isModerator = await ref.watch(communityModeratorProvider.future);
      if (!isModerator) {
        yield <CommunityReport>[];
        return;
      }

      final repo = ref.watch(communityRepoProvider);
      yield* repo.watchOpenReports();
    });
