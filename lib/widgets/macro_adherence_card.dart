import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repos/prime_repo.dart';
import '../state/providers.dart';

/// Shows macro adherence for the last 7 days on the home screen
class MacroAdherenceCard extends ConsumerWidget {
  const MacroAdherenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(activePlanProvider);
    final macrosAsync = ref.watch(weeklyMacroTotalsProvider);

    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) {
        if (plan == null) return const SizedBox.shrink();

        return macrosAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (dailyTotals) {
            if (dailyTotals.isEmpty) {
              return _EmptyMacroCard(theme: theme);
            }

            // Calculate adherence
            final adherence = _calculateAdherence(dailyTotals, plan);

            return Card(
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/nutrition'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nutrition This Week',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Overall adherence score
                      Row(
                        children: [
                          _AdherenceCircle(
                            percentage: adherence.overall,
                            size: 56,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getAdherenceLabel(adherence.overall),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: _getAdherenceColor(adherence.overall),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dailyTotals.length} ${dailyTotals.length == 1 ? "day" : "days"} logged',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Macro breakdown bars
                      _MacroBar(
                        label: 'Protein',
                        percentage: adherence.protein,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 8),
                      _MacroBar(
                        label: 'Carbs',
                        percentage: adherence.carbs,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(height: 8),
                      _MacroBar(
                        label: 'Fat',
                        percentage: adherence.fat,
                        color: Colors.blue.shade400,
                      ),

                      const SizedBox(height: 12),

                      // Tip based on adherence
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getAdherenceTip(adherence),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  _MacroAdherence _calculateAdherence(
    List<DailyMacroTotal> totals,
    dynamic plan,
  ) {
    if (totals.isEmpty) {
      return _MacroAdherence(overall: 0, protein: 0, carbs: 0, fat: 0);
    }

    double proteinSum = 0;
    double carbsSum = 0;
    double fatSum = 0;

    for (final day in totals) {
      // Calculate how close each day was to target (0-100%)
      // Being within 10% of target counts as 100%
      proteinSum += _dayAdherence(day.proteinG, plan.proteinG);
      carbsSum += _dayAdherence(day.carbsG, plan.carbsG);
      fatSum += _dayAdherence(day.fatG, plan.fatG);
    }

    final count = totals.length;
    final proteinAdh = proteinSum / count;
    final carbsAdh = carbsSum / count;
    final fatAdh = fatSum / count;

    // Overall is weighted: protein 40%, carbs 30%, fat 30%
    final overall = (proteinAdh * 0.4) + (carbsAdh * 0.3) + (fatAdh * 0.3);

    return _MacroAdherence(
      overall: overall.clamp(0, 100),
      protein: proteinAdh.clamp(0, 100),
      carbs: carbsAdh.clamp(0, 100),
      fat: fatAdh.clamp(0, 100),
    );
  }

  double _dayAdherence(int actual, int target) {
    if (target == 0) return 0;
    final ratio = actual / target;
    // Within 10% of target = 100% adherence
    if (ratio >= 0.9 && ratio <= 1.1) return 100;
    // Under target: penalize proportionally
    if (ratio < 0.9) return (ratio / 0.9) * 100;
    // Over target: slight penalty (better to hit than miss)
    if (ratio > 1.1) return 100 - ((ratio - 1.1) * 50).clamp(0, 30);
    return 100;
  }

  String _getAdherenceLabel(double percentage) {
    if (percentage >= 90) return 'Excellent! 🔥';
    if (percentage >= 75) return 'Good progress 💪';
    if (percentage >= 50) return 'Keep going 📈';
    return 'Room to grow 🌱';
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 50) return Colors.orange;
    return Colors.red.shade300;
  }

  String _getAdherenceTip(_MacroAdherence adherence) {
    if (adherence.overall >= 90) {
      return 'Crushing it! Consistency like this drives results.';
    }
    if (adherence.protein < adherence.carbs && adherence.protein < adherence.fat) {
      return 'Protein is your weak spot. Prioritize it at every meal.';
    }
    if (adherence.overall >= 70) {
      return 'Solid foundation. Small improvements compound over time.';
    }
    return 'Focus on logging meals consistently. Awareness is step one.';
  }
}

class _EmptyMacroCard extends StatelessWidget {
  final ThemeData theme;

  const _EmptyMacroCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/nutrition'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.restaurant,
                size: 32,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Nutrition',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log meals to see your macro adherence',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdherenceCircle extends StatelessWidget {
  final double percentage;
  final double size;

  const _AdherenceCircle({
    required this.percentage,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${percentage.round()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 50) return Colors.orange;
    return Colors.red.shade300;
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${percentage.round()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _MacroAdherence {
  final double overall;
  final double protein;
  final double carbs;
  final double fat;

  _MacroAdherence({
    required this.overall,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}