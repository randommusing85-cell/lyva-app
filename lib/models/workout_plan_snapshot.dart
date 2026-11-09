import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'workout_exercise.dart';
import 'workout_session_doc.dart';
import 'workout_template_doc.dart';

/// Frozen prescribed plan, not inferred exercise performance. JSON copies prevent
/// a caller's later edits from modifying the captured session history.
class WorkoutPlanSnapshot {
  final String planId;
  final int sourceTemplateId;
  final String json;
  const WorkoutPlanSnapshot._(this.planId, this.sourceTemplateId, this.json);

  static Object? _ordered(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _ordered(value[key])};
    }
    if (value is List) return value.map(_ordered).toList();
    return value;
  }

  factory WorkoutPlanSnapshot.capture(WorkoutTemplateDoc doc) {
    final template = WorkoutExercise.normalizeTemplate(
      Map<String, dynamic>.from(jsonDecode(doc.json) as Map),
    );
    template['planName'] = doc.planName;
    template['daysPerWeek'] = doc.daysPerWeek;
    final canonical = jsonEncode(_ordered(template));
    final id = 'template:${doc.id}:${sha256.convert(utf8.encode(canonical))}';
    return WorkoutPlanSnapshot._(
      id,
      doc.id,
      jsonEncode({
        'schemaVersion': 1,
        'planId': id,
        'sourceTemplateId': doc.id,
        'template': jsonDecode(canonical),
      }),
    );
  }

  static WorkoutPlanSnapshot? fromSession(WorkoutSessionDoc session) {
    try {
      final raw = session.templateSnapshotJson;
      if (raw == null || session.planId == null) return null;
      final data = jsonDecode(raw);
      if (data is! Map ||
          data['schemaVersion'] != 1 ||
          data['planId'] != session.planId ||
          data['sourceTemplateId'] is! int ||
          data['template'] is! Map) {
        return null;
      }
      final template = data['template'] as Map;
      if (template['daysPerWeek'] is! int ||
          template['daysPerWeek'] < 1 ||
          template['planName'] is! String) {
        return null;
      }
      final fingerprint = sha256.convert(
        utf8.encode(jsonEncode(_ordered(template))),
      );
      if (session.planId !=
          'template:${data['sourceTemplateId']}:$fingerprint') {
        return null;
      }
      final result = WorkoutPlanSnapshot._(
        session.planId!,
        data['sourceTemplateId'] as int,
        raw,
      );
      if (result.day(session.dayIndex) == null) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> get template =>
      Map<String, dynamic>.from(jsonDecode(json)['template'] as Map);
  String get name => template['planName']?.toString() ?? 'Workout plan';
  int get daysPerWeek => (template['daysPerWeek'] as num).toInt();
  Map<String, dynamic>? day(int dayIndex) {
    final days = template['days'];
    if (days is! List) return null;
    final matches = days
        .whereType<Map>()
        .where((d) => d['dayIndex'] == dayIndex)
        .toList();
    return matches.length == 1
        ? Map<String, dynamic>.from(matches.single)
        : null;
  }
}
