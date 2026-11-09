import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityReport {
  final String id;
  final String targetType;
  final String targetId;
  final String? postId;
  final String targetAuthorId;
  final String reporterId;
  final String reason;
  final String status;
  final String? moderatorId;
  final String? moderatorAction;
  final String? moderatorNote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const CommunityReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.postId,
    required this.targetAuthorId,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.moderatorId,
    required this.moderatorAction,
    required this.moderatorNote,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  bool get isComment => targetType == 'comment';
  bool get isOpen => status == 'open';

  factory CommunityReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CommunityReport(
      id: doc.id,
      targetType: data['targetType'] as String? ?? 'post',
      targetId: data['targetId'] as String? ?? '',
      postId: data['postId'] as String?,
      targetAuthorId: data['targetAuthorId'] as String? ?? '',
      reporterId: data['reporterId'] as String? ?? '',
      reason: data['reason'] as String? ?? 'Other',
      status: data['status'] as String? ?? 'open',
      moderatorId: data['moderatorId'] as String?,
      moderatorAction: data['moderatorAction'] as String?,
      moderatorNote: data['moderatorNote'] as String?,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readNullableDate(data['updatedAt']),
      resolvedAt: _readNullableDate(data['resolvedAt']),
    );
  }
}

class ModerationTarget {
  final String id;
  final String targetType;
  final String authorId;
  final String authorName;
  final String content;
  final bool isRemoved;
  final DateTime createdAt;

  const ModerationTarget({
    required this.id,
    required this.targetType,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.isRemoved,
    required this.createdAt,
  });
}

DateTime _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _readNullableDate(Object? value) {
  if (value == null) return null;
  return _readDate(value);
}
