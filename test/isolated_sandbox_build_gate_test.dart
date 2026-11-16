import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/account_access_service.dart';

void main() {
  test(
    'isolated build switch requires sandbox, explicit opt-in, and exact policy',
    () {
      expect(
        isolatedSandboxIdentityEnabled,
        const bool.fromEnvironment('EXPECT_ISOLATED_GATE'),
      );
    },
  );
}
