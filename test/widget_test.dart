// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/widgets/empty_state.dart';

void main() {
  testWidgets('workout empty state invokes the create action', (
    WidgetTester tester,
  ) async {
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState.noWorkoutPlan(onCreate: () => created = true),
        ),
      ),
    );
    expect(find.text('No Workout Plan Yet'), findsOneWidget);
    await tester.tap(find.text('Create Workout Plan'));
    expect(created, isTrue);
    expect(tester.takeException(), isNull);
  });
}
