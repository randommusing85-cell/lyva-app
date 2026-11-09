import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/circle_comment.dart';
import '../models/circle_post.dart';
import '../models/user_profile.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _postController = TextEditingController();
  final _imagePicker = ImagePicker();
  String _composerCategory = 'wins';
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  String? _selectedPhotoMimeType;
  final bool _signingIn = false;
  bool _posting = false;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost(UserProfile profile) async {
    if (_posting) return;
    setState(() => _posting = true);

    try {
      await ref
          .read(communityRepoProvider)
          .createPost(
            profile: profile,
            category: _composerCategory,
            content: _postController.text,
            photoBytes: _selectedPhotoBytes,
            photoContentType: _selectedPhotoMimeType,
          );
      _postController.clear();
      setState(() {
        _selectedPhotoBytes = null;
        _selectedPhotoName = null;
        _selectedPhotoMimeType = null;
      });
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shared with Circles')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_posting || _pickingPhoto) return;
    setState(() => _pickingPhoto = true);

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      if (bytes.length > _maxPostPhotoBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please choose a photo under 5 MB')),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoName = photo.name;
        _selectedPhotoMimeType = photo.mimeType;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
      _selectedPhotoMimeType = null;
    });
  }

  // Use the shared account flow so Circles cannot bypass identity/billing guards.
  Future<void> _signInWithApple() async {
    await Navigator.pushNamed(context, '/account');
    if (!mounted) return;
    ref.invalidate(circleAuthUserProvider);
    ref.invalidate(currentCircleProfileProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(circleAuthUserProvider);
    ref.invalidate(currentCircleProfileProvider);
    ref.invalidate(blockedCircleUsersProvider);
    ref.invalidate(circlePostsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final authAsync = ref.watch(circleAuthUserProvider);
    final circleProfileAsync = ref.watch(currentCircleProfileProvider);
    final selectedCategory = ref.watch(selectedCircleCategoryProvider);
    final postsAsync = ref.watch(circlePostsProvider);
    final blockedAsync = ref.watch(blockedCircleUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) {
              return const _CommunityMessage(
                icon: Icons.person_outline,
                title: 'Finish your profile first',
                message: 'Circles opens after Lyva knows your basic profile.',
              );
            }

            if (profile.age < 18) {
              return const _CommunityMessage(
                icon: Icons.lock_outline,
                title: 'Circles is 18+',
                message:
                    'Lyva community spaces are currently limited to adults.',
              );
            }

            return authAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _CommunityMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Could not check sign-in',
                message: e.toString(),
              ),
              data: (authUser) {
                if (authUser == null) {
                  return _CircleSignInGate(
                    signingIn: _signingIn,
                    onSignIn: _signInWithApple,
                  );
                }

                return circleProfileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _CommunityMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Circles is unavailable',
                    message: e.toString(),
                  ),
                  data: (_) {
                    final blockedUserIds =
                        blockedAsync.valueOrNull ?? <String>{};

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Circles',
                                      style: theme.textTheme.displayMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Private-by-default support from the Lyva community',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: IconButton(
                                  tooltip: 'My Circles profile',
                                  icon: const Icon(
                                    Icons.person_outline,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/community/profile',
                                    arguments: authUser.uid,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _ComposerCard(
                            controller: _postController,
                            selectedCategory: _composerCategory,
                            selectedPhotoBytes: _selectedPhotoBytes,
                            selectedPhotoName: _selectedPhotoName,
                            posting: _posting,
                            pickingPhoto: _pickingPhoto,
                            onCategoryChanged: (category) {
                              setState(() => _composerCategory = category);
                            },
                            onPickPhoto: _pickPhoto,
                            onRemovePhoto: _removePhoto,
                            onPost: () => _createPost(profile),
                          ),
                          const SizedBox(height: 18),
                          _CategoryStrip(
                            selectedCategory: selectedCategory,
                            onSelected: (category) {
                              ref
                                      .read(
                                        selectedCircleCategoryProvider.notifier,
                                      )
                                      .state =
                                  category;
                            },
                          ),
                          const SizedBox(height: 16),
                          postsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.only(top: 72),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => _FeedError(message: e.toString()),
                            data: (posts) {
                              final visiblePosts = posts
                                  .where(
                                    (post) =>
                                        !blockedUserIds.contains(post.authorId),
                                  )
                                  .toList(growable: false);

                              if (visiblePosts.isEmpty) {
                                return const _EmptyCirclesState();
                              }

                              return Column(
                                children: [
                                  for (final post in visiblePosts) ...[
                                    _CirclePostCard(
                                      post: post,
                                      onOpenComments: () => Navigator.pushNamed(
                                        context,
                                        '/community/post',
                                        arguments: post,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  const SizedBox(height: 20),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CircleSignInGate extends StatelessWidget {
  const _CircleSignInGate({required this.signingIn, required this.onSignIn});

  final bool signingIn;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(38),
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Sign in for Circles',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Community posts, replies, reports, and blocks are connected to your Lyva account.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: signingIn ? null : onSignIn,
                icon: signingIn
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.account_circle_outlined),
                label: const Text('Open account sign-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CirclePostDetailScreen extends ConsumerStatefulWidget {
  const CirclePostDetailScreen({super.key});

  @override
  ConsumerState<CirclePostDetailScreen> createState() =>
      _CirclePostDetailScreenState();
}

class _CirclePostDetailScreenState
    extends ConsumerState<CirclePostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment(CirclePost post, UserProfile profile) async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      await ref
          .read(communityRepoProvider)
          .addComment(
            postId: post.id,
            profile: profile,
            content: _commentController.text,
          );
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! CirclePost) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }

    final post = args;
    final profileAsync = ref.watch(userProfileProvider);
    final authAsync = ref.watch(circleAuthUserProvider);
    final commentsAsync = ref.watch(circleCommentsProvider(post.id));
    final blockedAsync = ref.watch(blockedCircleUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Conversation'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _CirclePostCard(post: post),
                  const SizedBox(height: 16),
                  Text(
                    'Replies',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _FeedError(message: e.toString()),
                    data: (comments) {
                      final blockedUserIds =
                          blockedAsync.valueOrNull ?? <String>{};
                      final visibleComments = comments
                          .where(
                            (comment) =>
                                !blockedUserIds.contains(comment.authorId),
                          )
                          .toList(growable: false);

                      if (visibleComments.isEmpty) {
                        return const _QuietCommentState();
                      }

                      return Column(
                        children: [
                          for (final comment in visibleComments) ...[
                            _CommentTile(comment: comment),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (profile) {
                if (profile == null ||
                    profile.age < 18 ||
                    authAsync.valueOrNull == null) {
                  return const SizedBox.shrink();
                }
                return _CommentComposer(
                  controller: _commentController,
                  sending: _sending,
                  onSend: () => _addComment(post, profile),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.selectedCategory,
    required this.selectedPhotoBytes,
    required this.selectedPhotoName,
    required this.posting,
    required this.pickingPhoto,
    required this.onCategoryChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onPost,
  });

  final TextEditingController controller;
  final String selectedCategory;
  final Uint8List? selectedPhotoBytes;
  final String? selectedPhotoName;
  final bool posting;
  final bool pickingPhoto;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.add_comment_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Share with care',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: selectedPhotoBytes == null ? 3 : 2,
            maxLines: 6,
            maxLength: 1200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: selectedPhotoBytes == null
                  ? 'A win, recipe, form question, or gentle ask...'
                  : 'Add a caption...',
              counterText: '',
            ),
          ),
          if (selectedPhotoBytes != null) ...[
            const SizedBox(height: 12),
            _SelectedPhotoPreview(
              bytes: selectedPhotoBytes!,
              fileName: selectedPhotoName,
              onRemove: posting ? null : onRemovePhoto,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _postCategories)
                ChoiceChip(
                  label: Text(category.label),
                  selected: selectedCategory == category.id,
                  onSelected: (_) => onCategoryChanged(category.id),
                  avatar: Icon(category.icon, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: posting || pickingPhoto ? null : onPickPhoto,
                icon: pickingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        selectedPhotoBytes == null
                            ? Icons.add_photo_alternate_outlined
                            : Icons.photo_library_outlined,
                      ),
                label: Text(
                  selectedPhotoBytes == null ? 'Add photo' : 'Change',
                ),
              ),
              if (selectedPhotoBytes != null) ...[
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: posting ? null : onRemovePhoto,
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No medical advice, body checks, shaming, contact details, or identifying photos.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: posting ? null : onPost,
              icon: posting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _feedCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _feedCategories[index];
          final selected = selectedCategory == category.id;
          return ChoiceChip(
            label: Text(category.label),
            selected: selected,
            avatar: Icon(category.icon, size: 16),
            onSelected: (_) => onSelected(category.id),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.textMuted.withValues(alpha: 0.18),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  const _SelectedPhotoPreview({
    required this.bytes,
    required this.onRemove,
    this.fileName,
  });

  final Uint8List bytes;
  final String? fileName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 10,
            right: 54,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                fileName?.trim().isNotEmpty == true
                    ? fileName!.trim()
                    : 'Selected photo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.52),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclePostCard extends ConsumerWidget {
  const _CirclePostCard({required this.post, this.onOpenComments});

  final CirclePost post;
  final VoidCallback? onOpenComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(communityRepoProvider);
    final currentUid = repo.currentUser?.uid;
    final isOwnPost = currentUid != null && currentUid == post.authorId;
    final supportAsync = ref.watch(circlePostSupportProvider(post.id));
    final supported = supportAsync.valueOrNull ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/community/profile',
                    arguments: post.authorId,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  child: Row(
                    children: [
                      _InitialAvatar(name: post.authorName),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _relativeTime(post.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CategoryPill(categoryId: post.category),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Post actions',
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showPostActions(
                  context: context,
                  ref: ref,
                  post: post,
                  isOwnPost: isOwnPost,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (post.content.trim().isNotEmpty) ...[
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (post.hasPhoto) ...[
            _PostPhoto(photoUrl: post.photoUrl),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 2),
          Row(
            children: [
              _ActionPill(
                icon: supported ? Icons.favorite : Icons.favorite_border,
                label: _countLabel(post.supportCount, 'Support'),
                active: supported,
                onTap: () =>
                    ref.read(communityRepoProvider).toggleSupport(post.id),
              ),
              const SizedBox(width: 8),
              _ActionPill(
                icon: Icons.chat_bubble_outline,
                label: _countLabel(post.commentCount, 'Reply'),
                onTap: onOpenComments,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.surfaceVariant,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.surfaceVariant,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textMuted,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment});

  final CircleComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(communityRepoProvider);
    final currentUid = repo.currentUser?.uid;
    final isOwnComment = currentUid != null && currentUid == comment.authorId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/community/profile',
                    arguments: comment.authorId,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      _InitialAvatar(name: comment.authorName, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.authorName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _relativeTime(comment.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Comment actions',
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showCommentActions(
                  context: context,
                  ref: ref,
                  comment: comment,
                  isOwnComment: isOwnComment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 700,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write a supportive reply...',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Send reply',
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final category = _categoryFor(categoryId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, this.size = 38});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'L' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.seasonAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.seasonAccent,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommunityMessage extends StatelessWidget {
  const _CommunityMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCirclesState extends StatelessWidget {
  const _EmptyCirclesState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48, bottom: 80),
      child: _CommunityMessage(
        icon: Icons.forum_outlined,
        title: 'No posts here yet',
        message: 'Start the conversation with something useful or encouraging.',
      ),
    );
  }
}

class _QuietCommentState extends StatelessWidget {
  const _QuietCommentState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No replies yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}

class _CircleCategory {
  const _CircleCategory(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

const _feedCategories = [
  _CircleCategory('all', 'All', Icons.public_outlined),
  ..._postCategories,
];

const _postCategories = [
  _CircleCategory('wins', 'Wins', Icons.emoji_events_outlined),
  _CircleCategory('recipes', 'Recipes', Icons.restaurant_menu_outlined),
  _CircleCategory('form', 'Form', Icons.fitness_center_outlined),
  _CircleCategory('questions', 'Questions', Icons.help_outline),
  _CircleCategory('cycle', 'Cycle', Icons.sync_outlined),
  _CircleCategory('postpartum', 'Postpartum', Icons.self_improvement_outlined),
];

const _maxPostPhotoBytes = 5 * 1024 * 1024;

_CircleCategory _categoryFor(String id) {
  return _feedCategories.firstWhere(
    (category) => category.id == id,
    orElse: () => _postCategories.first,
  );
}

String _relativeTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return DateFormat('MMM d').format(date);
}

String _countLabel(int count, String singular) {
  final safeCount = count < 0 ? 0 : count;
  if (safeCount == 0) {
    return singular;
  }
  if (singular == 'Reply') {
    return '$safeCount ${safeCount == 1 ? 'Reply' : 'Replies'}';
  }
  return '$safeCount $singular';
}

Future<void> _showPostActions({
  required BuildContext context,
  required WidgetRef ref,
  required CirclePost post,
  required bool isOwnPost,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwnPost)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete post'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(communityRepoProvider).removePost(post);
              },
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report post'),
              onTap: () async {
                Navigator.pop(ctx);
                final reason = await _pickReportReason(context);
                if (reason == null) return;
                await ref
                    .read(communityRepoProvider)
                    .reportPost(post: post, reason: reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Block member'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(communityRepoProvider).blockUser(post.authorId);
                ref.invalidate(blockedCircleUsersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member blocked')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
}

Future<void> _showCommentActions({
  required BuildContext context,
  required WidgetRef ref,
  required CircleComment comment,
  required bool isOwnComment,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwnComment)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete reply'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(communityRepoProvider).removeComment(comment);
              },
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report reply'),
              onTap: () async {
                Navigator.pop(ctx);
                final reason = await _pickReportReason(context);
                if (reason == null) return;
                await ref
                    .read(communityRepoProvider)
                    .reportComment(comment: comment, reason: reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Block member'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(communityRepoProvider)
                    .blockUser(comment.authorId);
                ref.invalidate(blockedCircleUsersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member blocked')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
}

Future<String?> _pickReportReason(BuildContext context) {
  const reasons = [
    'Unsafe fitness or diet advice',
    'Harassment or hate',
    'Spam',
    'Privacy concern',
    'Other',
  ];

  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Report reason',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          for (final reason in reasons)
            ListTile(
              title: Text(reason),
              onTap: () => Navigator.pop(ctx, reason),
            ),
        ],
      ),
    ),
  );
}
