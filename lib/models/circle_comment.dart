import 'package:cloud_firestore/cloud_firestore.dart';

class CircleComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final int reportCount;
  final bool isRemoved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CircleComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.reportCount,
    required this.isRemoved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CircleComment.fromFirestore(
    String postId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CircleComment(
      id: doc.id,
      postId: postId,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Lyva member',
      content: data['content'] as String? ?? '',
      reportCount: data['reportCount'] as int? ?? 0,
      isRemoved: data['isRemoved'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }
}

DateTime _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
