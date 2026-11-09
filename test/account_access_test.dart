import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/account_access_service.dart';

final clock = DateTime.utc(2026, 11, 3);

class Backend implements AccountBackend {
  String uid = 'a';
  bool binding = true;
  int prepares = 0;
  int checks = 0;
  Completer<BillingPermit>? pendingPermit;
  Completer<VerifiedPremiumAccess?>? pendingAccess;
  VerifiedPremiumAccess? access = VerifiedPremiumAccess(
    'a',
    VerifiedTier.premium,
    clock.add(const Duration(minutes: 1)),
  );
  @override
  Future<BillingPermit> prepareBilling(BillingAction action) async {
    prepares++;
    if (!binding) throw const AccountAccessException('Recovery required');
    return pendingPermit?.future ??
        Future.value(
          BillingPermit(
            uid: uid,
            revenueCatId: uid,
            action: action,
            policyRevision: 'synthetic-reviewed',
            expiresAt: clock.add(const Duration(minutes: 1)),
          ),
        );
  }

  @override
  Future<VerifiedPremiumAccess?> verifyPremium() async {
    checks++;
    return pendingAccess?.future ?? Future.value(access);
  }
}

void main() {
  late AccountSession session;
  late Backend backend;
  late AccountAccessService service;
  late String sdkId;
  late int operations;
  setUp(() {
    session = AccountSession()
      ..updateFromAuthBridge(uid: 'a', recoverable: true);
    backend = Backend();
    sdkId = 'a';
    operations = 0;
    service = AccountAccessService(
      session: session,
      backend: backend,
      currentRevenueCatId: () async => sdkId,
      now: () => clock,
    );
  });
  tearDown(() => session.dispose());
  Future<void> operation() async {
    operations++;
  }

  final denied = throwsA(isA<AccountAccessException>());

  test(
    'recoverable account plus server permit and entitlement completes purchase and restore',
    () async {
      for (final action in BillingAction.values) {
        expect(
          (await service.billing(action, operation)).tier,
          VerifiedTier.premium,
        );
      }
      expect(operations, 2);
      expect(backend.checks, 2);
    },
  );
  test(
    'signed out or anonymous identity cannot purchase restore or access premium',
    () async {
      for (final uid in [null, 'guest']) {
        session.updateFromAuthBridge(uid: uid);
        await expectLater(service.verifyPremium(), denied);
        for (final action in BillingAction.values) {
          await expectLater(service.billing(action, operation), denied);
        }
      }
      expect(operations, 0);
      expect(backend.prepares, 0);
      expect(backend.checks, 0);
    },
  );
  test(
    'legacy anonymous purchase identity preserved and recovery required',
    () async {
      sdkId = r'$RCAnonymousID:synthetic';
      await expectLater(
        service.billing(BillingAction.restore, operation),
        denied,
      );
      expect(sdkId, r'$RCAnonymousID:synthetic');
      expect(operations, 0);
    },
  );
  test(
    'different signed-in RevenueCat customer blocks without switching or merging',
    () async {
      sdkId = 'b';
      await expectLater(
        service.billing(BillingAction.purchase, operation),
        denied,
      );
      expect(sdkId, 'b');
      expect(operations, 0);
    },
  );
  test('unknown binding blocks even when SDK ID matches', () async {
    backend.binding = false;
    await expectLater(
      service.billing(BillingAction.restore, operation),
      denied,
    );
    expect(operations, 0);
  });
  test(
    'reinstallation can restore only after externally verified same-account binding',
    () async {
      sdkId = r'$RCAnonymousID:new-install';
      await expectLater(
        service.billing(BillingAction.restore, operation),
        denied,
      );
      // Simulates a separately reviewed recovery adapter, not an automatic merge.
      sdkId = 'a';
      expect(
        (await service.billing(BillingAction.restore, operation)).uid,
        'a',
      );
      expect(operations, 1);
    },
  );
  test('SDK success with missing server entitlement does not unlock', () async {
    backend.access = null;
    await expectLater(
      service.billing(BillingAction.purchase, operation),
      denied,
    );
    expect(operations, 1);
  });
  test('wrong-user and expired grants denied', () async {
    for (final access in [
      VerifiedPremiumAccess(
        'b',
        VerifiedTier.premium,
        clock.add(const Duration(days: 1)),
      ),
      VerifiedPremiumAccess('a', VerifiedTier.premium, clock),
    ]) {
      backend.access = access;
      await expectLater(service.verifyPremium(), denied);
    }
  });
  test('account switch before permit response prevents SDK purchase', () async {
    backend.pendingPermit = Completer();
    final future = service.billing(BillingAction.purchase, operation);
    final check = expectLater(future, denied);
    session.updateFromAuthBridge(uid: 'b', recoverable: true);
    backend.pendingPermit!.complete(
      BillingPermit(
        uid: 'a',
        revenueCatId: 'a',
        action: BillingAction.purchase,
        policyRevision: 'test',
        expiresAt: clock.add(const Duration(minutes: 1)),
      ),
    );
    await check;
    expect(operations, 0);
  });
  test('switch away and back invalidates delayed access', () async {
    backend.pendingAccess = Completer();
    final future = service.verifyPremium();
    final check = expectLater(future, denied);
    session.updateFromAuthBridge(uid: 'b', recoverable: true);
    session.updateFromAuthBridge(uid: 'a', recoverable: true);
    backend.pendingAccess!.complete(backend.access);
    await check;
  });
  test(
    'switch during native billing invalidates delayed success without profile writes',
    () async {
      final started = Completer<void>(), response = Completer<void>();
      final future = service.billing(BillingAction.restore, () {
        started.complete();
        return response.future;
      });
      final check = expectLater(future, denied);
      await started.future;
      session.updateFromAuthBridge(uid: 'b', recoverable: true);
      response.complete();
      await check;
      expect(backend.checks, 0);
    },
  );
  test(
    'concurrent restore rejected and failed attempt permits safe retry',
    () async {
      final started = Completer<void>(), response = Completer<void>();
      final future = service.billing(BillingAction.restore, () {
        started.complete();
        return response.future;
      });
      final check = expectLater(future, denied);
      await started.future;
      await expectLater(
        service.billing(BillingAction.purchase, operation),
        denied,
      );
      response.completeError(StateError('sensitive SDK details'));
      await check;
      expect(
        (await service.billing(BillingAction.restore, operation)).uid,
        'a',
      );
    },
  );
  test(
    'identity initialization runs only after an accepted server permit',
    () async {
      var setups = 0;
      service = AccountAccessService(
        session: session,
        backend: backend,
        currentRevenueCatId: () async => sdkId,
        now: () => clock,
        initializeRevenueCat: (uid) async {
          setups++;
          expect(uid, 'a');
        },
      );
      backend.binding = false;
      await expectLater(service.prepareBillingIdentity(), denied);
      expect(setups, 0);
      backend.binding = true;
      await service.prepareBillingIdentity();
      expect(setups, 1);
      expect(operations, 0);
    },
  );
  test('account change during SDK setup prevents native purchase', () async {
    service = AccountAccessService(
      session: session,
      backend: backend,
      currentRevenueCatId: () async => sdkId,
      now: () => clock,
      initializeRevenueCat: (_) async {
        session.updateFromAuthBridge(uid: 'b', recoverable: true);
      },
    );
    await expectLater(
      service.billing(BillingAction.purchase, operation),
      denied,
    );
    expect(operations, 0);
    expect(service.billingInFlight, false);
  });
  test(
    'disabled backend remains unavailable for signed-in identities',
    () async {
      service = AccountAccessService(
        session: session,
        backend: const UnavailableAccountBackend(),
        currentRevenueCatId: () async => sdkId,
      );
      await expectLater(service.verifyPremium(), denied);
      await expectLater(
        service.billing(BillingAction.restore, operation),
        denied,
      );
      expect(operations, 0);
    },
  );
}
