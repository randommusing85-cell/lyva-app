import 'package:cloud_functions/cloud_functions.dart';
export 'package:cloud_functions/cloud_functions.dart' show HttpsCallableOptions;
import '../repos/user_profile_repo.dart';
import 'personalization_safety.dart';

/// Every existing personalized AI callable goes through the current local gate.
/// Server authentication/entitlement and future clinical enforcement are separate.
class SafetyCallable {
  final String name;
  final HttpsCallableOptions? options;
  SafetyCallable(this.name, {this.options});
  Future<HttpsCallableResult<dynamic>> call(dynamic data) async {
    if (const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD')) {
      throw StateError(
        'Personalized AI is unavailable in this billing test build.',
      );
    }
    return PersonalizationSafety(UserProfileRepo().getProfile).run(
      () => FirebaseFunctions.instance
          .httpsCallable(name, options: options)
          .call(data),
    );
  }
}
