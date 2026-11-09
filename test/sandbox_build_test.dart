import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/safety_callable.dart';
import 'package:lyva_app/services/analytics_service.dart';
import 'package:lyva_app/services/step_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_privacy_test.dart' show RecordingAnalytics;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lyva_app/repos/community_repo.dart';

// Boundary doubles fail if sandbox code touches the production SDKs.
// ignore: subtype_of_sealed_class
class NoFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Firestore touched');
}
// ignore: subtype_of_sealed_class
class NoStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Storage touched');
}
// ignore: subtype_of_sealed_class
class NoAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Auth touched');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sandbox blocks live community reads even with a supplied verified UID', () async {
    final repo = CommunityRepo(firestore: NoFirestore(), auth: NoAuth(),
        storage: NoStorage(), verifiedUid: () => 'reviewed-tester');
    expect(repo.currentUser, isNull);
    expect(await repo.watchAuthUser().first, isNull);
    expect(() => repo.watchProfile('someone'), throwsA(isA<CommunityAccessException>()));
    expect(() => repo.watchPosts(category: 'wins'), throwsA(isA<CommunityAccessException>()));
    await expectLater(repo.toggleFollow('someone'), throwsA(isA<CommunityAccessException>()));
  }, skip: !const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD'));
  test('sandbox blocks Health platform calls including prior device grants', () async {
    final steps = StepTrackingService();
    expect(await steps.requestPermissions(), false);
    expect(await steps.canReadSteps(), false);
    await expectLater(steps.getTodaySteps(), throwsStateError);
    await expectLater(steps.getWeeklySteps(), throwsStateError);
  }, skip: !const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD'));
  test('sandbox cannot enable telemetry or overwrite ordinary analytics consent', () async {
    SharedPreferences.setMockInitialValues({AnalyticsService.preferenceKey: true});
    final recorder = RecordingAnalytics();
    final service = AnalyticsService.forTesting(recorder);
    await service.initialize();
    await service.setCollectionEnabled(true);
    await service.logAppOpened();
    expect(recorder.collection, [false, false]);
    expect(recorder.events, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool(AnalyticsService.preferenceKey), isTrue);
  }, skip: !const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD'));
  test(
    'sandbox build rejects AI before reading local health data or Firebase',
    () async {
      await expectLater(
        SafetyCallable('generatePlan').call({'fixture': true}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('billing test build'),
          ),
        ),
      );
    },
    skip: !const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD'),
  );
}
