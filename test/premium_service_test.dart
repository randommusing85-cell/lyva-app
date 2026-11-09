import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/account_access_service.dart';
import 'package:lyva_app/services/premium_service.dart';
import 'package:lyva_app/state/providers.dart';
import 'account_access_test.dart' show Backend, clock;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'each paid tier uses its exact product identifier, never price inference',
    () {
      expect(
        PremiumService.productIdFor(PremiumTier.essentials, yearly: false),
        'lyva_essentials_monthly',
      );
      expect(
        PremiumService.productIdFor(PremiumTier.essentials, yearly: true),
        'lyva_essentials_annually',
      );
      expect(
        PremiumService.productIdFor(PremiumTier.premium, yearly: false),
        'lyva_premium_monthly',
      );
      expect(
        PremiumService.productIdFor(PremiumTier.premium, yearly: true),
        'lyva_premium_annually',
      );
      for (final yearly in [false, true]) {
        expect(
          () => PremiumService.productIdFor(PremiumTier.none, yearly: yearly),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'native setup uses authenticated ID and refuses configured other accounts',
    () async {
      final calls = <MethodCall>[];
      var configured = false;
      var currentId = 'a';
      const channel = MethodChannel('purchases_flutter');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'isConfigured') return configured;
        if (call.method == 'getAppUserID') return currentId;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      for (final id in ['', r'$RCAnonymousID:legacy']) {
        expect(
          await PremiumService.initRevenueCat(apiKey: 'test', appUserId: id),
          false,
        );
      }
      expect(calls, isEmpty);
      expect(
        await PremiumService.initRevenueCat(apiKey: 'test', appUserId: 'a'),
        true,
      );
      expect(
        calls
            .singleWhere((c) => c.method == 'setupPurchases')
            .arguments['appUserId'],
        'a',
      );
      calls.clear();
      configured = true;
      currentId = 'b';
      expect(
        await PremiumService.initRevenueCat(apiKey: 'test', appUserId: 'a'),
        false,
      );
      expect(calls.map((c) => c.method), ['isConfigured', 'getAppUserID']);
    },
  );
  test(
    'expired verification lease denies access and every premium feature',
    () {
      final status = PremiumAccessStatus.subscribed(
        PremiumTier.premium,
        validUntil: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(status.hasAccess, false);
      for (final feature in PremiumFeature.values) {
        expect(status.canAccessFeature(feature), false);
      }
    },
  );
  test(
    'verified catalog enforces store period and rejects generic test products before SDK calls',
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
      StoreProduct product(String id, String? period) => StoreProduct(
        id,
        '',
        '',
        1,
        'SYNTHETIC',
        'USD',
        subscriptionPeriod: period,
      );
      for (final entry in PremiumService.reviewedProductPeriods.entries) {
        expect(
          PremiumService.isReviewedStoreProduct(
            product(entry.key, entry.value),
          ),
          true,
        );
      }
      for (final item in [
        product('monthly', 'P1M'),
        product('yearly', 'P1Y'),
        product('lifetime', null),
        product(PremiumService.premiumMonthlyProductId, 'P1Y'),
        product(PremiumService.essentialsAnnualProductId, null),
      ]) {
        expect(PremiumService.isReviewedStoreProduct(item), false);
        await expectLater(
          PremiumService().purchase(
            Package(
              'synthetic',
              PackageType.custom,
              item,
              const PresentedOfferingContext('synthetic', null, null),
            ),
          ),
          throwsA(
            isA<AccountAccessException>().having(
              (e) => e.message,
              'message',
              contains('subscription is unavailable'),
            ),
          ),
        );
      }
      expect(sdkCalls, 0);
    },
  );
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
        appUserId: 'a',
      ),
      isFalse,
    );
    expect(sdkCalls, 0);
    expect(
      await PremiumService.initRevenueCat(
        apiKey: 'synthetic-test-config',
        appUserId: 'a',
      ),
      isFalse,
    );
    expect(sdkCalls, 1);
  });
  test(
    'account switch invalidates Riverpod premium state without changing profile',
    () async {
      final session = AccountSession()
        ..updateFromAuthBridge(uid: 'a', recoverable: true);
      final backend = Backend()
        ..access = VerifiedPremiumAccess(
          'a',
          VerifiedTier.premium,
          DateTime.now().add(const Duration(minutes: 1)),
        );
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
    'signed-out premium/trial flags cannot grant access or invoke SDK offerings or restore',
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
        service.getOfferings(),
        throwsA(isA<AccountAccessException>()),
      );
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
    final backend = Backend()
      ..access = VerifiedPremiumAccess(
        'a',
        VerifiedTier.premium,
        DateTime.now().add(const Duration(minutes: 1)),
      );
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
        DateTime.now().add(const Duration(minutes: 1)),
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
