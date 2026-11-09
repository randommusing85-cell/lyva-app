import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/account_access_service.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/state/providers.dart';
import 'account_access_test.dart' show Backend, clock;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('each paid tier uses its exact product identifier, never price inference', () {
    expect(PremiumService.productIdFor(PremiumTier.essentials, yearly: false),
        'lyva_essentials_monthly');
    expect(PremiumService.productIdFor(PremiumTier.essentials, yearly: true),
        'lyva_essentials_annually');
    expect(PremiumService.productIdFor(PremiumTier.premium, yearly: false),
        'lyva_premium_monthly');
    expect(PremiumService.productIdFor(PremiumTier.premium, yearly: true),
        'lyva_premium_annually');
    for (final yearly in [false, true]) {
      expect(() => PremiumService.productIdFor(PremiumTier.none, yearly: yearly),
          throwsArgumentError);
    }
  });

  test('billing initialization failure does not block guest startup', () async {
    var sdkCalls = 0;
    const channel = MethodChannel('purchases_flutter');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async {
      sdkCalls++;
      throw PlatformException(
        code: 'unavailable',
        message: 'private native details',
      );
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    expect(
      await PremiumService.initRevenueCat(
        apiKey: 'goog_YOUR_ANDROID_REVENUECAT_KEY',
      ),
      isFalse,
    );
    expect(sdkCalls, 0);
    expect(
      await PremiumService.initRevenueCat(apiKey: 'synthetic-test-config'),
      isFalse,
    );
    expect(sdkCalls, 1);
  });
  test(
    'account switch invalidates Riverpod premium state without changing profile',
    () async {
      final session = AccountSession()
        ..updateFromAuthBridge(uid: 'a', recoverable: true);
      final backend = Backend();
      final profile = UserProfile()
        ..weightKg = 75
        ..premiumTrialStart = DateTime(2026);
      final service = PremiumService(
        account: AccountAccessService(
          session: session,
          backend: backend,
          currentRevenueCatId: () async => 'a',
          now: () => clock,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          accountSessionProvider.overrideWith((ref) => session),
          premiumServiceProvider.overrideWithValue(service),
          userProfileProvider.overrideWith((ref) async => profile),
          customerInfoStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(premiumAccessProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        (await container.read(premiumAccessProvider.future)).hasAccess,
        isTrue,
      );
      session.updateFromAuthBridge(uid: 'b', recoverable: true);
      expect(
        (await container.read(premiumAccessProvider.future)).hasAccess,
        isFalse,
      );
      expect(profile.weightKg, 75);
      expect(profile.premiumTrialStart, DateTime(2026));
    },
  );
  test(
    'signed-out premium/trial flags cannot grant access or invoke SDK restore',
    () async {
      var sdkCalls = 0;
      const channel = MethodChannel('purchases_flutter');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async {
        sdkCalls++;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final profile = UserProfile()
        ..isPremium = true
        ..premiumTier = 'premium'
        ..premiumTrialStart = DateTime.now();
      final trial = profile.premiumTrialStart;
      final service = PremiumService();
      expect((await service.getAccessStatusAsync(profile)).hasAccess, isFalse);
      expect(service.getAccessStatus(profile).hasAccess, isFalse);
      await expectLater(
        service.restorePurchases(),
        throwsA(isA<AccountAccessException>()),
      );
      expect(sdkCalls, 0);
      expect(profile.premiumTrialStart, trial);
      expect(profile.isPremium, isTrue);
    },
  );
  test('only server-verified tier grants its intended features', () async {
    final session = AccountSession()
      ..updateFromAuthBridge(uid: 'a', recoverable: true);
    addTearDown(session.dispose);
    final backend = Backend();
    final service = PremiumService(
      account: AccountAccessService(
        session: session,
        backend: backend,
        currentRevenueCatId: () async => 'a',
        now: () => clock,
      ),
    );
    for (final tier in VerifiedTier.values) {
      backend.access = VerifiedPremiumAccess(
        'a',
        tier,
        clock.add(const Duration(minutes: 1)),
      );
      final status = await service.getAccessStatusAsync(UserProfile());
      expect(status.canAccessFeature(PremiumFeature.exportData), isTrue);
      expect(
        status.canAccessFeature(PremiumFeature.aiCoaching),
        tier == VerifiedTier.premium,
      );
    }
    session.updateFromAuthBridge();
    expect(
      (await service.getAccessStatusAsync(UserProfile())).hasAccess,
      isFalse,
    );
  });
  test(
    'signed-in local trial remains untrusted pending product policy',
    () async {
      final session = AccountSession()
        ..updateFromAuthBridge(uid: 'a', recoverable: true);
      addTearDown(session.dispose);
      final backend = Backend()..access = null;
      final service = PremiumService(
        account: AccountAccessService(
          session: session,
          backend: backend,
          currentRevenueCatId: () async => 'a',
          now: () => clock,
        ),
      );
      expect(
        (await service.getAccessStatusAsync(
          UserProfile()..premiumTrialStart = DateTime.now(),
        )).hasAccess,
        isFalse,
      );
    },
  );
}
