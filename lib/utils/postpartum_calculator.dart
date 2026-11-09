import '../models/user_profile.dart';

/// Legacy stored vocabulary only; calendar dates no longer classify recovery.
enum PostPartumPhase {
  none,           // Not post-partum
  earlyRecovery,  // 0-12 weeks
  rebuilding,     // 12-24 weeks (3-6 months)
  strengthening,  // 24-78 weeks (6-18 months)
}

/// Legacy compatibility helpers; no clinical safety or timing assertions.
class PostPartumCalculator {
  /// Calculate weeks since delivery
  static int? getWeeksPostPartum(UserProfile profile) {
    if (profile.postPartumStatus == 'no' || profile.deliveryDate == null) {
      return null;
    }

    final now = DateTime.now();
    final delivery = profile.deliveryDate!;
    return delivery.isAfter(now) ? null : now.difference(delivery).inDays ~/ 7;
  }

  /// Calendar dates do not establish a recovery phase.
  static PostPartumPhase getPhase(UserProfile profile) => PostPartumPhase.none;

  /// Get phase name for display
  static String getPhaseName(PostPartumPhase phase) => 'Recovery timing is individual';

  /// Get phase emoji
  static String getPhaseEmoji(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return '💜'; // Heart for gentle care
      case PostPartumPhase.rebuilding:
        return '🌱'; // Growth
      case PostPartumPhase.strengthening:
        return '💪'; // Strength
      default:
        return '';
    }
  }

  /// Get short guidance for home screen
  static String getShortGuidance(PostPartumPhase phase) => 'Tailored postpartum plans are unavailable pending clinical review. Follow your clinician’s individual guidance.';

  /// Get detailed guidance
  static String getDetailedGuidance(PostPartumPhase phase) => getShortGuidance(phase);

  /// No exercise can be certified safe by this retired heuristic.
  static bool isExerciseSafe(UserProfile profile, String exerciseType) => false;

  /// Get intensity multiplier for post-partum
  static double getIntensityMultiplier(PostPartumPhase phase) => 1.0;

  /// Get red flag warnings
  static List<String> getRedFlags() => const []; // No unreviewed clinical classifier.

  /// Get exercise substitutions for post-partum
  static Map<String, String> getSafeSubstitutions() => const {};

  /// Check if core work needs diastasis assessment
  static bool needsDiastasisCheck(UserProfile profile, String exercise) => profile.postPartumStatus != 'no';

  /// Get color for phase (for UI)
  static String getPhaseColorHex(PostPartumPhase phase) {
    switch (phase) {
      case PostPartumPhase.earlyRecovery:
        return '#E1BEE7'; // Light purple
      case PostPartumPhase.rebuilding:
        return '#A5D6A7'; // Light green
      case PostPartumPhase.strengthening:
        return '#90CAF9'; // Light blue
      default:
        return '#E0E0E0'; // Gray
    }
  }

  /// Clearance cannot be inferred from a delivery date.
  static DateTime? getExpectedClearanceDate(UserProfile profile) => null;

  /// Product eligibility only; postpartum generation is disabled.
  static bool isReadyToStart(UserProfile profile) => profile.postPartumStatus == 'no';
}
