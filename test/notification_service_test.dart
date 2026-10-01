import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => 'Asia/Singapore',
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async {
        calls.add(call);
        return call.method == 'initialize' ? true : null;
      },
    );
    calls.clear();
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'selected workout days and local wall time reach native scheduling',
    () async {
      final profile = UserProfile()
        ..sex = 'female'
        ..trainingDaysPerWeek = 3
        ..scheduledDaysList = [1, 3, 7]
        ..notifyCheckIn = false
        ..notifyCycle = false
        ..reminderHour = 9
        ..reminderMinute = 30;
      await NotificationService().setupNotifications(profile);
      final schedules = calls
          .where((c) => c.method == 'zonedSchedule')
          .map((c) => c.arguments as Map)
          .toList();
      expect(schedules.map((s) => s['id']), [11, 13, 17]);
      for (final schedule in schedules) {
        expect(schedule['timeZoneName'], 'Asia/Singapore');
        final date = DateTime.parse(schedule['scheduledDateTime'] as String);
        expect(date.hour, 9);
        expect(date.minute, 30);
        expect(date.weekday, (schedule['id'] as int) - 10);
      }
    },
  );

  test('turning off workouts cancels Sunday as well as weekdays', () async {
    final profile = UserProfile()
      ..sex = 'female'
      ..notifyCheckIn = false
      ..notifyWorkout = false
      ..notifyCycle = false;
    await NotificationService().setupNotifications(profile);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    expect(
      calls
          .where((c) => c.method == 'cancel')
          .map((c) => (c.arguments as Map)['id']),
      contains(17),
    );
  });
}
