import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/user_profile.dart';
import '../models/workout_session_doc.dart';
import '../repos/lyva_repo.dart';
import '../services/premium_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dual_line_chart.dart';
import '../widgets/premium_gate.dart';
import '../widgets/stacked_bar_chart.dart';

class AdvancedAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  ConsumerState<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState
    extends ConsumerState<AdvancedAnalyticsScreen> {
  int _rangeDays = 30; // 7, 30, 90

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: PremiumGate(
        feature: PremiumFeature.advancedAnalytics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Date range selector
              Row(
                children: [
                  _RangeChip(
                    label: '7 Days',
                    selected: _rangeDays == 7,
                    onTap: () => setState(() => _rangeDays = 7),
                  ),
                  const SizedBox(width: 8),
                  _RangeChip(
                    label: '30 Days',
                    selected: _rangeDays == 30,
                    onTap: () => setState(() => _rangeDays = 30),
                  ),
                  const SizedBox(width: 8),
                  _RangeChip(
                    label: '90 Days',
                    selected: _rangeDays == 90,
                    onTap: () => setState(() => _rangeDays = 90),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Body composition trends
              _BodyCompositionCard(rangeDays: _rangeDays),

              const SizedBox(height: 16),

              // Macro adherence
              _MacroAdherenceCard(rangeDays: _rangeDays),

              const SizedBox(height: 16),

              // Workout frequency
              _WorkoutFrequencyCard(rangeDays: _rangeDays),

              const SizedBox(height: 16),

              // Mood/Energy × Cycle Phase
              _MoodEnergyCycleCard(rangeDays: _rangeDays),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== RANGE CHIP =====

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ===== BODY COMPOSITION CARD =====

class _BodyCompositionCard extends ConsumerWidget {
  final int rangeDays;

  const _BodyCompositionCard({required this.rangeDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInsAsync = ref.watch(extendedCheckInsProvider(rangeDays));

    return _AnalyticsCard(
      title: 'Body Composition',
      icon: Icons.monitor_weight_outlined,
      child: checkInsAsync.when(
        data: (checkIns) {
          if (checkIns.isEmpty) {
            return const _EmptyState(text: 'Check in daily to see trends');
          }

          // Reverse to chronological order
          final sorted = checkIns.reversed.toList();
          final weights = sorted.map((c) => c.weightKg).toList();
          final waists = sorted.map((c) => c.waistCm.toDouble()).toList();

          // Calculate deltas
          final weightDelta = weights.length >= 2
              ? weights.last - weights.first
              : 0.0;
          final waistValues = waists.where((w) => w > 0).toList();
          final waistDelta = waistValues.length >= 2
              ? waistValues.last - waistValues.first
              : 0.0;

          return Column(
            children: [
              // Delta badges
              Row(
                children: [
                  _DeltaBadge(
                    label: 'Weight',
                    delta: weightDelta,
                    unit: 'kg',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  if (waistValues.isNotEmpty)
                    _DeltaBadge(
                      label: 'Waist',
                      delta: waistDelta,
                      unit: 'cm',
                      color: AppColors.seasonAccent,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DualLineChart(
                data1: weights,
                data2: waists,
                color1: AppColors.primary,
                color2: AppColors.seasonAccent,
                label1: 'Weight (kg)',
                label2: 'Waist (cm)',
              ),
            ],
          );
        },
        loading: () => const _LoadingState(),
        error: (_, __) => const _EmptyState(text: 'Error loading data'),
      ),
    );
  }
}

// ===== MACRO ADHERENCE CARD =====

class _MacroAdherenceCard extends ConsumerWidget {
  final int rangeDays;

  const _MacroAdherenceCard({required this.rangeDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pick the right provider based on range
    final AsyncValue<List<DailyMacroTotal>> macrosAsync;
    if (rangeDays <= 7) {
      macrosAsync = ref.watch(weeklyMacroTotalsProvider);
    } else if (rangeDays <= 30) {
      macrosAsync = ref.watch(monthlyMacroTotalsProvider);
    } else {
      macrosAsync = ref.watch(quarterlyMacroTotalsProvider);
    }

    final planAsync = ref.watch(activePlanProvider);
    final targetCalories = planAsync.valueOrNull?.calories.toDouble() ?? 2000;

    return _AnalyticsCard(
      title: 'Macro Adherence',
      icon: Icons.pie_chart_outline,
      child: macrosAsync.when(
        data: (macros) {
          if (macros.isEmpty) {
            return const _EmptyState(text: 'Log meals to see adherence');
          }

          // Sort chronologically and take the last N days
          final sorted = List<DailyMacroTotal>.from(macros)
            ..sort((a, b) => a.date.compareTo(b.date));
          final display = sorted.length > 14
              ? sorted.sublist(sorted.length - 14)
              : sorted;

          final dateFormat = DateFormat('d');
          final barData = display.map((d) => StackedBarData(
            label: dateFormat.format(d.date),
            protein: (d.proteinG * 4).toDouble(),
            carbs: (d.carbsG * 4).toDouble(),
            fat: (d.fatG * 9).toDouble(),
          )).toList();

          // Calculate averages
          final avgCalories = macros.isEmpty
              ? 0
              : macros.fold<int>(0, (sum, d) => sum + d.calories) ~/
                  macros.length;

          return Column(
            children: [
              Row(
                children: [
                  _MetricBadge(
                    label: 'Avg',
                    value: '$avgCalories cal',
                    color: AppColors.caloriesRing,
                  ),
                  const SizedBox(width: 12),
                  _MetricBadge(
                    label: 'Target',
                    value: '${targetCalories.round()} cal',
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StackedBarChart(
                data: barData,
                targetLine: targetCalories,
              ),
            ],
          );
        },
        loading: () => const _LoadingState(),
        error: (_, __) => const _EmptyState(text: 'Error loading data'),
      ),
    );
  }
}

// ===== WORKOUT FREQUENCY CARD =====

class _WorkoutFrequencyCard extends ConsumerWidget {
  final int rangeDays;

  const _WorkoutFrequencyCard({required this.rangeDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final start = now.subtract(Duration(days: rangeDays));
    final repo = ref.watch(lyvaRepoProvider);

    return _AnalyticsCard(
      title: 'Workout Frequency',
      icon: Icons.fitness_center,
      child: FutureBuilder<List<WorkoutSessionDoc>>(
        future: repo.getSessionsInDateRange(start, now),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const _EmptyState(text: 'Complete workouts to see frequency');
          }

          final completed = sessions.where((s) => s.completed == true).length;
          final skipped = sessions.where((s) => s.skipped == true).length;
          final total = sessions.length;
          final rate = total > 0 ? (completed / total * 100).round() : 0;

          // Group by week
          final Map<int, int> weekCounts = {};
          for (final s in sessions) {
            if (s.completed != true) continue;
            final weekNum = (now.difference(s.date).inDays / 7).floor();
            weekCounts[weekNum] = (weekCounts[weekNum] ?? 0) + 1;
          }

          final weeks = rangeDays ~/ 7;
          final avgPerWeek = completed / (weeks > 0 ? weeks : 1);

          return Column(
            children: [
              // Metrics row
              Row(
                children: [
                  _MetricBadge(
                    label: 'Completed',
                    value: '$completed',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _MetricBadge(
                    label: 'Skipped',
                    value: '$skipped',
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  _MetricBadge(
                    label: 'Rate',
                    value: '$rate%',
                    color: AppColors.workoutsRing,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Weekly bars
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(weeks.clamp(1, 12), (i) {
                    final weekIndex = weeks - 1 - i;
                    final count = weekCounts[weekIndex] ?? 0;
                    final maxCount = weekCounts.values.isEmpty
                        ? 5
                        : weekCounts.values.reduce((a, b) => a > b ? a : b);
                    final barHeight =
                        maxCount > 0 ? (count / maxCount * 70).clamp(4.0, 70.0) : 4.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: weeks > 8 ? 16 : 28,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: i == weeks - 1 ? 1.0 : 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'W${i + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Avg ${avgPerWeek.toStringAsFixed(1)} workouts/week',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===== MOOD/ENERGY × CYCLE PHASE CARD =====

class _MoodEnergyCycleCard extends ConsumerWidget {
  final int rangeDays;

  const _MoodEnergyCycleCard({required this.rangeDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    // Only show if user tracks cycles
    if (profile == null || !profile.trackCycle) {
      return const SizedBox.shrink();
    }

    final checkInsAsync = ref.watch(extendedCheckInsProvider(rangeDays));

    return _AnalyticsCard(
      title: 'Mood & Energy by Cycle Phase',
      icon: Icons.psychology_outlined,
      child: checkInsAsync.when(
        data: (checkIns) {
          // Group check-ins by cycle phase
          final phases = ['Menstrual', 'Follicular', 'Ovulation', 'Luteal'];
          final moodByPhase = <String, List<int>>{};
          final energyByPhase = <String, List<int>>{};

          for (final phase in phases) {
            moodByPhase[phase] = [];
            energyByPhase[phase] = [];
          }

          for (final c in checkIns) {
            if (c.moodScore == null && c.energyScore == null) continue;
            final phase = _getCyclePhaseForDate(c.ts, profile);
            if (phase == null) continue;

            if (c.moodScore != null) {
              moodByPhase[phase]?.add(c.moodScore!);
            }
            if (c.energyScore != null) {
              energyByPhase[phase]?.add(c.energyScore!);
            }
          }

          final hasData = moodByPhase.values.any((l) => l.isNotEmpty) ||
              energyByPhase.values.any((l) => l.isNotEmpty);

          if (!hasData) {
            return const _EmptyState(
              text: 'Check in with mood & energy to see cycle correlations',
            );
          }

          return Column(
            children: [
              // Phase bars
              ...phases.map((phase) {
                final moods = moodByPhase[phase] ?? [];
                final energies = energyByPhase[phase] ?? [];
                final avgMood = moods.isEmpty
                    ? 0.0
                    : moods.reduce((a, b) => a + b) / moods.length;
                final avgEnergy = energies.isEmpty
                    ? 0.0
                    : energies.reduce((a, b) => a + b) / energies.length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          phase,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mood bar
                      Expanded(
                        child: _HorizontalBar(
                          value: avgMood,
                          maxValue: 5,
                          color: const Color(0xFF5C9EDB),
                          label: avgMood > 0
                              ? avgMood.toStringAsFixed(1)
                              : '-',
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Energy bar
                      Expanded(
                        child: _HorizontalBar(
                          value: avgEnergy,
                          maxValue: 5,
                          color: const Color(0xFFE6A23C),
                          label: avgEnergy > 0
                              ? avgEnergy.toStringAsFixed(1)
                              : '-',
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C9EDB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Mood',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6A23C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Energy',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          );
        },
        loading: () => const _LoadingState(),
        error: (_, __) => const _EmptyState(text: 'Error loading data'),
      ),
    );
  }

  String? _getCyclePhaseForDate(DateTime date, UserProfile profile) {
    final lastPeriod = profile.lastPeriodDate;
    if (lastPeriod == null) return null;

    final cycleLength = profile.cycleLength;
    final daysSincePeriod = date.difference(lastPeriod).inDays;
    final cycleDay = daysSincePeriod % cycleLength;

    if (cycleDay < 5) return 'Menstrual';
    if (cycleDay < (cycleLength * 0.45).round()) return 'Follicular';
    if (cycleDay < (cycleLength * 0.55).round()) return 'Ovulation';
    return 'Luteal';
  }
}

// ===== SHARED WIDGETS =====

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final String label;
  final double delta;
  final String unit;
  final Color color;

  const _DeltaBadge({
    required this.label,
    required this.delta,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final sign = isPositive ? '+' : '';
    final displayColor = delta.abs() < 0.1
        ? Colors.grey
        : isPositive
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $sign${delta.toStringAsFixed(1)} $unit',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: displayColor,
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color color;
  final String label;

  const _HorizontalBar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 22,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
