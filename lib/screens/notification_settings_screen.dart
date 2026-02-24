import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _notifyCheckIn = true;
  bool _notifyWorkout = true;
  bool _notifyCycle = true;
  bool _showCycleToggle = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        setState(() {
          _notifyCheckIn = profile.notifyCheckIn;
          _notifyWorkout = profile.notifyWorkout;
          _notifyCycle = profile.notifyCycle;
          _showCycleToggle = profile.sex == 'female' && profile.trackCycle;
          _reminderHour = profile.reminderHour;
          _reminderMinute = profile.reminderMinute;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final repo = ref.read(userProfileRepoProvider);
      final profile = await repo.getProfile();

      if (profile != null) {
        profile.notifyCheckIn = _notifyCheckIn;
        profile.notifyWorkout = _notifyWorkout;
        profile.notifyCycle = _notifyCycle;
        profile.reminderHour = _reminderHour;
        profile.reminderMinute = _reminderMinute;
        profile.updatedAt = DateTime.now();

        await repo.saveProfile(profile);
        
        // Update notifications
        await NotificationService().setupNotifications(profile);
        
        ref.invalidate(userProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification settings saved ✅')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );

    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notifications enabled ✅'
                : 'Notification permission denied',
          ),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await NotificationService().showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText =
        '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Permission request
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Stay Consistent',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gentle reminders help build habits. We\'ll never spam you.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Enable Notifications'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Reminder settings
          SwitchListTile(
            title: const Text('Daily Check-in Reminder'),
            subtitle: const Text('Remind me to log weight & waist'),
            value: _notifyCheckIn,
            onChanged: (v) => setState(() => _notifyCheckIn = v),
          ),

          SwitchListTile(
            title: const Text('Workout Day Reminder'),
            subtitle: const Text('Remind me on training days'),
            value: _notifyWorkout,
            onChanged: (v) => setState(() => _notifyWorkout = v),
          ),

          if (_showCycleToggle)
            SwitchListTile(
              title: const Text('Cycle Check-in'),
              subtitle: const Text('Daily tips based on your cycle phase'),
              value: _notifyCycle,
              onChanged: (v) => setState(() => _notifyCycle = v),
            ),

          const Divider(),

          // Time picker
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder Time'),
            subtitle: Text(timeText),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectTime,
          ),

          const Divider(),

          // Test notification
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Test Notification'),
            subtitle: const Text('Send a test notification now'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _testNotification,
          ),

          const SizedBox(height: 24),

          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tip: Set reminders for a time when you\'re usually free to log or train.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}