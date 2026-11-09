import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:lyva_app/services/step_tracking_service.dart';

class FakeHealth extends Health {
  FakeHealth(this.permission);
  final bool? permission;
  @override
  Future<void> configure() async {}
  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async => permission;
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test(
    'iOS unknown read permission permits attempting HealthKit reads',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final service = StepTrackingService(health: FakeHealth(null));
      expect(await service.isAuthorized(), isNull);
      expect(await service.canReadSteps(), isTrue);
    },
  );
  test('Android denied or unknown permission does not permit reads', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      await StepTrackingService(health: FakeHealth(false)).canReadSteps(),
      isFalse,
    );
    expect(
      await StepTrackingService(health: FakeHealth(null)).canReadSteps(),
      isFalse,
    );
    expect(
      await StepTrackingService(health: FakeHealth(true)).canReadSteps(),
      isTrue,
    );
  });
}
