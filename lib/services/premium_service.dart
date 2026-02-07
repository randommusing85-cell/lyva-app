import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Service for managing premium waitlist and feature interest tracking
class PremiumService {
  final _firestore = FirebaseFirestore.instance;

  static const _prefsWaitlistKey = 'premium_waitlist_joined';
  static const _prefsEmailKey = 'premium_waitlist_email';
  static const _prefsFeaturesKey = 'premium_interested_features';

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
