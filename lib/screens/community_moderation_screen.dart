import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/community_report.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';

class CommunityModerationScreen extends ConsumerWidget {
  const CommunityModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moderatorAsync = ref.watch(communityModeratorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Circles Moderation'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        top: false,
        child: moderatorAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ModerationMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not check access',
            message: e.toString(),
          ),
          data: (isModerator) {
            if (!isModerator) {
              return const _ModerationMessage(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Moderator access required',
                message:
                    'This account needs a Firebase custom claim: moderator=true or admin=true.',
              );
            }

            final reportsAsync = ref.watch(openCommunityReportsProvider);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(openCommunityReportsProvider);
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.all(20),
                  children: [_ModerationError(message: e.toString())],
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 120),
                        _ModerationMessage(
                          icon: Icons.verified_outlined,
                          title: 'All clear',
                          message:
                              'There are no open Circles reports right now.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ReportCard(report: reports[index]);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});

  final CommunityReport report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  late Future<ModerationTarget?> _targetFuture;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _targetFuture = ref
        .read(communityRepoProvider)
        .getModerationTarget(widget.report);
  }

  Future<void> _dismiss() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    try {
      await ref.read(communityRepoProvider).dismissReport(widget.report);
      ref.invalidate(openCommunityReportsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report dismissed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _removeContent() async {
    if (_resolving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove content?'),
        content: const Text(
          'This hides the reported post or reply from Circles and marks this report as resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _resolving = true);
    try {
      await ref
          .read(communityRepoProvider)
          .removeReportedContent(widget.report);
      ref.invalidate(openCommunityReportsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  report.isComment
                      ? Icons.mode_comment_outlined
                      : Icons.article_outlined,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.isComment ? 'Reported reply' : 'Reported post',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(report.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: report.status),
            ],
          ),
          const SizedBox(height: 14),
          _MetaRow(label: 'Reason', value: report.reason),
          const SizedBox(height: 8),
          _MetaRow(label: 'Reporter', value: report.reporterId),
          const SizedBox(height: 8),
          _MetaRow(label: 'Author', value: report.targetAuthorId),
          const SizedBox(height: 14),
          FutureBuilder<ModerationTarget?>(
            future: _targetFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final target = snapshot.data;
              if (target == null) {
                return const _TargetPreview(
                  authorName: 'Unknown',
                  content: 'The reported content could not be found.',
                  isRemoved: true,
                );
              }

              return _TargetPreview(
                authorName: target.authorName,
                content: target.content,
                isRemoved: target.isRemoved,
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resolving ? null : _dismiss,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resolving ? null : _removeContent,
                  icon: _resolving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.visibility_off_outlined),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetPreview extends StatelessWidget {
  const _TargetPreview({
    required this.authorName,
    required this.content,
    required this.isRemoved,
  });

  final String authorName;
  final String content;
  final bool isRemoved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  authorName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isRemoved)
                const Text(
                  'Removed',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'removed' => AppColors.error,
      'dismissed' => AppColors.success,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ModerationMessage extends StatelessWidget {
  const _ModerationMessage({
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

class _ModerationError extends StatelessWidget {
  const _ModerationError({required this.message});

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
