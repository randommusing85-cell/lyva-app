import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/services/routine_workout_answers.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/screens/workout_facts_screen.dart';

WorkoutTemplateDoc fixture({int sets = 3, bool duplicate = false}) =>
    WorkoutTemplateDoc()
      ..id = 1
      ..planName = 'Saved fixture'
      ..daysPerWeek = 2
      ..json = jsonEncode({
        'days': [
          {
            'dayIndex': 1,
            'title': 'First day',
            'exercises': [
              {
                'exerciseId': 'a',
                'name': 'Fixture move',
                'sets': sets,
                'reps': '6-8',
                'rest': '90s',
              },
              if (duplicate)
                {
                  'exerciseId': 'b',
                  'name': 'Fixture move',
                  'sets': 2,
                  'reps': '10',
                  'rest': '60s',
                },
            ],
          },
          {
            'dayIndex': 2,
            'title': 'Second day',
            'exercises': [
              {
                'exerciseId': 'c',
                'name': 'Other move',
                'sets': 4,
                'reps': '5',
                'rest': '120s',
              },
            ],
          },
        ],
      });

class FactsRepo extends LyvaRepo {
  WorkoutTemplateDoc current = fixture();
  WorkoutSessionDoc? last;
  int aiCalls = 0;
  @override
  Future<WorkoutTemplateDoc?> getLatestWorkoutTemplate() async => current;
  @override
  Future<WorkoutSessionDoc?> getLatestWorkoutSession({String? planId}) async =>
      last;
  @override
  Future<String> sendCoachMessage({
    required String userMessage,
    required Map<String, dynamic> context,
    required List<Map<String, String>> recentHistory,
    List<Map<String, dynamic>>? insights,
  }) async {
    aiCalls++;
    throw StateError('Unexpected AI');
  }
}

void main() {
  test(
    'supported facts route locally with exact prescriptions and source revision',
    () async {
      final repo = FactsRepo();
      final service = RoutineWorkoutAnswers.fromRepo(repo);
      for (final pair in {
        "today's workout": '3 sets, 6-8 reps, 90s rest',
        'sets for fixture move': '3 sets',
        'reps for exercise 1': '6-8 reps',
        'rest for exercise 1': '90 seconds rest',
        'plan schedule': 'Day 2: Second day',
      }.entries) {
        final result = await service.answer(pair.key);
        expect(result.status, RoutineAnswerStatus.answered);
        expect(result.text, contains(pair.value));
        expect(
          result.sourcePlanId,
          WorkoutPlanSnapshot.capture(repo.current).planId,
        );
      }
      expect(repo.aiCalls, 0);
    },
  );
  test(
    'duplicate names and missing targets ask for a number without guessing',
    () async {
      final repo = FactsRepo()..current = fixture(duplicate: true);
      final service = RoutineWorkoutAnswers.fromRepo(repo);
      expect(
        (await service.answer('rest for fixture move')).status,
        RoutineAnswerStatus.clarify,
      );
      expect(
        (await service.answer('rest for exercise 99')).status,
        RoutineAnswerStatus.clarify,
      );
      expect(
        (await service.answer('rest for exercise 2')).text,
        contains('60 seconds'),
      );
      expect(repo.aiCalls, 0);
    },
  );
  test(
    'unsupported guidance does not read data or trigger an AI fallback',
    () async {
      var reads = 0;
      final service = RoutineWorkoutAnswers(
        load: () async {
          reads++;
          return null;
        },
      );
      for (final text in [
        'How do I perform this?',
        'Is this safe after surgery?',
        'change my plan',
        'hello',
      ]) {
        expect(
          (await service.answer(text)).status,
          RoutineAnswerStatus.unsupported,
        );
      }
      expect(reads, 0);
    },
  );
  test('missing, corrupt and read failures return unavailable', () async {
    expect(
      (await RoutineWorkoutAnswers(
        load: () async => null,
      ).answer('today')).status,
      RoutineAnswerStatus.unavailable,
    );
    expect(
      (await RoutineWorkoutAnswers(
        load: () async => throw StateError('private error'),
      ).answer('today')).text,
      isNot(contains('private error')),
    );
    final repo = FactsRepo()..current = (fixture()..json = '{broken');
    expect(
      (await RoutineWorkoutAnswers.fromRepo(repo).answer('today')).status,
      RoutineAnswerStatus.unavailable,
    );
  });
  test(
    'concurrent plan edit/deletion never returns the old answer as current',
    () async {
      for (final removed in [false, true]) {
        var reads = 0;
        final service = RoutineWorkoutAnswers(
          load: () async {
            reads++;
            if (reads == 2 && removed) return null;
            return WorkoutFacts(
              WorkoutPlanSnapshot.capture(fixture(sets: reads == 1 ? 3 : 5)),
              1,
            );
          },
        );
        expect(
          (await service.answer('today')).status,
          RoutineAnswerStatus.stale,
        );
      }
    },
  );
  test('each request reloads plan and current progression', () async {
    final repo = FactsRepo();
    final service = RoutineWorkoutAnswers.fromRepo(repo);
    expect((await service.answer('today')).text, contains('3 sets'));
    repo.current = fixture(sets: 5);
    expect((await service.answer('today')).text, contains('5 sets'));
    repo.last = WorkoutSessionDoc()
      ..dayIndex = 1
      ..completed = true;
    expect(
      (await service.answer('today')).text,
      contains('Other move: 4 sets'),
    );
    expect(repo.aiCalls, 0);
  });
  testWidgets('guest facts screen works without account, premium or network', (
    tester,
  ) async {
    final repo = FactsRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lyvaRepoProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: WorkoutFactsScreen()),
      ),
    );
    await tester.tap(find.text("Today's workout"));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 sets, 6-8 reps, 90s rest'), findsOneWidget);
    expect(repo.aiCalls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('late local result after navigation is ignored safely', (
    tester,
  ) async {
    final pending = Completer<WorkoutFacts?>();
    final service = RoutineWorkoutAnswers(load: () => pending.future);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [routineWorkoutAnswersProvider.overrideWithValue(service)],
        child: const MaterialApp(home: WorkoutFactsScreen()),
      ),
    );
    await tester.tap(find.text("Today's workout"));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Text('Elsewhere')));
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Elsewhere'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
