import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/account_access_service.dart';
import 'package:lyva_app/services/callable_account_backend.dart';
import 'package:lyva_app/services/firebase_account_backend.dart';

void main() {
  final now = DateTime.utc(2026, 11, 9);
  final denied = throwsA(isA<AccountAccessException>());
  Map<String, Object?> response() => {
    'schemaVersion': 1,
    'environment': 'sandbox',
    'policyRevision': 'reviewed-v1',
    'uid': 'a',
    'revenueCatId': 'a',
    'action': 'restore',
    'status': 'active',
    'tier': 'premium',
    'expiresAtMillis': now
        .add(const Duration(minutes: 1))
        .millisecondsSinceEpoch,
  };
  CallableAccountBackend backend(Object? data) => CallableAccountBackend(
    policyRevision: 'reviewed-v1',
    now: () => now,
    invoke: (_, _) async => data,
  );
  test('default build has no active Firebase backend', () {
    expect(createFirebaseAccountBackend(), isA<UnavailableAccountBackend>());
  });
  test(
    'only action and wire version sent; UID and entitlement never sent',
    () async {
      final calls = <String>[];
      final service = CallableAccountBackend(
        policyRevision: 'reviewed-v1',
        now: () => now,
        invoke: (name, data) async {
          calls.add(name);
          expect(
            data,
            name == 'prepareAccountBilling'
                ? {'schemaVersion': 1, 'action': 'restore'}
                : {'schemaVersion': 1},
          );
          return response();
        },
      );
      expect((await service.prepareBilling(BillingAction.restore)).uid, 'a');
      expect((await service.verifyPremium())?.tier, VerifiedTier.premium);
      expect(calls, ['prepareAccountBilling', 'verifyAccountPremium']);
    },
  );
  test('inactive response explicitly denies access', () async {
    expect(
      await backend({...response(), 'status': 'inactive'}).verifyPremium(),
      isNull,
    );
  });
  test(
    'malformed, unknown version/policy/status/tier and expired leases denied',
    () async {
      for (final data in <Object?>[
        null,
        [],
        {},
        {...response(), 'schemaVersion': 2},
        {...response(), 'environment': null},
        {...response(), 'environment': 'production'},
        {...response(), 'policyRevision': 'unreviewed'},
        {...response(), 'status': 'pending'},
        {...response(), 'tier': 'trial'},
        {...response(), 'uid': ''},
        {...response(), 'expiresAtMillis': '2026-11-09'},
        {...response(), 'expiresAtMillis': now.millisecondsSinceEpoch},
        {
          ...response(),
          'expiresAtMillis': now
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
        },
      ]) {
        await expectLater(backend(data).verifyPremium(), denied);
      }
    },
  );
  test('permit for different identity or action denied', () async {
    for (final data in [
      {...response(), 'revenueCatId': 'b'},
      {...response(), 'action': 'purchase'},
    ]) {
      await expectLater(
        backend(data).prepareBilling(BillingAction.restore),
        denied,
      );
    }
  });
  test('transport error is sanitized and never grants access', () async {
    final service = CallableAccountBackend(
      policyRevision: 'reviewed-v1',
      invoke: (_, _) async => throw StateError('sensitive token'),
    );
    try {
      await service.verifyPremium();
      fail('must deny');
    } on AccountAccessException catch (error) {
      expect(error.message, isNot(contains('sensitive')));
    }
  });
}
