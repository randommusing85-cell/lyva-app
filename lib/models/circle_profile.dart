import 'package:cloud_firestore/cloud_firestore.dart';

class CircleProfile {
  final String uid;
  final String displayName;
  final String bio;
  final List<String> focusTags;
  final String avatarColor;
  final String profileVisibility;
  final bool adultConfirmed;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CircleProfile({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.focusTags,
    required this.avatarColor,
    required this.profileVisibility,
    required this.adultConfirmed,
    required this.followerCount,
    required this.followingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CircleProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CircleProfile(
      uid: data['uid'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? 'Lyva member',
      bio: data['bio'] as String? ?? '',
      focusTags: _readStringList(data['focusTags']),
      avatarColor: data['avatarColor'] as String? ?? 'sage',
      profileVisibility: data['profileVisibility'] as String? ?? 'circle_only',
      adultConfirmed: data['adultConfirmed'] as bool? ?? false,
      followerCount: data['followerCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

DateTime _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
