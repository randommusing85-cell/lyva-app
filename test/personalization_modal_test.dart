import 'package:lyva_app/widgets/generating_overlay.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/models/workout_template_doc.dart';
import 'package:lyva_app/screens/workout_plan_screen.dart';
// Synthetic regressions; no real network or health data.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/personalization_safety.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/widgets/personalization_boundary.dart';

class RefusingRepo extends LyvaRepo {
  final Completer<Map<String, dynamic>>? pending;
  final Object error;
  RefusingRepo({this.pending, this.error = const PersonalizationUnavailable('Synthetic refusal')});
  @override
  Future<WorkoutTemplateDoc?> getLatestWorkoutTemplate() async => null;
  @override
  Future<Map<String, dynamic>> generateWorkoutTemplate({required UserProfile profile, required String sex,
    required String level, required String equipment, required int daysPerWeek, int sessionDurationMin = 60,
    String? constraints, List<String>? injuries}) async {
    if (pending != null) return pending!.future;
    throw error;
  }
}
void main() {
  testWidgets('workout generation reports expected refusal without an unhandled error', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final p = UserProfile()..age = 30..sex = 'female'..heightCm = 160..weightKg = 60
      ..goal = 'recomp'..level = 'beginner'..equipment = 'gym'..trainingDaysPerWeek = 3
      ..createdAt = DateTime(2026)..updatedAt = DateTime(2026);
    await tester.pumpWidget(ProviderScope(overrides: [
      personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard))),
      userProfileProvider.overrideWith((ref) async => p),lyvaRepoProvider.overrideWithValue(RefusingRepo()),
    ], child: const MaterialApp(home: WorkoutPlanScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate'));await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Synthetic refusal'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
  });

  for (final sheet in [false, true]) {
    testWidgets('${sheet ? "sheet" : "dialog"} revocation removes prescription and never revives it', (tester) async {
      final changes = StreamController<PersonalizationDecision>();
      final nav = GlobalKey<NavigatorState>();
      final results = <bool?>[];
      await tester.pumpWidget(ProviderScope(overrides: [personalizationDecisionProvider.overrideWith((ref) => changes.stream)],
        child: MaterialApp(navigatorKey: nav, home: PersonalizationBoundary(child: Builder(builder: (context) => Scaffold(
          body: TextButton(onPressed: () {
            Widget preview(BuildContext ctx) => AlertDialog(content: const Text('Synthetic prescription'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept'))]);
            final result = sheet ? showPersonalizationBottomSheet<bool>(context: context, builder: preview)
                : showPersonalizationDialog<bool>(context: context, builder: preview);
            result.then(results.add);
          }, child: const Text('Preview'))))))));
      changes.add(const PersonalizationDecision(PersonalizationState.standard));await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));await tester.pumpAndSettle();
      expect(find.text('Synthetic prescription'), findsOneWidget);
      // An unrelated route must not be popped by revocation behind it.
      unawaited(nav.currentState!.push<void>(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Tracking route')))));
      await tester.pumpAndSettle();
      changes.add(const PersonalizationDecision(PersonalizationState.clearanceRequired));await tester.pumpAndSettle();
      expect(find.text('Tracking route'), findsOneWidget);
      nav.currentState!.pop();await tester.pumpAndSettle();
      expect(find.text('Synthetic prescription'), findsNothing);expect(find.text('Accept'), findsNothing);
      changes.add(const PersonalizationDecision(PersonalizationState.standard));await tester.pumpAndSettle();
      expect(find.text('Synthetic prescription'), findsNothing);
      await tester.tap(find.text('Close preview'));await tester.pumpAndSettle();
      expect(results, [null]);expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();unawaited(changes.close());
    });
  }
  test('second preflight prevents dispatch from the earlier stale snapshot', () async {
    final old = UserProfile()..updatedAt = DateTime(2026)..postPartumStatus = 'no';
    final revoked = UserProfile()..updatedAt = DateTime(2026, 2)..postPartumStatus = 'early';
    var reads = 0, calls = 0;
    await expectLater(PersonalizationSafety(() async => reads++ == 0 ? old : revoked).run(() async => ++calls), throwsA(isA<PersonalizationUnavailable>()));
    expect(calls, 0);
  });
  test('final dispatch window remains: response rejected but transmission cannot be recalled', () async {
    final old = UserProfile()..updatedAt = DateTime(2026)..postPartumStatus = 'no';
    final revoked = UserProfile()..updatedAt = DateTime(2026, 2)..postPartumStatus = 'early';
    var reads = 0, calls = 0;
    await expectLater(PersonalizationSafety(() async => reads++ < 2 ? old : revoked).run(() async => ++calls), throwsA(isA<PersonalizationUnavailable>()));
    expect(calls, 1);
  });

  testWidgets('a rapid denial and regrant cannot revive an open modal', (tester) async {
    final changes = StreamController<PersonalizationDecision>();
    await tester.pumpWidget(ProviderScope(overrides: [personalizationDecisionProvider.overrideWith((ref) => changes.stream)], child: MaterialApp(home: PersonalizationBoundary(child: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => showPersonalizationDialog<void>(context: ctx, builder: (_) => const AlertDialog(content: Text('Prescription'))), child: const Text('Open'))))))));
    changes.add(const PersonalizationDecision(PersonalizationState.standard));await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));await tester.pumpAndSettle();
    changes.add(const PersonalizationDecision(PersonalizationState.clearanceRequired));
    changes.add(const PersonalizationDecision(PersonalizationState.standard));
    await tester.pumpAndSettle();
    expect(find.text('Prescription'), findsNothing);expect(find.text('Close preview'), findsOneWidget);
    await tester.tap(find.text('Close preview'));await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();unawaited(changes.close());
  });
  for (final accept in [false, true]) {
    testWidgets('allowed confirmation returns $accept without altering navigation', (tester) async {
      final results = <bool?>[];
      await tester.pumpWidget(ProviderScope(overrides: [personalizationDecisionProvider.overrideWith((ref) => Stream.value(const PersonalizationDecision(PersonalizationState.standard)))], child: MaterialApp(home: PersonalizationBoundary(child: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () {
        showPersonalizationDialog<bool>(context: ctx, builder: (dialog) => AlertDialog(actions: [TextButton(onPressed: () => Navigator.pop(dialog, accept), child: const Text('Decision'))])).then(results.add);
      }, child: const Text('Open'))))))));
      await tester.pumpAndSettle();await tester.tap(find.text('Open'));await tester.pumpAndSettle();
      await tester.tap(find.text('Decision'));await tester.pumpAndSettle();expect(results, [accept]);
      expect(find.text('Open'), findsOneWidget);expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('dismissed revoked generating overlay discards late success', (tester) async {
    final changes = StreamController<PersonalizationDecision>();
    final response = Completer<String>();final results = <String?>[];final errors = <Object>[];
    await tester.pumpWidget(ProviderScope(overrides: [personalizationDecisionProvider.overrideWith((ref) => changes.stream)], child: MaterialApp(home: PersonalizationBoundary(child: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () {
      showGeneratingOverlay<String>(context: ctx, title: 'Synthetic generation', task: () => response.future).then(results.add, onError: (Object error) {errors.add(error);});
    }, child: const Text('Start'))))))));
    changes.add(const PersonalizationDecision(PersonalizationState.standard));await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));await tester.pump();
    changes.add(const PersonalizationDecision(PersonalizationState.clearanceRequired));await tester.pumpAndSettle();
    expect(find.text('Synthetic generation'), findsNothing);await tester.tap(find.text('Close preview'));await tester.pumpAndSettle();
    response.complete('late');await tester.pumpAndSettle();
    expect(results, isEmpty);expect(errors.single, isA<PersonalizationUnavailable>());expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();unawaited(changes.close());
  });
  test('second preflight read failure sends nothing', () async {
    final old = UserProfile()..updatedAt = DateTime(2026);var reads = 0, calls = 0;
    await expectLater(PersonalizationSafety(() async {if (reads++ == 0) return old;throw StateError('synthetic read failure');}).run(() async => ++calls), throwsStateError);
    expect(calls, 0);
  });

  for (final leave in [false, true]) {
    testWidgets('pending generation error is contained when navigation=$leave', (tester) async {
      tester.view.physicalSize = const Size(900, 1400);tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      final response = Completer<Map<String, dynamic>>();
      final nav = GlobalKey<NavigatorState>();final changes = StreamController<PersonalizationDecision>();
      final p = UserProfile()..age = 30..sex = 'female'..heightCm = 160..weightKg = 60
        ..goal = 'recomp'..level = 'beginner'..equipment = 'gym'..trainingDaysPerWeek = 3
        ..createdAt = DateTime(2026)..updatedAt = DateTime(2026);
      await tester.pumpWidget(ProviderScope(overrides: [
        personalizationDecisionProvider.overrideWith((ref) => changes.stream),
        userProfileProvider.overrideWith((ref) async => p),lyvaRepoProvider.overrideWithValue(RefusingRepo(pending: response)),
      ], child: MaterialApp(navigatorKey: nav, home: const WorkoutPlanScreen())));
      changes.add(const PersonalizationDecision(PersonalizationState.standard));await tester.pumpAndSettle();
      await tester.tap(find.text('Generate'));await tester.pump();
      if (leave) {
        unawaited(nav.currentState!.push<void>(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Tracking route')))));
        changes.add(const PersonalizationDecision(PersonalizationState.clearanceRequired));await tester.pumpAndSettle();
      }
      response.completeError(StateError('synthetic sensitive provider detail'));
      await tester.pumpAndSettle();expect(tester.takeException(), isNull);
      expect(find.textContaining('synthetic sensitive provider detail'), findsNothing);
      if (leave) {expect(find.text('Tracking route'), findsOneWidget);} else {
        expect(find.text('Workout generation could not complete. No new plan was saved.'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();unawaited(changes.close());
    });
  }
}
