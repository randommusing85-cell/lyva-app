import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/user_profile.dart';
import 'package:lyva_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final futureYear = DateTime.now().year + 1;
  final calls = <MethodCall>[];
  final pending = <int, Map>{};
  var enabled = true;
  var timezone = 'Asia/Singapore';
  var failSchedule = false;
  Completer<void>? pauseSchedule;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    enabled = true;
    timezone = 'Asia/Singapore';
    failSchedule = false;
    pauseSchedule = null;
    pending.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => timezone,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async {
        calls.add(call);
        if (call.method == 'cancel') {
          pending.remove((call.arguments as Map)['id']);
        }
        if (call.method == 'zonedSchedule') {
          if (pauseSchedule != null) await pauseSchedule!.future;
          if (failSchedule && pending.isNotEmpty) {
            throw PlatformException(code: 'test_failure');
          }
          final data = call.arguments as Map;
          pending[data['id'] as int] = data;
        }
        if (call.method == 'areNotificationsEnabled' ||
            call.method == 'requestNotificationsPermission') {
          return enabled;
        }
        if (call.method == 'checkPermissions') return {'isEnabled': enabled};
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
  test(
    'cycle check-in uses neutral wording and never repeats stale text',
    () async {
      await NotificationService().init();
      calls.clear();
      final now = tz.TZDateTime.now(tz.local);
      final profile = UserProfile()
        ..trackCycle = true
        ..notifyCycle = true
        ..lastPeriodDate = DateTime(now.year, now.month, now.day - 13)
        ..cycleLength = 28
        ..periodDuration = 5;
      await NotificationService().scheduleCycleAwareNotification(
        profile: profile,
        hour: 0,
        minute: 0,
      );
      final schedule =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(schedule['id'], 20);
      expect(schedule['title'], 'Optional cycle check-in');
      expect(schedule['matchDateTimeComponents'], isNull);
    },
  );
  test('retired period reminder only cancels its legacy ID', () async {
    await NotificationService().init();
    calls.clear();
    final now = tz.TZDateTime.now(tz.local);
    final profile = UserProfile()
      ..trackCycle = true
      ..notifyCycle = true
      ..lastPeriodDate = DateTime(now.year, now.month, now.day - 26)
      ..cycleLength = 28
      ..periodDuration = 5;
    await NotificationService().schedulePeriodApproachingNotification(
      profile: profile,
      hour: 0,
      minute: 0,
    );
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    expect(
      calls
          .where((c) => c.method == 'cancel')
          .map((c) => (c.arguments as Map)['id']),
      contains(21),
    );
  });
  test(
    'disabled tracking or reminder preference cancels existing cycle notifications',
    () async {
      for (final profile in [
        UserProfile()..trackCycle = false,
        UserProfile()
          ..trackCycle = true
          ..notifyCycle = true
          ..notifyCycle = false,
      ]) {
        calls.clear();
        await NotificationService().scheduleCycleAwareNotification(
          profile: profile,
          hour: 9,
          minute: 0,
        );
        await NotificationService().schedulePeriodApproachingNotification(
          profile: profile,
          hour: 9,
          minute: 0,
        );
        expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
        expect(
          calls
              .where((c) => c.method == 'cancel')
              .map((c) => (c.arguments as Map)['id']),
          containsAll([20, 21]),
        );
      }
    },
  );

  UserProfile reminders() => UserProfile()
    ..sex = 'female'
    ..trackCycle = true
    ..notifyCycle = true
    ..notifyCheckIn = true
    ..notifyWorkout = true
    ..scheduledDaysList = [1, 3, 7]
    ..reminderHour = 9
    ..reminderMinute = 30
    ..lastPeriodDate = DateTime(futureYear, 3, 1)
    ..periodDuration = 5
    ..cycleLength = 28;

  test(
    'denial cancels previous schedules without requesting permission',
    () async {
      final service = NotificationService.forTesting(
        now: () => DateTime(futureYear, 3, 5),
      );
      await service.setupNotifications(reminders());
      expect(pending, isNotEmpty);
      enabled = false;
      expect(await service.setupNotifications(reminders()), isFalse);
      expect(pending, isEmpty);
      expect(calls.where((c) => c.method.contains('request')), isEmpty);
    },
  );
  test(
    '14 distinct dated cycle tips fit bounded capacity and reflect each date',
    () async {
      final service = NotificationService.forTesting(
        now: () => DateTime(futureYear, 3, 5),
      );
      await service.setupNotifications(reminders());
      final cycle = pending.values
          .where((s) => (s['id'] as int) >= 100 && (s['id'] as int) < 114)
          .toList();
      expect(cycle.length, 14);
      expect(cycle.map((s) => s['scheduledDateTime']).toSet().length, 14);
      expect(cycle.map((s) => s['title']).toSet(), {'Optional cycle check-in'});
      expect(cycle.every((s) => s['matchDateTimeComponents'] == null), isTrue);
      expect(pending.length, lessThan(64));
      await service.setupNotifications(reminders()..notifyCycle = false);
      expect(pending.keys.where((id) => id >= 100), isEmpty);
    },
  );
  test('wall clock stays stable across DST and timezone refresh', () async {
    timezone = 'America/New_York';
    final service = NotificationService.forTesting(
      now: () => DateTime.utc(futureYear, 3, 7, 12),
    );
    await service.setupNotifications(reminders());
    for (final schedule in pending.values) {
      expect(schedule['timeZoneName'], 'America/New_York');
      expect(DateTime.parse(schedule['scheduledDateTime'] as String).hour, 9);
      expect(
        DateTime.parse(schedule['scheduledDateTime'] as String).minute,
        30,
      );
    }
    timezone = 'Asia/Tokyo';
    await service.setupNotifications(reminders());
    expect(
      pending.values.every((s) => s['timeZoneName'] == 'Asia/Tokyo'),
      isTrue,
    );
  });
  test('later opt-out wins over an in-flight schedule replacement', () async {
    final service = NotificationService.forTesting(
      now: () => DateTime(futureYear, 3, 5),
    );
    pauseSchedule = Completer<void>();
    final first = service.setupNotifications(reminders());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final second = service.setupNotifications(
      reminders()
        ..notifyCycle = false
        ..notifyCheckIn = false
        ..notifyWorkout = false,
    );
    pauseSchedule!.complete();
    await Future.wait([first, second]);
    expect(pending, isEmpty);
  });
  test(
    'native scheduling failure cleans partial state and queue can retry',
    () async {
      final service = NotificationService.forTesting(
        now: () => DateTime(futureYear, 3, 5),
      );
      failSchedule = true;
      await expectLater(
        service.setupNotifications(reminders()),
        throwsA(isA<PlatformException>()),
      );
      expect(pending, isEmpty);
      failSchedule = false;
      expect(await service.setupNotifications(reminders()), isTrue);
      expect(pending, isNotEmpty);
    },
  );
  test(
    'check-in schedule is independent of cycle defaults and creates no predicted-period alerts',
    () async {
      final service = NotificationService.forTesting(
        now: () => DateTime(futureYear, 3, 5),
      );
      await service.setupNotifications(reminders());
      final first = pending.values
          .map((s) => [s['id'], s['scheduledDateTime'], s['title']])
          .toList();
      await service.setupNotifications(
        reminders()
          ..lastPeriodDate = null
          ..cycleLength = 0
          ..periodDuration = 0,
      );
      expect(
        pending.values
            .map((s) => [s['id'], s['scheduledDateTime'], s['title']])
            .toList(),
        first,
      );
      expect(pending.keys.where((id) => id >= 200), isEmpty);
    },
  );
}
