import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'workout_exercise.dart';

/// Data-contract bounds, not clinical programming limits.
String _text(dynamic value) {
  if (value is! String || value.trim().isEmpty || value.length > 2000) {
    throw const FormatException('Missing or oversized catalogue text');
  }
  return value;
}

int _revision(dynamic value) {
  if (value is! int || value < 1) {
    throw const FormatException('Invalid revision');
  }
  return value;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is! Map) throw const FormatException('Expected catalogue object');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(dynamic value) {
  if (value is! List || value.length > 1000) {
    throw const FormatException('Invalid catalogue list');
  }
  return value;
}

String _id(dynamic value) {
  final id = _text(value);
  if (!RegExp(r'^[a-z][a-z0-9_]*:[a-z0-9][a-z0-9_.-]{0,95}$').hasMatch(id)) {
    throw const FormatException('Invalid stable catalogue ID');
  }
  return id;
}

Object? _ordered(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _ordered(value[key])};
  }
  if (value is List) return value.map(_ordered).toList();
  return value;
}

class CatalogueReference {
  final String id;
  final int revision;
  CatalogueReference._(this.id, this.revision);
  factory CatalogueReference.fromJson(Map<String, dynamic> json) =>
      CatalogueReference._(_id(json['id']), _revision(json['revision']));
  Map<String, dynamic> toJson() => {'id': id, 'revision': revision};
}

/// Declared provenance is auditable metadata, never proof of qualified review.
class CatalogueProvenance {
  final String status;
  final String source;
  final String? rightsEvidence, reviewer, qualificationEvidence;
  final DateTime? reviewedAt;
  CatalogueProvenance._(
    this.status,
    this.source,
    this.rightsEvidence,
    this.reviewer,
    this.qualificationEvidence,
    this.reviewedAt,
  );
  factory CatalogueProvenance.fromJson(Map<String, dynamic> json) {
    final status = _text(json['status']);
    if (!['draft', 'reviewed'].contains(status)) {
      throw const FormatException('Unknown review status');
    }
    final source = _text(json['source']);
    if (status == 'draft') {
      return CatalogueProvenance._(status, source, null, null, null, null);
    }
    final reviewedAt = DateTime.tryParse(_text(json['reviewedAt']));
    if (reviewedAt == null) throw const FormatException('Invalid review date');
    return CatalogueProvenance._(
      status,
      source,
      _text(json['rightsEvidence']),
      _text(json['reviewer']),
      _text(json['qualificationEvidence']),
      reviewedAt,
    );
  }
}

class CatalogueExercise {
  final CatalogueReference reference;
  final String name;
  final Set<String> equipment;
  final int difficulty; // 1–3, ordered product labels; not a safety rating.
  final List<String> setup, cues;
  final List<CatalogueReference> alternatives;
  final String? demonstrationReference;
  final CatalogueProvenance provenance;
  CatalogueExercise._(
    this.reference,
    this.name,
    this.equipment,
    this.difficulty,
    this.setup,
    this.cues,
    this.alternatives,
    this.demonstrationReference,
    this.provenance,
  );
  factory CatalogueExercise.fromJson(Map<String, dynamic> json) {
    final difficulty = _revision(json['difficulty']);
    if (difficulty > 3) throw const FormatException('Invalid difficulty');
    return CatalogueExercise._(
      CatalogueReference.fromJson(json),
      _text(json['name']),
      Set.unmodifiable(_list(json['equipment']).map(_text)),
      difficulty,
      List.unmodifiable(_list(json['setup']).map(_text)),
      List.unmodifiable(_list(json['cues']).map(_text)),
      List.unmodifiable(
        _list(
          json['alternatives'],
        ).map((e) => CatalogueReference.fromJson(_map(e))),
      ),
      json['demonstrationReference'] == null
          ? null
          : _text(json['demonstrationReference']),
      CatalogueProvenance.fromJson(_map(json['provenance'])),
    );
  }
}

class CataloguePrescription {
  final CatalogueReference exercise;
  final int sets, repMin, repMax, restSeconds;
  CataloguePrescription._(
    this.exercise,
    this.sets,
    this.repMin,
    this.repMax,
    this.restSeconds,
  );
  factory CataloguePrescription.fromJson(Map<String, dynamic> json) {
    final range = _map(json['repRange']);
    final sets = _revision(json['sets']);
    final min = _revision(range['min']), max = _revision(range['max']);
    final rest = json['restSeconds'];
    if (rest is! int) throw const FormatException('Rest must be explicit');
    // Reuse the existing structural prescription validator without its legacy defaults.
    WorkoutExercise(
      id: 'validation',
      name: 'validation',
      sets: sets,
      repMin: min,
      repMax: max,
      restSeconds: rest,
    );
    return CataloguePrescription._(
      CatalogueReference.fromJson(_map(json['exercise'])),
      sets,
      min,
      max,
      rest,
    );
  }
}

class CataloguePlan {
  final CatalogueReference reference;
  final String name;
  final List<List<CataloguePrescription>> days;
  final CatalogueProvenance provenance;
  CataloguePlan._(this.reference, this.name, this.days, this.provenance);
  factory CataloguePlan.fromJson(Map<String, dynamic> json) {
    final days = _list(json['days']);
    if (days.isEmpty || days.length > 7) {
      throw const FormatException('Invalid plan days');
    }
    final parsed = days.map((day) {
      final slots = _list(day);
      if (slots.isEmpty || slots.length > 100) {
        throw const FormatException('Invalid plan slots');
      }
      return List<CataloguePrescription>.unmodifiable(
        slots.map((s) => CataloguePrescription.fromJson(_map(s))),
      );
    });
    return CataloguePlan._(
      CatalogueReference.fromJson(json),
      _text(json['name']),
      List.unmodifiable(parsed),
      CatalogueProvenance.fromJson(_map(json['provenance'])),
    );
  }
}

class CatalogueConstraints {
  final Set<String> equipment, excludedExerciseIds;
  final int maximumDifficulty;
  final bool requiresIndividualReview;
  CatalogueConstraints({
    required Set<String> equipment,
    required this.maximumDifficulty,
    Set<String> excludedExerciseIds = const {},
    this.requiresIndividualReview = false,
  }) : equipment = Set.unmodifiable(equipment),
       excludedExerciseIds = Set.unmodifiable(excludedExerciseIds) {
    if (maximumDifficulty < 1 || maximumDifficulty > 3) {
      throw ArgumentError('Invalid difficulty');
    }
  }
}

enum CatalogueResolution {
  legacy,
  invalidReference,
  missing,
  revisionMismatch,
  unreviewed,
  constrained,
  available,
}

class ExerciseCatalogue {
  final int revision;
  final String digest;
  final Map<String, CatalogueExercise> exercises;
  final Map<String, CataloguePlan> plans;
  final bool _approvedBundle;
  final Map<String, String> _recordDigests;
  ExerciseCatalogue._(
    this.revision,
    this.digest,
    this.exercises,
    this.plans,
    this._approvedBundle,
    this._recordDigests,
  );

  /// Approval hashes must come from a separately reviewed release configuration,
  /// never the bundle or user input. Production currently supplies none.
  factory ExerciseCatalogue.fromJson(
    Map<String, dynamic> json, {
    Set<String> approvedBundleDigests = const {},
    ExerciseCatalogue? previousCatalogue,
  }) {
    if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported catalogue schema');
    }
    final revision = _revision(json['revision']);
    final exercises = <String, CatalogueExercise>{};
    for (final raw in _list(json['exercises'])) {
      final exercise = CatalogueExercise.fromJson(_map(raw));
      if (exercises.containsKey(exercise.reference.id)) {
        throw const FormatException('Duplicate exercise ID');
      }
      exercises[exercise.reference.id] = exercise;
    }
    final plans = <String, CataloguePlan>{};
    for (final raw in _list(json['plans'])) {
      final plan = CataloguePlan.fromJson(_map(raw));
      if (plans.containsKey(plan.reference.id) ||
          exercises.containsKey(plan.reference.id)) {
        throw const FormatException('Duplicate plan ID');
      }
      plans[plan.reference.id] = plan;
    }
    void requireReference(CatalogueReference reference) {
      if (exercises[reference.id]?.reference.revision != reference.revision) {
        throw const FormatException('Unresolved catalogue reference');
      }
    }

    for (final exercise in exercises.values) {
      for (final alternative in exercise.alternatives) {
        requireReference(alternative);
      }
    }
    for (final plan in plans.values) {
      for (final day in plan.days) {
        for (final slot in day) {
          requireReference(slot.exercise);
        }
      }
    }
    final digest = sha256
        .convert(utf8.encode(jsonEncode(_ordered(json))))
        .toString();
    final recordDigests = <String, String>{};
    for (final raw in [..._list(json['exercises']), ..._list(json['plans'])]) {
      final data = _map(raw);
      recordDigests[_id(data['id'])] = sha256
          .convert(utf8.encode(jsonEncode(_ordered(data))))
          .toString();
    }
    if (previousCatalogue != null) {
      if (digest != previousCatalogue.digest &&
          revision <= previousCatalogue.revision) {
        throw const FormatException('Changed bundle must advance revision');
      }
      for (final id in recordDigests.keys) {
        if ((previousCatalogue.exercises.containsKey(id) &&
                plans.containsKey(id)) ||
            (previousCatalogue.plans.containsKey(id) &&
                exercises.containsKey(id))) {
          throw const FormatException('Stable ID cannot change record kind');
        }
        final oldRevision =
            previousCatalogue.exercises[id]?.reference.revision ??
            previousCatalogue.plans[id]?.reference.revision;
        final newRevision =
            exercises[id]?.reference.revision ?? plans[id]!.reference.revision;
        if (oldRevision != null &&
            (newRevision < oldRevision ||
                (recordDigests[id] != previousCatalogue._recordDigests[id] &&
                    newRevision <= oldRevision))) {
          throw const FormatException('Changed record must advance revision');
        }
      }
    }
    return ExerciseCatalogue._(
      revision,
      digest,
      Map.unmodifiable(exercises),
      Map.unmodifiable(plans),
      approvedBundleDigests.contains(digest),
      Map.unmodifiable(recordDigests),
    );
  }

  bool _reviewed(CatalogueProvenance provenance) =>
      _approvedBundle && provenance.status == 'reviewed';
  bool _eligible(
    CatalogueExercise exercise,
    CatalogueConstraints constraints,
  ) =>
      !constraints.requiresIndividualReview &&
      !constraints.excludedExerciseIds.contains(exercise.reference.id) &&
      constraints.equipment.containsAll(exercise.equipment) &&
      exercise.difficulty <= constraints.maximumDifficulty;

  CatalogueResolution resolve(
    WorkoutExercise saved,
    CatalogueConstraints constraints,
  ) {
    final raw = saved.extras['catalogueRef'];
    if (raw == null) return CatalogueResolution.legacy;
    CatalogueReference reference;
    try {
      reference = CatalogueReference.fromJson(_map(raw));
    } catch (_) {
      return CatalogueResolution.invalidReference;
    }
    final exercise = exercises[reference.id];
    if (exercise == null) return CatalogueResolution.missing;
    if (exercise.reference.revision != reference.revision) {
      return CatalogueResolution.revisionMismatch;
    }
    if (!_reviewed(exercise.provenance)) return CatalogueResolution.unreviewed;
    return _eligible(exercise, constraints)
        ? CatalogueResolution.available
        : CatalogueResolution.constrained;
  }

  List<CatalogueExercise> eligibleExercises(CatalogueConstraints constraints) =>
      List.unmodifiable(
        exercises.values.where(
          (e) => _reviewed(e.provenance) && _eligible(e, constraints),
        ),
      );

  List<CatalogueExercise> alternativesFor(
    CatalogueReference reference,
    CatalogueConstraints constraints,
  ) {
    final source = exercises[reference.id];
    if (source == null ||
        source.reference.revision != reference.revision ||
        !_reviewed(source.provenance)) {
      return const [];
    }
    return List.unmodifiable(
      source.alternatives
          .map((r) => exercises[r.id]!)
          .where((e) => _reviewed(e.provenance) && _eligible(e, constraints)),
    );
  }

  /// Explicit creation only. Never mutates a saved workout or upgrades its refs.
  Map<String, dynamic>? instantiatePlan(
    CatalogueReference reference,
    CatalogueConstraints constraints,
  ) {
    final plan = plans[reference.id];
    if (plan == null ||
        plan.reference.revision != reference.revision ||
        !_reviewed(plan.provenance)) {
      return null;
    }
    if (plan.days.expand((d) => d).any((slot) {
      final exercise = exercises[slot.exercise.id]!;
      return !_reviewed(exercise.provenance) ||
          !_eligible(exercise, constraints);
    })) {
      return null;
    }
    return {
      'schemaVersion': 1,
      'planName': plan.name,
      'daysPerWeek': plan.days.length,
      'cataloguePlanRef': reference.toJson(),
      'days': [
        for (var d = 0; d < plan.days.length; d++)
          {
            'dayIndex': d + 1,
            'title': 'Day ${d + 1}',
            'exercises': [
              for (var i = 0; i < plan.days[d].length; i++)
                _slot(plan, plan.days[d][i], d, i),
            ],
          },
      ],
    };
  }

  Map<String, dynamic> _slot(
    CataloguePlan plan,
    CataloguePrescription slot,
    int day,
    int index,
  ) => WorkoutExercise(
    id: '${plan.reference.id}:day_${day + 1}_slot_${index + 1}',
    name: exercises[slot.exercise.id]!.name,
    sets: slot.sets,
    repMin: slot.repMin,
    repMax: slot.repMax,
    restSeconds: slot.restSeconds,
    extras: {'catalogueRef': slot.exercise.toJson()},
  ).toJson();
}
