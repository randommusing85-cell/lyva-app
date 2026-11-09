import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/cycle_log.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/screens/cycle_insights_screen.dart';
import 'package:lyva_app/state/providers.dart';

class FailedCycleRepo extends LyvaRepo {
  int attempts = 0;
  int edits = 0;
  @override
  Future<bool> updateCycleLogDetails(
    CycleLog original, {
    required String? notes,
    required int? severity,
  }) async {
    edits++;
    throw StateError("synthetic edit failure");
  }

  @override
  Future<void> saveTrackedCycleLog(CycleLog log) async {
    attempts++;
    throw StateError('synthetic failure');
  }
}

void main() {
  Future<void> render(
    WidgetTester tester, {
    bool failLoad = false,
    List<CycleLog> records = const [],
    FailedCycleRepo? repo,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => UserProfile()..trackCycle = true,
          ),
          premiumAccessProvider.overrideWith(
            (ref) async => PremiumAccessStatus.subscribed(PremiumTier.premium),
          ),
          cycleLogsProvider.overrideWith(
            (ref) => failLoad
                ? Stream<List<CycleLog>>.error(StateError('synthetic offline'))
                : Stream.value(records),
          ),
          latestCyclePredictionProvider.overrideWith(
            (ref) => throw StateError('Must not query AI predictions'),
          ),
          if (repo != null) lyvaRepoProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: CycleInsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'recorded-only default does not query prediction and distinguishes missing data',
    (tester) async {
      await render(tester);
      expect(find.text('Cycle tracker'), findsOneWidget);
      expect(find.text('Generate Prediction'), findsNothing);
      final toggle = find.byType(SwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'record load failure has explicit retry without inferred empty records',
    (tester) async {
      await render(tester, failLoad: true);
      expect(find.text('Retry records'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('failed symptom save retains selection for retry', (
    tester,
  ) async {
    final repo = FailedCycleRepo();
    await render(tester, repo: repo);
    final symptom = find.text('cramps');
    await tester.ensureVisible(symptom);
    await tester.tap(symptom);
    await tester.pumpAndSettle();
    final save = find.text('Log symptom today');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.attempts, 1);
    expect(find.textContaining('Could not save.'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'cramps'))
          .selected,
      true,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('edit failure retains draft and cancel leaves record untouched', (
    tester,
  ) async {
    final repo = FailedCycleRepo();
    final log = CycleLog()
      ..ts = DateTime.now()
      ..eventType = 'symptom'
      ..symptomType = 'cramps'
      ..severity = 2
      ..notes = 'original';
    await render(tester, repo: repo, records: [log]);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    final edit = find.text('Edit recorded details');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'draft');
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();
    expect(repo.edits, 1);
    expect(
      find.text('Could not save. Your edits are still here.'),
      findsOneWidget,
    );
    expect(find.text('draft'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(log.notes, 'original');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
