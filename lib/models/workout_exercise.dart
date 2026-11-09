/// Canonical exercise contract shared by generated and custom workouts.
/// Legacy custom fields are accepted on read; unknown AI fields are retained.
class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final int repMin;
  final int repMax;
  final int restSeconds;
  final Map<String, dynamic> extras;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.restSeconds,
    this.extras = const {},
  }) {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        sets < 1 ||
        sets > 100 ||
        repMin < 1 ||
        repMax < repMin ||
        repMax > 1000 ||
        restSeconds < 0 ||
        restSeconds > 3600) {
      throw const FormatException('Invalid workout exercise');
    }
  }

  factory WorkoutExercise.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
  }) {
    int number(dynamic value) {
      if (value is int) return value;
      if (value is num && value.isFinite && value == value.roundToDouble()) {
        return value.toInt();
      }
      return int.tryParse('$value') ??
          (throw const FormatException('Invalid exercise number'));
    }

    final range = json['repRange'];
    final legacy = '${json['reps'] ?? ''}'.split('-');
    final minimum = range is Map ? number(range['min']) : number(legacy.first);
    final maximum = range is Map ? number(range['max']) : number(legacy.last);
    final rest =
        json['restSeconds'] ??
        json['rest']?.toString().replaceFirst(RegExp(r's$'), '') ??
        (['main', 'secondary'].contains(json['liftClass']) ? 150 : 90);
    final suppliedId = json['exerciseId']?.toString().trim();
    return WorkoutExercise(
      id: suppliedId == null || suppliedId.isEmpty ? fallbackId : suppliedId,
      name: json['name']?.toString() ?? '',
      sets: number(json['workingSets'] ?? json['sets']),
      repMin: minimum,
      repMax: maximum,
      restSeconds: number(rest),
      extras: Map.of(json),
    );
  }

  Map<String, dynamic> toJson() => {
    ...extras,
    'exerciseId': id,
    'name': name,
    'workingSets': sets,
    'repRange': {'min': repMin, 'max': repMax},
    'restSeconds': restSeconds,
  }..removeWhere((key, _) => ['sets', 'reps', 'rest'].contains(key));

  static Map<String, dynamic> normalizeTemplate(Map<String, dynamic> source) {
    final rawDays = source['days'];
    if (rawDays is! List || rawDays.isEmpty) {
      throw const FormatException('Workout has no days');
    }
    final days = <Map<String, dynamic>>[];
    for (var d = 0; d < rawDays.length; d++) {
      if (rawDays[d] is! Map) {
        throw const FormatException('Invalid workout day');
      }
      final day = Map<String, dynamic>.from(rawDays[d] as Map);
      final rawExercises = day['exercises'];
      if (rawExercises is! List) {
        throw const FormatException('Invalid workout exercises');
      }
      final used = <String>{};
      final exercises = <Map<String, dynamic>>[];
      for (var e = 0; e < rawExercises.length; e++) {
        if (rawExercises[e] is! Map) {
          throw const FormatException('Invalid workout exercise');
        }
        final raw = Map<String, dynamic>.from(rawExercises[e] as Map);
        final fallback = 'day_${d + 1}_exercise_${e + 1}';
        var exercise = WorkoutExercise.fromJson(raw, fallbackId: fallback);
        if (used.contains(exercise.id)) {
          var replacement = fallback;
          while (used.contains(replacement)) {
            replacement = '${replacement}_duplicate';
          }
          raw['exerciseId'] = replacement;
          exercise = WorkoutExercise.fromJson(raw, fallbackId: replacement);
        }
        used.add(exercise.id);
        exercises.add(exercise.toJson());
      }
      days.add({
        ...day,
        'dayIndex': day['dayIndex'] ?? d + 1,
        'title': day['title'] ?? day['dayName'] ?? 'Day ${d + 1}',
        'exercises': exercises,
      });
    }
    return {...source, 'schemaVersion': 1, 'days': days};
  }
}
