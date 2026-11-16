import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/account_access_service.dart';
import 'package:lyva_app/services/callable_account_backend.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15);
  const uid = 'fixture-firebase-user';
  const billingId = '0c7ca340-aed8-423a-a236-b9a82c18c766';
  final denied = throwsA(isA<AccountAccessException>());
  late AccountSession session;
  late String sdkId;
  late int operations;
  late int initializations;
  setUp(() {
    session = AccountSession()
      ..updateFromAuthBridge(uid: uid, recoverable: true);
    sdkId = billingId;
    operations = 0;
    initializations = 0;
  });
  tearDown(() => session.dispose());
  AccountAccessService setup({
    bool clientOptIn = true,
    bool transportOptIn = true,
    String id = billingId,
    String policy = isolatedSandboxBillingPolicy,
  }) {
    return AccountAccessService(
      session: session,
      isolatedSandboxIdentity: clientOptIn,
      now: () => now,
      currentRevenueCatId: () async => sdkId,
      initializeRevenueCat: (id) async {
        initializations++;
        expect(id, billingId);
        // Fixture models already-initialized SDK; do not overwrite its identity.
      },
      backend: CallableAccountBackend(
        isolatedSandboxIdentity: transportOptIn,
        policyRevision: policy,
        now: () => now,
        invoke: (name, body) async {
          expect(body.containsKey('uid'), isFalse);
          expect(body.containsKey('revenueCatId'), isFalse);
          return {
            'schemaVersion': 1,
            'environment': 'sandbox',
            'policyRevision': policy,
            'uid': uid,
            'expiresAtMillis': now
                .add(const Duration(seconds: 60))
                .millisecondsSinceEpoch,
            if (name == 'prepareAccountBilling') ...{
              'action': body['action'],
              'revenueCatId': id,
            } else ...{
              'status': 'active',
              'tier': 'premium',
            },
          };
        },
      ),
    );
  }

  test(
    'explicit local opt-in uses separate SDK ID but Firebase-scoped access',
    () async {
      for (final action in BillingAction.values) {
        final access = await setup().billing(action, () async {
          operations++;
        });
        expect(access.uid, uid);
      }
      expect(operations, 2);
    },
  );
  test(
    'both default production-shaped paths reject the separate identity',
    () async {
      for (final service in [
        setup(clientOptIn: false),
        setup(transportOptIn: false),
      ]) {
        await expectLater(
          service.billing(BillingAction.purchase, () async {
            operations++;
          }),
          denied,
        );
      }
      expect(operations, 0);
      expect(initializations, 0);
    },
  );
  test(
    'isolated policy rejects legacy UID, anonymous ID, invalid UUID and wrong policy',
    () async {
      for (final service in [
        setup(id: uid),
        setup(id: r'$RCAnonymousID:old'),
        setup(id: 'guessable'),
        setup(policy: 'ios-single-tester-sandbox-v1'),
      ]) {
        await expectLater(service.prepareBillingIdentity(), denied);
      }
      expect(initializations, 0);
    },
  );
  test('pre-existing SDK identity mismatch blocks store operation', () async {
    sdkId = uid;
    await expectLater(
      setup().billing(BillingAction.restore, () async {
        operations++;
      }),
      denied,
    );
    expect(operations, 0);
  });
  test('SDK identity switch during purchase prevents access', () async {
    await expectLater(
      setup().billing(BillingAction.purchase, () async {
        sdkId = uid;
      }),
      denied,
    );
  });
  test('Firebase identity switch during purchase prevents access', () async {
    await expectLater(
      setup().billing(BillingAction.purchase, () async {
        session.updateFromAuthBridge(uid: 'other', recoverable: true);
      }),
      denied,
    );
  });
}
