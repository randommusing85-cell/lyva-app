import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_template_doc.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';
import '../widgets/premium_gate.dart';

class WorkoutCoachScreen extends ConsumerStatefulWidget {
  const WorkoutCoachScreen({super.key});

  @override
  ConsumerState<WorkoutCoachScreen> createState() => _WorkoutCoachScreenState();
}

class _WorkoutCoachScreenState extends ConsumerState<WorkoutCoachScreen> {
  // ===== WORKOUT PLAN LOCK METHODS =====
  bool _canRegeneratePlan(WorkoutTemplateDoc template) {
    final now = DateTime.now();
    final daysSince = now.difference(template.createdAt).inDays;
    return daysSince >= 14;
  }

  int _daysUntilRegenerate(WorkoutTemplateDoc template) {
    final now = DateTime.now();
    final daysSince = now.difference(template.createdAt).inDays;
    final remaining = 14 - daysSince;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _navigateToRegenerate(WorkoutTemplateDoc template) async {
    // Check if plan can be regenerated
    if (!_canRegeneratePlan(template)) {
      // Show lock explanation dialog
      final shouldProceed = await _showLockExplanationDialog(template);

      if (shouldProceed != true) {
        return;
      }
    }

    // Lock is not active or user confirmed, proceed to regenerate
    if (mounted) {
      Navigator.pushNamed(context, '/workout');
    }
  }

  Future<bool?> _showLockExplanationDialog(WorkoutTemplateDoc template) {
    final daysLeft = _daysUntilRegenerate(template);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Plan Locked'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your workout plan is locked for $daysLeft more day${daysLeft == 1 ? '' : 's'}.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Why the lock?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consistency is key to seeing results. Your body needs time to adapt to your workout routine. Changing programs too frequently can prevent you from making real progress.',
              ),
              const SizedBox(height: 16),
              const Text(
                'What you can do now:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('• Customize individual exercises in your current plan'),
              const Text('• Adjust sets and reps as needed'),
              const Text('• Add or remove exercises for each day'),
              const Text('• Focus on progressive overload'),
              const SizedBox(height: 16),
              Text(
                'After the lock period, you can regenerate a completely new plan if needed.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Got it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              Navigator.pushNamed(context, '/my-workout');
            },
            child: const Text('Edit Current Plan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(latestWorkoutTemplateProvider);
    final theme = Theme.of(context);

    // Track analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (templateAsync.valueOrNull != null) {
        final analytics = ref.read(analyticsProvider);
        final template = templateAsync.value!;
        analytics.logAiCoachQueried(
          type: 'workout',
          daysSincePlanCreated: DateTime.now().difference(template.createdAt).inDays,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Workout AI Coach')),
      body: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (template) {
          if (template == null) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No workout plan yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a workout plan first to get AI coaching.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/workout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Create Workout Plan'),
                  ),
                ],
              ),
            );
          }

          // Parse template JSON
          Map<String, dynamic>? templateData;
          try {
            templateData = jsonDecode(template.json) as Map<String, dynamic>;
          } catch (_) {
            templateData = null;
          }

          final canRegenerate = _canRegeneratePlan(template);
          final daysLeft = _daysUntilRegenerate(template);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Plan Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
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
                              color: AppColors.primaryLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Plan',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  template.planName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: template.level),
                          _InfoChip(label: template.equipment.replaceAll('_', ' ')),
                          _InfoChip(label: '${template.daysPerWeek} days/week'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Created ${_formatDate(template.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Lock Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: canRegenerate
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canRegenerate
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canRegenerate ? Icons.lock_open : Icons.lock_outline,
                        color: canRegenerate
                            ? AppColors.primary
                            : Colors.orange.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              canRegenerate
                                  ? 'Plan Unlocked'
                                  : 'Plan Locked',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: canRegenerate
                                    ? AppColors.primary
                                    : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              canRegenerate
                                  ? 'You can generate a new workout plan'
                                  : 'Unlocks in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: canRegenerate
                                    ? AppColors.textSecondary
                                    : Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions Section
                Text(
                  'What would you like to do?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Current Plan Button
                _ActionCard(
                  icon: Icons.edit_outlined,
                  title: 'Customize Current Plan',
                  subtitle: 'Edit exercises, sets, and reps',
                  onTap: () => Navigator.pushNamed(context, '/my-workout'),
                ),

                const SizedBox(height: 12),

                // Generate New Plan Button
                _ActionCard(
                  icon: canRegenerate ? Icons.auto_awesome : Icons.lock_outline,
                  title: 'Generate New Plan',
                  subtitle: canRegenerate
                      ? 'Create a completely new workout program'
                      : 'Locked for $daysLeft more day${daysLeft == 1 ? '' : 's'}',
                  locked: !canRegenerate,
                  onTap: () => _navigateToRegenerate(template),
                ),

                const SizedBox(height: 24),

                // Tips Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Training Tips',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TipItem(text: 'Focus on progressive overload - increase weight or reps gradually'),
                      _TipItem(text: 'Rest 1-2 minutes between sets for strength gains'),
                      _TipItem(text: 'Track your weights to see progress over time'),
                      _TipItem(text: 'Consistency beats perfection - show up even on tough days'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Premium: AI Coaching
                PremiumFeatureCard(
                  feature: PremiumFeature.aiCoaching,
                  icon: Icons.chat_bubble_outline,
                  title: 'AI Coaching',
                  description: 'Have personalized conversations with your AI coach',
                ),

                const SizedBox(height: 12),

                // Premium: AI Memory
                PremiumFeatureCard(
                  feature: PremiumFeature.aiMemory,
                  icon: Icons.psychology_outlined,
                  title: 'AI Memory',
                  description: 'AI learns your patterns and gives smarter advice over time',
                ),

                const SizedBox(height: 12),

                // Premium: Custom Workouts
                PremiumFeatureCard(
                  feature: PremiumFeature.customWorkouts,
                  icon: Icons.edit_note_outlined,
                  title: 'Custom Workouts',
                  description: 'Build your own workout routines from scratch',
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 14) return '1 week ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? AppColors.textMuted.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.textMuted.withOpacity(0.1)
                    : AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: locked ? AppColors.textMuted : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: locked ? AppColors.textMuted : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: locked ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: locked ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.primary)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
