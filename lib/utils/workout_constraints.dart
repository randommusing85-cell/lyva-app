import '../models/user_profile.dart';

/// Keep profile limitations in the existing backend's constraints field.
class WorkoutConstraints {
  static String fromProfile(
    UserProfile profile, {
    String? additionalConstraints,
    List<String>? additionalInjuries,
  }) {
    final constraints = <String>[];
    if (additionalConstraints != null &&
        additionalConstraints.trim().isNotEmpty &&
        additionalConstraints.trim() != 'none') {
      constraints.add(additionalConstraints.trim());
    }
    final injuries = {...profile.injuryList, ...?additionalInjuries};
    if (injuries.isNotEmpty) {
      constraints.add(
        'Injuries/limitations: ${injuries.join(', ')}. '
        'Avoid exercises that aggravate these areas and provide alternatives.',
      );
    }
    final notes = profile.injuryNotes?.trim();
    if (notes != null && notes.isNotEmpty) {
      constraints.add('Injury notes: $notes');
    }
    if (profile.postPartumStatus != 'no') {
      constraints.add(
        'Postpartum stage: ${profile.postPartumStatus}; '
        'delivery date: ${profile.deliveryDate?.toIso8601String() ?? 'unknown'}; '
        'delivery type: ${profile.deliveryType}; '
        'medical clearance: ${profile.medicalClearance}; '
        'diastasis recti guidance requested: ${profile.checkDiastasis}. '
        'Adapt the plan to these recovery limitations.',
      );
    }
    if (profile.trackCycle) {
      constraints.add(
        'Cycle-aware training requested; '
        'last period: ${profile.lastPeriodDate?.toIso8601String() ?? 'unknown'}; '
        'cycle length: ${profile.cycleLength} days; '
        'period duration: ${profile.periodDuration} days.',
      );
    }
    return constraints.isEmpty ? 'none' : constraints.join('\n');
  }
}
