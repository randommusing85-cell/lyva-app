import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../models/prime_plan.dart';
import '../models/workout_template_doc.dart';
import '../theme/app_theme.dart';

/// Unified Plans tab showing both Nutrition and Workout plans
/// Redesigned to match Figma designs
class PlansTabScreen extends ConsumerWidget {
  const PlansTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Text(
                'My Plans',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your personalized journey',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Nutrition Plan Card
              const _NutritionPlanCard(),

              const SizedBox(height: 20),

              // Workout Plan Card
              const _WorkoutPlanCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== NUTRITION PLAN CARD =====
class _NutritionPlanCard extends ConsumerWidget {
  const _NutritionPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(activePlanProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: planAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (plan) {
          if (plan == null) {
            return _EmptyPlanContent(
              icon: Icons.restaurant_menu,
              title: 'Nutrition Plan',
              subtitle: 'Create your personalized meal plan',
              buttonText: 'Create Plan',
              onTap: () => Navigator.pushNamed(context, '/plan'),
            );
          }
          return _NutritionPlanContent(plan: plan);
        },
      ),
    );
  }
}

class _NutritionPlanContent extends StatelessWidget {
  final PrimePlan plan;

  const _NutritionPlanContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final daysSinceCreation = DateTime.now().difference(plan.createdAt).inDays;
    final daysRemaining = (14 - daysSinceCreation).clamp(0, 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Icons.restaurant_menu,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      plan.planName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Days badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daysRemaining > 0 ? '$daysRemaining days' : 'Unlocked',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Large calorie display
        Center(
          child: Column(
            children: [
              Text(
                '${plan.calories}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'calories per day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Macro boxes row
        Row(
          children: [
            Expanded(
              child: _MacroBox(
                value: '${plan.proteinG}',
                label: 'Protein',
                color: AppColors.proteinGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MacroBox(
                value: '${plan.carbsG}',
                label: 'Carbs',
                color: AppColors.carbsYellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MacroBox(
                value: '${plan.fatG}',
                label: 'Fat',
                color: AppColors.fatPink,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/myplan'),
                icon: const Icon(Icons.smart_toy_outlined, size: 18),
                label: const Text('AI Coach'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textMuted),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/nutrition'),
                icon: const Icon(Icons.restaurant, size: 18),
                label: const Text('Log Meal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===== WORKOUT PLAN CARD =====
class _WorkoutPlanCard extends ConsumerWidget {
  const _WorkoutPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templateAsync = ref.watch(latestWorkoutTemplateProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: templateAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (template) {
          if (template == null) {
            return _EmptyPlanContent(
              icon: Icons.fitness_center,
              title: 'Workout Plan',
              subtitle: 'Create your personalized workout plan',
              buttonText: 'Create Plan',
              onTap: () => Navigator.pushNamed(context, '/workout'),
            );
          }
          return _WorkoutPlanContent(template: template);
        },
      ),
    );
  }
}

class _WorkoutPlanContent extends StatelessWidget {
  final WorkoutTemplateDoc template;

  const _WorkoutPlanContent({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final daysSinceCreation = DateTime.now().difference(template.createdAt).inDays;
    final daysRemaining = (14 - daysSinceCreation).clamp(0, 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
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
                    'Workout',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    template.planName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Days badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daysRemaining > 0 ? '$daysRemaining days' : 'Unlocked',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '${template.daysPerWeek}',
                label: 'days per week',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatBox(
                value: '45',  // Default session duration
                label: 'min sessions',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Action buttons row (matching nutrition section)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/workout-coach'),
                icon: const Icon(Icons.smart_toy_outlined, size: 18),
                label: const Text('AI Coach'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textMuted),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/my-workout'),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('View Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===== SHARED COMPONENTS =====

class _MacroBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MacroBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _EmptyPlanContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onTap,
          child: Text(buttonText),
        ),
      ],
    );
  }
}
