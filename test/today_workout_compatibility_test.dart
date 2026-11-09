import 'package:lyva_app/services/personalization_safety.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/screens/today_workout_screen.dart';
import 'package:lyva_app/screens/saved_templates_screen.dart';
import 'package:lyva_app/models/workout_exercise.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/state/providers.dart';

void main() {
  for (final canonical in [false, true]) {
    testWidgets(
      'saved template preview reads ${canonical ? 'canonical' : 'legacy'} prescriptions',
      (tester) async {
        final source = <String, dynamic>{
          'days': [
            {
              'dayName': 'Legs',
              'exercises': [
                {'name': 'Squat', 'sets': 4, 'reps': '8', 'rest': '120s'},
              ],
            },
          ],
        };
        final doc = WorkoutTemplateDoc()
          ..planName = 'Preview Fixture'
          ..createdAt = DateTime(2026)
          ..daysPerWeek = 1
          ..json = jsonEncode(
            canonical ? WorkoutExercise.normalizeTemplate(source) : source,
          );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),
              customTemplatesProvider.overrideWith((ref) async => [doc]),
              premiumAccessProvider.overrideWith(
                (ref) async =>
                    PremiumAccessStatus.subscribed(PremiumTier.premium),
              ),
            ],
            child: const MaterialApp(home: SavedTemplatesScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview Fixture'));
        await tester.pumpAndSettle();
        expect(find.text('Day 1: Legs'), findsOneWidget);
        expect(find.text('4 x 8-8'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'legacy custom plan displays prescriptions and counts selected exercises',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final doc = WorkoutTemplateDoc()
        ..planName = 'Custom'
        ..daysPerWeek = 1
        ..json = jsonEncode({
          'days': [
            {
              'dayName': 'Custom Legs',
              'exercises': [
                {'name': 'Squat', 'sets': 4, 'reps': '8', 'rest': '120s'},
                {'name': 'Lunge', 'sets': 2, 'reps': '12', 'rest': '30s'},
              ],
            },
          ],
        });
      final active = StateProvider<WorkoutTemplateDoc>((ref) => doc);
      final container = ProviderContainer(
        overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),
          latestWorkoutTemplateProvider.overrideWith(
            (ref) async => ref.watch(active),
          ),
          todayWorkoutDayProvider.overrideWith((ref) async => 1),
          userProfileProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TodayWorkoutScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom Legs'), findsOneWidget);
      expect(find.text('4 sets'), findsOneWidget);
      expect(find.text('8-8 reps'), findsOneWidget);
      expect(find.text('120s'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('complete-exercise-1')));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('complete-exercise-2')));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      container.read(active.notifier).state = WorkoutTemplateDoc()
        ..id = 99
        ..planName = 'Another plan'
        ..daysPerWeek = 1
        ..json = doc.json;
      await tester.pumpAndSettle();
      expect(find.text('0/2'), findsOneWidget);
      container.read(active.notifier).state = doc;
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
