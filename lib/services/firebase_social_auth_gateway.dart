import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'social_auth_service.dart';

/// These are reviewed-build gates, not credentials. Default builds make no auth
/// calls. Enable only after staging/provider/native setup has been validated.
class SocialAuthConfiguration {
  final bool appleReviewed;
  final bool googleReviewed;
  final String projectId;
  const SocialAuthConfiguration({
    this.appleReviewed = false,
    this.googleReviewed = false,
    this.projectId = '',
  });
  static const build = SocialAuthConfiguration(
    appleReviewed: bool.fromEnvironment('LYVA_APPLE_AUTH_REVIEWED'),
    googleReviewed: bool.fromEnvironment('LYVA_GOOGLE_AUTH_REVIEWED'),
    projectId: String.fromEnvironment('LYVA_AUTH_PROJECT_ID'),
  );
}

class FirebaseSocialAuthGateway implements SocialAuthGateway {
  final SocialAuthConfiguration configuration;
  Future<void>? _googleInitialization;
  FirebaseSocialAuthGateway({
    this.configuration = SocialAuthConfiguration.build,
  });

  bool get _configured =>
      (Platform.isIOS || Platform.isAndroid) &&
      configuration.projectId.isNotEmpty &&
      Firebase.apps.isNotEmpty &&
      Firebase.app().options.projectId == configuration.projectId;
  @override
  bool available(SocialProvider provider) =>
      _configured &&
      (provider == SocialProvider.apple
          ? configuration.appleReviewed
          : configuration.googleReviewed);
  bool get _enabled =>
      available(SocialProvider.apple) || available(SocialProvider.google);
  AuthIdentity? _identity(User? user) => user == null
      ? null
      : AuthIdentity(
          user.uid,
          user.providerData.map((p) => p.providerId).toSet(),
          anonymous: user.isAnonymous,
          email: user.email,
        );
  @override
  AuthIdentity? get current =>
      _enabled ? _identity(FirebaseAuth.instance.currentUser) : null;
  @override
  Stream<AuthIdentity?> get changes => _enabled
      ? FirebaseAuth.instance.idTokenChanges().map(_identity)
      : Stream.value(null);

  @override
  Future<AuthIdentity> signIn(SocialProvider provider) async {
    if (!available(provider)) {
      throw const SocialAuthFailure(
        'This sign-in option is currently unavailable.',
      );
    }
    try {
      UserCredential result;
      if (provider == SocialProvider.apple) {
        result = await FirebaseAuth.instance.signInWithProvider(
          AppleAuthProvider()..addScope('email'),
        );
      } else {
        final google = GoogleSignIn.instance;
        try {
          await (_googleInitialization ??= google.initialize());
        } catch (_) {
          _googleInitialization = null;
          rethrow;
        }
        if (!google.supportsAuthenticate()) {
          throw const SocialAuthFailure(
            'Google sign-in is unavailable on this platform.',
          );
        }
        final account = await google.authenticate();
        final token = account.authentication.idToken;
        if (token == null || token.isEmpty) {
          throw const SocialAuthFailure(
            'Google could not verify this account.',
          );
        }
        result = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: token),
        );
      }
      final identity = _identity(result.user);
      if (identity == null) {
        throw const SocialAuthFailure(
          'Sign-in did not complete. Please try again.',
        );
      }
      return identity;
    } on FirebaseAuthException catch (error) {
      if ([
        'web-context-cancelled',
        'popup-closed-by-user',
        'canceled',
      ].contains(error.code)) {
        throw const SocialAuthFailure('', cancelled: true);
      }
      if ([
        'account-exists-with-different-credential',
        'credential-already-in-use',
      ].contains(error.code)) {
        throw const SocialAuthFailure(
          'This account uses a different sign-in method. Use the original method; accounts have not been merged.',
        );
      }
      if (error.code == 'network-request-failed') {
        throw const SocialAuthFailure('Check your connection and try again.');
      }
      throw const SocialAuthFailure(
        'Sign-in is unavailable. Please try again later.',
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialAuthFailure('', cancelled: true);
      }
      throw const SocialAuthFailure(
        'Google sign-in is unavailable. Please try again later.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!_enabled) return;
    // Sign out of Firebase first; never touch RevenueCat or the local health DB.
    await FirebaseAuth.instance.signOut();
    if (_googleInitialization != null) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
