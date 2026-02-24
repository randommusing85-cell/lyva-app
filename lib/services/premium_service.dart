import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/user_profile.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Subscription tier
enum PremiumTier {
  none,       // No subscription
  essentials, // $4.99/mo or $29.99/yr
  premium,    // $9.99/mo or $49.99/yr
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

  const PremiumAccessStatus._({
    required this.type,
    this.tier = PremiumTier.none,
    this.trialDaysRemaining = 0,
  });

  // Factories
  static const none = PremiumAccessStatus._(type: PremiumAccessType.none);
  static const expired = PremiumAccessStatus._(type: PremiumAccessType.expired);

  factory PremiumAccessStatus.subscribed(PremiumTier tier) =>
      PremiumAccessStatus._(type: PremiumAccessType.premium, tier: tier);

  factory PremiumAccessStatus.trial(int daysRemaining) =>
      PremiumAccessStatus._(
        type: PremiumAccessType.trial,
        tier: PremiumTier.premium, // Trial unlocks everything
        trialDaysRemaining: daysRemaining,
      );

  /// Whether user has any access (subscription or trial)
  bool get hasAccess =>
      type == PremiumAccessType.premium || type == PremiumAccessType.trial;

  /// Whether user can access a specific feature based on their tier
  bool canAccessFeature(PremiumFeature feature) {
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
  aiCoaching('ai_coaching', 'AI Coaching', 'Get personalized AI coaching conversations', PremiumTier.premium),
  aiMemory('ai_memory', 'AI Memory', 'AI learns your patterns and gives smarter advice over time', PremiumTier.premium),
  progressPhotos('progress_photos', 'Progress Photos', 'Upload photos for AI body analysis and celeb comparisons', PremiumTier.premium),
  cyclePredictions('cycle_predictions', 'Cycle Predictions', 'AI-powered period cycle predictions and training adjustments', PremiumTier.premium),

  // Essentials tier features
  advancedAnalytics('advanced_analytics', 'Advanced Analytics', 'Detailed trends and insights', PremiumTier.essentials),
  mealScanner('meal_scanner', 'Meal Scanner', 'Scan meals for instant nutrition info', PremiumTier.essentials),
  customWorkouts('custom_workouts', 'Custom Workouts', 'Build your own workout routines', PremiumTier.essentials),
  exportData('export_data', 'Export Data', 'Export your progress data', PremiumTier.essentials);

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
    return (aiCoachMessageCap - profile.aiCoachMessagesUsed).clamp(0, aiCoachMessageCap);
  }

  /// Remaining photo analyses this month
  int photoAnalysesRemaining(UserProfile profile) {
    return (photoAnalysisCap - profile.photoAnalysesUsed).clamp(0, photoAnalysisCap);
  }

  // ===== REVENUECAT INITIALIZATION =====

  /// Initialize RevenueCat SDK. Call once at app startup.
  static Future<void> initRevenueCat({required String apiKey}) async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
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

  /// Get access status combining RevenueCat subscription + local trial.
  /// RevenueCat is the source of truth for paid subscriptions.
  Future<PremiumAccessStatus> getAccessStatusAsync(UserProfile? profile) async {
    // 1. Check RevenueCat first (paid subscription)
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final tier = getTierFromCustomerInfo(customerInfo);
      if (tier != PremiumTier.none) {
        return PremiumAccessStatus.subscribed(tier);
      }
    } catch (_) {
      // Offline or SDK not configured — fall through to local
    }

    // 2. Fall back to local trial/profile check
    return getAccessStatus(profile);
  }

  /// Synchronous access status check (local only, for backward compat)
  PremiumAccessStatus getAccessStatus(UserProfile? profile) {
    if (profile == null) return PremiumAccessStatus.none;
    if (profile.isPremium) {
      // Cached subscription tier
      final tier = _tierFromString(profile.premiumTier);
      return PremiumAccessStatus.subscribed(tier);
    }

    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return PremiumAccessStatus.none;

    final elapsed = DateTime.now().difference(trialStart).inDays;
    final remaining = trialDurationDays - elapsed;

    if (remaining > 0) return PremiumAccessStatus.trial(remaining);
    return PremiumAccessStatus.expired;
  }

  PremiumTier _tierFromString(String? tierStr) {
    if (tierStr == 'premium') return PremiumTier.premium;
    if (tierStr == 'essentials') return PremiumTier.essentials;
    return PremiumTier.premium; // Default for legacy isPremium = true
  }

  // ===== PURCHASE & RESTORE =====

  /// Fetch available offerings for the paywall
  Future<Offerings> getOfferings() => Purchases.getOfferings();

  /// Purchase a package (monthly or yearly subscription)
  Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  /// Restore previously purchased subscriptions
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  /// Get the App Store / Play Store subscription management URL
  Future<String?> getManagementUrl() async {
    final info = await Purchases.getCustomerInfo();
    return info.managementURL;
  }

  // ===== PROMO CODE REDEMPTION =====

  // TODO: Replace with Cloud Function call for server-side validation
  // e.g. final res = await FirebaseFunctions.instance
  //   .httpsCallable('redeemPromoCode').call({'code': code});
  static const Map<String, PremiumTier> _validPromoCodes = {
    'PRIMEFORM2025': PremiumTier.premium,
    'KINETICIQ': PremiumTier.premium,
    'ESSENTIALS': PremiumTier.essentials,
  };

  /// Validate a promo code and return the tier it unlocks.
  /// Returns null if the code is invalid.
  PremiumTier? redeemPromoCode(String code) {
    final normalized = code.trim().toUpperCase();
    return _validPromoCodes[normalized];
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
    if (profile.isPremium) return false;
    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return false;
    return DateTime.now().difference(trialStart).inDays >= trialDurationDays;
  }

}
