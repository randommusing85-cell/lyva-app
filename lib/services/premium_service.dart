import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Premium access status
enum PremiumAccessType { premium, trial, expired, none }

class PremiumAccessStatus {
  final PremiumAccessType type;
  final int trialDaysRemaining;

  const PremiumAccessStatus._(this.type, [this.trialDaysRemaining = 0]);

  static const premium = PremiumAccessStatus._(PremiumAccessType.premium);
  static const expired = PremiumAccessStatus._(PremiumAccessType.expired);
  static const none = PremiumAccessStatus._(PremiumAccessType.none);

  factory PremiumAccessStatus.trial(int daysRemaining) =>
      PremiumAccessStatus._(PremiumAccessType.trial, daysRemaining);

  bool get hasAccess =>
      type == PremiumAccessType.premium || type == PremiumAccessType.trial;
}

/// Premium feature enum for tracking interest
enum PremiumFeature {
  aiCoaching('ai_coaching', 'AI Coaching', 'Get personalized AI coaching conversations'),
  aiMemory('ai_memory', 'AI Memory', 'AI learns your patterns and gives smarter advice over time'),
  progressPhotos('progress_photos', 'Progress Photos', 'Upload photos for AI body analysis and celeb comparisons'),
  cyclePredictions('cycle_predictions', 'Cycle Predictions', 'AI-powered period cycle predictions and training adjustments'),
  advancedAnalytics('advanced_analytics', 'Advanced Analytics', 'Detailed trends and insights'),
  mealScanner('meal_scanner', 'Meal Scanner', 'Scan meals for instant nutrition info'),
  customWorkouts('custom_workouts', 'Custom Workouts', 'Build your own workout routines'),
  exportData('export_data', 'Export Data', 'Export your progress data');

  final String id;
  final String name;
  final String description;

  const PremiumFeature(this.id, this.name, this.description);
}

/// Service for managing premium access, trial, and waitlist
class PremiumService {
  final _firestore = FirebaseFirestore.instance;

  static const _prefsWaitlistKey = 'premium_waitlist_joined';
  static const _prefsEmailKey = 'premium_waitlist_email';
  static const _prefsFeaturesKey = 'premium_interested_features';

  static const int trialDurationDays = 7;

  // ===== PREMIUM ACCESS =====

  /// Get the premium access status for a user profile
  PremiumAccessStatus getAccessStatus(UserProfile? profile) {
    if (profile == null) return PremiumAccessStatus.none;
    if (profile.isPremium) return PremiumAccessStatus.premium;

    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return PremiumAccessStatus.none;

    final elapsed = DateTime.now().difference(trialStart).inDays;
    final remaining = trialDurationDays - elapsed;

    if (remaining > 0) return PremiumAccessStatus.trial(remaining);
    return PremiumAccessStatus.expired;
  }

  /// Get trial days remaining (null if no trial, 0 if expired)
  int? getTrialDaysRemaining(UserProfile profile) {
    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return null;
    final remaining = trialDurationDays - DateTime.now().difference(trialStart).inDays;
    return remaining.clamp(0, trialDurationDays);
  }

  /// Check if trial has expired
  bool isTrialExpired(UserProfile profile) {
    if (profile.isPremium) return false;
    final trialStart = profile.premiumTrialStart;
    if (trialStart == null) return false;
    return DateTime.now().difference(trialStart).inDays >= trialDurationDays;
  }

  // ===== WAITLIST (existing) =====

  /// Check if user has already joined the waitlist
  Future<bool> hasJoinedWaitlist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsWaitlistKey) ?? false;
  }

  /// Get the email used to join waitlist
  Future<String?> getWaitlistEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsEmailKey);
  }

  /// Join the premium waitlist with email
  Future<void> joinWaitlist({
    required String email,
    List<PremiumFeature>? interestedFeatures,
  }) async {
    final timestamp = FieldValue.serverTimestamp();
    final features = interestedFeatures?.map((f) => f.id).toList() ?? [];

    // Store in Firestore
    await _firestore.collection('premium_waitlist').add({
      'email': email,
      'interested_features': features,
      'joined_at': timestamp,
      'platform': 'mobile',
      'source': 'in_app',
    });

    // Store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsWaitlistKey, true);
    await prefs.setString(_prefsEmailKey, email);
    await prefs.setStringList(_prefsFeaturesKey, features);
  }

  /// Track interest in a specific premium feature (without email)
  Future<void> trackFeatureInterest(PremiumFeature feature) async {
    await _firestore.collection('premium_feature_interest').add({
      'feature': feature.id,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get locally stored interested features
  Future<List<String>> getInterestedFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsFeaturesKey) ?? [];
  }

  /// Update waitlist with additional feature interest
  Future<void> updateFeatureInterest(List<PremiumFeature> features) async {
    final email = await getWaitlistEmail();
    if (email == null) return;

    final featureIds = features.map((f) => f.id).toList();

    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsFeaturesKey, featureIds);

    // Find and update Firestore document
    final query = await _firestore
        .collection('premium_waitlist')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'interested_features': featureIds,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }
}
