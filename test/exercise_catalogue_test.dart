import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/exercise_catalogue.dart';
import 'package:lyva_app/models/workout_exercise.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/models/workout_session_doc.dart';

// Fictional contract fixtures, NOT exercise instructions or review evidence.
Map<String, dynamic> fixture() {
  Map<String, dynamic> provenance() => {
    'status': 'reviewed',
    'source': 'synthetic test fixture',
    'rightsEvidence': 'test-only',
    'reviewer': 'fictional test reviewer',
    'qualificationEvidence': 'test-only, no real qualification',
    'reviewedAt': '2026-01-01T00:00:00Z',
  };
  return {
    'schemaVersion': 1,
    'revision': 1,
    'exercises': [
      for (final id in ['a', 'b'])
        {
          'id': 'fixture:$id',
          'revision': 1,
          'name': 'Fixture $id',
          'equipment': id == 'a' ? ['fixture_equipment'] : <String>[],
          'difficulty': 1,
          'setup': ['Fixture setup text'],
          'cues': ['Fixture cue text'],
          'alternatives': id == 'a'
              ? [
                  {'id': 'fixture:b', 'revision': 1},
                ]
              : <dynamic>[],
          'provenance': provenance(),
        },
    ],
    'plans': [
      {
        'id': 'fixture:plan',
        'revision': 1,
        'name': 'Fixture plan',
        'provenance': provenance(),
        'days': [
          [
            {
              'exercise': {'id': 'fixture:a', 'revision': 1},
              'sets': 3,
              'repRange': {'min': 6, 'max': 8},
              'restSeconds': 90,
            },
          ],
        ],
      },
    ],
  };
}

CatalogueConstraints constraints({
  bool review = false,
  Set<String> equipment = const {'fixture_equipment'},
  Set<String> excluded = const {},
}) => CatalogueConstraints(
  equipment: equipment,
  maximumDifficulty: 1,
  requiresIndividualReview: review,
  excludedExerciseIds: excluded,
);
ExerciseCatalogue approved(Map<String, dynamic> source) {
  final unapproved = ExerciseCatalogue.fromJson(source);
  return ExerciseCatalogue.fromJson(
    source,
    approvedBundleDigests: {unapproved.digest},
  );
}

CatalogueReference reference(String id, [int revision = 1]) =>
    CatalogueReference.fromJson({'id': id, 'revision': revision});
WorkoutExercise saved({Object? ref}) => WorkoutExercise(
  id: 'session_slot',
  name: 'Original saved name',
  sets: 4,
  repMin: 8,
  repMax: 10,
  restSeconds: 120,
  extras: {if (ref != null) 'catalogueRef': ref},
);

void main() {
  test(
    'reviewed metadata alone cannot enable content; empty catalogue is safe',
    () {
      final catalogue = ExerciseCatalogue.fromJson(fixture());
      expect(catalogue.eligibleExercises(constraints()), isEmpty);
      expect(
        catalogue.instantiatePlan(reference('fixture:plan'), constraints()),
        isNull,
      );
      expect(
        ExerciseCatalogue.fromJson({
          'schemaVersion': 1,
          'revision': 1,
          'exercises': [],
          'plans': [],
        }).eligibleExercises(constraints()),
        isEmpty,
      );
    },
  );
  test('draft record cannot be selected even in an approved bundle', () {
    final source = fixture();
    source['exercises'][0]['provenance']['status'] = 'draft';
    final catalogue = approved(source);
    expect(
      catalogue.eligibleExercises(constraints()).map((e) => e.reference.id),
      ['fixture:b'],
    );
    expect(
      catalogue.instantiatePlan(reference('fixture:plan'), constraints()),
      isNull,
    );
  });
  test(
    'explicit equipment, exclusions and unresolved health constraints fail closed',
    () {
      final catalogue = approved(fixture());
      expect(
        catalogue
            .eligibleExercises(constraints(equipment: {}))
            .map((e) => e.reference.id),
        ['fixture:b'],
      );
      expect(
        catalogue.eligibleExercises(
          constraints(excluded: {'fixture:a', 'fixture:b'}),
        ),
        isEmpty,
      );
      expect(catalogue.eligibleExercises(constraints(review: true)), isEmpty);
      expect(
        catalogue.instantiatePlan(
          reference('fixture:plan'),
          constraints(review: true),
        ),
        isNull,
      );
      expect(
        catalogue
            .alternativesFor(reference('fixture:a'), constraints())
            .single
            .reference
            .id,
        'fixture:b',
      );
      expect(
        catalogue.alternativesFor(
          reference('fixture:a'),
          constraints(excluded: {'fixture:b'}),
        ),
        isEmpty,
      );
    },
  );
  test(
    'legacy/missing/malformed/version references never match by name or mutate saved data',
    () {
      final catalogue = approved(fixture());
      final cases = <WorkoutExercise, CatalogueResolution>{
        saved(): CatalogueResolution.legacy,
        saved(ref: {'id': 'fixture:missing', 'revision': 1}):
            CatalogueResolution.missing,
        saved(ref: {'id': 'fixture:a', 'revision': 2}):
            CatalogueResolution.revisionMismatch,
        saved(ref: 'bad'): CatalogueResolution.invalidReference,
        saved(ref: {'id': 'fixture:a', 'revision': 1}):
            CatalogueResolution.available,
      };
      for (final pair in cases.entries) {
        final before = jsonEncode(pair.key.toJson());
        expect(catalogue.resolve(pair.key, constraints()), pair.value);
        expect(jsonEncode(pair.key.toJson()), before);
      }
    },
  );
  test(
    'explicit plan creation round trips through existing schema and frozen history',
    () {
      final catalogue = approved(fixture());
      final plan = catalogue.instantiatePlan(
        reference('fixture:plan'),
        constraints(),
      )!;
      final normalized = WorkoutExercise.normalizeTemplate(plan);
      expect(normalized, plan);
      final exercise = normalized['days'][0]['exercises'][0];
      expect(exercise['catalogueRef'], {'id': 'fixture:a', 'revision': 1});
      expect(exercise['workingSets'], 3);
      expect(exercise['restSeconds'], 90);
      expect(
        catalogue.instantiatePlan(reference('fixture:plan'), constraints()),
        plan,
      );
      final doc = WorkoutTemplateDoc()
        ..id = 9
        ..planName = 'Saved'
        ..daysPerWeek = 1
        ..json = jsonEncode(plan);
      final snapshot = WorkoutPlanSnapshot.capture(doc);
      final session = WorkoutSessionDoc()
        ..dayIndex = 1
        ..planId = snapshot.planId
        ..templateSnapshotJson = snapshot.json;
      plan['days'][0]['exercises'][0]['workingSets'] = 99;
      expect(
        WorkoutPlanSnapshot.fromSession(
          session,
        )!.day(1)!['exercises'][0]['workingSets'],
        3,
      );
    },
  );
  test(
    'unsupported versions, duplicates, dangling refs and invalid prescriptions rejected',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (s) => s['schemaVersion'] = 2,
        (s) => s['exercises'].add(s['exercises'][0]),
        (s) => s['plans'][0]['days'][0][0]['exercise']['revision'] = 2,
        (s) => s['plans'][0]['days'][0][0]['restSeconds'] = -1,
        (s) => s['plans'][0]['days'][0][0]['repRange']['max'] = 1,
        (s) => s['exercises'][0]['provenance'].remove('rightsEvidence'),
      ]) {
        final source = fixture();
        mutate(source);
        expect(() => ExerciseCatalogue.fromJson(source), throwsFormatException);
      }
    },
  );
  test(
    'approval is content-bound; bundle and changed record revisions must advance',
    () {
      final source = fixture();
      final old = approved(source);
      source['exercises'][0]['name'] = 'Changed fixture';
      expect(
        ExerciseCatalogue.fromJson(
          source,
          approvedBundleDigests: {old.digest},
        ).eligibleExercises(constraints()),
        isEmpty,
      );
      expect(
        () => ExerciseCatalogue.fromJson(source, previousCatalogue: old),
        throwsFormatException,
      );
      source['revision'] = 2;
      expect(
        () => ExerciseCatalogue.fromJson(source, previousCatalogue: old),
        throwsFormatException,
      );
      source['exercises'][0]['revision'] = 2;
      source['plans'][0]['days'][0][0]['exercise']['revision'] = 2;
      source['plans'][0]['revision'] = 2;
      final next = ExerciseCatalogue.fromJson(source, previousCatalogue: old);
      expect(
        next.resolve(
          saved(ref: {'id': 'fixture:a', 'revision': 1}),
          constraints(),
        ),
        CatalogueResolution.revisionMismatch,
      );
    },
  );
  test(
    'source mutations cannot change parsed catalogue, exposed collections are immutable',
    () {
      final source = fixture();
      final catalogue = approved(source);
      source['exercises'][0]['name'] = 'tampered';
      source['exercises'][0]['equipment'].clear();
      expect(catalogue.exercises['fixture:a']!.name, 'Fixture a');
      expect(catalogue.exercises['fixture:a']!.equipment, {
        'fixture_equipment',
      });
      expect(() => catalogue.exercises.clear(), throwsUnsupportedError);
      expect(
        () => catalogue.exercises['fixture:a']!.cues.add('tampered'),
        throwsUnsupportedError,
      );
    },
  );
  test('difficulty limits and plan review are enforced independently', () {
    final source = fixture();
    source['exercises'][1]['difficulty'] = 3;
    source['plans'][0]['provenance']['status'] = 'draft';
    final catalogue = approved(source);
    expect(catalogue.eligibleExercises(constraints()).map((e) => e.reference.id), ['fixture:a']);
    expect(catalogue.alternativesFor(reference('fixture:a'), constraints()), isEmpty);
    expect(catalogue.instantiatePlan(reference('fixture:plan'), constraints()), isNull);
  });
  test('stable IDs cannot be recycled as another record kind', () {
    final old = ExerciseCatalogue.fromJson(fixture());
    final source = fixture();
    source['revision'] = 2;
    source['exercises'].removeAt(0);
    source['plans'][0]['id'] = 'fixture:a';
    source['plans'][0]['revision'] = 2;
    source['plans'][0]['days'][0][0]['exercise']['id'] = 'fixture:b';
    expect(() => ExerciseCatalogue.fromJson(source, previousCatalogue: old), throwsFormatException);
  });
}
