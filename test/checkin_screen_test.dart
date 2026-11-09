import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/workout_session_doc.dart';
import 'package:lyva_app/screens/trends_screen.dart';
import 'package:lyva_app/screens/advanced_analytics_screen.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/screens/checkin_screen.dart';
import 'package:lyva_app/services/checkin_preferences.dart';
import 'package:lyva_app/services/step_tracking_service.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/widgets/dual_line_chart.dart';
class CheckRepo extends LyvaRepo {
  List<CheckIn> saved = [];
  bool fail = false;
  Completer<void>? pending;
  DateTime? last;
  @override Future<List<WorkoutSessionDoc>> getSessionsInDateRange(DateTime start, DateTime end) async => [];
  @override Future<List<CheckIn>> getCheckInsInDateRange(DateTime start, DateTime end) async => [];
  @override Future<DateTime?> latestMeasurementDate() async => last;
  @override Future<void> addCheckIn(CheckIn c) async { if (pending != null) await pending!.future; if (fail) throw StateError('disk'); saved.add(c); }
}
class Prefs extends CheckInPreferences {
  String value = 'manual'; bool fail = false;
  @override Future<String> read() async => value;
  @override Future<void> save(String next) async { if (fail) throw StateError('disk'); value = next; }
}
class NoSteps extends StepTrackingService { @override Future<bool> canReadSteps() async => false; }
void main() {
  Future<void> render(WidgetTester tester, CheckRepo repo, Prefs prefs) async {
    tester.view.physicalSize = const Size(900, 1800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [lyvaRepoProvider.overrideWithValue(repo),
      checkInPreferencesProvider.overrideWithValue(prefs), stepTrackingServiceProvider.overrideWithValue(NoSteps())], child: MaterialApp(
        home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CheckInScreen())), child: const Text('Open check-in')))))));
    await tester.tap(find.text('Open check-in')); await tester.pumpAndSettle();
  }
  testWidgets('guest can save mood-only with null measurements and no step grant', (tester) async {
    final repo = CheckRepo(); await render(tester, repo, Prefs());
    expect(find.byKey(const ValueKey('checkin-Weight')), findsNothing);
    await tester.tap(find.text('Good')); await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(repo.saved.single.moodScore, 4); expect(repo.saved.single.weightKg, isNull); expect(repo.saved.single.stepsToday, isNull);
  });
  testWidgets('empty entry rejected; zero steps is a real entry', (tester) async {
    final repo = CheckRepo(); await render(tester, repo, Prefs());
    await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(repo.saved, isEmpty); expect(find.text('Add at least one item to your check-in.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('checkin-Steps Today')), '0');
    await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(repo.saved.single.stepsToday, 0); expect(repo.saved.single.weightKg, isNull);
  });
  testWidgets('measurement opt-in rejects nonfinite input and preserves valid entry after save failure', (tester) async {
    final repo = CheckRepo()..fail = true; await render(tester, repo, Prefs());
    await tester.tap(find.text('Add measurements (optional)')); await tester.pumpAndSettle();
    final weight = find.byKey(const ValueKey('checkin-Weight'));
    await tester.enterText(weight, 'NaN'); await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(find.text('Invalid'), findsOneWidget); expect(repo.saved, isEmpty);
    await tester.enterText(weight, '70.5'); await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(find.textContaining('Check-in was not saved'), findsOneWidget);
    expect(tester.widget<TextFormField>(weight).controller!.text, '70.5');
    repo.fail = false; await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(repo.saved.single.weightKg, 70.5); expect(repo.saved.single.waistCm, isNull);
  });
  testWidgets('weekly preference controls default expansion without requiring measurements', (tester) async {
    final repo = CheckRepo()..last = DateTime.now(); final prefs = Prefs()..value = 'weekly';
    await render(tester, repo, prefs); expect(find.byKey(const ValueKey('checkin-Weight')), findsNothing);
    await tester.tap(find.text('Weekly')); await tester.pumpAndSettle();
    await tester.tap(find.text('Daily').last); await tester.pumpAndSettle();
    expect(prefs.value, 'daily'); expect(find.byKey(const ValueKey('checkin-Weight')), findsOneWidget);
    await tester.tap(find.text('Good')); await tester.tap(find.text('Save Check-in')); await tester.pumpAndSettle();
    expect(repo.saved.single.weightKg, isNull);
  });
  testWidgets('pending save cannot be double submitted', (tester) async {
    final repo = CheckRepo()..pending = Completer<void>(); await render(tester, repo, Prefs());
    await tester.tap(find.text('Good')); await tester.tap(find.text('Save Check-in')); await tester.pump();
    expect(find.text('Save Check-in'), findsNothing); repo.pending!.complete(); await tester.pumpAndSettle();
    expect(repo.saved.length, 1);
  });
  testWidgets('measurement chart handles gaps and all-missing data without zero points', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DualLineChart(data1: [70, null, 71], data2: [null, 80, null], color1: Colors.blue, color2: Colors.green))));
    await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DualLineChart(data1: [null], data2: [null], color1: Colors.blue, color2: Colors.green))));
    expect(find.text('No data yet'), findsOneWidget);
  });
  testWidgets('trends renders mood-only data without casting null or removing calendar', (tester) async {
    final c = CheckIn()..ts = DateTime.now()..moodScore = 3;
    await tester.pumpWidget(ProviderScope(overrides: [
      lyvaRepoProvider.overrideWithValue(CheckRepo()),
      latestCheckInsStreamProvider.overrideWith((ref) => Stream.value([c])),
      thisWeekSessionsProvider.overrideWith((ref) async => []),
      userProfileProvider.overrideWith((ref) async => null),
      todayMealsStreamProvider.overrideWith((ref) => Stream.value([])),
      activePlanProvider.overrideWith((ref) async => null),
      weeklyStepsProvider.overrideWith((ref) async => {}),
      latestCyclePredictionProvider.overrideWith((ref) async => null),
      premiumAccessProvider.overrideWith((ref) async => throw StateError('Disabled fixture')),
    ], child: const MaterialApp(home: TrendsScreen())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('${DateTime.now().day}'), findsWidgets);
    await tester.ensureVisible(find.text('Optional measurement and step charts'));
    await tester.tap(find.text('Optional measurement and step charts')); await tester.pumpAndSettle();
    expect(find.text('No weight recorded'), findsOneWidget);
  });
  testWidgets('advanced analytics handles independent missing weight and waist records', (tester) async {
    final records = [CheckIn()..ts = DateTime.now()..moodScore = 3,
      CheckIn()..ts = DateTime.now().subtract(const Duration(days: 1))..weightKg = 70,
      CheckIn()..ts = DateTime.now().subtract(const Duration(days: 2))..waistCm = 80];
    await tester.pumpWidget(ProviderScope(overrides: [
      lyvaRepoProvider.overrideWithValue(CheckRepo()),
      extendedCheckInsProvider(30).overrideWith((ref) async => records),
      monthlyMacroTotalsProvider.overrideWith((ref) async => []),
      activePlanProvider.overrideWith((ref) async => null),
      userProfileProvider.overrideWith((ref) async => null),
    ], child: const MaterialApp(home: AdvancedAnalyticsScreen())));
    await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
    expect(find.textContaining('gaps are unrecorded'), findsOneWidget);
  });

}
