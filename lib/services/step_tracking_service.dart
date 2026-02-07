import 'package:health/health.dart';

class StepTrackingService {
  final Health _health = Health();
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _permissions = [HealthDataAccess.READ];

  /// Ensure Health is configured before use.
  Future<void> _ensureConfigured() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }
  }

  /// Request read permission for step data.
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(_types, permissions: _permissions);
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Check if we have authorization to read steps.
  Future<bool> isAuthorized() async {
    try {
      await _ensureConfigured();
      final result = await _health.hasPermissions(_types, permissions: _permissions);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Get total steps for today (midnight to now).
  Future<int> getTodaySteps() async {
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return _getStepsInRange(midnight, now);
  }

  /// Get total steps for a specific date.
  Future<int> getStepsForDate(DateTime date) async {
    await _ensureConfigured();
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _getStepsInRange(start, end);
  }

  /// Get daily step totals for the last 7 days.
  Future<Map<DateTime, int>> getWeeklySteps() async {
    await _ensureConfigured();
    final now = DateTime.now();
    final results = <DateTime, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      results[date] = await getStepsForDate(date);
    }

    return results;
  }

  Future<int> _getStepsInRange(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
