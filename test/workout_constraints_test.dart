import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/utils/workout_constraints.dart';

void main() {
  test('injuries and recovery context survive workout generation input', () {
    final profile = UserProfile()
      ..injuryList = ['knee_left']
      ..injuryNotes = 'Pain on stairs'
      ..postPartumStatus = 'early'
      ..deliveryDate = DateTime(2026, 1, 1)
      ..deliveryType = 'cesarean'
      ..medicalClearance = false
      ..checkDiastasis = true;
    final result = WorkoutConstraints.fromProfile(
      profile,
      additionalConstraints: 'No jumping',
    );
    for (final expected in [
      'knee_left',
      'Pain on stairs',
      'early',
      '2026-01-01',
      'cesarean',
      'medical clearance: false',
      'guidance requested: true',
      'No jumping',
    ]) {
      expect(result, contains(expected));
    }
  });

  test('cycle details are included only when tracking is enabled', () {
    final profile = UserProfile()..lastPeriodDate = DateTime(2026, 1, 1);
    expect(WorkoutConstraints.fromProfile(profile), 'none');
    profile.trackCycle = true;
    expect(WorkoutConstraints.fromProfile(profile), contains('2026-01-01'));
  });
}
