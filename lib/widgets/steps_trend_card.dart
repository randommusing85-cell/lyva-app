import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';

class StepsTrendCard extends ConsumerWidget {
  const StepsTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyStepsProvider);

    return weeklyAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return _buildChart(context, data);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChart(BuildContext context, Map<DateTime, int> data) {
    final entries = data.entries.toList();
    final maxSteps = entries.map((e) => e.value).fold<int>(1, (a, b) => a > b ? a : b);
    const stepGoal = 8000;
    final chartMax = maxSteps > stepGoal ? maxSteps : stepGoal;

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.directions_walk, size: 18, color: AppColors.stepsRing),
              const SizedBox(width: 8),
              const Text(
                'Steps This Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final fraction = chartMax > 0 ? (entry.value / chartMax).clamp(0.0, 1.0) : 0.0;
                final isToday = _isToday(entry.key);
                final dayLabel = DateFormat('E').format(entry.key).substring(0, 2);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatSteps(entry.value),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isToday ? AppColors.stepsRing : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: fraction == 0 ? 0.02 : fraction,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: entry.value >= stepGoal
                                    ? AppColors.stepsRing
                                    : isToday
                                        ? AppColors.stepsRing.withOpacity(0.7)
                                        : AppColors.stepsRing.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                            color: isToday ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Goal line label
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 2,
                color: AppColors.stepsRing.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Goal: ${_formatSteps(stepGoal)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return steps.toString();
  }
}
