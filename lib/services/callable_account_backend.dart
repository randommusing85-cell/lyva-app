import 'account_access_service.dart';

typedef AccountCallable =
    Future<Object?> Function(String name, Map<String, Object?> data);

/// Versioned wire contract. Firebase's callable transport supplies the ID token;
/// neither identity, health data nor client entitlements go in the request body.
/// A matching response is not sufficient server security: the deployed callable
/// must independently authenticate and verify ownership with RevenueCat.
class CallableAccountBackend implements AccountBackend {
  final AccountCallable invoke;
  final String policyRevision;
  final DateTime Function() now;

  CallableAccountBackend({
    required this.invoke,
    required this.policyRevision,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  static const _failure = AccountAccessException(
    'Account verification is unavailable. Please try again later.',
  );

  Future<Map<Object?, Object?>> _request(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      if (policyRevision.trim().isEmpty) throw _failure;
      final response = await invoke(name, {'schemaVersion': 1, ...data});
      if (response is! Map ||
          response['schemaVersion'] != 1 ||
          // This candidate is exclusively for coordinated sandbox testing.
          response['environment'] != 'sandbox' ||
          response['policyRevision'] != policyRevision) {
        throw _failure;
      }
      return Map<Object?, Object?>.from(response);
    } catch (_) {
      // Do not surface token, provider or server exception details in the UI.
      throw _failure;
    }
  }

  String _string(Map<Object?, Object?> data, String field) {
    final value = data[field];
    if (value is! String || value.trim().isEmpty) throw _failure;
    return value;
  }

  DateTime _expiry(Map<Object?, Object?> data) {
    final value = data['expiresAtMillis'];
    if (value is! int) throw _failure;
    final current = now();
    // Short verification leases; never cache a subscription's entire lifetime.
    if (value <= current.millisecondsSinceEpoch ||
        value >
            current.add(const Duration(minutes: 5)).millisecondsSinceEpoch) {
      throw _failure;
    }
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  @override
  Future<BillingPermit> prepareBilling(BillingAction action) async {
    final data = await _request('prepareAccountBilling', {
      'action': action.name,
    });
    final uid = _string(data, 'uid');
    if (data['action'] != action.name || data['revenueCatId'] != uid) {
      throw _failure;
    }
    return BillingPermit(
      uid: uid,
      revenueCatId: uid,
      action: action,
      policyRevision: policyRevision,
      expiresAt: _expiry(data),
    );
  }

  @override
  Future<VerifiedPremiumAccess?> verifyPremium() async {
    final data = await _request('verifyAccountPremium', {});
    if (data['status'] == 'inactive') return null;
    if (data['status'] != 'active') throw _failure;
    final tier = switch (data['tier']) {
      'essentials' => VerifiedTier.essentials,
      'premium' => VerifiedTier.premium,
      _ => throw _failure,
    };
    return VerifiedPremiumAccess(_string(data, 'uid'), tier, _expiry(data));
  }
}
