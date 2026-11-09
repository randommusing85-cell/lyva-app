import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/circle_comment.dart';
import '../models/circle_post.dart';
import '../models/circle_profile.dart';
import '../models/community_report.dart';
import '../models/user_profile.dart';

class CommunityAccessException implements Exception {
  final String message;
  const CommunityAccessException(this.message);

  @override
  String toString() => message;
}

/// UI boundary only: Firestore/Storage rules must independently authorize users.
bool communityIdentityMatches({
  required String? verifiedUid,
  required String? firebaseUid,
  required bool anonymous,
}) =>
    verifiedUid != null &&
    verifiedUid.isNotEmpty &&
    verifiedUid == firebaseUid &&
    !anonymous;

class CommunityRepo {
  CommunityRepo({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    required String? Function() verifiedUid,
  }) : _verifiedUid = verifiedUid,
       _firestoreInstance = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageInstance = storage ?? FirebaseStorage.instance;

  final String? Function() _verifiedUid;
  final FirebaseFirestore _firestoreInstance;
  final FirebaseAuth _auth;
  final FirebaseStorage _storageInstance;

  void _requireCommunityBuild() {
    if (const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD')) {
      throw const CommunityAccessException(
        'Circles is unavailable in this billing test build.',
      );
    }
  }

  FirebaseFirestore get _firestore {
    _requireCommunityBuild();
    return _firestoreInstance;
  }

  FirebaseStorage get _storage {
    _requireCommunityBuild();
    return _storageInstance;
  }

  static const int maxPostPhotoBytes = 5 * 1024 * 1024;

  static const Set<String> allowedCategories = {
    'wins',
    'recipes',
    'form',
    'questions',
    'cycle',
    'postpartum',
  };

  static const Set<String> allowedFocusTags = {
    'strength',
    'fat_loss',
    'recomp',
    'nutrition',
    'cycle_aware',
    'postpartum',
    'mobility',
    'consistency',
  };

  static const Set<String> allowedAvatarColors = {
    'sage',
    'clay',
    'rose',
    'gold',
    'blue',
  };

  User? get currentUser {
    if (const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD')) return null;
    final user = _auth.currentUser;
    if (user == null ||
        !communityIdentityMatches(
          verifiedUid: _verifiedUid(),
          firebaseUid: user.uid,
          anonymous: user.isAnonymous,
        )) {
      return null;
    }
    return user;
  }

  Stream<User?> watchAuthUser() {
    if (const bool.fromEnvironment('LYVA_SANDBOX_TEST_BUILD')) {
      return Stream.value(null);
    }
    return _auth.authStateChanges().map((user) {
      if (user == null ||
          !communityIdentityMatches(
            verifiedUid: _verifiedUid(),
            firebaseUid: user.uid,
            anonymous: user.isAnonymous,
          )) {
        return null;
      }
      return user;
    });
  }

  User _requireSignedInUser() {
    final user = currentUser;
    if (user == null) {
      throw const CommunityAccessException(
        'Sign in to your verified Lyva account to use Circles.',
      );
    }
    return user;
  }

  Future<bool> isCurrentUserModerator() async {
    final user = currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? <String, dynamic>{};
    return claims['moderator'] == true || claims['admin'] == true;
  }

  Future<CircleProfile> ensureCurrentProfile(UserProfile profile) async {
    if (profile.age < 18) {
      throw const CommunityAccessException(
        'Lyva Circles is available to adults 18 and older.',
      );
    }

    final user = _requireSignedInUser();
    final displayName = _displayNameFor(profile);
    final ref = _firestore.collection('communityProfiles').doc(user.uid);
    final snapshot = await ref.get();

    final data = <String, dynamic>{
      'uid': user.uid,
      'profileVisibility': 'circle_only',
      'adultConfirmed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (snapshot.exists) {
      final existing = snapshot.data() ?? <String, dynamic>{};
      await ref.set({
        ...data,
        if ((existing['displayName'] as String?)?.trim().isEmpty ?? true)
          'displayName': displayName,
        if (existing['bio'] == null) 'bio': '',
        if (existing['focusTags'] == null) 'focusTags': <String>[],
        if (existing['avatarColor'] == null)
          'avatarColor': _avatarColorFor(user.uid),
        if (existing['followerCount'] == null) 'followerCount': 0,
        if (existing['followingCount'] == null) 'followingCount': 0,
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        ...data,
        'displayName': displayName,
        'bio': '',
        'focusTags': <String>[],
        'avatarColor': _avatarColorFor(user.uid),
        'followerCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final updated = await ref.get();
    return CircleProfile.fromFirestore(updated);
  }

  Stream<CircleProfile?> watchProfile(String uid) {
    return _firestore.collection('communityProfiles').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return CircleProfile.fromFirestore(snapshot);
    });
  }

  Stream<List<CirclePost>> watchPostsByAuthor(String authorId) {
    return _firestore
        .collection('circlePosts')
        .where('authorId', isEqualTo: authorId)
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CirclePost.fromFirestore)
              .where((post) => post.hasVisibleContent)
              .toList(growable: false),
        );
  }

  Stream<bool> watchIsFollowing(String profileUid) {
    final user = _requireSignedInUser();
    if (profileUid == user.uid) return Stream<bool>.value(false);

    return _firestore
        .collection('communityProfiles')
        .doc(user.uid)
        .collection('following')
        .doc(profileUid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> updateCurrentPublicProfile({
    required String displayName,
    required String bio,
    required List<String> focusTags,
    required String avatarColor,
  }) async {
    final user = _requireSignedInUser();
    final safeDisplayName = _validateDisplayName(displayName);
    final safeBio = _validateOptionalProfileText(bio, maxLength: 160);
    final safeFocusTags = focusTags
        .where(allowedFocusTags.contains)
        .take(5)
        .toList(growable: false);
    final safeAvatarColor = allowedAvatarColors.contains(avatarColor)
        ? avatarColor
        : 'sage';

    await _firestore.collection('communityProfiles').doc(user.uid).set({
      'uid': user.uid,
      'displayName': safeDisplayName,
      'bio': safeBio,
      'focusTags': safeFocusTags,
      'avatarColor': safeAvatarColor,
      'profileVisibility': 'circle_only',
      'adultConfirmed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleFollow(String profileUid) async {
    final user = _requireSignedInUser();
    if (profileUid == user.uid) return;

    final currentProfileRef = _firestore
        .collection('communityProfiles')
        .doc(user.uid);
    final targetProfileRef = _firestore
        .collection('communityProfiles')
        .doc(profileUid);
    final followingRef = currentProfileRef
        .collection('following')
        .doc(profileUid);
    final followerRef = targetProfileRef.collection('followers').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final followingSnapshot = await transaction.get(followingRef);
      final targetSnapshot = await transaction.get(targetProfileRef);
      if (!targetSnapshot.exists) {
        throw const CommunityAccessException('That profile is no longer here.');
      }

      if (followingSnapshot.exists) {
        transaction.delete(followingRef);
        transaction.delete(followerRef);
        transaction.update(currentProfileRef, {
          'followingCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(targetProfileRef, {
          'followerCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final now = FieldValue.serverTimestamp();
        transaction.set(followingRef, {
          'followerId': user.uid,
          'followedId': profileUid,
          'createdAt': now,
        });
        transaction.set(followerRef, {
          'followerId': user.uid,
          'followedId': profileUid,
          'createdAt': now,
        });
        transaction.update(currentProfileRef, {
          'followingCount': FieldValue.increment(1),
          'updatedAt': now,
        });
        transaction.update(targetProfileRef, {
          'followerCount': FieldValue.increment(1),
          'updatedAt': now,
        });
      }
    });
  }

  Stream<List<CirclePost>> watchPosts({required String category}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('circlePosts')
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(60);

    if (category != 'all') {
      query = _firestore
          .collection('circlePosts')
          .where('category', isEqualTo: category)
          .where('isRemoved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(60);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(CirclePost.fromFirestore)
          .where((post) => post.hasVisibleContent)
          .toList(growable: false),
    );
  }

  Stream<List<CircleComment>> watchComments(String postId) {
    return _firestore
        .collection('circlePosts')
        .doc(postId)
        .collection('comments')
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt')
        .limit(120)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CircleComment.fromFirestore(postId, doc))
              .where((comment) => comment.content.trim().isNotEmpty)
              .toList(growable: false),
        );
  }

  Stream<Set<String>> watchBlockedUserIds() async* {
    final user = _requireSignedInUser();
    yield* _firestore
        .collection('communityProfiles')
        .doc(user.uid)
        .collection('blocked')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<bool> watchPostSupport(String postId) async* {
    final user = _requireSignedInUser();
    yield* _firestore
        .collection('circlePosts')
        .doc(postId)
        .collection('supports')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> createPost({
    required UserProfile profile,
    required String category,
    required String content,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    final user = _requireSignedInUser();
    final safeCategory = allowedCategories.contains(category)
        ? category
        : 'wins';
    final hasPhoto = photoBytes != null && photoBytes.isNotEmpty;
    final safeContent = _validateContent(
      content,
      maxLength: 1200,
      minLength: hasPhoto ? 0 : 8,
    );

    if (profile.age < 18) {
      throw const CommunityAccessException(
        'Lyva Circles is available to adults 18 and older.',
      );
    }

    String photoUrl = '';
    String photoPath = '';
    String safePhotoContentType = '';
    var photoSizeBytes = 0;
    final postRef = _firestore.collection('circlePosts').doc();

    if (hasPhoto) {
      photoSizeBytes = photoBytes.length;
      if (photoSizeBytes > maxPostPhotoBytes) {
        throw const CommunityAccessException(
          'Please choose a photo under 5 MB.',
        );
      }

      safePhotoContentType = _safeImageContentType(photoContentType);
      photoPath = 'circle-post-photos/${user.uid}/${postRef.id}.jpg';
      final storageRef = _storage.ref(photoPath);
      await storageRef.putData(
        photoBytes,
        SettableMetadata(
          contentType: safePhotoContentType,
          customMetadata: {'ownerId': user.uid, 'postId': postRef.id},
        ),
      );
      photoUrl = await storageRef.getDownloadURL();
    }

    final authorName = _displayNameFor(profile);
    try {
      await postRef.set({
        'authorId': user.uid,
        'authorName': authorName,
        'category': safeCategory,
        'content': safeContent,
        if (hasPhoto) ...{
          'photoUrl': photoUrl,
          'photoPath': photoPath,
          'photoContentType': safePhotoContentType,
          'photoSizeBytes': photoSizeBytes,
        },
        'supportCount': 0,
        'commentCount': 0,
        'reportCount': 0,
        'isEdited': false,
        'isRemoved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (photoPath.isNotEmpty) {
        await _storage.ref(photoPath).delete().catchError((_) {});
      }
      rethrow;
    }
  }

  Future<void> addComment({
    required String postId,
    required UserProfile profile,
    required String content,
  }) async {
    final user = _requireSignedInUser();
    final safeContent = _validateContent(content, maxLength: 700);
    final postRef = _firestore.collection('circlePosts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(postRef.collection('comments').doc(), {
        'authorId': user.uid,
        'authorName': _displayNameFor(profile),
        'content': safeContent,
        'reportCount': 0,
        'isRemoved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> toggleSupport(String postId) async {
    final user = _requireSignedInUser();
    final postRef = _firestore.collection('circlePosts').doc(postId);
    final supportRef = postRef.collection('supports').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final support = await transaction.get(supportRef);
      if (support.exists) {
        transaction.delete(supportRef);
        transaction.update(postRef, {
          'supportCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(supportRef, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'supportCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> removePost(CirclePost post) async {
    final user = _requireSignedInUser();
    if (post.authorId != user.uid) return;

    await _firestore.collection('circlePosts').doc(post.id).update({
      'isRemoved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeComment(CircleComment comment) async {
    final user = _requireSignedInUser();
    if (comment.authorId != user.uid) return;

    final postRef = _firestore.collection('circlePosts').doc(comment.postId);
    final commentRef = postRef.collection('comments').doc(comment.id);

    await _firestore.runTransaction((transaction) async {
      transaction.update(commentRef, {
        'isRemoved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> reportPost({
    required CirclePost post,
    required String reason,
  }) async {
    final user = _requireSignedInUser();
    await _firestore
        .collection('communityReports')
        .doc('post_${post.id}_${user.uid}')
        .set({
          'targetType': 'post',
          'targetId': post.id,
          'targetAuthorId': post.authorId,
          'reporterId': user.uid,
          'reason': reason,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    await _firestore.collection('circlePosts').doc(post.id).update({
      'reportCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportComment({
    required CircleComment comment,
    required String reason,
  }) async {
    final user = _requireSignedInUser();
    await _firestore
        .collection('communityReports')
        .doc('comment_${comment.id}_${user.uid}')
        .set({
          'targetType': 'comment',
          'targetId': comment.id,
          'postId': comment.postId,
          'targetAuthorId': comment.authorId,
          'reporterId': user.uid,
          'reason': reason,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    await _firestore
        .collection('circlePosts')
        .doc(comment.postId)
        .collection('comments')
        .doc(comment.id)
        .update({
          'reportCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> blockUser(String blockedUserId) async {
    final user = _requireSignedInUser();
    if (blockedUserId == user.uid) return;

    await _firestore
        .collection('communityProfiles')
        .doc(user.uid)
        .collection('blocked')
        .doc(blockedUserId)
        .set({
          'blockedUserId': blockedUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<CommunityReport>> watchOpenReports() {
    return _firestore
        .collection('communityReports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CommunityReport.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<ModerationTarget?> getModerationTarget(CommunityReport report) async {
    if (report.targetType == 'post') {
      final doc = await _firestore
          .collection('circlePosts')
          .doc(report.targetId)
          .get();
      final post = doc.exists ? CirclePost.fromFirestore(doc) : null;
      if (post == null) return null;
      return ModerationTarget(
        id: post.id,
        targetType: 'post',
        authorId: post.authorId,
        authorName: post.authorName,
        content: post.content,
        isRemoved: post.isRemoved,
        createdAt: post.createdAt,
      );
    }

    final postId = report.postId;
    if (postId == null || postId.isEmpty) return null;

    final doc = await _firestore
        .collection('circlePosts')
        .doc(postId)
        .collection('comments')
        .doc(report.targetId)
        .get();
    final comment = doc.exists
        ? CircleComment.fromFirestore(postId, doc)
        : null;
    if (comment == null) return null;
    return ModerationTarget(
      id: comment.id,
      targetType: 'comment',
      authorId: comment.authorId,
      authorName: comment.authorName,
      content: comment.content,
      isRemoved: comment.isRemoved,
      createdAt: comment.createdAt,
    );
  }

  Future<void> dismissReport(CommunityReport report) async {
    final user = _requireSignedInUser();
    await _firestore.collection('communityReports').doc(report.id).update({
      'status': 'dismissed',
      'moderatorId': user.uid,
      'moderatorAction': 'dismissed',
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeReportedContent(CommunityReport report) async {
    final user = _requireSignedInUser();
    final reportRef = _firestore.collection('communityReports').doc(report.id);

    await _firestore.runTransaction((transaction) async {
      if (report.targetType == 'post') {
        final postRef = _firestore
            .collection('circlePosts')
            .doc(report.targetId);
        transaction.update(postRef, {
          'isRemoved': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final postId = report.postId;
        if (postId == null || postId.isEmpty) {
          throw const CommunityAccessException(
            'Reported comment is missing a post id.',
          );
        }

        final postRef = _firestore.collection('circlePosts').doc(postId);
        final commentRef = postRef.collection('comments').doc(report.targetId);
        final commentSnapshot = await transaction.get(commentRef);
        final isAlreadyRemoved =
            commentSnapshot.data()?['isRemoved'] as bool? ?? false;

        transaction.update(commentRef, {
          'isRemoved': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!isAlreadyRemoved) {
          transaction.update(postRef, {
            'commentCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.update(reportRef, {
        'status': 'removed',
        'moderatorId': user.uid,
        'moderatorAction': 'removed_content',
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _displayNameFor(UserProfile profile) {
    final trimmed = profile.name.trim();
    if (trimmed.isEmpty) return 'Lyva member';
    final first = trimmed.split(RegExp(r'\s+')).first.trim();
    if (first.length < 2) return 'Lyva member';
    return first.length > 24 ? first.substring(0, 24) : first;
  }

  String _avatarColorFor(String uid) {
    final colors = allowedAvatarColors.toList(growable: false);
    final index = uid.codeUnits.fold<int>(0, (total, code) => total + code);
    return colors[index % colors.length];
  }

  String _validateDisplayName(String value) {
    final trimmed = _validateOptionalProfileText(value, maxLength: 32);
    if (trimmed.length < 2) {
      throw const CommunityAccessException(
        'Please choose a display name with at least 2 characters.',
      );
    }
    return trimmed;
  }

  String _validateOptionalProfileText(
    String content, {
    required int maxLength,
  }) {
    final trimmed = content.trim();
    if (trimmed.length > maxLength) {
      throw CommunityAccessException(
        'Please keep this under $maxLength characters.',
      );
    }

    final hasEmail = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,}\b').hasMatch(trimmed);
    final hasPhone = RegExp(
      r'\b(?:\+?\d[\d\-\s().]{7,}\d)\b',
    ).hasMatch(trimmed);
    if (hasEmail || hasPhone) {
      throw const CommunityAccessException(
        'For privacy, avoid sharing contact details in Circles.',
      );
    }

    return trimmed;
  }

  String _validateContent(
    String content, {
    required int maxLength,
    int minLength = 8,
  }) {
    final trimmed = content.trim();
    if (trimmed.length < minLength) {
      throw const CommunityAccessException(
        'Please share a little more detail.',
      );
    }
    if (trimmed.length > maxLength) {
      throw CommunityAccessException(
        'Please keep this under $maxLength characters.',
      );
    }

    final lower = trimmed.toLowerCase();
    const unsafePhrases = [
      'thinspo',
      'pro ana',
      'pro-ana',
      'purge tips',
      'starve yourself',
      'laxative diet',
    ];
    if (unsafePhrases.any(lower.contains)) {
      throw const CommunityAccessException(
        'That looks like unsafe fitness or diet advice. Please rephrase it.',
      );
    }

    final hasEmail = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,}\b').hasMatch(trimmed);
    final hasPhone = RegExp(
      r'\b(?:\+?\d[\d\-\s().]{7,}\d)\b',
    ).hasMatch(trimmed);
    if (hasEmail || hasPhone) {
      throw const CommunityAccessException(
        'For privacy, avoid sharing contact details in Circles.',
      );
    }

    return trimmed;
  }

  String _safeImageContentType(String? contentType) {
    final normalized = contentType?.toLowerCase().trim() ?? '';
    if (normalized == 'image/png') return 'image/png';
    if (normalized == 'image/heic') return 'image/heic';
    if (normalized == 'image/heif') return 'image/heif';
    return 'image/jpeg';
  }
}
