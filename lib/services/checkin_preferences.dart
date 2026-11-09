import 'package:shared_preferences/shared_preferences.dart';

/// Presentation preference only: no notifications or measurement advice.
class CheckInPreferences {
  static const choices = ['manual', 'daily', 'weekly'];
  static const key = 'checkin_measurement_frequency_v1';
  Future<String> read() async {
    final value = (await SharedPreferences.getInstance()).getString(key);
    return choices.contains(value) ? value! : 'manual';
  }
  Future<void> save(String value) async {
    if (!choices.contains(value)) throw ArgumentError('Unknown frequency');
    if (!await (await SharedPreferences.getInstance()).setString(key, value)) throw StateError('Preference not saved');
  }
  static bool due(String preference, DateTime? lastMeasurement, DateTime now) {
    if (preference == 'manual' || !choices.contains(preference)) return false;
    if (lastMeasurement == null) return true;
    final then = lastMeasurement.toLocal(), current = now.toLocal();
    final days = DateTime.utc(current.year, current.month, current.day).difference(DateTime.utc(then.year, then.month, then.day)).inDays;
    return days >= (preference == 'weekly' ? 7 : 1);
  }
}
