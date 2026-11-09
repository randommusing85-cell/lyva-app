import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/state/providers.dart';
import 'package:lyva_app/widgets/premium_gate.dart';

void main() {
  testWidgets('protected content is absent until access is verified', (
    tester,
  ) async {
    final result = Completer<PremiumAccessStatus>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [premiumAccessProvider.overrideWith((ref) => result.future)],
        child: const MaterialApp(
          home: Scaffold(
            body: PremiumGate(
              feature: PremiumFeature.aiCoaching,
              child: Text('Protected action'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Protected action'), findsNothing);
    result.complete(PremiumAccessStatus.subscribed(PremiumTier.premium));
    await tester.pumpAndSettle();
    expect(find.text('Protected action'), findsOneWidget);
  });
  testWidgets('access errors keep protected content unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumAccessProvider.overrideWith(
            (ref) async => throw StateError('offline'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PremiumGate(
              feature: PremiumFeature.aiCoaching,
              child: Text('Protected action'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Protected action'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
