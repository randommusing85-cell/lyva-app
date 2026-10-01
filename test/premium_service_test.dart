import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = PremiumService();
  final expiredProfile = UserProfile()
    ..isPremium = true
    ..premiumTier = 'premium'
    ..premiumTrialStart = DateTime.now().subtract(const Duration(days: 20));

  Map<String, dynamic> customerInfo({String? tier}) {
    final entitlements = <String, dynamic>{
      if (tier != null)
        tier: {
          'identifier': tier,
          'isActive': true,
          'willRenew': true,
          'latestPurchaseDate': '2026-01-01',
          'originalPurchaseDate': '2026-01-01',
          'productIdentifier': 'subscription',
          'isSandbox': true,
        },
    };
    return {
      'entitlements': {'all': entitlements, 'active': entitlements},
      'allPurchaseDates': <String, String>{},
      'activeSubscriptions': <String>[],
      'allPurchasedProductIdentifiers': <String>[],
      'nonSubscriptionTransactions': [],
      'firstSeen': '2026-01-01',
      'originalAppUserId': 'test',
      'allExpirationDates': <String, String>{},
      'requestDate': '2026-01-01',
    };
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('expired RevenueCat entitlement overrides stale paid profile', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => customerInfo());
    final status = await service.getAccessStatusAsync(expiredProfile);
    expect(status.hasAccess, isFalse);
  });

  test('SDK failure cannot restore cached or promo premium access', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'offline'),
    );
    expect(
      (await service.getAccessStatusAsync(expiredProfile)).hasAccess,
      isFalse,
    );
    expect(
      service.getAccessStatus(UserProfile()..isPremium = true).hasAccess,
      isFalse,
    );
  });

  test(
    'active paid essentials and premium tiers retain correct access',
    () async {
      for (final tier in ['essentials', 'premium']) {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => customerInfo(tier: tier),
        );
        final status = await service.getAccessStatusAsync(expiredProfile);
        expect(status.canAccessFeature(PremiumFeature.exportData), isTrue);
        expect(
          status.canAccessFeature(PremiumFeature.aiCoaching),
          tier == 'premium',
        );
      }
    },
  );

  test('valid local trial remains available without a subscription', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => customerInfo());
    final profile = UserProfile()..premiumTrialStart = DateTime.now();
    expect(
      (await service.getAccessStatusAsync(profile)).type,
      PremiumAccessType.trial,
    );
  });
}
