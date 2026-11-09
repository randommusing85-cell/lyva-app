import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/workout_exercise.dart';

void main() {
  Map<String, dynamic> legacy() => {
    'days': [
      {
        'dayName': 'Legs',
        'exercises': [
          {'name': 'Squat', 'sets': 4, 'reps': '8', 'rest': '120s'},
          {'name': 'Squat', 'sets': 2, 'reps': '10-12', 'rest': '30s'},
        ],
      },
    ],
  };
  test(
    'legacy custom workouts retain values, unique IDs and day names across round trips',
    () {
      final original = legacy();
      final normalized = WorkoutExercise.normalizeTemplate(original);
      final day = normalized['days'][0];
      final first = day['exercises'][0];
      expect(day['title'], 'Legs');
      expect(first['workingSets'], 4);
      expect(first['repRange'], {'min': 8, 'max': 8});
      expect(first['restSeconds'], 120);
      expect(first['exerciseId'], isNot(day['exercises'][1]['exerciseId']));
      expect(WorkoutExercise.normalizeTemplate(normalized), normalized);
      expect(
        original['days'][0]['exercises'][0].containsKey('exerciseId'),
        isFalse,
      );
    },
  );
  test('generated exercise metadata and assigned IDs survive persistence', () {
    final Map<String, dynamic> source = {
      'days': [
        {
          'dayIndex': 1,
          'title': 'Upper',
          'exercises': [
            {
              'exerciseId': 'press',
              'name': 'Press',
              'workingSets': 3,
              'repRange': {'min': 6, 'max': 8},
              'restSeconds': 150,
              'alternatives': [
                {'name': 'Dumbbell press'},
              ],
              'liftClass': 'main',
            },
          ],
        },
      ],
    };
    final normalized = WorkoutExercise.normalizeTemplate(source);
    expect(
      normalized['days'][0]['exercises'][0],
      source['days'][0]['exercises'][0],
    );
  });
  test(
    'duplicate IDs are repaired deterministically without colliding with legacy IDs',
    () {
      final source = legacy();
      for (final exercise in source['days'][0]['exercises']) {
        exercise['exerciseId'] = 'same';
      }
      final normalized = WorkoutExercise.normalizeTemplate(source);
      final exercises = normalized['days'][0]['exercises'] as List;
      expect(exercises.map((e) => e['exerciseId']).toSet().length, 2);
      expect(WorkoutExercise.normalizeTemplate(normalized), normalized);
    },
  );
  test('malformed and unsafe numeric values fail before persistence', () {
    for (final change in [
      {'sets': 0},
      {'sets': 2.5},
      {'reps': '12-8'},
      {'rest': '-1s'},
      {'name': ''},
    ]) {
      final source = legacy();
      source['days'][0]['exercises'][0].addAll(change);
      expect(
        () => WorkoutExercise.normalizeTemplate(source),
        throwsFormatException,
      );
    }
    expect(
      () => WorkoutExercise.normalizeTemplate({'days': []}),
      throwsFormatException,
    );
  });
}
