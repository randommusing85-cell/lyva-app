import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/utils/workout_constraints.dart';

void main() {
  test('postpartum constraints never serialize sensitive recovery data', () {
    final profile = UserProfile()..postPartumStatus = 'early'..medicalClearance = true;
    expect(() => WorkoutConstraints.fromProfile(profile), throwsStateError);
  });
  test('existing injury constraints remain available for standard profiles', () {
    final profile = UserProfile()..injuryList = ['knee_left'];
    expect(WorkoutConstraints.fromProfile(profile), contains('knee_left'));
  });

  test('cycle details are included only when tracking is enabled', () {
    final profile = UserProfile()..lastPeriodDate = DateTime(2026, 1, 1);
    expect(WorkoutConstraints.fromProfile(profile), 'none');
    profile.trackCycle = true;
    expect(
      WorkoutConstraints.fromProfile(profile),
      contains('Do not infer ovulation'),
    );
    expect(
      WorkoutConstraints.fromProfile(profile),
      isNot(contains('2026-01-01')),
    );
  });
}
