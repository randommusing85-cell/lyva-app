import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/account_access_service.dart';
import 'package:lyva_app/services/social_auth_service.dart';
import 'package:lyva_app/services/firebase_social_auth_gateway.dart';
import 'package:lyva_app/screens/account_screen.dart';
import 'package:lyva_app/state/providers.dart';

class FakeSocialGateway implements SocialAuthGateway {
  final events = StreamController<AuthIdentity?>.broadcast();
  bool enabled = true;
  AuthIdentity? user;
  Completer<AuthIdentity>? pending;
  Object? signInError;
  bool failSignOut = false;
  int signIns = 0;
  int signOuts = 0;
  @override
  bool available(SocialProvider provider) => enabled;
  @override
  AuthIdentity? get current => user;
  @override
  Stream<AuthIdentity?> get changes => events.stream;
  @override
  Future<AuthIdentity> signIn(SocialProvider provider) async {
    signIns++;
    if (signInError != null) throw signInError!;
    final result =
        await (pending?.future ??
            Future.value(
              AuthIdentity('account-a', {
                provider == SocialProvider.apple ? 'apple.com' : 'google.com',
              }, email: 'account@example.invalid'),
            ));
    user = result;
    events.add(result);
    return result;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (failSignOut) throw StateError('private provider response');
    user = null;
    events.add(null);
  }
}

void main() {
  late FakeSocialGateway gateway;
  late AccountSession session;
  late SocialAuthController controller;
  late bool billing;
  late bool scopeOwnsNotifiers;
  setUp(() {
    scopeOwnsNotifiers = false;
    gateway = FakeSocialGateway();
    session = AccountSession();
    billing = false;
    controller = SocialAuthController(
      gateway: gateway,
      session: session,
      billingInFlight: () => billing,
    )..start();
  });
  tearDown(() async {
    if (!scopeOwnsNotifiers) {
      controller.dispose();
      session.dispose();
    }
    await gateway.events.close();
  });

  for (final provider in SocialProvider.values) {
    test(
      '$provider authenticates recoverable account and sign-out clears access',
      () async {
        await controller.signIn(provider);
        expect(session.uid, 'account-a');
        expect(session.recoverable, isTrue);
        final result = controller.signOut();
        expect(session.uid, isNull); // synchronous invalidation
        await result;
        expect(gateway.user, isNull);
        expect(controller.busy, isFalse);
      },
    );
  }
  test('unconfigured providers cause no SDK sign-in call', () async {
    gateway.enabled = false;
    await controller.signIn(SocialProvider.apple);
    await controller.signIn(SocialProvider.google);
    expect(gateway.signIns, 0);
    expect(session.recoverable, isFalse);
  });
  test('cancelled sign-in keeps guest tracking state without error', () async {
    gateway.signInError = const SocialAuthFailure('', cancelled: true);
    await controller.signIn(SocialProvider.google);
    expect(session.uid, isNull);
    expect(controller.message, isNull);
    expect(controller.busy, isFalse);
  });
  test('provider failure exposes no raw details and allows retry', () async {
    gateway.signInError = StateError('token and private health data');
    await controller.signIn(SocialProvider.apple);
    expect(controller.message, 'Sign-in failed. Please try again.');
    gateway.signInError = null;
    await controller.signIn(SocialProvider.apple);
    expect(session.recoverable, isTrue);
  });
  test('anonymous or unexpected-provider result is not recoverable', () async {
    for (final identity in [
      const AuthIdentity('guest', {'apple.com'}, anonymous: true),
      const AuthIdentity('other', {'password'}),
    ]) {
      gateway.pending = Completer();
      final attempt = controller.signIn(SocialProvider.apple);
      gateway.pending!.complete(identity);
      await attempt;
      expect(session.recoverable, isFalse);
      expect(controller.needsSignOutRetry, isTrue);
      await controller.signOut();
    }
  });
  test(
    'switch requires explicit sign-out and never merges providers',
    () async {
      await controller.signIn(SocialProvider.apple);
      await controller.signIn(SocialProvider.google);
      expect(gateway.signIns, 1);
      await controller.signOut();
      await controller.signIn(SocialProvider.google);
      expect(gateway.signIns, 2);
      expect(session.recoverable, isTrue);
    },
  );
  test(
    'guest choice during delayed sign-in clears eventual native session',
    () async {
      gateway.pending = Completer();
      final attempt = controller.signIn(SocialProvider.apple);
      final guest = controller.signOut();
      expect(session.uid, isNull);
      gateway.pending!.complete(const AuthIdentity('late', {'apple.com'}));
      await attempt;
      await guest;
      expect(session.uid, isNull);
      expect(gateway.current, isNull);
      expect(gateway.signOuts, 1);
    },
  );
  test('duplicate sign-in is serialized', () async {
    gateway.pending = Completer();
    final attempt = controller.signIn(SocialProvider.google);
    await controller.signIn(SocialProvider.apple);
    expect(gateway.signIns, 1);
    gateway.pending!.complete(const AuthIdentity('a', {'google.com'}));
    await attempt;
  });
  test(
    'failed sign-out stays fail closed and blocks switching until retry',
    () async {
      await controller.signIn(SocialProvider.apple);
      gateway.failSignOut = true;
      await controller.signOut();
      expect(session.recoverable, isFalse);
      expect(controller.needsSignOutRetry, isTrue);
      gateway.events.add(gateway.user);
      await Future<void>.delayed(Duration.zero);
      expect(session.recoverable, isFalse);
      await controller.signIn(SocialProvider.google);
      expect(gateway.signIns, 1);
      gateway.failSignOut = false;
      await controller.signOut();
      expect(controller.needsSignOutRetry, isFalse);
    },
  );
  test('billing in flight prevents identity mutations', () async {
    await controller.signIn(SocialProvider.apple);
    billing = true;
    await controller.signOut();
    expect(gateway.signOuts, 0);
    expect(session.recoverable, isTrue);
    await controller.signIn(SocialProvider.google);
    expect(gateway.signIns, 1);
  });
  test(
    'restored provider session and external sign-out update local gate',
    () async {
      gateway.user = const AuthIdentity('restored', {'google.com'});
      gateway.events.add(gateway.user);
      await Future<void>.delayed(Duration.zero);
      expect(session.uid, 'restored');
      gateway.user = null;
      gateway.events.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(session.uid, isNull);
    },
  );
  test(
    'auth stream error invalidates access and requires explicit recovery',
    () async {
      gateway.user = const AuthIdentity('a', {'apple.com'});
      gateway.events.add(gateway.user);
      await Future<void>.delayed(Duration.zero);
      gateway.events.addError(StateError('private'));
      await Future<void>.delayed(Duration.zero);
      expect(session.recoverable, isFalse);
      expect(controller.needsSignOutRetry, isTrue);
    },
  );
  test(
    'default native gateway stays disabled without touching Firebase',
    () async {
      final native = FirebaseSocialAuthGateway();
      expect(native.available(SocialProvider.apple), isFalse);
      expect(native.available(SocialProvider.google), isFalse);
      expect(await native.changes.first, isNull);
      await expectLater(
        native.signIn(SocialProvider.apple),
        throwsA(isA<SocialAuthFailure>()),
      );
      await native.signOut();
    },
  );
  test('stale auth event cannot resurrect another account', () async {
    gateway.user = const AuthIdentity('current', {'google.com'});
    gateway.events.add(gateway.user);
    await Future<void>.delayed(Duration.zero);
    gateway.events.add(const AuthIdentity('stale', {'apple.com'}));
    await Future<void>.delayed(Duration.zero);
    expect(session.uid, 'current');
  });

  testWidgets(
    'account screen offers both providers; sign-in does not imply Premium',
    (tester) async {
      scopeOwnsNotifiers = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            socialAuthControllerProvider.overrideWith((ref) => controller),
            accountSessionProvider.overrideWith((ref) => session),
          ],
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('You’re signed in'), findsOneWidget);
      expect(find.text('account@example.invalid'), findsOneWidget);
      expect(
        find.text('Subscription access is verified separately from sign-in.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sign out or switch account'));
      await tester.pumpAndSettle();
      expect(find.text('Continue without an account'), findsOneWidget);
      expect(find.text('account@example.invalid'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('disabled sign-in retains guest exit', (tester) async {
    scopeOwnsNotifiers = true;
    gateway.enabled = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialAuthControllerProvider.overrideWith((ref) => controller),
          accountSessionProvider.overrideWith((ref) => session),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: find.text('Continue with Apple'), matching: find.byWidgetPredicate((widget) => widget is FilledButton)),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Continue without an account'), findsOneWidget);
    expect(gateway.signIns, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
