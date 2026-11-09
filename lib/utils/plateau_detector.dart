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
  final double? weightChangeKg;

  /// Most recent 7-day average weight
  final double? week1Avg;

  /// Previous 7-day average weight (days 8-14)
  final double? week2Avg;

  /// Earliest 7-day average weight (days 15-21), or null if insufficient data
  final double? week3Avg;

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
    this.week3Avg,
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

  /// Uses local calendar days, one latest valid observation per day, and only
  /// observations from the current phase. Input order does not matter.
  static PlateauStatus analyze({
    required List<CheckIn> checkIns,
    required PrimePlan currentPlan,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final phase = currentPlan.phase;
    final phaseStart = currentPlan.phaseStartedAt ?? currentPlan.createdAt;
    final daysInPhase = (_day(clock) - _day(phaseStart)).clamp(0, 1000000);
    final daily = <int, CheckIn>{};
    for (final entry in checkIns) {
      final age = _day(clock) - _day(entry.ts);
      if (entry.ts.isAfter(clock) ||
          entry.ts.isBefore(phaseStart) ||
          age < 0 ||
          age >= 21 ||
          entry.weightKg == null ||
          !entry.weightKg!.isFinite ||
          entry.weightKg! <= 0) {
        continue;
      }
      final previous = daily[age];
      if (previous == null ||
          entry.ts.isAfter(previous.ts) ||
          (entry.ts == previous.ts && entry.id > previous.id)) {
        daily[age] = entry;
      }
    }
    final weeks = List.generate(
      3,
      (week) => daily.entries
          .where((e) => e.key >= week * 7 && e.key < (week + 1) * 7)
          .map((e) => e.value)
          .toList(),
    );
    final averages = weeks.map(_averageWeight).toList();
    PlateauStatus result(
      String summary, {
      bool stalled = false,
      double? change,
      int? remaining,
    }) => PlateauStatus(
      isPlateaued: stalled,
      weightChangeKg: change,
      week1Avg: averages[0],
      week2Avg: averages[1],
      week3Avg: averages[2],
      daysInCurrentPhase: daysInPhase,
      currentPhase: phase,
      daysRemainingInRefeed: remaining,
      summary: summary,
    );

    if (phase == 'refeed') {
      final remaining = daysRemainingInRefeed(currentPlan, now: clock);
      return result(
        remaining > 0
            ? 'Refeed break in progress - $remaining days remaining.'
            : 'Refeed break complete! Ready to resume deficit.',
        remaining: remaining,
      );
    }
    if (phase != 'deficit' && phase != 'resumed_deficit') {
      return result(
        'Plateau assessment is only available during a deficit phase.',
      );
    }
    if (phaseStart.isAfter(clock) || daysInPhase < minDaysInDeficit) {
      return result(
        'Too early to assess - ${minDaysInDeficit - daysInPhase} more days in deficit needed.',
      );
    }
    // Preserve the existing 14-observation minimum, counting distinct valid days.
    // Every calendar week must be represented; never substitute another week.
    if (daily.length < minCheckInsRequired ||
        weeks.any((week) => week.isEmpty)) {
      return result(
        'Not enough dated check-in data: ${daily.length}/$minCheckInsRequired days across the last 3 weeks.',
      );
    }
    final totalChange = (averages[2]! - averages[0]!).abs();
    final waist1 = _averageWaist(weeks[0]);
    final waist3 = _averageWaist(weeks[2]);
    final waistDropping =
        waist1 != null && waist3 != null && (waist3 - waist1) > waistRecompThresholdCm;
    final stalled = totalChange < stallThresholdKg && !waistDropping;
    return result(
      stalled
          ? 'Recorded weight averages changed by ${totalChange.toStringAsFixed(1)}kg across the last 3 calendar weeks.'
          : waistDropping
          ? 'Weight is stable while recorded waist measurements decreased.'
          : 'Recorded weight averages changed across the observation window.',
      stalled: stalled,
      change: totalChange,
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
    return calculateTDEE(
      bmr: bmr,
      trainingDaysPerWeek: trainingDaysPerWeek,
    ).round();
  }

  // ===========================================================================
  // REFEED PHASE HELPERS
  // ===========================================================================

  /// Calculate how many days remain in the refeed phase.
  /// Returns 0 if refeed is complete or plan is not in refeed phase.
  static int daysRemainingInRefeed(PrimePlan plan, {DateTime? now}) {
    if (plan.phase != 'refeed') return 0;
    final start = plan.phaseStartedAt ?? plan.createdAt;
    final elapsed = _day(now ?? DateTime.now()) - _day(start);
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

  // UTC midnight is used only as a date ordinal, avoiding DST duration errors.
  static int _day(DateTime value) {
    final local = value.toLocal();
    return DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static double? _averageWeight(List<CheckIn> entries) => entries.isEmpty
      ? null
      : entries.fold<double>(0, (sum, c) => sum + c.weightKg!) / entries.length;

  static double? _averageWaist(List<CheckIn> entries) {
    final valid = entries
        .where((c) => c.waistCm != null && c.waistCm!.isFinite && c.waistCm! > 0)
        .toList();
    return valid.isEmpty
        ? null
        : valid.fold<double>(0, (sum, c) => sum + c.waistCm!) / valid.length;
  }
}
