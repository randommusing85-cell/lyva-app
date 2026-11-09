import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/cycle_calendar_data.dart';
import 'package:lyva_app/models/cycle_log.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/widgets/cycle_calendar.dart';

void main() {
  UserProfile profile() => UserProfile()
    ..trackCycle = true
    ..cycleLength = 31;
  CycleLog log(int day, String type) => CycleLog()
    ..ts = DateTime(2026, 1, day)
    ..eventType = type;
  CycleCalendarData data({
    bool estimate = false,
    List<CycleLog>? records,
    DateTime? today,
  }) => CycleCalendarData(
    profile: profile(),
    logs:
        records ??
        [
          log(-61, 'period_start'),
          log(-30, 'period_start'),
          log(1, 'period_start'),
          log(3, 'symptom')
            ..symptomType = 'cramps'
            ..severity = 3
            ..notes = 'Synthetic note',
        ],
    today: today ?? DateTime(2026, 1, 3),
    showEstimate: estimate,
  );
  test('recorded start never implies intervening bleeding or no symptoms', () {
    final d = data();
    expect(d.events(DateTime(2026, 1, 2)), isEmpty);
    expect(d.summary(DateTime(2026, 1, 2)), 'No events logged');
    expect(d.projectedStart, isNull);
  });
  test(
    'one projection uses logged intervals, never default length or rolling missed cycles',
    () {
      expect(data(estimate: true).projectedStart, DateTime(2026, 2, 1));
      expect(
        data(estimate: true, today: DateTime(2026, 2, 2)).projectedStart,
        isNull,
      );
      expect(data(estimate: true, records: []).projectedStart, isNull);
      expect(
        data(estimate: true, records: [log(20, 'period_start')]).projectedStart,
        isNull,
      );
    },
  );
  test('opt-out and invalid length suppress all presentation', () {
    final p = profile()..trackCycle = false;
    final d = CycleCalendarData(
      profile: p,
      logs: [log(1, 'period_start')],
      today: DateTime(2026, 1, 3),
      showEstimate: true,
    );
    expect(d.events(DateTime(2026, 1, 1)), isEmpty);
    expect(d.projectedStart, isNull);
    p.trackCycle = true;
    p.cycleLength = 0;
    expect(d.projectedStart, isNull);
  });
  test(
    'multiple same-day records and duplicates preserve details without shifting estimate',
    () {
      final d = data(
        estimate: true,
        records: [
          log(1, 'period_start'),
          log(1, 'period_start'),
          log(1, 'spotting'),
        ],
      );
      expect(d.events(DateTime(2026, 1, 1)).length, 3);
      expect(d.projectedStart, isNull);
    },
  );
  Future<void> render(
    WidgetTester tester, {
    bool reduced = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(child: CycleCalendar(data: data())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'month week day retain selection and progressively show details',
    (tester) async {
      await render(tester);
      expect(find.text('January 2026'), findsOneWidget);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Sat, Jan 3'), findsOneWidget);
      await tester.tap(find.text('Sat, Jan 3'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic note'), findsOneWidget);
      expect(find.text('Reported severity: 3/5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('month navigation handles year rollover', (tester) async {
    await render(tester);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2025'), findsOneWidget);
  });
  testWidgets('reduced motion keeps fades static and large text fits', (
    tester,
  ) async {
    await render(tester, reduced: true, scale: 2);
    for (final widget in tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    )) {
      expect(widget.duration, Duration.zero);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'date semantics include facts, selection and action independent of color',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await render(tester);
        final node = find.bySemanticsLabel('January 3, 2026. cramps logged');
        expect(node, findsOneWidget);
        expect(
          tester
              .getSemantics(node)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          true,
        );
      } finally {
        handle.dispose();
      }
    },
  );
  testWidgets(
    'today selection follows date refresh but historical selection stays put',
    (tester) async {
      Future<void> show(DateTime today) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CycleCalendar(data: data(today: today)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(DateTime(2026, 1, 31));
      await show(DateTime(2026, 2, 1));
      expect(find.text('February 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await show(DateTime(2026, 2, 2));
      expect(find.text('January 2026'), findsOneWidget);
    },
  );
  testWidgets('logged categories have different visible non-color markers', (
    tester,
  ) async {
    await render(tester);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
  });
}
