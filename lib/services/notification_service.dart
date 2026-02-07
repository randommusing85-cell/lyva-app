import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/user_profile.dart';
import '../utils/cycle_calculator.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
    // Android 13+ requires explicit permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
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
    // Cancel existing workout reminders (IDs 10-16 for each day)
    for (int i = 10; i <= 16; i++) {
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
  }) async {
    if (!profile.trackCycle) return;

    final phase = CycleCalculator.getCurrentPhase(profile);
    if (phase == null) return;

    String title;
    String body;

    switch (phase) {
      case CyclePhase.menstrual:
        title = 'Period Week 🌙';
        body = 'Go easy today. Light movement is still progress.';
        break;
      case CyclePhase.follicular:
        title = 'Building Phase 🌱';
        body = 'Great time to push harder! Your body is primed for gains.';
        break;
      case CyclePhase.ovulation:
        title = 'Peak Performance ⭐';
        body = 'You\'re at your strongest. Make it count!';
        break;
      case CyclePhase.luteal:
        title = 'Wind Down Phase 🍂';
        body = 'Lower energy is normal. Maintaining is winning.';
        break;
    }

    // Schedule for tomorrow morning
    await _notifications.zonedSchedule(
      20, // Cycle notification ID
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cycle_reminder',
          'Cycle-Aware Tips',
          channelDescription: 'Training tips based on your cycle phase',
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

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by ID
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Setup all notifications based on user profile
  Future<void> setupNotifications(UserProfile profile) async {
    if (profile.notifyCheckIn) {
      await scheduleCheckInReminder(
        hour: profile.reminderHour,
        minute: profile.reminderMinute,
      );
    } else {
      await cancel(1);
    }

    if (profile.notifyWorkout) {
      // For now, schedule for all training days
      // You could make this smarter by checking the actual workout schedule
      final workoutDays = List.generate(
        profile.trainingDaysPerWeek,
        (i) => i + 1, // Monday = 1, etc.
      );
      await scheduleWorkoutReminder(
        hour: profile.reminderHour,
        minute: profile.reminderMinute,
        daysOfWeek: workoutDays,
      );
    } else {
      for (int i = 10; i <= 16; i++) {
        await cancel(i);
      }
    }

    // Schedule cycle notification if applicable
    if (profile.sex == 'female' && profile.trackCycle) {
      await scheduleCycleAwareNotification(
        profile: profile,
        hour: profile.reminderHour,
        minute: profile.reminderMinute,
      );
    }
  }

  // Helper: Get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // Helper: Get next instance of a specific day and time
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != dayOfWeek) {
      scheduled = scheduled.add(const Duration(days: 1));
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