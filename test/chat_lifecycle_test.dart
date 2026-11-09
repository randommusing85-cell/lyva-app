import 'package:lyva_app/services/personalization_safety.dart';
import 'package:lyva_app/services/routine_workout_answers.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/ai_insight.dart';
import 'package:lyva_app/models/coach_message.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/repos/user_profile_repo.dart';
import 'package:lyva_app/screens/ai_coaching_screen.dart';
import 'package:lyva_app/services/analytics_service.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/state/providers.dart';

class ControlledCoachRepo extends LyvaRepo {
  final response = Completer<String>();
  int epoch = 0;
  int starts = 0;
  int completions = 0;
  int aiCalls = 0;
  @override
  int get chatGeneration => epoch;
  @override
  Future<bool> beginCoachTurn(
    CoachMessage user,
    CoachMessage placeholder,
    int generation,
  ) async {
    starts++;
    return true;
  }

  @override
  Future<bool> completeCoachTurn(CoachMessage message, int generation) async {
    if (generation != epoch) return false;
    completions++;
    return true;
  }

  @override
  Future<void> clearCoachMessages() async {
    epoch++;
  }

  @override
  Future<Map<String, dynamic>> buildCoachingContext() async => {};
  @override
  Future<List<CoachMessage>> getRecentCoachMessages({int limit = 20}) async =>
      [];
  @override
  Future<List<AiInsight>> getActiveInsights() async => [];
  @override
  Future<String> sendCoachMessage({
    required String userMessage,
    required Map<String, dynamic> context,
    required List<Map<String, String>> recentHistory,
    List<Map<String, dynamic>>? insights,
  }) {
    aiCalls++;
    return response.future;
  }
}

class UsageRepo extends UserProfileRepo {
  int used = 0;
  @override
  Future<void> incrementCoachMessageUsage() async {
    used++;
  }
}

class SilentAnalytics extends Fake implements AnalyticsService {
  @override
  Future<void> logAiCoachSessionStarted() async {}
  @override
  Future<void> logAiCoachMessageSent() async {}
}

class AllowedPremium extends Fake implements PremiumService {
  @override
  Future<PremiumAccessStatus> getAccessStatusAsync(
    UserProfile? profile,
  ) async => PremiumAccessStatus.subscribed(PremiumTier.premium);
}

void main() {
  for (final action in [
    'clear-success',
    'clear-error',
    'navigate-success',
    'navigate-error',
  ]) {
    testWidgets('delayed coach response after $action', (tester) async {
      final repo = ControlledCoachRepo();
      final usage = UsageRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),
            lyvaRepoProvider.overrideWithValue(repo),
            userProfileRepoProvider.overrideWithValue(usage),
            userProfileProvider.overrideWith((ref) async => null),
            premiumAccessProvider.overrideWith(
              (ref) async =>
                  PremiumAccessStatus.subscribed(PremiumTier.premium),
            ),
            premiumServiceProvider.overrideWithValue(AllowedPremium()),
            analyticsProvider.overrideWithValue(SilentAnalytics()),
            coachMessagesProvider.overrideWith((ref) => Stream.value([])),
            aiInsightsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AiCoachingScreen(),
                    ),
                  ),
                  child: const Text('Open coach'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open coach'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump();
      expect(repo.starts, 1);
      if (action.startsWith('clear')) {
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
      } else {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      if (action.endsWith('error')) {
        repo.response.completeError(StateError('offline'));
      } else {
        repo.response.complete('Test reply');
      }
      await tester.pumpAndSettle();
      expect(repo.completions, action.startsWith('clear') ? 0 : 1);
      expect(usage.used, action == 'navigate-success' ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }
  for (final clear in [false, true]) {
    testWidgets(
      'routine coach answer skips AI/usage and respects clear=$clear',
      (tester) async {
        final repo = ControlledCoachRepo();
        final usage = UsageRepo();
        final pending = Completer<WorkoutFacts?>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),
              lyvaRepoProvider.overrideWithValue(repo),
              userProfileRepoProvider.overrideWithValue(usage),
              userProfileProvider.overrideWith((ref) async => null),
              premiumAccessProvider.overrideWith(
                (ref) async =>
                    PremiumAccessStatus.subscribed(PremiumTier.premium),
              ),
              premiumServiceProvider.overrideWithValue(AllowedPremium()),
              analyticsProvider.overrideWithValue(SilentAnalytics()),
              coachMessagesProvider.overrideWith((ref) => Stream.value([])),
              aiInsightsProvider.overrideWith((ref) async => []),
              routineWorkoutAnswersProvider.overrideWithValue(
                RoutineWorkoutAnswers(load: () => pending.future),
              ),
            ],
            child: const MaterialApp(home: AiCoachingScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), "today's workout");
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();
        await tester.pump();
        expect(repo.starts, 1);
        if (clear) {
          await tester.tap(find.byIcon(Icons.delete_outline));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Clear'));
          await tester.pumpAndSettle();
        }
        pending.complete(null);
        await tester.pumpAndSettle();
        expect(repo.aiCalls, 0);
        expect(usage.used, 0);
        expect(repo.completions, clear ? 0 : 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
