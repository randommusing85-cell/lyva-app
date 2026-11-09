import 'package:cloud_firestore/cloud_firestore.dart';

class CirclePost {
  final String id;
  final String authorId;
  final String authorName;
  final String category;
  final String content;
  final String photoUrl;
  final String photoPath;
  final String photoContentType;
  final int photoSizeBytes;
  final int supportCount;
  final int commentCount;
  final int reportCount;
  final bool isEdited;
  final bool isRemoved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CirclePost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.content,
    required this.photoUrl,
    required this.photoPath,
    required this.photoContentType,
    required this.photoSizeBytes,
    required this.supportCount,
    required this.commentCount,
    required this.reportCount,
    required this.isEdited,
    required this.isRemoved,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasEngagement => supportCount > 0 || commentCount > 0;
  bool get hasPhoto => photoUrl.trim().isNotEmpty;
  bool get hasVisibleContent => content.trim().isNotEmpty || hasPhoto;

  factory CirclePost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CirclePost(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Lyva member',
      category: data['category'] as String? ?? 'wins',
      content: data['content'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      photoPath: data['photoPath'] as String? ?? '',
      photoContentType: data['photoContentType'] as String? ?? '',
      photoSizeBytes: data['photoSizeBytes'] as int? ?? 0,
      supportCount: data['supportCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
      isEdited: data['isEdited'] as bool? ?? false,
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
