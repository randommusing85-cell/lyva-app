import '../models/checkin.dart';
import '../models/prime_plan.dart';
import '../models/user_profile.dart';

// Reuse existing TDEE functions from trends_screen.dart
// (top-level functions, importable directly)
import '../screens/trends_screen.dart' show calculateBMR, calculateTDEE;

// =============================================================================
// PLATEAU STATUS
// =============================================================================

/// Result of plateau analysis
class PlateauStatus {
  /// Whether a weight plateau has been detected
  final bool isPlateaued;

  /// Absolute weight change over the analysis window (kg)
  final double weightChangeKg;

  /// Most recent 7-day average weight
  final double week1Avg;

  /// Previous 7-day average weight (days 8-14)
  final double week2Avg;

  /// Earliest 7-day average weight (days 15-21), or 0 if insufficient data
  final double week3Avg;

  /// Days the user has been in the current plan phase
  final int daysInCurrentPhase;

  /// Current diet phase from the active plan
  final String currentPhase;

  /// Days remaining in refeed (null if not in refeed)
  final int? daysRemainingInRefeed;

  /// Human-readable explanation of the analysis
  final String summary;

  const PlateauStatus({
    required this.isPlateaued,
    required this.weightChangeKg,
    required this.week1Avg,
    required this.week2Avg,
    this.week3Avg = 0,
    required this.daysInCurrentPhase,
    required this.currentPhase,
    this.daysRemainingInRefeed,
    required this.summary,
  });
}

// =============================================================================
// PLATEAU DETECTOR
// =============================================================================

/// Detects weight plateaus and manages refeed/diet break logic.
/// Pure-Dart utility with static methods (follows CycleCalculator pattern).
class PlateauDetector {
  PlateauDetector._(); // Prevent instantiation

  /// Minimum check-ins required for reliable plateau detection
  static const int minCheckInsRequired = 14;

  /// Weight change threshold (kg) below which we consider it a "stall"
  static const double stallThresholdKg = 0.5;

  /// Waist change threshold (cm) — if waist dropped more than this,
  /// the user may be recomping (losing fat, gaining muscle), not plateaued
  static const double waistRecompThresholdCm = 1.0;

  /// Minimum days in deficit before plateau detection activates
  static const int minDaysInDeficit = 21;

  /// Default refeed duration in days
  static const int refeedDurationDays = 14;

  // ===========================================================================
  // ANALYSIS
  // ===========================================================================

  /// Analyze check-in data and determine plateau status.
  ///
  /// [checkIns] must be sorted most-recent-first (descending by ts).
  /// [currentPlan] is the active nutrition plan.
  static PlateauStatus analyze({
    required List<CheckIn> checkIns,
    required PrimePlan currentPlan,
  }) {
    final phase = currentPlan.phase;
    final phaseStart = currentPlan.phaseStartedAt ?? currentPlan.createdAt;
    final daysInPhase = DateTime.now().difference(phaseStart).inDays;

    // If in refeed phase, report refeed status instead of plateau
    if (phase == 'refeed') {
      final remaining = daysRemainingInRefeed(currentPlan);
      return PlateauStatus(
        isPlateaued: false,
        weightChangeKg: 0,
        week1Avg: _weekAvg(checkIns, 0, 7),
        week2Avg: _weekAvg(checkIns, 7, 14),
        daysInCurrentPhase: daysInPhase,
        currentPhase: phase,
        daysRemainingInRefeed: remaining,
        summary: remaining > 0
            ? 'Refeed break in progress — $remaining days remaining.'
            : 'Refeed break complete! Ready to resume deficit.',
      );
    }

    // Need sufficient data for analysis
    if (checkIns.length < minCheckInsRequired) {
      return PlateauStatus(
        isPlateaued: false,
        weightChangeKg: 0,
        week1Avg: 0,
        week2Avg: 0,
        daysInCurrentPhase: daysInPhase,
        currentPhase: phase,
        summary: 'Not enough check-in data yet (${checkIns.length}/$minCheckInsRequired).',
      );
    }

    // Must be in deficit for at least 3 weeks before detecting plateau
    if (phase == 'deficit' && daysInPhase < minDaysInDeficit) {
      return PlateauStatus(
        isPlateaued: false,
        weightChangeKg: 0,
        week1Avg: _weekAvg(checkIns, 0, 7),
        week2Avg: _weekAvg(checkIns, 7, 14),
        daysInCurrentPhase: daysInPhase,
        currentPhase: phase,
        summary: 'Too early to assess — ${minDaysInDeficit - daysInPhase} more days in deficit needed.',
      );
    }

    // Calculate rolling 7-day averages for 3 weeks
    final week1 = _weekAvg(checkIns, 0, 7);   // Most recent week
    final week2 = _weekAvg(checkIns, 7, 14);  // Previous week
    final week3 = checkIns.length >= 21
        ? _weekAvg(checkIns, 14, 21)
        : week2; // Fall back to week2 if not enough data for week3

    final totalChange = (week3 - week1).abs();

    // Check if weight is actually stalled
    final weightStalled = totalChange < stallThresholdKg;

    // Guard against false positives: if waist is dropping significantly,
    // the user may be recomping (losing fat, gaining muscle)
    bool waistDropping = false;
    if (checkIns.length >= 14) {
      final waist1 = _weekAvgWaist(checkIns, 0, 7);
      final waist3 = checkIns.length >= 21
          ? _weekAvgWaist(checkIns, 14, 21)
          : _weekAvgWaist(checkIns, 7, 14);
      if (waist1 > 0 && waist3 > 0) {
        waistDropping = (waist3 - waist1) > waistRecompThresholdCm;
      }
    }

    final isPlateaued = weightStalled && !waistDropping;

    String summary;
    if (isPlateaued) {
      summary = 'Weight has stalled (${totalChange.toStringAsFixed(1)}kg change over 3 weeks). '
          'A maintenance break may help reset your metabolism.';
    } else if (waistDropping) {
      summary = 'Weight is stable but waist is shrinking — you may be recomping. Keep going!';
    } else {
      summary = 'On track — weight is changing as expected.';
    }

    return PlateauStatus(
      isPlateaued: isPlateaued,
      weightChangeKg: totalChange,
      week1Avg: week1,
      week2Avg: week2,
      week3Avg: week3,
      daysInCurrentPhase: daysInPhase,
      currentPhase: phase,
      summary: summary,
    );
  }

  // ===========================================================================
  // MAINTENANCE CALORIE CALCULATION
  // ===========================================================================

  /// Calculate maintenance (TDEE) calories based on the user's current stats.
  /// Used when transitioning from deficit to refeed.
  static int calculateMaintenanceCalories({
    required UserProfile profile,
    required int trainingDaysPerWeek,
  }) {
    final bmr = calculateBMR(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      sex: profile.sex,
    );
    return calculateTDEE(bmr: bmr, trainingDaysPerWeek: trainingDaysPerWeek).round();
  }

  // ===========================================================================
  // REFEED PHASE HELPERS
  // ===========================================================================

  /// Calculate how many days remain in the refeed phase.
  /// Returns 0 if refeed is complete or plan is not in refeed phase.
  static int daysRemainingInRefeed(PrimePlan plan) {
    if (plan.phase != 'refeed') return 0;
    final start = plan.phaseStartedAt ?? plan.createdAt;
    final elapsed = DateTime.now().difference(start).inDays;
    return (refeedDurationDays - elapsed).clamp(0, refeedDurationDays);
  }

  /// Check if the refeed period has completed.
  static bool isRefeedComplete(PrimePlan plan) {
    if (plan.phase != 'refeed') return false;
    return daysRemainingInRefeed(plan) <= 0;
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Compute average weight for a slice of check-ins.
  /// [start] and [end] are indices (0 = most recent).
  static double _weekAvg(List<CheckIn> checkIns, int start, int end) {
    final slice = checkIns.skip(start).take(end - start).toList();
    if (slice.isEmpty) return 0;
    final sum = slice.fold<double>(0, (s, c) => s + c.weightKg);
    return sum / slice.length;
  }

  /// Compute average waist measurement for a slice of check-ins.
  static double _weekAvgWaist(List<CheckIn> checkIns, int start, int end) {
    final slice = checkIns
        .skip(start)
        .take(end - start)
        .where((c) => c.waistCm > 0)
        .toList();
    if (slice.isEmpty) return 0;
    final sum = slice.fold<double>(0, (s, c) => s + c.waistCm);
    return sum / slice.length;
  }
}
