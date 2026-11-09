import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/utils/cycle_calculator.dart';
import 'package:lyva_app/state/providers.dart' hide CyclePhase;
import 'package:lyva_app/screens/cycle_insights_screen.dart';

void main() {
  UserProfile profile() => UserProfile()
    ..trackCycle = true
    ..lastPeriodDate = DateTime(2026, 1, 1)
    ..cycleLength = 28
    ..periodDuration = 5;
  test(
    'retired APIs never infer phases or rolling cycles from profile dates',
    () {
      for (final length in [0, 21, 28, 35]) {
        final p = profile()..cycleLength = length;
        for (var day = 1; day <= 70; day++) {
          expect(
            CycleCalculator.getCurrentPhase(p, at: DateTime(2026, 1, day)),
            isNull,
          );
          expect(
            CycleCalculator.getCurrentCycleDay(p, at: DateTime(2026, 1, day)),
            isNull,
          );
          expect(
            CycleCalculator.getDaysUntilNextPeriod(
              p,
              at: DateTime(2026, 1, day),
            ),
            isNull,
          );
        }
      }
    },
  );
  test('compatibility provider never publishes physiological phase', () async {
    final container = ProviderContainer(
      overrides: [userProfileProvider.overrideWith((ref) async => profile())],
    );
    addTearDown(container.dispose);
    expect(await container.read(currentCyclePhaseProvider.future), isNull);
  });
  testWidgets(
    'opt-out hides cycle insights without querying saved predictions',
    (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) async => profile()..trackCycle = false,
            ),
            latestCyclePredictionProvider.overrideWith((ref) async {
              reads++;
              return null;
            }),
          ],
          child: const MaterialApp(home: CycleInsightsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Cycle tracking is off'), findsOneWidget);
      expect(reads, 0);
      expect(find.text('AI Prediction'), findsNothing);
    },
  );
}
