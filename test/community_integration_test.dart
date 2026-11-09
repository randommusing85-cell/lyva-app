import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/circle_post.dart';
import 'package:lyva_app/models/circle_profile.dart';
import 'package:lyva_app/repos/community_repo.dart';

// Test-only Firestore boundary double; no production subclass is introduced.
// ignore: subtype_of_sealed_class
class _Document implements DocumentSnapshot<Map<String, dynamic>> {
  _Document(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'community identity fails closed for guests, mismatches and anonymous users',
    () {
      expect(
        communityIdentityMatches(
          verifiedUid: null,
          firebaseUid: 'u',
          anonymous: false,
        ),
        isFalse,
      );
      expect(
        communityIdentityMatches(
          verifiedUid: '',
          firebaseUid: '',
          anonymous: false,
        ),
        isFalse,
      );
      expect(
        communityIdentityMatches(
          verifiedUid: 'u',
          firebaseUid: 'v',
          anonymous: false,
        ),
        isFalse,
      );
      expect(
        communityIdentityMatches(
          verifiedUid: 'u',
          firebaseUid: 'u',
          anonymous: true,
        ),
        isFalse,
      );
      expect(
        communityIdentityMatches(
          verifiedUid: 'u',
          firebaseUid: 'u',
          anonymous: false,
        ),
        isTrue,
      );
    },
  );
  test(
    'missing community profile never implies adult confirmation or public visibility',
    () {
      final profile = CircleProfile.fromFirestore(_Document('member', {}));
      expect(profile.uid, 'member');
      expect(profile.adultConfirmed, isFalse);
      expect(profile.profileVisibility, 'circle_only');
      expect(profile.focusTags, isEmpty);
    },
  );

  test('community profile ignores malformed non-string focus tags', () {
    final profile = CircleProfile.fromFirestore(
      _Document('member', {
        'focusTags': ['strength', 42, null],
      }),
    );
    expect(profile.focusTags, ['strength']);
  });

  test('empty posts are not visible content or engaged', () {
    final post = CirclePost.fromFirestore(
      _Document('post', {'content': '   '}),
    );
    expect(post.hasVisibleContent, isFalse);
    expect(post.hasEngagement, isFalse);
  });

  test('photo-only post is visible and support preserves engagement', () {
    final post = CirclePost.fromFirestore(
      _Document('post', {
        'photoUrl': 'https://example.invalid/photo.jpg',
        'supportCount': 1,
      }),
    );
    expect(post.hasPhoto, isTrue);
    expect(post.hasVisibleContent, isTrue);
    expect(post.hasEngagement, isTrue);
  });

  test(
    'merged community entry uses shared account flow, preserving shell reminder lifecycle',
    () {
      final community = File(
        'lib/screens/community_screen.dart',
      ).readAsStringSync();
      expect(community, contains("Navigator.pushNamed(context, '/account')"));
      expect(community, isNot(contains('.signInWithApple()')));
      final shell = File('lib/screens/app_shell.dart').readAsStringSync();
      expect(shell, contains('CommunityScreen()'));
      expect(shell, contains('WidgetsBindingObserver'));
      expect(
        shell,
        contains('NotificationService().setupNotifications(profile)'),
      );
    },
  );
}
