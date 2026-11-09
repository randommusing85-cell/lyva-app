import '../models/user_profile.dart';

/// Versioned product boundary, NOT a clinical screening algorithm.
enum PersonalizationState {
  standard, insufficientInformation, clearanceRequired, clinicalReviewRequired,
  pauseForClinician, urgentEscalation,
}

class PersonalizationDecision {
  static const policyVersion = 1;
  final PersonalizationState state;
  const PersonalizationDecision(this.state);
  bool get allowed => state == PersonalizationState.standard;
  String get message => switch (state) {
    PersonalizationState.standard => 'Standard planning available.',
    PersonalizationState.insufficientInformation => 'Personalized guidance is unavailable until profile information can be checked. Tracking remains available.',
    PersonalizationState.clearanceRequired => 'Lyva requires your reported doctor or OBGYN clearance before tailored postpartum plans. These plans remain unavailable pending clinical review. Tracking remains available.',
    PersonalizationState.clinicalReviewRequired => 'Your reported clearance is saved. Tailored postpartum plans remain unavailable pending clinical review. Tracking remains available.',
    PersonalizationState.pauseForClinician => 'Personalized guidance is paused pending clinician advice. Tracking remains available.',
    PersonalizationState.urgentEscalation => 'Personalized guidance is unavailable. Follow the clinician-reviewed urgent-care instructions supplied by your care team.',
  };
  void requireAllowed() {
    if (!allowed) throw PersonalizationUnavailable(message);
  }

  /// Escalation inputs are test seams only. No live symptom classification.
  static PersonalizationDecision evaluate(UserProfile? profile, {
    bool syntheticUrgent = false, bool syntheticPause = false,
  }) {
    if (syntheticUrgent) return const PersonalizationDecision(PersonalizationState.urgentEscalation);
    if (syntheticPause) return const PersonalizationDecision(PersonalizationState.pauseForClinician);
    if (profile == null) return const PersonalizationDecision(PersonalizationState.insufficientInformation);
    if (profile.postPartumStatus == 'no') return const PersonalizationDecision(PersonalizationState.standard);
    if (!profile.medicalClearance) return const PersonalizationDecision(PersonalizationState.clearanceRequired);
    // No caller can enable postpartum generation by supplying clearance alone.
    return const PersonalizationDecision(PersonalizationState.clinicalReviewRequired);
  }
}

class PersonalizationUnavailable implements Exception {
  final String message;
  const PersonalizationUnavailable(this.message);
  @override
  String toString() => message;
}

class PersonalizationSafety {
  final Future<UserProfile?> Function() readProfile;
  PersonalizationSafety(this.readProfile);
  static String revision(UserProfile p) => '${PersonalizationDecision.policyVersion}:${p.id}:${p.updatedAt.toUtc().microsecondsSinceEpoch}:${p.postPartumStatus}:${p.medicalClearance}';

  Future<T> run<T>(Future<T> Function() operation) async {
    final before = await readProfile();
    PersonalizationDecision.evaluate(before).requireAllowed();
    final expected = revision(before!);
    // A second fresh read rejects a snapshot invalidated during initial preflight.
    // This narrows a local window; dispatch and remote processing are NOT atomic
    // with profile writes. Trusted server authorization is still required.
    final preflight = await readProfile();
    PersonalizationDecision.evaluate(preflight).requireAllowed();
    if (revision(preflight!) != expected) {
      throw const PersonalizationUnavailable('Your profile changed before this request. Review your information before trying again.');
    }
    final result = await operation();
    final after = await readProfile();
    PersonalizationDecision.evaluate(after).requireAllowed();
    if (revision(after!) != expected) {
      throw const PersonalizationUnavailable('Your profile changed. This response was discarded; review your current information before trying again.');
    }
    return result;
  }
}
