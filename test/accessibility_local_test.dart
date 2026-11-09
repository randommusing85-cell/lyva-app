import 'package:lyva_app/services/personalization_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/theme/app_theme.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/screens/plan_review_screen.dart';
import 'package:lyva_app/screens/weekly_review_screen.dart';
import 'package:lyva_app/screens/meal_picker_screen.dart';
import 'package:lyva_app/screens/guided_workout_screen.dart';
import 'meal_picker_test.dart' show PickerRepo;
import 'guided_workout_screen_test.dart' show RunnerRepo;
import 'weekly_review_screen_test.dart' show FakeReview;

void main() {
  Future<void> render(
    WidgetTester tester,
    Widget child, {
    PickerRepo? meals,
    RunnerRepo? runner,
    FakeReview? review,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
            personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),
          activePlanProvider.overrideWith((ref) async => null),
          if (meals != null) lyvaRepoProvider.overrideWithValue(meals),
          if (runner != null) lyvaRepoProvider.overrideWithValue(runner),
          if (review != null)
            weeklyReviewServiceProvider.overrideWithValue(review),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('plan review supports narrow viewport and doubled text', (
    tester,
  ) async {
    await render(tester, const PlanReviewScreen());
    await scan(tester);
  });
  testWidgets('weekly review supports narrow viewport and doubled text', (
    tester,
  ) async {
    await render(tester, const WeeklyReviewScreen(), review: FakeReview());
    await tester.scrollUntilVisible(
      find.text('Load current week evidence'),
      200,
    );
    await tester.tap(find.text('Load current week evidence'));
    await tester.pumpAndSettle();
    await scan(tester);
  });
  testWidgets('meal portion form supports narrow viewport and doubled text', (
    tester,
  ) async {
    await render(tester, const MealPickerScreen(), meals: PickerRepo());
    await tester.scrollUntilVisible(find.text('Earlier meal'), 200);
    await tester.tap(find.text('Earlier meal'));
    await tester.pumpAndSettle();
    await scan(tester);
  });
  testWidgets('guided workout supports narrow viewport and doubled text', (
    tester,
  ) async {
    await render(
      tester,
      const GuidedWorkoutScreen(sessionId: 17),
      runner: RunnerRepo(),
    );
    await scan(tester);
  });
  test('interactive theme foreground/background contrast is at least 4.5', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05));
    }

    final theme = AppTheme.lightTheme;
    expect(
      contrast(theme.colorScheme.primary, theme.colorScheme.onPrimary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(
        theme.textButtonTheme.style!.foregroundColor!.resolve({})!,
        AppColors.background,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });
  testWidgets(
    'visible review controls expose labels and Android-sized touch targets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await render(tester, const PlanReviewScreen());
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    },
  );
  testWidgets('weekly load failure exposes a live status region', (
    tester,
  ) async {
    await render(
      tester,
      const WeeklyReviewScreen(),
      review: FakeReview()..fail = true,
    );
    await tester.scrollUntilVisible(
      find.text('Load current week evidence'),
      200,
    );
    await tester.tap(find.text('Load current week evidence'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
      findsOneWidget,
    );
  });
}
