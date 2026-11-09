import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/cycle_log.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/personalized_cycle_service.dart';

void main() {
  final service = PersonalizedCycleService();

  group('PersonalizedCycleService', () {
    test('learns a stable personal cycle and returns a prediction window', () {
      final first = DateTime(2026, 1, 1);
      final second = first.add(const Duration(days: 28));
      final third = second.add(const Duration(days: 29));
      final profile = _profile(lastPeriod: third, cycleLength: 32);

      final insight = service.buildInsight(
        profile: profile,
        cycleLogs: [
          _periodStart(first),
          _periodStart(second),
          _periodStart(third),
        ],
        checkIns: const [],
        workouts: const [],
        now: third.add(const Duration(days: 10)),
      );

      expect(insight, isNotNull);
      expect(insight!.isPersonalized, isTrue);
      expect(insight.completedCycleCount, 2);
      expect(insight.predictedCycleLength, inInclusiveRange(28, 31));
      expect(
        insight.periodWindowStart.isBefore(insight.predictedPeriodDate),
        isTrue,
      );
      expect(
        insight.periodWindowEnd.isAfter(insight.predictedPeriodDate),
        isTrue,
      );
    });

    test('reduces the influence of a likely missed period log', () {
      final first = DateTime(2026, 1, 1);
      final second = first.add(const Duration(days: 28));
      final fourth = second.add(const Duration(days: 56));
      final profile = _profile(lastPeriod: fourth, cycleLength: 28);

      final insight = service.buildInsight(
        profile: profile,
        cycleLogs: [
          _periodStart(first),
          _periodStart(second),
          _periodStart(fourth),
        ],
        checkIns: const [],
        workouts: const [],
        now: fourth.add(const Duration(days: 5)),
      );

      expect(insight, isNotNull);
      expect(insight!.inferredMissedLogs, 1);
      expect(insight.predictedCycleLength, inInclusiveRange(27, 29));
    });

    test('uses current recovery signals instead of a phase rule', () {
      final lastPeriod = DateTime(2026, 3, 8);
      final now = DateTime(2026, 4, 1, 8);
      final profile = _profile(lastPeriod: lastPeriod, cycleLength: 28);
      final checkIn = CheckIn()
        ..ts = now
        ..weightKg = 62
        ..waistCm = 72
        ..stepsToday = 5000
        ..moodScore = 2
        ..energyScore = 2
        ..sleepScore = 2
        ..stressScore = 5
        ..sorenessScore = 4
        ..hungerScore = 5;
      final symptom = CycleLog()
        ..ts = now
        ..eventType = 'symptom'
        ..symptomType = 'cramps'
        ..severity = 4;

      final insight = service.buildInsight(
        profile: profile,
        cycleLogs: [symptom],
        checkIns: [checkIn],
        workouts: const [],
        now: now,
      );

      expect(insight, isNotNull);
      expect(insight!.readiness.level, ReadinessLevel.recover);
      expect(insight.recommendation.workoutVolumeAdjustmentPercent, 0);
      expect(insight.recommendation.nutritionTitle, 'Plan for higher hunger');
      expect(
        insight.recommendation.reasons.any(
          (reason) => reason.contains('Energy'),
        ),
        isTrue,
      );
    });

    test('asks for a check-in when no current readiness data exists', () {
      final lastPeriod = DateTime(2026, 5, 1);
      final insight = service.buildInsight(
        profile: _profile(lastPeriod: lastPeriod, cycleLength: 28),
        cycleLogs: const [],
        checkIns: const [],
        workouts: const [],
        now: lastPeriod.add(const Duration(days: 8)),
      );

      expect(insight, isNotNull);
      expect(insight!.readiness.level, ReadinessLevel.checkInNeeded);
      expect(insight.readiness.score, isNull);
    });

    test('caps confidence while the user is postpartum', () {
      final first = DateTime(2026, 1, 1);
      final starts = List.generate(
        7,
        (index) => first.add(Duration(days: index * 28)),
      );
      final profile = _profile(lastPeriod: starts.last, cycleLength: 28)
        ..postPartumStatus = 'late';

      final insight = service.buildInsight(
        profile: profile,
        cycleLogs: starts.map(_periodStart).toList(),
        checkIns: const [],
        workouts: const [],
        now: starts.last.add(const Duration(days: 4)),
      );

      expect(insight, isNotNull);
      expect(insight!.confidence, lessThanOrEqualTo(0.48));
      expect(insight.recommendation.workoutVolumeAdjustmentPercent, 0);
      expect(insight.personalizationBoundaryMessage, isNotNull);
      expect(insight.recommendation.workoutBody, contains('clinical review'));
      expect(insight.phaseGuidance, contains('clinical review'));
    });
  });
}

UserProfile _profile({required DateTime lastPeriod, required int cycleLength}) {
  return UserProfile()
    ..postPartumStatus = 'no'
    ..trackCycle = true
    ..lastPeriodDate = lastPeriod
    ..cycleLength = cycleLength
    ..periodDuration = 5;
}

CycleLog _periodStart(DateTime date) {
  return CycleLog()
    ..ts = date
    ..eventType = 'period_start';
}
