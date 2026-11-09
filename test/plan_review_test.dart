import 'package:lyva_app/widgets/recorded_week_card.dart';
import 'package:lyva_app/models/recorded_week.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/screens/plan_review_screen.dart';
import 'package:lyva_app/state/providers.dart';

void main() {
  testWidgets('week route reads recorded facts without generating a revision', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activePlanProvider.overrideWith((ref) async => null),
          recordedWeekProvider.overrideWith((ref, anchor) async {
            reads++;
            return RecordedWeek.resolve(
              anchor: anchor,
              now: anchor,
              sessions: [],
              checkIns: [],
            );
          }),
        ],
        child: const MaterialApp(home: PlanReviewScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review my week'));
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(
      find.textContaining('0 day(s) with completed workouts'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not mean you were inactive'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'guest can inspect missing data and change categories without remote services',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [activePlanProvider.overrideWith((ref) async => null)],
          child: const MaterialApp(home: PlanReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved nutrition targets are unavailable'), findsOneWidget);
      expect(find.textContaining('verified rationale'), findsOneWidget);
      await tester.tap(find.text('Something changed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My health or comfort changed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot assess symptoms'), findsOneWidget);
      expect(find.textContaining('No revision is created'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'load failures are explicit and retry does not fabricate targets',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activePlanProvider.overrideWith((ref) async {
              calls++;
              throw StateError('synthetic');
            }),
          ],
          child: const MaterialApp(home: PlanReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved plan could not be loaded.'), findsOneWidget);
      await tester.tap(find.text('Retry plan'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('2200'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
