import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/repos/user_profile_repo.dart';
import 'package:lyva_app/screens/onboarding_screen.dart';
import 'package:lyva_app/services/analytics_service.dart';
import 'package:lyva_app/state/providers.dart';

class OnboardingRepo extends UserProfileRepo {
  UserProfile? saved;
  @override
  Future<UserProfile?> getProfile() async => saved;
  @override
  Future<void> saveProfile(UserProfile profile) async {
    saved = profile;
  }
}

class OnboardingAnalytics extends Fake implements AnalyticsService {
  @override
  Future<void> logOnboardingStarted() async {}
  @override
  Future<void> logOnboardingCompleted({
    required int age,
    required String sex,
    required String goal,
    required bool tracksCycle,
    required bool isPostPartum,
  }) async {}
}

void main() {
  Future<OnboardingRepo> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = OnboardingRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepoProvider.overrideWithValue(repo),
          analyticsProvider.overrideWithValue(OnboardingAnalytics()),
        ],
        child: MaterialApp(
          home: const OnboardingScreen(),
          routes: {'/home': (_) => const Scaffold(body: Text('Guest home'))},
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> choose(WidgetTester tester, String field, String option) async {
    final target = find.byKey(ValueKey('onboarding-$field'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  Future<void> goals(WidgetTester tester) async {
    await choose(tester, 'goal', 'Build muscle');
    await choose(tester, 'level', 'Beginner (0-1 years)');
    await choose(tester, 'equipment', 'Bodyweight Only');
    await choose(tester, 'trainingDays', '3 days');
    await next(tester);
  }

  Future<void> basics(WidgetTester tester) async {
    for (final pair in {
      'name': 'Alex',
      'age': '30',
      'height': '165',
      'weight': '60',
    }.entries) {
      await tester.enterText(
        find.byKey(ValueKey('onboarding-${pair.key}')),
        pair.value,
      );
    }
    await choose(tester, 'sex', 'Female');
    await next(tester);
  }

  testWidgets(
    'goals and availability require deliberate choices; measurements start blank',
    (tester) async {
      final repo = await open(tester);
      await next(tester);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(repo.saved, isNull);
      expect(find.text('Choose your availability'), findsOneWidget);
      await goals(tester);
      expect(find.text('Step 2 of 3'), findsOneWidget);
      for (final field in ['age', 'height', 'weight']) {
        expect(
          tester
              .widget<TextFormField>(find.byKey(ValueKey('onboarding-$field')))
              .controller!
              .text,
          isEmpty,
        );
      }
    },
  );
  testWidgets(
    'guest can defer weekdays and reach orientation without generation or account',
    (tester) async {
      final repo = await open(tester);
      await goals(tester);
      await basics(tester);
      await choose(tester, 'postPartumStatus', 'No');
      await tester.ensureVisible(find.text('Save and continue'));
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(repo.saved!.scheduledDaysList, isEmpty);
      expect(repo.saved!.trainingDaysPerWeek, 3);
      expect(repo.saved!.goal, 'bulk');
      expect(repo.saved!.sex, 'female');
      expect(repo.saved!.trackCycle, isFalse);
      expect(find.text('Your first session'), findsOneWidget);
      await tester.tap(find.text('Explore basic tracking'));
      await tester.pumpAndSettle();
      expect(find.text('Guest home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'back preserves input and postpartum question cannot default to clearance',
    (tester) async {
      final repo = await open(tester);
      await goals(tester);
      await basics(tester);
      await tester.ensureVisible(find.text('Save and continue'));
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(repo.saved, isNull);
      expect(
        find.text('Please answer the postpartum question.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Back'));
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('onboarding-name')),
            )
            .controller!
            .text,
        'Alex',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('onboarding-weight')),
            )
            .controller!
            .text,
        '60',
      );
    },
  );
  testWidgets('fixed weekdays must be selected before continuing', (tester) async {
    final repo=await open(tester);
    await tester.tap(find.text('Choose weekdays later')); await tester.pumpAndSettle();
    await goals(tester);
    expect(find.text('Step 1 of 3'),findsOneWidget); expect(repo.saved,isNull);
    expect(find.text('Choose your weekdays or choose them later.'),findsOneWidget);
  });
  testWidgets('postpartum tracking can save missing clearance without inferring it', (tester) async {
    final repo=await open(tester); await goals(tester); await basics(tester);
    await choose(tester,'postPartumStatus','Yes (0-12 weeks)');
    await tester.ensureVisible(find.text('Save and continue')); await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();
    expect(repo.saved, isNotNull);
    expect(repo.saved!.deliveryDate, isNull);
    expect(repo.saved!.medicalClearance, isFalse);
    expect(repo.saved!.postPartumStatus, isNot('no'));
  });
}
