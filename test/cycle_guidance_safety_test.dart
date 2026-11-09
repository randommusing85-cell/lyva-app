import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/utils/cycle_calculator.dart';
import 'package:lyva_app/widgets/cycle_phase_card.dart';

void main() {
  test('calendar buckets cannot prescribe intensity', () {
    for (final phase in CyclePhase.values) {
      expect(CycleCalculator.getIntensityMultiplier(phase), 1);
      expect(
        CycleCalculator.getTrainingGuidance(phase),
        contains('do not determine'),
      );
    }
  });
  testWidgets(
    'home card shows recorded experience, not inferred hormones or peak strength',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) async => UserProfile()..trackCycle = true,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CyclePhaseCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cycle records'), findsOneWidget);
      expect(find.text('Peak Week'), findsNothing);
      expect(find.textContaining('strongest'), findsNothing);
    },
  );
}
