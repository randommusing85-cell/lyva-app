import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/user_profile.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() : _clock = DateTime.now;
  @visibleForTesting
  NotificationService.forTesting({DateTime Function()? now})
    : _clock = now ?? DateTime.now;
  final DateTime Function() _clock;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void> _scheduleQueue = Future<void>.value();
  static const cycleHorizonDays = 14;

  Future<bool> notificationsEnabled() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    return false;
  }

  Future<void> _cancelOwnedSchedules() async {
    for (final id in [
      1,
      ...List.generate(8, (i) => 10 + i),
      20,
      21,
      ...List.generate(cycleHorizonDays, (i) => 100 + i),
      ...List.generate(cycleHorizonDays, (i) => 200 + i),
    ]) {
      await _notifications.cancel(id);
    }
  }

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screens
    // This would need to be connected to your navigation
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (call on first launch or from settings)
  Future<bool> requestPermissions() async {
    await init();
    // Android 13+ requires explicit permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Schedule daily check-in reminder
  Future<void> scheduleCheckInReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.cancel(1); // Cancel existing

    await _notifications.zonedSchedule(
      1,
      'Daily Check-in 📊',
      'Log your weight and waist to track progress',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_reminder',
          'Check-in Reminders',
          channelDescription: 'Daily reminders to log your check-in',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
      payload: 'checkin',
    );
  }

  /// Schedule workout reminder for specific days
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> daysOfWeek, // 1 = Monday, 7 = Sunday
  }) async {
    // Cancel existing workout reminders (IDs 11-17, plus legacy ID 10)
    for (int i = 10; i <= 17; i++) {
      await _notifications.cancel(i);
    }

    for (final day in daysOfWeek) {
      await _notifications.zonedSchedule(
        10 + day,
        'Workout Day 💪',
        'Time to train! Your workout is ready.',
        _nextInstanceOfDayAndTime(day, hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminder',
            'Workout Reminders',
            channelDescription: 'Reminders on your scheduled workout days',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'workout',
      );
    }
  }

  /// Schedule cycle-aware notification (for women tracking cycle)
  Future<void> scheduleCycleAwareNotification({
    required UserProfile profile,
    required int hour,
    required int minute,
    tz.TZDateTime? deliveryDate,
    int? notificationId,
  }) async {
    final id = notificationId ?? 20;
    final scheduled = deliveryDate ?? _nextInstanceOfTime(hour, minute);
    await _notifications.cancel(id);
    if (!profile.trackCycle || !profile.notifyCycle) return;

    const title = 'Optional cycle check-in';
    const body = 'Record how you feel if you want to. Calendar dates do not determine workout intensity.';

    // Schedule for tomorrow morning
    await _notifications.zonedSchedule(
      id, // Cycle notification ID
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cycle_reminder',
          'Cycle Check-ins',
          channelDescription: 'Optional reminders to review your recorded experience',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'cycle',
    );
  }

  /// Retired period-prediction reminder. Keep cancellation compatibility for
  /// already scheduled IDs; no calendar heuristic creates replacement alerts.
  Future<void> schedulePeriodApproachingNotification({
    required UserProfile profile, required int hour, required int minute,
    tz.TZDateTime? deliveryDate, int? notificationId,
  }) async {
    await _notifications.cancel(notificationId ?? 21);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by ID
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> _configureLocalTimezone() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  }

  /// Setup all notifications based on user profile
  Future<bool> setupNotifications(UserProfile profile) {
    // Capture preferences before awaiting; callers may edit the same model later.
    final snapshot = UserProfile()
      ..sex = profile.sex
      ..trackCycle = profile.trackCycle
      ..notifyCheckIn = profile.notifyCheckIn
      ..notifyWorkout = profile.notifyWorkout
      ..notifyCycle = profile.notifyCycle
      ..scheduledDays = profile.scheduledDays
      ..reminderHour = profile.reminderHour
      ..reminderMinute = profile.reminderMinute;
    final task = _scheduleQueue.then((_) => _replaceSchedules(snapshot));
    _scheduleQueue = task.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return task;
  }

  Future<bool> _replaceSchedules(UserProfile profile) async {
    await init();
    await _cancelOwnedSchedules();
    try {
      await _configureLocalTimezone();
      if (profile.reminderHour < 0 ||
          profile.reminderHour > 23 ||
          profile.reminderMinute < 0 ||
          profile.reminderMinute > 59) {
        throw ArgumentError('Invalid reminder time');
      }
      if (!await notificationsEnabled()) return false;
      if (profile.notifyCheckIn) {
        await scheduleCheckInReminder(
          hour: profile.reminderHour,
          minute: profile.reminderMinute,
        );
      }
      if (profile.notifyWorkout) {
        await scheduleWorkoutReminder(
          hour: profile.reminderHour,
          minute: profile.reminderMinute,
          daysOfWeek: profile.scheduledDaysList
              .where((d) => d >= 1 && d <= 7)
              .toSet()
              .toList(),
        );
      }
      if (profile.sex == 'female' &&
          profile.trackCycle &&
          profile.notifyCycle) {
        final first = _nextInstanceOfTime(
          profile.reminderHour,
          profile.reminderMinute,
        );
        for (var i = 0; i < cycleHorizonDays; i++) {
          final date = tz.TZDateTime(
            tz.local,
            first.year,
            first.month,
            first.day + i,
            profile.reminderHour,
            profile.reminderMinute,
          );
          await scheduleCycleAwareNotification(
            profile: profile,
            hour: profile.reminderHour,
            minute: profile.reminderMinute,
            deliveryDate: date,
            notificationId: 100 + i,
          );
        }
      }
      return true;
    } catch (_) {
      await _cancelOwnedSchedules();
      rethrow;
    }
  }

  // Helper: Get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.from(_clock(), tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  // Helper: Get next instance of a specific day and time
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != dayOfWeek) {
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  /// Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test Notification 🎉',
      'Notifications are working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test',
          channelDescription: 'Test notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
