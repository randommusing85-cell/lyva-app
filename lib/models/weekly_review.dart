import 'package:isar/isar.dart';
part 'weekly_review.g.dart';

/// Local no-change decisions only. Never stores source health text or targets.
@collection
class WeeklyReview {
  Id id = Isar.autoIncrement;
  int schemaVersion = 1;
  late DateTime weekStart;
  late DateTime createdAt;
  late String sourceRevision;
  String decisionToken = '';
  String status = 'draft';
  DateTime? decidedAt;
}
