import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/prime_plan.dart';
import 'package:lyva_app/utils/plateau_detector.dart';

void main() {
  final now = DateTime(2026, 11, 3, 12);
  PrimePlan plan({String phase = 'deficit', int elapsed = 30}) => PrimePlan()
    ..createdAt = now.subtract(const Duration(days: 60))
    ..phase = phase
    ..phaseStartedAt = DateTime(now.year, now.month, now.day - elapsed, 18);
  CheckIn entry(
    int age, {
    double weight = 70,
    double waist = 80,
    int hour = 8,
  }) => CheckIn()
    ..id = age + 1
    ..ts = DateTime(now.year, now.month, now.day - age, hour)
    ..weightKg = weight
    ..waistCm = waist
    ..stepsToday = 0;
  List<CheckIn> days() => List.generate(21, entry);
  PlateauStatus analyze(List<CheckIn> entries, {PrimePlan? current}) =>
      PlateauDetector.analyze(
        checkIns: entries,
        currentPlan: current ?? plan(),
        now: now,
      );

  test('unsorted calendar windows use their actual dates', () {
    final entries = List.generate(
      21,
      (age) => entry(
        age,
        weight: age < 7
            ? 68
            : age < 14
            ? 69
            : 70,
      ),
    );
    final result = analyze(entries.reversed.toList());
    expect(result.week1Avg, 68);
    expect(result.week2Avg, 69);
    expect(result.week3Avg, 70);
    expect(result.weightChangeKg, 2);
    expect(result.isPlateaued, isFalse);
  });
  test('stable 21 calendar days meet existing criteria', () {
    expect(analyze(days()).isPlateaued, isTrue);
  });
  test('many duplicate entries in one day cannot satisfy minimum', () {
    final result = analyze(List.generate(30, (i) => entry(0, hour: i % 12)));
    expect(result.isPlateaued, isFalse);
    expect(result.summary, contains('1/14'));
  });
  test('latest valid daily observation wins regardless of input order', () {
    final entries = [...days(), entry(0, weight: 140, hour: 6)];
    expect(analyze(entries).week1Avg, 70);
    expect(analyze(entries.reversed.toList()).week1Avg, 70);
  });
  test('equal timestamps choose highest persisted ID consistently', () {
    final newer = entry(0, weight: 77)..id = 100;
    expect(analyze([...days(), newer]).week1Avg, 71);
    expect(analyze([newer, ...days()]).week1Avg, 71);
  });
  test('missing full week cannot borrow observations from another week', () {
    final result = analyze(
      days().where((e) => now.difference(e.ts).inDays < 14).toList(),
    );
    expect(result.isPlateaued, isFalse);
    expect(result.week3Avg, isNull);
  });
  test(
    'missing days remain missing; existing 14-day minimum spans all windows',
    () {
      final entries = List.generate(14, (i) => entry(i < 7 ? i : i + 7));
      expect(analyze(entries).isPlateaued, isFalse); // middle week absent
      entries[7] = entry(10);
      expect(analyze(entries).isPlateaued, isTrue);
      expect(analyze(entries.sublist(1)).isPlateaued, isFalse);
    },
  );
  test('old, future and invalid weights do not create observations', () {
    final entries = [
      entry(30),
      entry(-1),
      entry(0, weight: double.nan),
      entry(1, weight: double.infinity),
      entry(2, weight: 0),
      entry(3, weight: -1),
    ];
    final result = analyze(entries);
    expect(result.isPlateaued, isFalse);
    expect(result.summary, contains('0/14'));
  });
  for (final phase in ['deficit', 'resumed_deficit']) {
    test('$phase enforces the existing 21 calendar-day wait', () {
      expect(
        analyze(days(), current: plan(phase: phase, elapsed: 20)).isPlateaued,
        isFalse,
      );
      expect(
        analyze(days(), current: plan(phase: phase, elapsed: 21)).isPlateaued,
        isTrue,
      );
    });
  }
  test('pre-resume maintenance observations are excluded', () {
    final result = analyze(
      days(),
      current: plan(phase: 'resumed_deficit', elapsed: 3),
    );
    expect(result.week2Avg, isNull);
    expect(result.week3Avg, isNull);
    expect(result.isPlateaued, isFalse);
  });
  test('refeed and unknown phases never trigger plateau', () {
    expect(
      analyze(days(), current: plan(phase: 'refeed')).isPlateaued,
      isFalse,
    );
    expect(
      analyze(days(), current: plan(phase: 'maintenance')).isPlateaued,
      isFalse,
    );
  });
  test(
    'waist reduction prevents plateau; missing waist is not zero evidence',
    () {
      final entries = List.generate(
        21,
        (age) => entry(age, waist: age < 7 ? 77 : 80),
      );
      expect(analyze(entries).isPlateaued, isFalse);
      expect(
        analyze(
          days().map((e) => e..waistCm = double.nan).toList(),
        ).isPlateaued,
        isTrue,
      );
    },
  );
  test(
    'calendar timer handles midnight and month boundary, not elapsed hours',
    () {
      final current = plan(phase: 'refeed')
        ..phaseStartedAt = DateTime(2026, 10, 31, 23, 59);
      expect(
        PlateauDetector.daysRemainingInRefeed(
          current,
          now: DateTime(2026, 11, 1, 0, 1),
        ),
        13,
      );
      expect(
        PlateauDetector.daysRemainingInRefeed(
          current,
          now: DateTime(2026, 11, 14),
        ),
        0,
      );
      expect(
        PlateauDetector.daysRemainingInRefeed(
          current,
          now: DateTime(2026, 10, 30),
        ),
        14,
      );
    },
  );
  test(
    'future phase start fails closed and legacy plan uses creation date',
    () {
      expect(analyze(days(), current: plan(elapsed: -1)).isPlateaued, isFalse);
      expect(
        analyze(days(), current: plan()..phaseStartedAt = null).isPlateaued,
        isTrue,
      );
    },
  );
}
