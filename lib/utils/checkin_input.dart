import '../models/checkin.dart';

class CheckInInput {
  static CheckIn parse({
    required DateTime now,
    String weight = '',
    String waist = '',
    String steps = '',
    String note = '',
    int? mood,
    int? energy,
    int? sleep,
    int? stress,
    int? soreness,
    int? hunger,
  }) {
    double? measure(String raw, double min, double max) {
      if (raw.trim().isEmpty) return null;
      final value = double.tryParse(raw.trim());
      if (value == null || !value.isFinite || value < min || value > max) {
        throw const FormatException('Invalid measurement');
      }
      return value;
    }

    final weightValue = measure(weight, 30, 250),
        waistValue = measure(waist, 40, 200);
    final stepValue = steps.trim().isEmpty ? null : int.tryParse(steps.trim());
    if (steps.trim().isNotEmpty &&
        (stepValue == null || stepValue < 0 || stepValue > 100000)) {
      throw const FormatException('Invalid steps');
    }
    if ([
      mood,
      energy,
      sleep,
      stress,
      soreness,
      hunger,
    ].any((v) => v != null && (v < 1 || v > 5))) {
      throw const FormatException('Invalid score');
    }
    if (note.length > 2000) throw const FormatException('Note too long');
    if (weightValue == null &&
        waistValue == null &&
        stepValue == null &&
        mood == null &&
        energy == null &&
        sleep == null &&
        stress == null &&
        soreness == null &&
        hunger == null &&
        note.trim().isEmpty) {
      throw const FormatException('Add at least one item to your check-in.');
    }
    return CheckIn()
      ..ts = now
      ..weightKg = weightValue
      ..waistCm = waistValue
      ..stepsToday = stepValue
      ..sleepScore = sleep
      ..stressScore = stress
      ..sorenessScore = soreness
      ..hungerScore = hunger
      ..moodScore = mood
      ..energyScore = energy
      ..note = note.trim().isEmpty ? null : note.trim();
  }
}
