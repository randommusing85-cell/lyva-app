import '../models/user_profile.dart';

/// Menstrual cycle phases
enum CyclePhase {
  menstrual, // Days 1-5 (period)
  follicular, // Legacy calendar bucket, not a measured phase
  ovulation, // Legacy calendar bucket, not confirmed ovulation
  luteal, // Legacy calendar bucket, not a symptom prediction
}

/// Calculate current cycle phase and provide training guidance
class CycleCalculator {
  /// Retired compatibility APIs. Calendar/profile defaults cannot establish
  /// physiological phases or a defensible period countdown. New tracker uses
  /// explicitly labeled logged-history presentation, not these legacy buckets.
  static CyclePhase? getCurrentPhase(UserProfile profile, {DateTime? at}) =>
      null;
  static int? getCurrentCycleDay(UserProfile profile, {DateTime? at}) => null;
  static int? getDaysUntilNextPeriod(UserProfile profile, {DateTime? at}) =>
      null;

  /// Get user-friendly phase name
  static String getPhaseName(CyclePhase phase) => 'Unverified calendar label';

  /// Get phase emoji
  static String getPhaseEmoji(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '🌙';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '⭐';
      case CyclePhase.luteal:
        return '🍂';
    }
  }

  /// Compatibility helpers: calendar phase must not prescribe effort.
  static String getTrainingGuidance(CyclePhase phase) =>
      'Use your recorded symptoms and preferences; calendar dates do not determine workout capacity.';
  static String getShortGuidance(CyclePhase phase) =>
      'Your recorded experience matters more than a calendar estimate.';
  static double getIntensityMultiplier(CyclePhase phase) => 1.0;

  /// Get color for phase (for UI)
  static String getPhaseColorHex(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '#FF6B9D'; // Pink
      case CyclePhase.follicular:
        return '#4CAF50'; // Green
      case CyclePhase.ovulation:
        return '#FFC107'; // Gold
      case CyclePhase.luteal:
        return '#FF9800'; // Orange
    }
  }
}
