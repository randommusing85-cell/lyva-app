import '../models/workout_exercise.dart';
import '../models/workout_plan_snapshot.dart';
import '../repos/lyva_repo.dart';
import '../utils/workout_progression.dart';

enum RoutineAnswerStatus { answered, clarify, unavailable, stale, unsupported }

class WorkoutFacts {
  final WorkoutPlanSnapshot plan;
  final int dayIndex;
  const WorkoutFacts(this.plan, this.dayIndex);
  String get key => '${plan.planId}:day_$dayIndex';
}

class RoutineAnswer {
  final RoutineAnswerStatus status;
  final String text;
  final String? sourcePlanId;
  const RoutineAnswer(this.status, this.text, {this.sourcePlanId});
}

/// Local retrieval only: no network, AI, analytics, usage counters or writes.
class RoutineWorkoutAnswers {
  final Future<WorkoutFacts?> Function() _load;
  RoutineWorkoutAnswers({required Future<WorkoutFacts?> Function() load})
    : _load = load;
  factory RoutineWorkoutAnswers.fromRepo(LyvaRepo repo) =>
      RoutineWorkoutAnswers(
        load: () async {
          final template = await repo.getLatestWorkoutTemplate();
          if (template == null || template.daysPerWeek < 1) return null;
          final plan = WorkoutPlanSnapshot.capture(template);
          final last = await repo.getLatestWorkoutSession(planId: plan.planId);
          return WorkoutFacts(
            plan,
            workoutDayIndex(template.daysPerWeek, last),
          );
        },
      );

  static String _normalize(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[?]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool handles(String request) {
    final q = _normalize(request);
    return [
          "today",
          "today's workout",
          "what is today's workout",
          "show today's workout",
          'plan schedule',
          'what is my plan schedule',
          'show my plan schedule',
        ].contains(q) ||
        RegExp(r'^(sets|reps|rest|prescription) for (.+)$').hasMatch(q);
  }

  Future<RoutineAnswer> answer(String request) async {
    final question = _normalize(request);
    final today = [
      "today",
      "today's workout",
      "what is today's workout",
      "show today's workout",
    ].contains(question);
    final schedule = [
      'plan schedule',
      'what is my plan schedule',
      'show my plan schedule',
    ].contains(question);
    final exerciseQuery = RegExp(
      r'^(sets|reps|rest|prescription) for (.+)$',
    ).firstMatch(question);
    if (!today && !schedule && exerciseQuery == null) {
      return const RoutineAnswer(
        RoutineAnswerStatus.unsupported,
        "I can read today's saved workout, the plan schedule, or sets/reps/rest for an exercise. "
        'Technique, medical advice and plan changes are not available here. No AI request was sent.',
      );
    }
    try {
      final facts = await _load();
      if (facts == null) {
        return const RoutineAnswer(
          RoutineAnswerStatus.unavailable,
          'No saved workout plan is available.',
        );
      }
      final day = facts.plan.day(facts.dayIndex);
      if (day == null) {
        return const RoutineAnswer(
          RoutineAnswerStatus.unavailable,
          'The saved workout day is unavailable.',
        );
      }
      final raw = day['exercises'];
      if (raw is! List) {
        return const RoutineAnswer(
          RoutineAnswerStatus.unavailable,
          'The saved prescriptions could not be read.',
        );
      }
      final exercises = <WorkoutExercise>[];
      for (var i = 0; i < raw.length; i++) {
        exercises.add(
          WorkoutExercise.fromJson(
            Map<String, dynamic>.from(raw[i] as Map),
            fallbackId: 'slot_${i + 1}',
          ),
        );
      }
      String content;
      var status = RoutineAnswerStatus.answered;
      if (today) {
        content = exercises.isEmpty
            ? 'No exercises are saved for this day.'
            : [
                for (var i = 0; i < exercises.length; i++)
                  '${i + 1}. ${_prescription(exercises[i])}',
              ].join('\n');
      } else if (schedule) {
        final days = facts.plan.template['days'] as List;
        content =
            'Saved plan sequence (${days.length} days; not calendar appointments):\n${days.map((d) => 'Day ${d['dayIndex']}: ${d['title']}').join('\n')}';
      } else {
        final target = exerciseQuery!.group(2)!;
        final number = RegExp(r'^exercise ([1-9][0-9]*)$').firstMatch(target);
        final matches = number == null
            ? exercises.where((e) => _normalize(e.name) == target).toList()
            : [
                if (int.parse(number.group(1)!) <= exercises.length)
                  exercises[int.parse(number.group(1)!) - 1],
              ];
        if (matches.length != 1) {
          status = RoutineAnswerStatus.clarify;
          content =
              "I couldn't identify one exercise in today's saved workout. Use its number, for example 'rest for exercise 1'.";
        } else {
          final e = matches.single;
          content = switch (exerciseQuery.group(1)) {
            'sets' => '${e.name}: ${e.sets} sets.',
            'reps' => '${e.name}: ${e.repMin}-${e.repMax} reps.',
            'rest' => '${e.name}: ${e.restSeconds} seconds rest.',
            _ => _prescription(e),
          };
        }
      }
      // Re-read rather than serving a cached plan after concurrent edits/completion.
      final current = await _load();
      if (current?.key != facts.key) {
        return const RoutineAnswer(
          RoutineAnswerStatus.stale,
          'Your saved workout changed while I was reading it. Ask again for the current version.',
        );
      }
      final version = facts.plan.planId.split(':').last.substring(0, 8);
      return RoutineAnswer(
        status,
        '$content\n\nSource: saved plan "${facts.plan.name}", version $version, Day ${facts.dayIndex}.',
        sourcePlanId: facts.plan.planId,
      );
    } catch (_) {
      return const RoutineAnswer(
        RoutineAnswerStatus.unavailable,
        'Saved workout data could not be read. No AI request was sent.',
      );
    }
  }

  static String _prescription(WorkoutExercise e) =>
      '${e.name}: ${e.sets} sets, ${e.repMin}-${e.repMax} reps, ${e.restSeconds}s rest.';
}
