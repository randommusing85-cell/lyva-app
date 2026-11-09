import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_auth_service.dart';
import '../state/providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(socialAuthControllerProvider);
    final session = ref.watch(accountSessionProvider);
    final connected = session.recoverable;
    return Scaffold(
      appBar: AppBar(title: const Text('Your account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  connected ? 'You’re signed in' : 'Sign in to Lyva',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'An account is required for purchases, restores and Premium. Basic tracking is available without one.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your existing tracking records stay on this device. Signing in does not move purchases or upload your records.',
                ),
                const SizedBox(height: 24),
                if (connected || auth.needsSignOutRetry) ...[
                  if (connected && auth.signedInEmail != null)
                    Text(auth.signedInEmail!),
                  if (connected)
                    const Text(
                      'Subscription access is verified separately from sign-in.',
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: auth.busy ? null : auth.signOut,
                    child: Text(
                      auth.needsSignOutRetry
                          ? 'Retry sign-out'
                          : 'Sign out or switch account',
                    ),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed:
                        auth.busy || !auth.available(SocialProvider.apple)
                        ? null
                        : () => auth.signIn(SocialProvider.apple),
                    icon: const Icon(Icons.apple),
                    label: const Text('Continue with Apple'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed:
                        auth.busy || !auth.available(SocialProvider.google)
                        ? null
                        : () => auth.signIn(SocialProvider.google),
                    child: const Text('Continue with Google'),
                  ),
                  if (!auth.available(SocialProvider.apple) &&
                      !auth.available(SocialProvider.google)) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Sign-in is currently unavailable. You can keep tracking without an account.',
                    ),
                  ],
                ],
                if (auth.busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (auth.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(auth.message!),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    if (auth.busy) await auth.signOut();
                    if (context.mounted) {
                      Navigator.maybePop(context);
                    }
                  },
                  child: Text(
                    connected
                        ? 'Back to tracking'
                        : 'Continue without an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
