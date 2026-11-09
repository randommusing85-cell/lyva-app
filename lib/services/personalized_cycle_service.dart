import 'dart:math' as math;

import '../models/checkin.dart';
import '../models/cycle_log.dart';
import '../models/user_profile.dart';
import '../models/workout_session_doc.dart';
import '../utils/cycle_calculator.dart';
import 'personalization_safety.dart';

enum ReadinessLevel { checkInNeeded, recover, lighten, steady, ready }

class PersonalizedCycleInsight {
  final DateTime generatedAt;
  final DateTime lastPeriodStart;
  final DateTime predictedPeriodDate;
  final DateTime periodWindowStart;
  final DateTime periodWindowEnd;
  final DateTime estimatedOvulationDate;
  final int predictedCycleLength;
  final int currentCycleDay;
  final int completedCycleCount;
  final int inferredMissedLogs;
  final double variabilityDays;
  final double confidence;
  final CyclePhase currentPhase;
  final double phaseConfidence;
  final bool isPersonalized;
  final ReadinessAssessment readiness;
  final AdaptiveCycleRecommendation recommendation;
  final List<String> predictionFactors;
  final String? personalizationBoundaryMessage;

  /// This local heuristic has not been clinically calibrated. Never use it for
  /// contraception, fertility decisions, hormone inference or exercise clearance.
  static const estimateNotice =
      'Calendar estimates are uncertain and are not clinical predictions.';

  const PersonalizedCycleInsight({
    required this.generatedAt,
    required this.lastPeriodStart,
    required this.predictedPeriodDate,
    required this.periodWindowStart,
    required this.periodWindowEnd,
    required this.estimatedOvulationDate,
    required this.predictedCycleLength,
    required this.currentCycleDay,
    required this.completedCycleCount,
    required this.inferredMissedLogs,
    required this.variabilityDays,
    required this.confidence,
    required this.currentPhase,
    required this.phaseConfidence,
    required this.isPersonalized,
    required this.readiness,
    required this.recommendation,
    required this.predictionFactors,
    this.personalizationBoundaryMessage,
  });

  String get confidenceLabel {
    if (confidence >= 0.75) return 'More recorded cycles';
    if (confidence >= 0.5) return 'Building a history';
    return 'Early estimate';
  }

  String get modelLabel =>
      isPersonalized ? 'Personal model' : 'Learning your pattern';

  int get daysUntilExpected =>
      _dateOnly(predictedPeriodDate).difference(_dateOnly(generatedAt)).inDays;

  int get daysUntilWindowStart =>
      _dateOnly(periodWindowStart).difference(_dateOnly(generatedAt)).inDays;

  bool get windowHasPassed => generatedAt.isAfter(
    DateTime(
      periodWindowEnd.year,
      periodWindowEnd.month,
      periodWindowEnd.day,
      23,
      59,
      59,
    ),
  );

  String get phaseName {
    switch (currentPhase) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Estimated ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  String get phaseGuidance {
    if (personalizationBoundaryMessage != null) {
      return personalizationBoundaryMessage!;
    }
    if (!readiness.hasRecentCheckIn) {
      return 'Your phase is estimated. Check in so Lyva can respond to how you actually feel today.';
    }
    switch (readiness.level) {
      case ReadinessLevel.recover:
        return 'Your current signals suggest recovery may be more useful than pushing intensity today.';
      case ReadinessLevel.lighten:
        return 'Your current signals are below your usual baseline. A small adjustment may help.';
      case ReadinessLevel.ready:
        return 'Your current signals are above your usual baseline. Progress only if your warm-up agrees.';
      case ReadinessLevel.steady:
        return 'Your current signals are close to your baseline. Your planned session should be appropriate.';
      case ReadinessLevel.checkInNeeded:
        return 'Use the phase as context, not a rule. Your check-in determines the daily recommendation.';
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class ReadinessAssessment {
  final int? score;
  final int? baselineScore;
  final int? prePeriodPatternDelta;
  final int? energyScore;
  final int? sleepScore;
  final int? stressScore;
  final int? sorenessScore;
  final int? hungerScore;
  final int? symptomSeverity;
  final int? recentWorkoutExertion;
  final int observationsUsed;
  final bool hasRecentCheckIn;
  final ReadinessLevel level;

  const ReadinessAssessment({
    required this.score,
    required this.baselineScore,
    required this.prePeriodPatternDelta,
    required this.energyScore,
    required this.sleepScore,
    required this.stressScore,
    required this.sorenessScore,
    required this.hungerScore,
    required this.symptomSeverity,
    required this.recentWorkoutExertion,
    required this.observationsUsed,
    required this.hasRecentCheckIn,
    required this.level,
  });

  String get label {
    switch (level) {
      case ReadinessLevel.checkInNeeded:
        return 'Check-in needed';
      case ReadinessLevel.recover:
        return 'Recovery recommended';
      case ReadinessLevel.lighten:
        return 'Consider a lighter day';
      case ReadinessLevel.steady:
        return 'Near your baseline';
      case ReadinessLevel.ready:
        return 'Above your baseline';
    }
  }
}

class AdaptiveCycleRecommendation {
  final String workoutTitle;
  final String workoutBody;
  final int workoutVolumeAdjustmentPercent;
  final String nutritionTitle;
  final String nutritionBody;
  final String notificationTitle;
  final String notificationBody;
  final List<String> reasons;

  const AdaptiveCycleRecommendation({
    required this.workoutTitle,
    required this.workoutBody,
    required this.workoutVolumeAdjustmentPercent,
    required this.nutritionTitle,
    required this.nutritionBody,
    required this.notificationTitle,
    required this.notificationBody,
    required this.reasons,
  });
}

class PersonalizedCycleService {
  static const modelVersion = 'local_bayesian_v1';

  PersonalizedCycleInsight? buildInsight({
    required UserProfile profile,
    required List<CycleLog> cycleLogs,
    required List<CheckIn> checkIns,
    required List<WorkoutSessionDoc> workouts,
    DateTime? now,
  }) {
    if (!profile.trackCycle || profile.lastPeriodDate == null) return null;

    final generatedAt = now ?? DateTime.now();
    final starts = _periodStarts(
      cycleLogs,
      profile.lastPeriodDate!,
      generatedAt,
    );
    if (starts.isEmpty) return null;

    final priorMean = profile.cycleLength.clamp(21, 45).toDouble();
    final intervalResult = _cycleIntervals(starts, priorMean);
    final estimate = _estimateCycleLength(
      intervalResult.samples,
      priorMean,
      postpartum: profile.postPartumStatus != 'no',
    );

    final lastStart = starts.last;
    final predictedLength = estimate.mean.round().clamp(18, 60).toInt();
    final predictedDate = lastStart.add(Duration(days: predictedLength));
    final missingPenalty = intervalResult.inferredMissedLogs > 0 ? 1.0 : 0.0;
    final halfWindow = math
        .max(2, (estimate.standardDeviation * 1.28 + missingPenalty).ceil())
        .clamp(2, 12)
        .toInt();
    final windowStart = predictedDate.subtract(Duration(days: halfWindow));
    final windowEnd = predictedDate.add(Duration(days: halfWindow));
    final estimatedOvulation = predictedDate.subtract(const Duration(days: 14));
    final currentDay = math.max(
      1,
      _dateOnly(generatedAt).difference(lastStart).inDays + 1,
    );
    final currentPhase = _phaseForDate(
      generatedAt,
      lastStart: lastStart,
      periodDuration: profile.periodDuration,
      estimatedOvulation: estimatedOvulation,
    );

    final readiness = _buildReadiness(
      now: generatedAt,
      checkIns: checkIns,
      cycleLogs: cycleLogs,
      workouts: workouts,
      periodStarts: starts,
      predictedDate: predictedDate,
    );
    final boundary = PersonalizationDecision.evaluate(profile);
    final recommendation = boundary.allowed
        ? _buildRecommendation(
            readiness,
            daysUntilExpected: _dateOnly(
              predictedDate,
            ).difference(_dateOnly(generatedAt)).inDays,
          )
        : AdaptiveCycleRecommendation(
            workoutTitle: 'Personalized guidance unavailable',
            workoutBody: boundary.message,
            workoutVolumeAdjustmentPercent: 0,
            nutritionTitle: 'Tracking remains available',
            nutritionBody: boundary.message,
            notificationTitle: 'Tracking remains available',
            notificationBody: boundary.message,
            reasons: [boundary.message],
          );
    final completedCycles = intervalResult.observedIntervalCount;
    final confidence = _confidence(
      completedCycles: completedCycles,
      standardDeviation: estimate.standardDeviation,
      inferredMissedLogs: intervalResult.inferredMissedLogs,
      postpartum: profile.postPartumStatus != 'no',
    );

    final factors = <String>[
      if (completedCycles == 0)
        'Starting from your ${profile.cycleLength}-day baseline'
      else
        '$completedCycles completed ${completedCycles == 1 ? 'cycle' : 'cycles'} used',
      'Typical variation is about ${estimate.standardDeviation.toStringAsFixed(1)} days',
      if (intervalResult.inferredMissedLogs > 0)
        '${intervalResult.inferredMissedLogs} possible missed ${intervalResult.inferredMissedLogs == 1 ? 'log was' : 'logs were'} handled',
      if (profile.postPartumStatus != 'no')
        'Postpartum cycles can be less predictable',
    ];

    return PersonalizedCycleInsight(
      generatedAt: generatedAt,
      lastPeriodStart: lastStart,
      predictedPeriodDate: predictedDate,
      periodWindowStart: windowStart,
      periodWindowEnd: windowEnd,
      estimatedOvulationDate: estimatedOvulation,
      predictedCycleLength: predictedLength,
      currentCycleDay: currentDay,
      completedCycleCount: completedCycles,
      inferredMissedLogs: intervalResult.inferredMissedLogs,
      variabilityDays: estimate.standardDeviation,
      confidence: confidence,
      currentPhase: currentPhase,
      phaseConfidence: (confidence * 0.75).clamp(0.15, 0.75).toDouble(),
      isPersonalized: completedCycles >= 2,
      readiness: readiness,
      recommendation: recommendation,
      predictionFactors: factors,
      personalizationBoundaryMessage: boundary.allowed
          ? null
          : boundary.message,
    );
  }

  List<DateTime> _periodStarts(
    List<CycleLog> logs,
    DateTime profileStart,
    DateTime now,
  ) {
    final candidates = <DateTime>[
      _dateOnly(profileStart),
      ...logs
          .where((log) => log.eventType == 'period_start')
          .map((log) => _dateOnly(log.ts)),
    ]..sort();

    final starts = <DateTime>[];
    for (final date in candidates) {
      if (date.isAfter(_dateOnly(now))) continue;
      if (starts.isEmpty) {
        starts.add(date);
        continue;
      }
      final gap = date.difference(starts.last).inDays;
      if (gap == 0) continue;
      if (gap < 14) continue;
      starts.add(date);
    }
    return starts;
  }

  _IntervalResult _cycleIntervals(
    List<DateTime> starts,
    double referenceLength,
  ) {
    final samples = <_WeightedSample>[];
    var observed = 0;
    var inferredMissed = 0;

    for (var i = 1; i < starts.length; i++) {
      final gap = starts[i].difference(starts[i - 1]).inDays;
      if (gap < 18 || gap > 180) continue;

      observed++;
      if (gap <= 45) {
        samples.add(_WeightedSample(gap.toDouble(), 1.0 + i * 0.08));
        continue;
      }

      var bestParts = 1;
      var bestUnit = gap.toDouble();
      var bestDistance = (gap - referenceLength).abs();
      final maxParts = math.min(6, gap ~/ 18);
      for (var parts = 2; parts <= maxParts; parts++) {
        final unit = gap / parts;
        if (unit < 18 || unit > 45) continue;
        final distance = (unit - referenceLength).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestParts = parts;
          bestUnit = unit;
        }
      }

      if (bestParts > 1 && bestDistance <= 6) {
        samples.add(_WeightedSample(bestUnit, 0.45 + i * 0.04));
        inferredMissed += bestParts - 1;
      } else if (gap <= 60) {
        samples.add(_WeightedSample(gap.toDouble(), 0.35));
      }
    }

    return _IntervalResult(
      samples: samples,
      observedIntervalCount: observed,
      inferredMissedLogs: inferredMissed,
    );
  }

  _CycleEstimate _estimateCycleLength(
    List<_WeightedSample> samples,
    double priorMean, {
    required bool postpartum,
  }) {
    final priorWeight = samples.isEmpty ? 4.0 : 2.0;
    final priorVariance = postpartum ? 36.0 : 16.0;
    var weightedTotal = priorMean * priorWeight;
    var weightTotal = priorWeight;

    for (final sample in samples) {
      final distance = (sample.value - priorMean).abs();
      final robustWeight =
          sample.weight * (distance <= 10 ? 1.0 : 10 / distance);
      weightedTotal += sample.value * robustWeight;
      weightTotal += robustWeight;
    }
    final mean = (weightedTotal / weightTotal).clamp(18.0, 60.0).toDouble();

    var varianceTotal =
        priorWeight * (priorVariance + math.pow(priorMean - mean, 2));
    var varianceWeight = priorWeight;
    for (final sample in samples) {
      varianceTotal += sample.weight * math.pow(sample.value - mean, 2);
      varianceWeight += sample.weight;
    }
    final standardDeviation = math
        .sqrt(varianceTotal / varianceWeight)
        .clamp(1.5, 10.0)
        .toDouble();

    return _CycleEstimate(mean: mean, standardDeviation: standardDeviation);
  }

  double _confidence({
    required int completedCycles,
    required double standardDeviation,
    required int inferredMissedLogs,
    required bool postpartum,
  }) {
    var confidence = 0.28;
    confidence += math.min(completedCycles, 8) * 0.065;
    confidence += ((8 - standardDeviation).clamp(0, 6) / 6) * 0.15;
    confidence -= math.min(inferredMissedLogs, 3) * 0.04;
    if (postpartum) confidence = math.min(confidence, 0.48);
    return confidence.clamp(0.2, 0.9).toDouble();
  }

  CyclePhase _phaseForDate(
    DateTime date, {
    required DateTime lastStart,
    required int periodDuration,
    required DateTime estimatedOvulation,
  }) {
    final day = _dateOnly(date).difference(lastStart).inDays + 1;
    if (day <= math.max(1, periodDuration)) return CyclePhase.menstrual;

    final ovulationDistance = _dateOnly(
      date,
    ).difference(_dateOnly(estimatedOvulation)).inDays;
    if (ovulationDistance < -1) return CyclePhase.follicular;
    if (ovulationDistance <= 1) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  ReadinessAssessment _buildReadiness({
    required DateTime now,
    required List<CheckIn> checkIns,
    required List<CycleLog> cycleLogs,
    required List<WorkoutSessionDoc> workouts,
    required List<DateTime> periodStarts,
    required DateTime predictedDate,
  }) {
    final sortedCheckIns = checkIns.where((c) => !c.ts.isAfter(now)).toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    final latest = sortedCheckIns
        .where(
          (checkIn) =>
              !checkIn.ts.isAfter(now) &&
              now.difference(checkIn.ts) <= const Duration(hours: 36),
        )
        .firstOrNull;
    final latestBaseScore = latest == null ? null : _checkInReadiness(latest);

    final baselineScores = sortedCheckIns
        .map(_checkInReadiness)
        .whereType<double>()
        .toList();
    final baseline = baselineScores.length >= 3
        ? baselineScores.reduce((a, b) => a + b) / baselineScores.length
        : null;

    final prePeriodScores = <double>[];
    for (final checkIn in sortedCheckIns) {
      final score = _checkInReadiness(checkIn);
      if (score == null) continue;
      final checkInDate = _dateOnly(checkIn.ts);
      final nextStart = periodStarts
          .where((start) => start.isAfter(checkInDate))
          .firstOrNull;
      if (nextStart == null) continue;
      final daysBefore = nextStart.difference(checkInDate).inDays;
      if (daysBefore >= 1 && daysBefore <= 5) prePeriodScores.add(score);
    }

    int? patternDelta;
    if (baseline != null && prePeriodScores.length >= 3) {
      final prePeriod =
          prePeriodScores.reduce((a, b) => a + b) / prePeriodScores.length;
      patternDelta = (prePeriod - baseline).round();
    }

    final today = _dateOnly(now);
    final symptomSeverity = cycleLogs
        .where(
          (log) =>
              log.eventType == 'symptom' &&
              _dateOnly(log.ts) == today &&
              log.severity != null,
        )
        .map((log) => log.severity!)
        .fold<int?>(null, (maxValue, value) {
          if (maxValue == null || value > maxValue) return value;
          return maxValue;
        });

    final recentWorkout = [...workouts]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentExertion = recentWorkout
        .where(
          (workout) =>
              workout.completed &&
              workout.perceivedExertion != null &&
              !workout.date.isAfter(now) &&
              now.difference(workout.date) <= const Duration(hours: 48),
        )
        .map((workout) => workout.perceivedExertion)
        .firstOrNull;

    double? adjustedScore = latestBaseScore;
    if (adjustedScore != null && symptomSeverity != null) {
      adjustedScore -= symptomSeverity * 2.5;
    }
    if (adjustedScore != null &&
        recentExertion != null &&
        recentExertion >= 4) {
      adjustedScore -= 4;
    }
    adjustedScore = adjustedScore?.clamp(0, 100).toDouble();

    final daysUntilExpected = _dateOnly(
      predictedDate,
    ).difference(_dateOnly(now)).inDays;
    final hasPatternDip =
        patternDelta != null && patternDelta <= -8 && daysUntilExpected <= 5;

    final ReadinessLevel level;
    if (adjustedScore == null && symptomSeverity == null) {
      level = ReadinessLevel.checkInNeeded;
    } else if ((symptomSeverity ?? 0) >= 4 ||
        (adjustedScore != null && adjustedScore < 42)) {
      level = ReadinessLevel.recover;
    } else if ((adjustedScore != null && adjustedScore < 58) || hasPatternDip) {
      level = ReadinessLevel.lighten;
    } else if (adjustedScore != null && adjustedScore >= 78) {
      level = ReadinessLevel.ready;
    } else {
      level = ReadinessLevel.steady;
    }

    return ReadinessAssessment(
      score: adjustedScore?.round(),
      baselineScore: baseline?.round(),
      prePeriodPatternDelta: patternDelta,
      energyScore: latest?.energyScore,
      sleepScore: latest?.sleepScore,
      stressScore: latest?.stressScore,
      sorenessScore: latest?.sorenessScore,
      hungerScore: latest?.hungerScore,
      symptomSeverity: symptomSeverity,
      recentWorkoutExertion: recentExertion,
      observationsUsed: baselineScores.length,
      hasRecentCheckIn: latest != null,
      level: level,
    );
  }

  double? _checkInReadiness(CheckIn checkIn) {
    final values = <double>[
      if (checkIn.energyScore != null) checkIn.energyScore! * 20.0,
      if (checkIn.moodScore != null) checkIn.moodScore! * 20.0,
      if (checkIn.sleepScore != null) checkIn.sleepScore! * 20.0,
      if (checkIn.stressScore != null) (6 - checkIn.stressScore!) * 20.0,
      if (checkIn.sorenessScore != null) (6 - checkIn.sorenessScore!) * 20.0,
    ];
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  AdaptiveCycleRecommendation _buildRecommendation(
    ReadinessAssessment readiness, {
    required int daysUntilExpected,
  }) {
    final reasons = <String>[];
    if (readiness.energyScore != null && readiness.energyScore! <= 2) {
      reasons.add('Energy is ${readiness.energyScore}/5 today');
    }
    if (readiness.sleepScore != null && readiness.sleepScore! <= 2) {
      reasons.add('Sleep quality is ${readiness.sleepScore}/5');
    }
    if (readiness.stressScore != null && readiness.stressScore! >= 4) {
      reasons.add('Stress is ${readiness.stressScore}/5');
    }
    if (readiness.sorenessScore != null && readiness.sorenessScore! >= 4) {
      reasons.add('Soreness is ${readiness.sorenessScore}/5');
    }
    if (readiness.symptomSeverity != null && readiness.symptomSeverity! >= 3) {
      reasons.add(
        'A cycle symptom was logged at ${readiness.symptomSeverity}/5',
      );
    }
    if (readiness.recentWorkoutExertion != null &&
        readiness.recentWorkoutExertion! >= 4) {
      reasons.add('Your recent workout felt demanding');
    }
    if (readiness.prePeriodPatternDelta != null &&
        readiness.prePeriodPatternDelta! <= -8 &&
        daysUntilExpected <= 5) {
      reasons.add('Your past check-ins tend to dip near your expected period');
    }
    if (reasons.isEmpty) {
      reasons.add(
        readiness.hasRecentCheckIn
            ? 'Your current signals are close to your personal baseline'
            : 'No recent recovery check-in is available',
      );
    }

    late final String workoutTitle;
    late final String workoutBody;
    late final int adjustment;
    switch (readiness.level) {
      case ReadinessLevel.recover:
        workoutTitle = 'Prioritize recovery';
        workoutBody =
            'Consider rest or a comfortable option rather than pushing through symptoms. Stop if pain or symptoms worsen; seek clinical advice when needed.';
        adjustment = 0;
        break;
      case ReadinessLevel.lighten:
        workoutTitle = 'Use a lighter option';
        workoutBody =
            'Consider a lighter option or rest based on how you feel. This check-in does not determine a safe training dose.';
        adjustment = 0;
        break;
      case ReadinessLevel.ready:
        workoutTitle = 'Review how you feel';
        workoutBody =
            'A higher check-in score does not establish exercise readiness or justify increasing intensity. Follow an appropriate existing plan and adjust to symptoms.';
        adjustment = 0;
        break;
      case ReadinessLevel.steady:
        workoutTitle = 'Stay with the plan';
        workoutBody =
            'Your recorded signals are near baseline. They do not establish exercise clearance; use how you feel and appropriate guidance.';
        adjustment = 0;
        break;
      case ReadinessLevel.checkInNeeded:
        workoutTitle = 'Check in before adjusting';
        workoutBody =
            'Log energy, sleep, stress and soreness so Lyva can suggest an appropriate session option.';
        adjustment = 0;
        break;
    }

    late final String nutritionTitle;
    late final String nutritionBody;
    if ((readiness.hungerScore ?? 0) >= 4) {
      nutritionTitle = 'Plan for higher hunger';
      nutritionBody =
          'Keep your daily target, but use a filling meal or snack with protein and fibre. Place some planned carbohydrates around training.';
    } else if (readiness.level == ReadinessLevel.recover ||
        readiness.level == ReadinessLevel.lighten) {
      nutritionTitle = 'Support recovery';
      nutritionBody =
          'Prioritize regular meals, hydration and carbohydrates around training. Avoid making today an aggressive restriction day.';
    } else if (!readiness.hasRecentCheckIn) {
      nutritionTitle = 'Keep your current nutrition plan';
      nutritionBody =
          'Add today\'s hunger and recovery signals before Lyva suggests a personalized change.';
    } else {
      nutritionTitle = 'Keep your current nutrition plan';
      nutritionBody =
          'There is no strong personal signal to change today. Keep protein, hydration and meal timing consistent.';
    }

    final notificationTitle = switch (readiness.level) {
      ReadinessLevel.recover => 'Recovery may serve you today',
      ReadinessLevel.lighten => 'A lighter option is ready',
      ReadinessLevel.ready => 'Your readiness is above baseline',
      ReadinessLevel.steady => 'Your plan fits today\'s signals',
      ReadinessLevel.checkInNeeded => 'Help Lyva personalize today',
    };
    final notificationBody = switch (readiness.level) {
      ReadinessLevel.recover =>
        'Lyva noticed lower recovery signals. Open your adaptive options.',
      ReadinessLevel.lighten =>
        'Your signals are below baseline. See a small workout adjustment.',
      ReadinessLevel.ready =>
        'Your signals look strong. Progress only if your warm-up agrees.',
      ReadinessLevel.steady =>
        'Your signals are near baseline. Your planned session looks suitable.',
      ReadinessLevel.checkInNeeded =>
        'Log sleep, energy, stress and soreness for a personal recommendation.',
    };

    return AdaptiveCycleRecommendation(
      workoutTitle: workoutTitle,
      workoutBody: workoutBody,
      workoutVolumeAdjustmentPercent: adjustment,
      nutritionTitle: nutritionTitle,
      nutritionBody: nutritionBody,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
      reasons: reasons,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _IntervalResult {
  final List<_WeightedSample> samples;
  final int observedIntervalCount;
  final int inferredMissedLogs;

  const _IntervalResult({
    required this.samples,
    required this.observedIntervalCount,
    required this.inferredMissedLogs,
  });
}

class _WeightedSample {
  final double value;
  final double weight;

  const _WeightedSample(this.value, this.weight);
}

class _CycleEstimate {
  final double mean;
  final double standardDeviation;

  const _CycleEstimate({required this.mean, required this.standardDeviation});
}
