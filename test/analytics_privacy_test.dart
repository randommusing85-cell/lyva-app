import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lyva_app/services/analytics_service.dart';

class RecordingAnalytics extends Fake implements FirebaseAnalytics {
  final events = <String>[];
  final parameters = <Map<String, Object>?>[];
  final properties = <String, String?>{};
  final collection = <bool>[];
  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    collection.add(enabled);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    properties[name] = value;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    events.add(name);
    this.parameters.add(parameters);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingAnalytics recorder;
  late AnalyticsService analytics;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recorder = RecordingAnalytics();
    analytics = AnalyticsService.forTesting(recorder);
  });
  test(
    'fresh install defaults off and clears legacy health properties',
    () async {
      await analytics.initialize();
      await analytics.logAppOpened();
      expect(analytics.enabled.value, isFalse);
      expect(recorder.events, isEmpty);
      expect(recorder.collection, [false]);
      expect(recorder.properties['postpartum_status'], isNull);
      expect(recorder.properties.keys, contains('tracks_cycle'));
    },
  );
  test(
    'opt in retains only coarse events without health parameters or free text',
    () async {
      await analytics.initialize();
      await analytics.setCollectionEnabled(true);
      await analytics.logOnboardingCompleted(
        age: 32,
        sex: 'female',
        goal: 'loss',
        tracksCycle: true,
        isPostPartum: true,
      );
      await analytics.logCheckInCompleted(
        weightKg: 70,
        waistCm: 80,
        stepsToday: 5000,
        hasNote: true,
      );
      await analytics.logCycleSymptomLogged(
        symptomType: 'sensitive',
        severity: 4,
      );
      await analytics.logPostPartumGuidanceViewed(
        phase: 'early',
        weeksPostPartum: 5,
      );
      await analytics.logError(
        errorType: 'error',
        screen: 'private',
        details: 'health data',
      );
      await analytics.logScreenView('cycle');
      await analytics.logNutritionPlanSaved(
        planName: 'sensitive note',
        calories: 1800,
      );
      expect(recorder.events, ['onboarding_completed']);
      expect(recorder.parameters, [null]);
      expect(
        recorder.properties.values.every((value) => value == null),
        isTrue,
      );
    },
  );
  test('choice survives restart and opt out stops collection', () async {
    await analytics.initialize();
    await analytics.setCollectionEnabled(true);
    final restarted = AnalyticsService.forTesting(recorder);
    await restarted.initialize();
    expect(restarted.enabled.value, isTrue);
    await restarted.setCollectionEnabled(false);
    await restarted.logAppOpened();
    expect(recorder.events, isEmpty);
    expect(recorder.collection.last, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AnalyticsService.preferenceKey,
      ),
      isFalse,
    );
  });
  test('rapid opt in then opt out preserves the latest choice', () async {
    await analytics.initialize();
    final first = analytics.setCollectionEnabled(true);
    final last = analytics.setCollectionEnabled(false);
    await Future.wait([first, last]);
    expect(analytics.enabled.value, isFalse);
    expect(recorder.collection.last, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AnalyticsService.preferenceKey,
      ),
      isFalse,
    );
  });
}
