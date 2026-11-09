import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/services/personalized_cycle_service.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  UserProfile profile() => UserProfile()
    ..postPartumStatus = 'no'
    ..trackCycle = true
    ..lastPeriodDate = DateTime(2026, 11, 1)
    ..cycleLength = 28
    ..periodDuration = 5;
  CheckIn checkIn(DateTime at) => CheckIn()
    ..ts = at
    ..moodScore = 5
    ..energyScore = 5
    ..sleepScore = 5;
  final service = PersonalizedCycleService();

  test('reported postpartum clearance cannot enable recommendations', () {
    for (final clearance in [false, true]) {
      final p = profile()
        ..postPartumStatus = 'late'
        ..medicalClearance = clearance;
      final result = service.buildInsight(
        profile: p,
        cycleLogs: [],
        checkIns: [checkIn(now)],
        workouts: [],
        now: now,
      )!;
      expect(result.readiness.level, ReadinessLevel.ready);
      expect(result.personalizationBoundaryMessage, isNotNull);
      expect(result.recommendation.workoutVolumeAdjustmentPercent, 0);
      expect(result.recommendation.workoutBody, contains('clinical review'));
      expect(
        result.recommendation.notificationBody,
        result.personalizationBoundaryMessage,
      );
      expect(result.phaseGuidance, result.personalizationBoundaryMessage);
    }
  });

  test('future records cannot establish current readiness', () {
    final result = service.buildInsight(
      profile: profile(),
      cycleLogs: [],
      checkIns: [checkIn(now.add(const Duration(hours: 1)))],
      workouts: [
        WorkoutSessionDoc()
          ..date = now.add(const Duration(hours: 1))
          ..completed = true
          ..perceivedExertion = 5,
      ],
      now: now,
    )!;
    expect(result.readiness.level, ReadinessLevel.checkInNeeded);
    expect(result.readiness.hasRecentCheckIn, false);
    expect(result.readiness.observationsUsed, 0);
    expect(result.readiness.recentWorkoutExertion, isNull);
  });

  test('tracking opt-out produces no insight', () {
    expect(
      service.buildInsight(
        profile: profile()..trackCycle = false,
        cycleLogs: [],
        checkIns: [checkIn(now)],
        workouts: [],
        now: now,
      ),
      isNull,
    );
  });
}
