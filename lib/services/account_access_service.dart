import 'package:flutter/foundation.dart';

enum BillingAction { purchase, restore }

enum VerifiedTier { essentials, premium }

class AccountAccessException implements Exception {
  final String message;
  const AccountAccessException(this.message);
  @override
  String toString() => message;
}

/// Client UX state only. The backend independently verifies tokens and providers.
/// A future selected auth bridge must invalidate this state before any switch.
class AccountSession extends ChangeNotifier {
  String? _uid;
  bool _recoverable = false;
  int _revision = 0;
  String? get uid => _uid;
  bool get recoverable => _recoverable;
  int get revision => _revision;

  void updateFromAuthBridge({String? uid, bool recoverable = false}) {
    _revision++;
    _uid = uid;
    _recoverable = recoverable && uid != null && uid.isNotEmpty;
    notifyListeners();
  }
}

class BillingPermit {
  final String uid;
  final String revenueCatId;
  final BillingAction action;
  final String policyRevision;
  final DateTime expiresAt;
  const BillingPermit({
    required this.uid,
    required this.revenueCatId,
    required this.action,
    required this.policyRevision,
    required this.expiresAt,
  });
}

class VerifiedPremiumAccess {
  final String uid;
  final VerifiedTier tier;
  final DateTime expiresAt;
  const VerifiedPremiumAccess(this.uid, this.tier, this.expiresAt);
}

abstract interface class AccountBackend {
  // The eventual transport sends a Firebase token, never a caller-selected UID,
  // anonymous RevenueCat ID, client entitlement or local trial date.
  Future<BillingPermit> prepareBilling(BillingAction action);
  Future<VerifiedPremiumAccess?> verifyPremium();
}

class UnavailableAccountBackend implements AccountBackend {
  const UnavailableAccountBackend();
  @override
  Future<BillingPermit> prepareBilling(BillingAction action) async =>
      throw const AccountAccessException(
        'Account verification is unavailable. Please try again later.',
      );
  @override
  Future<VerifiedPremiumAccess?> verifyPremium() async =>
      throw const AccountAccessException(
        'Account verification is unavailable. Please try again later.',
      );
}

/// No health-profile repository or identity-mutating SDK methods are accessible
/// here. The optional initializer must never logIn/logOut or merge users.
class AccountAccessService {
  final AccountSession session;
  final AccountBackend backend;
  final Future<String> Function() currentRevenueCatId;
  final DateTime Function() now;
  final Future<void> Function(String uid)? initializeRevenueCat;
  bool _billingInFlight = false;
  bool get billingInFlight => _billingInFlight;
  AccountAccessService({
    required this.session,
    required this.backend,
    required this.currentRevenueCatId,
    this.initializeRevenueCat,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  int _begin() {
    if (!session.recoverable || session.uid == null) {
      throw const AccountAccessException(
        'Sign in to an account before using Premium, purchasing or restoring.',
      );
    }
    return session.revision;
  }

  void _check(int revision, String uid) {
    if (session.revision != revision ||
        session.uid != uid ||
        !session.recoverable) {
      throw const AccountAccessException(
        'Your account changed. Please try again.',
      );
    }
  }

  Future<VerifiedPremiumAccess?> verifyPremium() async {
    final revision = _begin();
    final uid = session.uid!;
    final result = await backend.verifyPremium();
    _check(revision, uid);
    if (result != null &&
        (result.uid != uid || !result.expiresAt.isAfter(now()))) {
      throw const AccountAccessException('Unable to verify Premium access.');
    }
    return result;
  }

  /// Offerings use the same reviewed identity setup as purchase/restore. This
  /// serializes setup with billing; it never launches a store transaction.
  Future<void> prepareBillingIdentity() async {
    final revision = _begin();
    final uid = session.uid!;
    if (_billingInFlight) {
      throw const AccountAccessException('Billing is already in progress.');
    }
    _billingInFlight = true;
    try {
      await _prepareIdentity(BillingAction.purchase, revision, uid);
    } finally {
      _billingInFlight = false;
    }
  }

  Future<void> _prepareIdentity(
    BillingAction action,
    int revision,
    String uid,
  ) async {
    final permit = await backend.prepareBilling(action);
    _check(revision, uid);
    if (permit.uid != uid ||
        permit.revenueCatId != uid ||
        permit.action != action ||
        permit.policyRevision.isEmpty ||
        !permit.expiresAt.isAfter(now())) {
      throw const AccountAccessException(
        'Unable to verify this purchase or restore.',
      );
    }
    await initializeRevenueCat?.call(uid);
    _check(revision, uid);
    final currentId = await currentRevenueCatId();
    _check(revision, uid);
    if (currentId != permit.revenueCatId) {
      throw const AccountAccessException(
        'Your purchases need account recovery before continuing.',
      );
    }
    if (!permit.expiresAt.isAfter(now())) {
      throw const AccountAccessException(
        'Account verification expired. Please try again.',
      );
    }
  }

  Future<VerifiedPremiumAccess> billing(
    BillingAction action,
    Future<void> Function() operation,
  ) async {
    final revision = _begin();
    final uid = session.uid!;
    if (_billingInFlight) {
      throw const AccountAccessException(
        'A purchase or restore is already in progress.',
      );
    }
    _billingInFlight = true;
    try {
      await _prepareIdentity(action, revision, uid);
      await operation();
      _check(revision, uid);
      final afterId = await currentRevenueCatId();
      _check(revision, uid);
      if (afterId != uid) {
        throw const AccountAccessException(
          'Your purchase account changed. Please verify access again.',
        );
      }
      final access = await verifyPremium();
      _check(revision, uid);
      if (access == null) {
        throw const AccountAccessException(
          'No verified subscription was found. If you completed a purchase, try restoring after verification is available.',
        );
      }
      return access;
    } on AccountAccessException {
      rethrow;
    } catch (_) {
      throw const AccountAccessException(
        'Unable to verify the purchase or restore. Please try again later.',
      );
    } finally {
      _billingInFlight = false;
    }
  }
}
