import 'dart:async';
import 'package:flutter/foundation.dart';
import 'account_access_service.dart';

enum SocialProvider { apple, google }

class AuthIdentity {
  final String uid;
  final Set<String> providers;
  final bool anonymous;
  final String? email;
  const AuthIdentity(
    this.uid,
    this.providers, {
    this.anonymous = false,
    this.email,
  });
  bool get recoverable =>
      uid.isNotEmpty &&
      !anonymous &&
      providers.any((id) => id == 'apple.com' || id == 'google.com');
}

class SocialAuthFailure implements Exception {
  final String message;
  final bool cancelled;
  const SocialAuthFailure(this.message, {this.cancelled = false});
}

abstract interface class SocialAuthGateway {
  bool available(SocialProvider provider);
  AuthIdentity? get current;
  Stream<AuthIdentity?> get changes;
  Future<AuthIdentity> signIn(SocialProvider provider);
  Future<void> signOut();
}

/// Coordinates local UI state only. Firebase verifies provider credentials;
/// backend account/binding/entitlement checks remain independent and fail closed.
class SocialAuthController extends ChangeNotifier {
  final SocialAuthGateway gateway;
  final AccountSession session;
  final bool Function() billingInFlight;
  StreamSubscription<AuthIdentity?>? _subscription;
  Future<void>? _signInFlight;
  Future<void>? _signOutFlight;
  bool _started = false;
  bool _disposed = false;
  bool _guestOnly = false;
  bool _signOutFailed = false;
  bool _busy = false;
  int _generation = 0;
  String? _message;
  bool get busy => _busy;
  String? get message => _message;
  bool get needsSignOutRetry => _signOutFailed;
  String? get signedInEmail =>
      session.recoverable && gateway.current?.uid == session.uid
      ? gateway.current?.email
      : null;

  SocialAuthController({
    required this.gateway,
    required this.session,
    required this.billingInFlight,
  });

  bool available(SocialProvider provider) => gateway.available(provider);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _apply(AuthIdentity? identity) {
    if (session.uid == identity?.uid &&
        session.recoverable == (identity?.recoverable ?? false)) {
      return;
    }
    session.updateFromAuthBridge(
      uid: identity?.uid,
      recoverable: identity?.recoverable ?? false,
    );
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscription = gateway.changes.listen(
      (identity) {
        if (!_busy && !_guestOnly && !_disposed) {
          if (gateway.current?.uid != identity?.uid) return;
          _apply(identity);
          _notify();
        }
      },
      onError: (Object _) {
        if (_disposed) return;
        _generation++;
        _guestOnly = true;
        _busy = false;
        _apply(null);
        _message =
            'Account verification was interrupted. Sign out and try again.';
        _signOutFailed = true;
        _notify();
      },
    );
  }

  Future<void> signIn(SocialProvider provider) {
    if (_disposed) return Future.value();
    if (_busy || billingInFlight()) {
      _message = 'Wait for the current operation to finish.';
      _notify();
      return Future.value();
    }
    if (_signOutFailed || session.uid != null) {
      _message = 'Sign out before choosing another account.';
      _notify();
      return Future.value();
    }
    if (!available(provider)) {
      _message = 'This sign-in option is currently unavailable.';
      _notify();
      return Future.value();
    }
    final generation = ++_generation;
    _guestOnly = false;
    _busy = true;
    _message = null;
    _apply(null);
    _notify();
    return _signInFlight = _completeSignIn(provider, generation);
  }

  Future<void> _completeSignIn(SocialProvider provider, int generation) async {
    try {
      final identity = await gateway.signIn(provider);
      if (_disposed || generation != _generation) return;
      final expected = provider == SocialProvider.apple
          ? 'apple.com'
          : 'google.com';
      if (!identity.recoverable ||
          !identity.providers.contains(expected) ||
          gateway.current?.uid != identity.uid) {
        throw const SocialAuthFailure(
          'Unable to verify this account. Sign out and try again.',
        );
      }
      _apply(identity);
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _guestOnly = true;
      _apply(null);
      if (error is SocialAuthFailure && error.cancelled) {
        _message = null;
      } else {
        _message = error is SocialAuthFailure
            ? error.message
            : 'Sign-in failed. Please try again.';
      }
      // An SDK may have established a session before a later failure. Never
      // silently adopt it or start another provider over it.
      _signOutFailed = gateway.current != null;
    } finally {
      if (!_disposed && generation == _generation) {
        _busy = false;
        _notify();
      }
    }
  }

  Future<void> signOut() {
    if (_disposed) return Future.value();
    if (_signOutFlight != null) return _signOutFlight!;
    if (billingInFlight()) {
      _message = 'Finish the purchase or restore before signing out.';
      _notify();
      return Future.value();
    }
    final pending = _signInFlight;
    ++_generation;
    _guestOnly = true;
    _busy = true;
    _message = null;
    _apply(null); // revoke local access before any native await
    _notify();
    return _signOutFlight = _completeSignOut(pending);
  }

  Future<void> _completeSignOut(Future<void>? pending) async {
    try {
      // A delayed native sign-in must finish before clearing its persisted session.
      await pending;
      await gateway.signOut();
      if (gateway.current != null) {
        throw const SocialAuthFailure('Sign-out did not complete.');
      }
      _signOutFailed = false;
    } catch (_) {
      _signOutFailed = true;
      _message = 'Sign-out could not finish. Retry before switching accounts.';
    } finally {
      _signInFlight = null;
      _signOutFlight = null;
      if (!_disposed) {
        _busy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
