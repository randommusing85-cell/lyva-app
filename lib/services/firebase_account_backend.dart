import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'account_access_service.dart';
import 'callable_account_backend.dart';

/// Intentionally opt-in until the server contract, restore ownership policy and
/// provider configuration have been reviewed and tested in the selected project.
AccountBackend createFirebaseAccountBackend() {
  const reviewed = bool.fromEnvironment('LYVA_ACCOUNT_BACKEND_REVIEWED');
  const sandbox = bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD');
  const project = String.fromEnvironment('LYVA_AUTH_PROJECT_ID');
  const region = String.fromEnvironment('LYVA_ACCOUNT_FUNCTIONS_REGION');
  const policy = String.fromEnvironment('LYVA_BILLING_POLICY_REVISION');
  if (!reviewed ||
      !sandbox ||
      project.isEmpty ||
      region.isEmpty ||
      policy.isEmpty ||
      Firebase.apps.isEmpty ||
      Firebase.app().options.projectId != project) {
    return const UnavailableAccountBackend();
  }
  final app = Firebase.app();
  final auth = FirebaseAuth.instanceFor(app: app);
  final functions = FirebaseFunctions.instanceFor(app: app, region: region);
  return CallableAccountBackend(
    policyRevision: policy,
    invoke: (name, data) async {
      final user = auth.currentUser;
      if (user == null ||
          user.isAnonymous ||
          !user.providerData.any(
            (p) => p.providerId == 'apple.com' || p.providerId == 'google.com',
          )) {
        throw const AccountAccessException('Sign in before verifying access.');
      }
      await user.getIdToken(true);
      if (auth.currentUser?.uid != user.uid) {
        throw const AccountAccessException('Your account changed.');
      }
      return (await functions
              .httpsCallable(
                switch (name) {
                  'prepareAccountBilling' => 'lyvaSandboxPrepareBilling',
                  'verifyAccountPremium' => 'lyvaSandboxVerifyPremium',
                  _ => throw const AccountAccessException(
                    'Unknown billing operation.',
                  ),
                },
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 45),
                ),
              )
              .call<Object?>(data))
          .data;
    },
  );
}
