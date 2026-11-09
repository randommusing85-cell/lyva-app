import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/recorded_week.dart';
import 'package:lyva_app/models/weekly_review.dart';
import 'package:lyva_app/services/weekly_review_service.dart';
import 'package:lyva_app/screens/weekly_review_screen.dart';

class FakeReview extends WeeklyReviewService {
  int accepts = 0, loads = 0;
  bool fail = false;
  Completer<WeeklyReviewView>? delayed;
  WeeklyReviewView value(String status) {
    final date = DateTime(2026, 11, 3);
    return WeeklyReviewView(
      WeeklyReview()
        ..id = 1
        ..weekStart = DateTime(2026, 11, 2)
        ..createdAt = date
        ..sourceRevision = 'test'
        ..decisionToken = 'token'
        ..status = status,
      RecordedWeek.resolve(anchor: date, now: date, sessions: [], checkIns: []),
      'No nutrition targets saved.',
      status == 'stale',
    );
  }

  @override
  Future<WeeklyReviewView> prepare() async {
    loads++;
    if (fail) throw StateError('synthetic');
    return delayed == null ? value('draft') : delayed!.future;
  }

  @override
  Future<WeeklyReviewView> decide(
    int id,
    String revision, {
    required bool accept,
  }) async {
    if (accept) accepts++;
    return value(accept ? 'accepted' : 'declined');
  }
}

void main() {
  Future<void> show(WidgetTester tester, FakeReview fake) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [weeklyReviewServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: WeeklyReviewScreen()),
      ),
    );
  }

  testWidgets(
    'opening does not prepare or accept; acknowledgement requires explicit review',
    (tester) async {
      final fake = FakeReview();
      await show(tester, fake);
      expect(fake.loads, 0);
      expect(fake.accepts, 0);
      await tester.tap(find.text('Load current week evidence'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        FilledButton,
        'Acknowledge no-change review',
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(fake.accepts, 1);
      expect(find.text('Status: accepted'), findsOneWidget);
      expect(find.text('Withdraw acknowledgement'), findsOneWidget);
    },
  );
  testWidgets('failure clears evidence and can retry without accepting', (
    tester,
  ) async {
    final fake = FakeReview()..fail = true;
    await show(tester, fake);
    await tester.tap(find.text('Load current week evidence'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Review could not be completed'),
      findsOneWidget,
    );
    expect(find.text('Acknowledge no-change review'), findsNothing);
    fake.fail = false;
    await tester.tap(find.text('Load current week evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Status: draft'), findsOneWidget);
    expect(fake.accepts, 0);
  });
  testWidgets(
    'late load after navigation cannot accept or update disposed screen',
    (tester) async {
      final fake = FakeReview()..delayed = Completer<WeeklyReviewView>();
      await show(tester, fake);
      await tester.tap(find.text('Load current week evidence'));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      fake.delayed!.complete(fake.value('draft'));
      await tester.pumpAndSettle();
      expect(fake.accepts, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
