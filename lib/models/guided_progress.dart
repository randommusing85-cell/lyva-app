import 'dart:convert';
import 'workout_exercise.dart';
import 'workout_plan_snapshot.dart';

/// Local recorded performance, separate from the immutable prescription.
class GuidedProgress {
  final int revision;
  final int currentExercise;
  final Map<String, List<int?>> reps;
  final Map<String, List<bool>> done;
  final DateTime? restUntil;
  final bool endedEarly;
  GuidedProgress._(
    this.revision,
    this.currentExercise,
    this.reps,
    this.done,
    this.restUntil,
    this.endedEarly,
  );

  static List<WorkoutExercise> exercises(WorkoutPlanSnapshot plan, int day) {
    final raw = plan.day(day)?['exercises'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('Missing saved exercises');
    }
    return List.unmodifiable(
      raw.map(
        (e) => WorkoutExercise.fromJson(
          Map<String, dynamic>.from(e as Map),
          fallbackId: 'invalid',
        ),
      ),
    );
  }

  factory GuidedProgress.read(String? json, List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) throw const FormatException('Empty workout');
    if (json == null) {
      return GuidedProgress._(
        0,
        0,
        Map.unmodifiable({
          for (final e in exercises)
            e.id: List<int?>.unmodifiable(List.filled(e.sets, null)),
        }),
        Map.unmodifiable({
          for (final e in exercises)
            e.id: List<bool>.unmodifiable(List.filled(e.sets, false)),
        }),
        null,
        false,
      );
    }
    final data = jsonDecode(json);
    if (data is! Map ||
        data['version'] != 1 ||
        data['revision'] is! int ||
        data['revision'] < 0 ||
        data['current'] is! int ||
        data['current'] < 0 ||
        data['current'] >= exercises.length ||
        data['endedEarly'] is! bool ||
        data['done'] is! Map ||
        data['reps'] is! Map) {
      throw const FormatException('Invalid saved progress');
    }
    final done = <String, List<bool>>{};
    final reps = <String, List<int?>>{};
    if ((data['done'] as Map).length != exercises.length ||
        (data['reps'] as Map).length != exercises.length) {
      throw const FormatException('Progress does not match prescription');
    }
    for (final e in exercises) {
      final d = data['done'][e.id], r = data['reps'][e.id];
      if (d is! List ||
          r is! List ||
          d.length != e.sets ||
          r.length != e.sets ||
          d.any((v) => v is! bool) ||
          r.any((v) => v != null && (v is! int || v < 0 || v > 1000))) {
        throw const FormatException('Invalid set record');
      }
      done[e.id] = List<bool>.unmodifiable(d.cast<bool>());
      reps[e.id] = List<int?>.unmodifiable(r.cast<int?>());
    }
    final rest = data['restUntil'];
    if (rest != null && (rest is! String || DateTime.tryParse(rest) == null)) {
      throw const FormatException('Invalid rest time');
    }
    return GuidedProgress._(
      data['revision'],
      data['current'],
      Map.unmodifiable(reps),
      Map.unmodifiable(done),
      rest == null ? null : DateTime.parse(rest).toUtc(),
      data['endedEarly'],
    );
  }

  int get completedSets => done.values.expand((e) => e).where((v) => v).length;
  int get totalSets => done.values.fold(0, (n, e) => n + e.length);
  int remainingRest(DateTime now) => restUntil == null
      ? 0
      : ((restUntil!.difference(now.toUtc()).inMilliseconds / 1000).ceil())
            .clamp(0, 3600);
  Map<String, dynamic> toJson() => {
    'version': 1,
    'revision': revision,
    'current': currentExercise,
    'reps': reps,
    'done': done,
    'restUntil': restUntil?.toUtc().toIso8601String(),
    'endedEarly': endedEarly,
  };
  String get json => jsonEncode(toJson());
  GuidedProgress change(
    List<WorkoutExercise> exercises, {
    int? current,
    String? exerciseId,
    int? setIndex,
    bool? checked,
    int? actualReps,
    bool clearReps = false,
    DateTime? restUntil,
    bool clearRest = false,
    bool? endedEarly,
    int? revision,
  }) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (current != null) data['current'] = current;
    if (revision != null) data['revision'] = revision;
    if (endedEarly != null) data['endedEarly'] = endedEarly;
    if (clearRest || restUntil != null) {
      data['restUntil'] = restUntil?.toUtc().toIso8601String();
    }
    if (exerciseId != null && setIndex != null) {
      if (checked != null) data['done'][exerciseId][setIndex] = checked;
      if (actualReps != null || clearReps) {
        data['reps'][exerciseId][setIndex] = actualReps;
      }
    }
    return GuidedProgress.read(jsonEncode(data), exercises);
  }
}
