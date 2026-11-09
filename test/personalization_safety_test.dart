import 'package:lyva_app/screens/plans_tab_screen.dart';
import 'package:lyva_app/models/coach_message.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/models/workout_plan_snapshot.dart';
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/repos/user_profile_repo.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/services/personalization_safety.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/widgets/personalization_boundary.dart';
import 'package:lyva_app/utils/postpartum_calculator.dart';

UserProfile fixture() => UserProfile()
  ..age = 30..sex = 'female'..heightCm = 160..weightKg = 60
  ..goal = 'recomp'..level = 'beginner'..equipment = 'gym'
  ..trainingDaysPerWeek = 3..createdAt = DateTime(2026)..updatedAt = DateTime(2026);

void main() {
  test('default denied, clearance alone cannot enable postpartum planning', () {
    expect(PersonalizationDecision.evaluate(null).allowed, false);
    for (final status in ['early', 'late', '', 'unknown']) {
      for (final cleared in [false, true]) {
        final p = fixture()..postPartumStatus = status..medicalClearance = cleared;
        expect(PersonalizationDecision.evaluate(p).allowed, false);
        expect(PostPartumCalculator.isExerciseSafe(p, 'unknown'), false);
        expect(PostPartumCalculator.getExpectedClearanceDate(p), null);
      }
    }
    expect(PostPartumCalculator.getSafeSubstitutions(), isEmpty);
    expect(PersonalizationDecision.evaluate(fixture()).allowed, true);
  });
  test('synthetic urgent and pause are deterministic and never authorize', () {
    expect(PersonalizationDecision.evaluate(fixture(), syntheticUrgent: true, syntheticPause: true).state, PersonalizationState.urgentEscalation);
    expect(PersonalizationDecision.evaluate(fixture(), syntheticPause: true).state, PersonalizationState.pauseForClinician);
  });
  test('refusal makes zero calls; read failure fails closed', () async {
    var calls = 0;
    final gate = PersonalizationSafety(() async => fixture()..postPartumStatus = 'early');
    await expectLater(gate.run(() async => ++calls), throwsA(isA<PersonalizationUnavailable>()));
    expect(calls, 0);
    await expectLater(PersonalizationSafety(() async => throw StateError('read failed')).run(() async => ++calls), throwsStateError);
    expect(calls, 0);
  });
  test('delayed success is discarded after revocation or any profile revision', () async {
    for (final revoke in [false, true]) {
      var p = fixture();
      final started = Completer<void>();
      final response = Completer<String>();
      final result = PersonalizationSafety(() async => p).run(() {started.complete();return response.future;});
      final rejected = expectLater(result, throwsA(isA<PersonalizationUnavailable>()));
      await started.future;
      p = fixture()..updatedAt = DateTime(2026, 2)..postPartumStatus = revoke ? 'early' : 'no';
      response.complete('must not escape');
      await rejected;
    }
  });
  test('request errors propagate and retry rechecks current eligibility', () async {
    var p = fixture(); var calls = 0;
    final gate = PersonalizationSafety(() async => p);
    await expectLater(gate.run(() async {calls++;throw StateError('network');}), throwsStateError);
    p = fixture()..postPartumStatus = 'early';
    await expectLater(gate.run(() async => ++calls), throwsA(isA<PersonalizationUnavailable>()));
    expect(calls, 1);
  });
  testWidgets('revocation removes active content; errors cannot reveal it', (tester) async {
    final changes = StreamController<PersonalizationDecision>();
    await tester.pumpWidget(ProviderScope(overrides: [personalizationDecisionProvider.overrideWith((ref) => changes.stream)], child: const MaterialApp(home: PersonalizationBoundary(child: Text('prescription')))));
    expect(find.text('prescription'), findsNothing);
    changes.add(const PersonalizationDecision(PersonalizationState.standard));await tester.pumpAndSettle();
    expect(find.text('prescription'), findsOneWidget);
    changes.add(const PersonalizationDecision(PersonalizationState.clearanceRequired));await tester.pumpAndSettle();
    expect(find.text('prescription'), findsNothing);
    changes.addError(StateError('read'));await tester.pumpAndSettle();
    expect(find.text('prescription'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    unawaited(changes.close());
  });
  testWidgets('blocked Plans tab describes preserved data rather than missing plans', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.clinicalReviewRequired))),
    ], child: const MaterialApp(home: PlansTabScreen())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your saved records are preserved'), findsOneWidget);
    expect(find.text('Create Plan'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  group('synthetic durable profile and transaction checks', () {
    late Directory dir;late Isar db;late UserProfileRepo profiles;
    setUpAll(() async {await Isar.initializeIsarCore(libraries: {Abi.macosArm64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
        Abi.macosX64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
        Abi.linuxX64: File('vendor/isar_flutter_libs/linux/libisar.so').absolute.path,
        Abi.windowsX64: File('vendor/isar_flutter_libs/windows/isar.dll').absolute.path}, download: false);});
    setUp(() async {dir = await Directory.systemTemp.createTemp('lyva_safety_synthetic_');db = await Isar.open([UserProfileSchema, PrimePlanSchema, CoachMessageSchema],directory: dir.path,name: 'safety', inspector: false);profiles = UserProfileRepo(openDatabase: () async => db);await profiles.saveProfile(fixture());});
    tearDown(() async {await db.close();await dir.delete(recursive: true);});
    test('revocation persists; stale save cannot restore clearance; reopen preserves denial', () async {
      final stale = (await profiles.getProfile())!..medicalClearance = true;
      final fresh = (await profiles.getProfile())!..postPartumStatus = 'early'..medicalClearance = false;
      await profiles.saveProfile(fresh);
      await expectLater(profiles.saveProfile(stale), throwsStateError);
      await db.close();db = await Isar.open([UserProfileSchema, PrimePlanSchema, CoachMessageSchema],directory: dir.path,name: 'safety', inspector: false);
      expect(PersonalizationDecision.evaluate(await profiles.getProfile()).allowed, false);
      expect((await profiles.getProfile())!.medicalClearance, false);
    });
    test('deleted profile cannot be recreated by an old operation', () async {
      final stale = (await profiles.getProfile())!;
      await profiles.deleteProfile();
      await expectLater(profiles.saveProfile(stale), throwsStateError);
      expect(await profiles.getProfile(), null);
    });
    test('late coach answer and error cannot be saved after revocation', () async {
      final repo = LyvaRepo(openDatabase: () async => db);
      final user = CoachMessage()..ts = DateTime.now()..role = 'user'..content = 'synthetic';
      final reply = CoachMessage()..ts = DateTime.now()..role = 'assistant'..content = ''..isLoading = true;
      expect(await repo.beginCoachTurn(user, reply, repo.chatGeneration), true);
      final p = (await profiles.getProfile())!..postPartumStatus = 'early'..medicalClearance = false;
      await profiles.saveProfile(p);
      reply.content = 'late generated guidance';reply.isLoading = false;
      expect(await repo.completeCoachTurn(reply, repo.chatGeneration), false);
      reply.content = 'late error';
      expect(await repo.completeCoachTurn(reply, repo.chatGeneration), false);
      expect((await db.coachMessages.get(reply.id))!.content, '');
    });
    test('saved workout start and resume cannot bypass postpartum denial', () async {
      final doc = WorkoutTemplateDoc()..planName = 'Synthetic'..daysPerWeek = 1..json = '{"days":[{"exercises":[]}]}';
      final plan = WorkoutPlanSnapshot.capture(doc);
      final p = (await profiles.getProfile())!..postPartumStatus = 'early'..medicalClearance = true;
      await profiles.saveProfile(p);
      final repo = LyvaRepo(openDatabase: () async => db);
      await expectLater(repo.startTodaySession(dayIndex: 1, plan: plan), throwsA(isA<PersonalizationUnavailable>()));
      await expectLater(repo.beginGuidedSession(dayIndex: 1, plan: plan), throwsA(isA<PersonalizationUnavailable>()));
    });
    test('persisting a plan after revocation fails inside write transaction', () async {
      final p = (await profiles.getProfile())!..postPartumStatus = 'early';await profiles.saveProfile(p);
      final repo = LyvaRepo(openDatabase: () async => db);
      await expectLater(repo.upsertPlan(PrimePlan()), throwsA(isA<PersonalizationUnavailable>()));
      expect(await db.primePlans.count(), 0);
    });
  });
}
