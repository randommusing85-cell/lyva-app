import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/workout_template_doc.dart';
import '../state/providers.dart';
import '../widgets/premium_gate.dart';
import '../services/premium_service.dart';

class SavedTemplatesScreen extends ConsumerStatefulWidget {
  const SavedTemplatesScreen({super.key});

  @override
  ConsumerState<SavedTemplatesScreen> createState() =>
      _SavedTemplatesScreenState();
}

class _SavedTemplatesScreenState extends ConsumerState<SavedTemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(customTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Custom Workouts'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/custom-workout-builder',
          );
          if (result == true) {
            ref.invalidate(customTemplatesProvider);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body: PremiumGate(
        feature: PremiumFeature.customWorkouts,
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTemplateList(templates);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.fitness_center_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Custom Workouts Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your own workout plan with the exercises you love. Tap the button below to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/custom-workout-builder',
                );
                if (result == true) {
                  ref.invalidate(customTemplatesProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Workout Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList(List<WorkoutTemplateDoc> templates) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final exerciseCount = _countExercises(template);

        return Dismissible(
          key: ValueKey(template.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Workout Plan'),
                content: Text(
                    'Delete "${template.planName}"? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            final repo = ref.read(primeRepoProvider);
            await repo.deleteWorkoutTemplate(template.id);
            ref.invalidate(customTemplatesProvider);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: InkWell(
              onTap: () => _showTemplateDetail(template),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.planName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: '${template.daysPerWeek} days/week',
                        ),
                        const SizedBox(width: 12),
                        _InfoChip(
                          icon: Icons.fitness_center_outlined,
                          label: '$exerciseCount exercises',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created ${dateFormat.format(template.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _countExercises(WorkoutTemplateDoc template) {
    try {
      final data = Map<String, dynamic>.from(
        jsonDecode(template.json) as Map,
      );
      final days = data['days'] as List?;
      if (days == null) return 0;
      int count = 0;
      for (final day in days) {
        final exercises = (day as Map)['exercises'] as List?;
        count += exercises?.length ?? 0;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  void _showTemplateDetail(WorkoutTemplateDoc template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollController) => _TemplateDetailSheet(
          template: template,
          scrollController: scrollController,
          onActivate: () async {
            final repo = ref.read(primeRepoProvider);
            // Save this template as the latest (active) one
            final newTemplate = WorkoutTemplateDoc()
              ..createdAt = DateTime.now()
              ..planName = template.planName
              ..level = template.level
              ..equipment = template.equipment
              ..daysPerWeek = template.daysPerWeek
              ..sex = template.sex
              ..isCustom = true
              ..json = template.json;
            await repo.saveWorkoutTemplate(newTemplate);

            ref.read(analyticsProvider).logCustomWorkoutActivated();
            ref.invalidate(latestWorkoutTemplateProvider);

            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${template.planName}" is now active!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _TemplateDetailSheet extends StatelessWidget {
  final WorkoutTemplateDoc template;
  final ScrollController scrollController;
  final VoidCallback onActivate;

  const _TemplateDetailSheet({
    required this.template,
    required this.scrollController,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(
        jsonDecode(template.json) as Map,
      );
    } catch (_) {
      data = {};
    }

    final days = (data['days'] as List?) ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              template.planName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Days list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: days.length,
                itemBuilder: (ctx, i) {
                  final day = days[i] as Map;
                  final exercises = (day['exercises'] as List?) ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${i + 1}: ${day['dayName'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...exercises.map((ex) {
                          final e = ex as Map;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 6, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${e['name']}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${e['sets']} x ${e['reps']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Activate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Set as Active Plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
