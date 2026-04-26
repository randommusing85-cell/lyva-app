import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/progress_photo.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';

class ProgressPhotoDetailScreen extends ConsumerStatefulWidget {
  const ProgressPhotoDetailScreen({super.key});

  @override
  ConsumerState<ProgressPhotoDetailScreen> createState() => _ProgressPhotoDetailScreenState();
}

class _ProgressPhotoDetailScreenState extends ConsumerState<ProgressPhotoDetailScreen> {
  bool _analyzing = false;

  Future<void> _analyzePhoto(ProgressPhoto photo) async {
    // Check usage cap before analyzing
    final profile = await ref.read(userProfileProvider.future);
    if (profile != null) {
      final service = ref.read(premiumServiceProvider);
      if (!service.canAnalyzePhoto(profile)) {
        if (mounted) _showPhotoLimitDialog();
        return;
      }
    }

    setState(() => _analyzing = true);

    try {
      final repo = ref.read(lyvaRepoProvider);
      final imageBytes = await File(photo.imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Build user context
      final userContext = {
        'sex': profile?.sex,
        'age': profile?.age,
        'heightCm': profile?.heightCm,
        'weightKg': profile?.weightKg,
        'goal': profile?.goal,
      };

      final analysis = await repo.analyzeProgressPhoto(
        base64Image: base64Image,
        userContext: userContext,
      );

      // Update the photo record
      photo.analysisJson = jsonEncode(analysis);
      photo.analysisComplete = true;
      photo.analysisRequested = true;
      await repo.saveProgressPhoto(photo);
      ref.read(analyticsProvider).logProgressPhotoAnalyzed();

      // Increment usage counter
      await ref.read(userProfileRepoProvider).incrementPhotoAnalysisUsage();
      ref.invalidate(userProfileProvider);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _showPhotoLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.photo_camera_outlined, size: 40, color: Colors.orange.shade600),
        title: const Text('Monthly Limit Reached'),
        content: Text(
          'You\'ve used all ${PremiumService.photoAnalysisCap} photo analyses this month. '
          'Your analyses reset at the start of each month.\n\n'
          'Need more? Analysis packs are coming soon!',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = ModalRoute.of(context)!.settings.arguments as ProgressPhoto;

    Map<String, dynamic>? analysis;
    if (photo.analysisComplete && photo.analysisJson != null) {
      analysis = jsonDecode(photo.analysisJson!) as Map<String, dynamic>;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(DateFormat('MMMM d, yyyy').format(photo.ts)),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Photo'),
                  content: const Text('This photo will be permanently deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(lyvaRepoProvider).deleteProgressPhoto(photo.id);
                // Delete the file too
                try { await File(photo.imagePath).delete(); } catch (_) {}
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photo.imagePath),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: Icon(Icons.broken_image, size: 48, color: AppColors.textMuted)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (analysis != null) ...[
              // Body composition
              if (analysis['bodyFatEstimate'] != null)
                _AnalysisCard(
                  icon: Icons.pie_chart,
                  title: 'Body Composition Estimate',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '~${analysis['bodyFatEstimate']}% body fat',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (analysis['measurements'] is Map) ...[
                        const SizedBox(height: 8),
                        ...((analysis['measurements'] as Map).entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key.toString().replaceAll('_', ' '),
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                                Text(
                                  '${e.value}',
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Celeb comparison
              if (analysis['celebComparison'] is Map)
                _AnalysisCard(
                  icon: Icons.star,
                  title: 'Physique Comparison',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis['celebComparison']['name'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis['celebComparison']['description'] ?? '',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Changes since last
              if (analysis['changesSinceLast'] is Map && analysis['changesSinceLast']['notes'] != null)
                _AnalysisCard(
                  icon: Icons.trending_up,
                  title: 'Changes',
                  child: Text(
                    analysis['changesSinceLast']['notes'],
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),

              // Encouragement
              if (analysis['encouragement'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    analysis['encouragement'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Analyze button with usage info
              ref.watch(userProfileProvider).when(
                data: (currentProfile) {
                  final service = ref.read(premiumServiceProvider);
                  final remaining = currentProfile != null
                      ? service.photoAnalysesRemaining(currentProfile)
                      : PremiumService.photoAnalysisCap;
                  final used = currentProfile?.photoAnalysesUsed ?? 0;
                  final cap = PremiumService.photoAnalysisCap;
                  final limitReached = remaining <= 0;

                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_analyzing || limitReached) ? null : () => _analyzePhoto(photo),
                          icon: _analyzing
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(limitReached ? Icons.lock_outline : Icons.auto_awesome),
                          label: Text(
                            _analyzing
                                ? 'Analyzing...'
                                : limitReached
                                    ? 'Limit Reached'
                                    : 'Analyze Photo',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: limitReached ? Colors.grey.shade400 : AppColors.seasonAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          limitReached
                              ? 'Monthly limit reached ($used/$cap). Resets next month.'
                              : 'AI-powered body analysis  ·  $used/$cap used this month',
                          style: TextStyle(
                            fontSize: 12,
                            color: limitReached ? Colors.orange.shade700 : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _AnalysisCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.seasonAccent),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
