import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/circle_post.dart';
import '../models/circle_profile.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';

class CommunityProfileScreen extends ConsumerStatefulWidget {
  const CommunityProfileScreen({super.key});

  @override
  ConsumerState<CommunityProfileScreen> createState() =>
      _CommunityProfileScreenState();
}

class _CommunityProfileScreenState
    extends ConsumerState<CommunityProfileScreen> {
  bool _busy = false;

  Future<void> _toggleFollow(String uid) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await ref.read(communityRepoProvider).toggleFollow(uid);
      ref.invalidate(circleFollowingProvider(uid));
      ref.invalidate(circleProfileProvider(uid));
      ref.invalidate(currentCircleProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _blockProfile(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block member?'),
        content: const Text(
          'Their posts and replies will be hidden from your Circles feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(communityRepoProvider).blockUser(uid);
      ref.invalidate(blockedCircleUsersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Member blocked')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _editProfile(CircleProfile profile) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditCircleProfileSheet(profile: profile),
    );
    if (saved == true) {
      ref.invalidate(circleProfileProvider(profile.uid));
      ref.invalidate(currentCircleProfileProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! String || args.isEmpty) {
      return const Scaffold(body: Center(child: Text('Profile not found')));
    }

    final uid = args;
    final profileAsync = ref.watch(circleProfileProvider(uid));
    final postsAsync = ref.watch(circleProfilePostsProvider(uid));
    final followingAsync = ref.watch(circleFollowingProvider(uid));
    final currentUid = ref.watch(circleAuthUserProvider).valueOrNull?.uid;
    final isOwnProfile = currentUid == uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Circles Profile'),
        backgroundColor: AppColors.background,
        actions: [
          if (!isOwnProfile)
            IconButton(
              tooltip: 'Block member',
              icon: const Icon(Icons.block_outlined),
              onPressed: () => _blockProfile(uid),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ProfileMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            message: e.toString(),
          ),
          data: (profile) {
            if (profile == null) {
              return const _ProfileMessage(
                icon: Icons.person_off_outlined,
                title: 'Profile not found',
                message: 'This Circles profile may have been deleted.',
              );
            }

            final isFollowing = followingAsync.valueOrNull ?? false;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(circleProfileProvider(uid));
                ref.invalidate(circleProfilePostsProvider(uid));
                ref.invalidate(circleFollowingProvider(uid));
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _ProfileHeader(
                    profile: profile,
                    isOwnProfile: isOwnProfile,
                    isFollowing: isFollowing,
                    busy: _busy,
                    onFollow: () => _toggleFollow(uid),
                    onEdit: () => _editProfile(profile),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recent Posts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  postsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 42),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _InlineError(message: e.toString()),
                    data: (posts) {
                      if (posts.isEmpty) {
                        return const _EmptyPostsState();
                      }

                      return Column(
                        children: [
                          for (final post in posts) ...[
                            _ProfilePostTile(post: post),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.busy,
    required this.onFollow,
    required this.onEdit,
  });

  final CircleProfile profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool busy;
  final VoidCallback onFollow;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleProfileAvatar(profile: profile, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CountLabel(
                          count: profile.followerCount,
                          label: 'followers',
                        ),
                        const SizedBox(width: 16),
                        _CountLabel(
                          count: profile.followingCount,
                          label: 'following',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              profile.bio,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ],
          if (profile.focusTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in profile.focusTags)
                  Chip(
                    label: Text(_focusTagLabel(tag)),
                    avatar: Icon(_focusTagIcon(tag), size: 16),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: isOwnProfile
                ? OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                  )
                : ElevatedButton.icon(
                    onPressed: busy ? null : onFollow,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isFollowing
                                ? Icons.check_circle_outline
                                : Icons.person_add_alt,
                          ),
                    label: Text(isFollowing ? 'Following' : 'Follow'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditCircleProfileSheet extends ConsumerStatefulWidget {
  const _EditCircleProfileSheet({required this.profile});

  final CircleProfile profile;

  @override
  ConsumerState<_EditCircleProfileSheet> createState() =>
      _EditCircleProfileSheetState();
}

class _EditCircleProfileSheetState
    extends ConsumerState<_EditCircleProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late Set<String> _selectedTags;
  late String _avatarColor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio);
    _selectedTags = widget.profile.focusTags.toSet();
    _avatarColor = widget.profile.avatarColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await ref
          .read(communityRepoProvider)
          .updateCurrentPublicProfile(
            displayName: _nameController.text,
            bio: _bioController.text,
            focusTags: _selectedTags.toList(growable: false),
            avatarColor: _avatarColor,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Circles Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                maxLength: 32,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 4,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'A short intro for other Lyva members',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Focus',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _focusTagOptions)
                    FilterChip(
                      label: Text(_focusTagLabel(tag)),
                      avatar: Icon(_focusTagIcon(tag), size: 16),
                      selected: _selectedTags.contains(tag),
                      onSelected: (selected) {
                        setState(() {
                          if (selected && _selectedTags.length < 5) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Avatar color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final colorId in _avatarColorIds)
                    _ColorChoice(
                      colorId: colorId,
                      selected: _avatarColor == colorId,
                      onSelected: () => setState(() => _avatarColor = colorId),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePostTile extends StatelessWidget {
  const _ProfilePostTile({required this.post});

  final CirclePost post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/community/post', arguments: post),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SmallCategoryPill(category: post.category),
                if (post.hasPhoto) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.photo_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
                const Spacer(),
                Text(
                  _relativeTime(post.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.content.trim().isNotEmpty) ...[
              Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
              if (post.hasPhoto) const SizedBox(height: 12),
            ],
            if (post.hasPhoto) _ProfilePostPhoto(photoUrl: post.photoUrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text('${post.supportCount}'),
                const SizedBox(width: 14),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text('${post.commentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePostPhoto extends StatelessWidget {
  const _ProfilePostPhoto({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
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

class _CircleProfileAvatar extends StatelessWidget {
  const _CircleProfileAvatar({required this.profile, required this.size});

  final CircleProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(profile.avatarColor);
    final initial = profile.displayName.trim().isEmpty
        ? 'L'
        : profile.displayName.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.colorId,
    required this.selected,
    required this.onSelected,
  });

  final String colorId;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(colorId);
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${count < 0 ? 0 : count}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _SmallCategoryPill extends StatelessWidget {
  const _SmallCategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _categoryLabel(category),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPostsState extends StatelessWidget {
  const _EmptyPostsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No public Circles posts yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
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
            Icon(icon, size: 42, color: AppColors.primary),
            const SizedBox(height: 14),
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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

const _focusTagOptions = [
  'strength',
  'fat_loss',
  'recomp',
  'nutrition',
  'cycle_aware',
  'postpartum',
  'mobility',
  'consistency',
];

const _avatarColorIds = ['sage', 'clay', 'rose', 'gold', 'blue'];

String _focusTagLabel(String tag) {
  switch (tag) {
    case 'strength':
      return 'Strength';
    case 'fat_loss':
      return 'Fat loss';
    case 'recomp':
      return 'Recomp';
    case 'nutrition':
      return 'Nutrition';
    case 'cycle_aware':
      return 'Cycle-aware';
    case 'postpartum':
      return 'Postpartum';
    case 'mobility':
      return 'Mobility';
    case 'consistency':
      return 'Consistency';
    default:
      return tag;
  }
}

IconData _focusTagIcon(String tag) {
  switch (tag) {
    case 'strength':
      return Icons.fitness_center_outlined;
    case 'fat_loss':
      return Icons.local_fire_department_outlined;
    case 'recomp':
      return Icons.auto_graph_outlined;
    case 'nutrition':
      return Icons.restaurant_menu_outlined;
    case 'cycle_aware':
      return Icons.sync_outlined;
    case 'postpartum':
      return Icons.self_improvement_outlined;
    case 'mobility':
      return Icons.accessibility_new_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

String _categoryLabel(String category) {
  switch (category) {
    case 'recipes':
      return 'Recipes';
    case 'form':
      return 'Form';
    case 'questions':
      return 'Questions';
    case 'cycle':
      return 'Cycle';
    case 'postpartum':
      return 'Postpartum';
    case 'wins':
    default:
      return 'Wins';
  }
}

Color _avatarColor(String colorId) {
  switch (colorId) {
    case 'clay':
      return AppColors.seasonAccent;
    case 'rose':
      return AppColors.fatPink;
    case 'gold':
      return AppColors.carbsYellow;
    case 'blue':
      return AppColors.workoutsRing;
    case 'sage':
    default:
      return AppColors.primary;
  }
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
