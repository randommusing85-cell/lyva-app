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
      throw StateError('Tailored postpartum generation is disabled pending clinical review.');
    }
    if (profile.trackCycle) {
      constraints.add(
        'Do not infer ovulation, hormone levels or workout intensity from calendar dates. '
        'Use explicitly reported symptoms and preferences instead.',
      );
    }
    return constraints.isEmpty ? 'none' : constraints.join('\n');
  }
}
