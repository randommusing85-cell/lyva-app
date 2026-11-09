import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/user_profile.dart';
import 'account_access_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Subscription tier
enum PremiumTier {
  none, // No subscription
  essentials, // $4.99/mo or $39.99/yr
  premium, // $9.99/mo or $79.99/yr
}

/// Access type
enum PremiumAccessType { premium, trial, expired, none }

// ============================================================================
// ACCESS STATUS
// ============================================================================

class PremiumAccessStatus {
  final PremiumAccessType type;
  final PremiumTier tier;
  final int trialDaysRemaining;
  final DateTime? validUntil;

  const PremiumAccessStatus._({
    required this.type,
    this.tier = PremiumTier.none,
    this.trialDaysRemaining = 0,
    this.validUntil,
  });

  // Factories
  static const none = PremiumAccessStatus._(type: PremiumAccessType.none);
  static const expired = PremiumAccessStatus._(type: PremiumAccessType.expired);

  factory PremiumAccessStatus.subscribed(
    PremiumTier tier, {
    DateTime? validUntil,
  }) => PremiumAccessStatus._(
    type: PremiumAccessType.premium,
    tier: tier,
    validUntil: validUntil,
  );

  factory PremiumAccessStatus.trial(int daysRemaining) => PremiumAccessStatus._(
    type: PremiumAccessType.trial,
    tier: PremiumTier.premium, // Trial unlocks everything
    trialDaysRemaining: daysRemaining,
  );

  /// Whether user has any access (subscription or trial)
  bool get hasAccess =>
      (validUntil == null || validUntil!.isAfter(DateTime.now())) &&
      (type == PremiumAccessType.premium || type == PremiumAccessType.trial);

  /// Whether user can access a specific feature based on their tier
  bool canAccessFeature(PremiumFeature feature) {
    if (!hasAccess) return false;
    // Trial unlocks all features
    if (type == PremiumAccessType.trial) return true;

    // Premium tier unlocks everything
    if (tier == PremiumTier.premium) return true;

    // Essentials tier only unlocks essentials features
    if (tier == PremiumTier.essentials) {
      return feature.requiredTier == PremiumTier.essentials;
    }

    return false;
  }

  // Legacy compatibility — still used by some UI checks
  // Prefer canAccessFeature() for feature-level checks
  static const premium = PremiumAccessStatus._(
    type: PremiumAccessType.premium,
    tier: PremiumTier.premium,
  );
}

// ============================================================================
// PREMIUM FEATURE ENUM
// ============================================================================

/// Premium features with tier assignment
enum PremiumFeature {
  // Premium tier features (AI-powered)
  aiCoaching(
    'ai_coaching',
    'AI Coaching',
    'Get personalized AI coaching conversations',
    PremiumTier.premium,
  ),
  aiMemory(
    'ai_memory',
    'AI Memory',
    'AI learns your patterns and gives smarter advice over time',
    PremiumTier.premium,
  ),
  progressPhotos(
    'progress_photos',
    'Progress Photos',
    'Upload photos for AI body analysis and celeb comparisons',
    PremiumTier.premium,
  ),
  cyclePredictions(
    'cycle_predictions',
    'Cycle Tracker',
    'Recorded cycle events and optional calendar-only estimates',
    PremiumTier.premium,
  ),

  // Essentials tier features
  advancedAnalytics(
    'advanced_analytics',
    'Advanced Analytics',
    'Detailed trends and insights',
    PremiumTier.essentials,
  ),
  mealScanner(
    'meal_scanner',
    'Meal Scanner',
    'Scan meals for instant nutrition info',
    PremiumTier.essentials,
  ),
  customWorkouts(
    'custom_workouts',
    'Custom Workouts',
    'Build your own workout routines',
    PremiumTier.essentials,
  ),
  exportData(
    'export_data',
    'Export Data',
    'Export your progress data',
    PremiumTier.essentials,
  );

  final String id;
  final String name;
  final String description;
  final PremiumTier requiredTier;

  const PremiumFeature(this.id, this.name, this.description, this.requiredTier);
}

// ============================================================================
// PREMIUM SERVICE
// ============================================================================

/// Service for managing premium access, subscriptions, and trial
class PremiumService {
  final AccountAccessService account;
  PremiumService({AccountAccessService? account})
    : account =
          account ??
          AccountAccessService(
            session: AccountSession(),
            backend: const UnavailableAccountBackend(),
            currentRevenueCatId: () => Purchases.appUserID,
          );

  PremiumAccessStatus _verified(VerifiedPremiumAccess access) =>
      PremiumAccessStatus.subscribed(
        access.tier == VerifiedTier.premium
            ? PremiumTier.premium
            : PremiumTier.essentials,
        validUntil: access.expiresAt,
      );

  // Exact existing App Store identifiers. Never infer a tier from price.
  static const essentialsMonthlyProductId = 'lyva_essentials_monthly';
  static const essentialsAnnualProductId = 'lyva_essentials_annually';
  static const premiumMonthlyProductId = 'lyva_premium_monthly';
  static const premiumAnnualProductId = 'lyva_premium_annually';

  // Verified against App Store Connect and RevenueCat on 2026-11-09.
  // Google Play products must be separately reviewed before enabling Android.
  static const reviewedProductPeriods = {
    essentialsMonthlyProductId: 'P1M',
    essentialsAnnualProductId: 'P1Y',
    premiumMonthlyProductId: 'P1M',
    premiumAnnualProductId: 'P1Y',
  };

  static bool isReviewedStoreProduct(StoreProduct product) =>
      reviewedProductPeriods.containsKey(product.identifier) &&
      reviewedProductPeriods[product.identifier] == product.subscriptionPeriod;

  static String productIdFor(PremiumTier tier, {required bool yearly}) {
    return switch ((tier, yearly)) {
      (PremiumTier.essentials, false) => essentialsMonthlyProductId,
      (PremiumTier.essentials, true) => essentialsAnnualProductId,
      (PremiumTier.premium, false) => premiumMonthlyProductId,
      (PremiumTier.premium, true) => premiumAnnualProductId,
      (PremiumTier.none, _) => throw ArgumentError(
        'PremiumTier.none does not have a product identifier.',
      ),
    };
  }

  static const int trialDurationDays = 7;

  // RevenueCat entitlement identifiers
  static const _entitlementEssentials = 'essentials';
  static const _entitlementPremium = 'premium';

  // ===== USAGE CAPS =====

  /// Monthly AI coach message cap for Premium tier
  static const int aiCoachMessageCap = 50;

  /// Monthly photo analysis cap for Premium tier
  static const int photoAnalysisCap = 4;

  /// Check if the user's usage counters need a monthly reset.
  /// Returns true if counters were reset.
  static bool checkAndResetUsageIfNeeded(UserProfile profile) {
    final resetDate = profile.usageResetDate;
    final now = DateTime.now();

    if (resetDate == null) {
      // First time — initialize reset date to start of current month
      profile.usageResetDate = DateTime(now.year, now.month, 1);
      profile.aiCoachMessagesUsed = 0;
      profile.photoAnalysesUsed = 0;
      return true;
    }

    // Check if we've rolled into a new month since last reset
    if (now.year > resetDate.year ||
        (now.year == resetDate.year && now.month > resetDate.month)) {
      profile.usageResetDate = DateTime(now.year, now.month, 1);
      profile.aiCoachMessagesUsed = 0;
      profile.photoAnalysesUsed = 0;
      return true;
    }

    return false;
  }

  /// Whether the user can send another AI coach message
  bool canSendCoachMessage(UserProfile profile) {
    return profile.aiCoachMessagesUsed < aiCoachMessageCap;
  }

  /// Whether the user can request another photo analysis
  bool canAnalyzePhoto(UserProfile profile) {
    return profile.photoAnalysesUsed < photoAnalysisCap;
  }

  /// Remaining AI coach messages this month
  int coachMessagesRemaining(UserProfile profile) {
    return (aiCoachMessageCap - profile.aiCoachMessagesUsed).clamp(
      0,
      aiCoachMessageCap,
    );
  }

  /// Remaining photo analyses this month
  int photoAnalysesRemaining(UserProfile profile) {
    return (photoAnalysisCap - profile.photoAnalysesUsed).clamp(
      0,
      photoAnalysisCap,
    );
  }

  // ===== REVENUECAT INITIALIZATION =====

  /// Billing setup must not prevent guests from using local tracking.
  static Future<bool> initRevenueCat({
    required String apiKey,
    required String appUserId,
  }) async {
    if (apiKey.isEmpty ||
        apiKey.contains('YOUR_') ||
        appUserId.isEmpty ||
        appUserId.startsWith(r'$RCAnonymousID:')) {
      return false;
    }
    try {
      if (await Purchases.isConfigured) {
        return await Purchases.appUserID == appUserId;
      }
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = appUserId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== SUBSCRIPTION STATUS =====

  /// Get current tier from RevenueCat CustomerInfo
  PremiumTier getTierFromCustomerInfo(CustomerInfo info) {
    if (info.entitlements.active.containsKey(_entitlementPremium)) {
      return PremiumTier.premium;
    }
    if (info.entitlements.active.containsKey(_entitlementEssentials)) {
      return PremiumTier.essentials;
    }
    return PremiumTier.none;
  }

  /// Paid access requires a recoverable account and fresh server verification.
  /// Local trial dates are preserved, but the trial policy is not yet verified.
  Future<PremiumAccessStatus> getAccessStatusAsync(UserProfile? profile) async {
    try {
      final access = await account.verifyPremium();
      return access == null ? PremiumAccessStatus.none : _verified(access);
    } catch (_) {
      return PremiumAccessStatus.none;
    }
  }

  /// Neither a cached profile nor a local trial can authorize premium access.
  PremiumAccessStatus getAccessStatus(UserProfile? profile) =>
      PremiumAccessStatus.none;

  // ===== PURCHASE & RESTORE =====

  /// Fetch available offerings for the paywall
  Future<Offerings> getOfferings() async {
    await account.prepareBillingIdentity();
    return Purchases.getOfferings();
  }

  /// SDK completion alone never grants access or updates the local health profile.
  Future<PremiumAccessStatus> purchase(Package package) async {
    if (!isReviewedStoreProduct(package.storeProduct)) {
      throw const AccountAccessException(
        'This subscription is unavailable. Please refresh the available plans.',
      );
    }
    return _verified(
      await account.billing(BillingAction.purchase, () async {
        await Purchases.purchasePackage(package);
      }),
    );
  }

  Future<PremiumAccessStatus> restorePurchases() async => _verified(
    await account.billing(BillingAction.restore, () async {
      await Purchases.restorePurchases();
    }),
  );

  /// Get the App Store / Play Store subscription management URL
  Future<String?> getManagementUrl() async {
    final info = await Purchases.getCustomerInfo();
    return info.managementURL;
  }

  // ===== TRIAL =====

  /// Get trial days remaining (null if no trial, 0 if expired)
  int? getTrialDaysRemaining(UserProfile profile) {
    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return null;
    final remaining =
        trialDurationDays - DateTime.now().difference(trialStart).inDays;
    return remaining.clamp(0, trialDurationDays);
  }

  /// Check if trial has expired
  bool isTrialExpired(UserProfile profile) {
    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return false;
    return DateTime.now().difference(trialStart).inDays >= trialDurationDays;
  }
}
