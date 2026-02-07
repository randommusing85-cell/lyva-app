import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/providers.dart';
import '../models/meal_log.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_progress_ring.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';
import '../widgets/premium_gate.dart';
import '../widgets/steps_trend_card.dart';

// ===== BMR/TDEE CALCULATOR =====

/// Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
double calculateBMR({
  required double weightKg,
  required int heightCm,
  required int age,
  required String sex,
}) {
  // Mifflin-St Jeor equation (most accurate for modern populations)
  if (sex == 'male') {
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  } else {
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }
}

/// Calculate Total Daily Energy Expenditure based on activity level
double calculateTDEE({
  required double bmr,
  required int trainingDaysPerWeek,
}) {
  // Activity multipliers
  double multiplier;
  if (trainingDaysPerWeek <= 1) {
    multiplier = 1.2; // Sedentary
  } else if (trainingDaysPerWeek <= 3) {
    multiplier = 1.375; // Lightly active
  } else if (trainingDaysPerWeek <= 5) {
    multiplier = 1.55; // Moderately active
  } else {
    multiplier = 1.725; // Very active
  }
  return bmr * multiplier;
}

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logTrendsViewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);
    final sessionsAsync = ref.watch(thisWeekSessionsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final todayMealsAsync = ref.watch(todayMealsStreamProvider);
    final planAsync = ref.watch(activePlanProvider);

    final monthYear = DateFormat('MMMM yyyy').format(_selectedDate);

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
                'Statistics',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monthYear,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Week calendar
              _WeekCalendar(
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),

              const SizedBox(height: 24),

              // Overview section
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Overview cards grid
              _OverviewCards(
                checkInsAsync: checkInsAsync,
                sessionsAsync: sessionsAsync,
                profileAsync: profileAsync,
              ),

              const SizedBox(height: 24),

              // Daily Progress chart
              _DailyProgressCard(
                checkInsAsync: checkInsAsync,
                todayMealsAsync: todayMealsAsync,
                profileAsync: profileAsync,
                planAsync: planAsync,
              ),

              const SizedBox(height: 24),

              // Weight trend chart
              _WeightChartCard(checkInsAsync: checkInsAsync),

              const SizedBox(height: 24),

              // Consistency chart
              _ConsistencyCard(sessionsAsync: sessionsAsync),

              const SizedBox(height: 24),

              // Steps trend chart (7-day)
              const StepsTrendCard(),

              const SizedBox(height: 24),

              // Premium: Progress Photos
              PremiumFeatureCard(
                feature: PremiumFeature.progressPhotos,
                icon: Icons.camera_outlined,
                title: 'Progress Photos',
                description: 'Upload photos for AI body analysis and achievable celeb comparisons',
              ),

              const SizedBox(height: 12),

              // Premium: Advanced Analytics
              PremiumFeatureCard(
                feature: PremiumFeature.advancedAnalytics,
                icon: Icons.analytics_outlined,
                title: 'Advanced Analytics',
                description: 'Body composition trends, performance tracking, and detailed insights',
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Week calendar row with selectable days
class _WeekCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Get the start of the week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        children: [
          // Day labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Date numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final date = startOfWeek.add(Duration(days: i));
              final isSelected = date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;
              final isToday = date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primaryLight.withOpacity(0.3)
                            : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Overview cards grid
class _OverviewCards extends StatelessWidget {
  final AsyncValue<List<dynamic>> checkInsAsync;
  final AsyncValue<List<dynamic>> sessionsAsync;
  final AsyncValue<dynamic> profileAsync;

  const _OverviewCards({
    required this.checkInsAsync,
    required this.sessionsAsync,
    required this.profileAsync,
  });

  @override
  Widget build(BuildContext context) {
    final checkIns = checkInsAsync.valueOrNull ?? [];
    final sessions = sessionsAsync.valueOrNull ?? [];

    // Calculate stats
    final totalCalories = _calculateTotalCalories(checkIns);
    final totalTime = _calculateTotalTime(sessions);
    final totalExercises = _calculateTotalExercises(sessions);
    final weightChange = _calculateWeightChange(checkIns);

    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            icon: Icons.local_fire_department_outlined,
            value: totalCalories.toStringAsFixed(0),
            label: 'Cal\nBurnt',
            color: AppColors.caloriesRing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            icon: Icons.timer_outlined,
            value: totalTime,
            label: 'Total\nTime',
            color: AppColors.stepsRing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            icon: Icons.fitness_center,
            value: totalExercises.toString(),
            label: 'Exercises',
            color: AppColors.workoutsRing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            icon: Icons.trending_down,
            value: weightChange,
            label: 'kg',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  double _calculateTotalCalories(List<dynamic> checkIns) {
    // Estimate based on steps (rough: 0.04 cal per step)
    if (checkIns.isEmpty) return 0;
    final totalSteps = checkIns.fold<int>(
        0, (sum, c) => sum + ((c.stepsToday as int?) ?? 0));
    return totalSteps * 0.04;
  }

  String _calculateTotalTime(List<dynamic> sessions) {
    final completed = sessions.where((s) => s.completed == true).length;
    final minutes = completed * 45; // Assume 45 min avg
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h\n${mins}m';
    }
    return '${mins}m';
  }

  int _calculateTotalExercises(List<dynamic> sessions) {
    // Estimate 5 exercises per session
    final completed = sessions.where((s) => s.completed == true).length;
    return completed * 5;
  }

  String _calculateWeightChange(List<dynamic> checkIns) {
    if (checkIns.length < 2) return '0.0';
    final latest = checkIns.first.weightKg as double;
    final oldest = checkIns.last.weightKg as double;
    final change = latest - oldest;
    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}';
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Daily Progress donut chart card
class _DailyProgressCard extends ConsumerWidget {
  final AsyncValue<List<dynamic>> checkInsAsync;
  final AsyncValue<List<MealLog>> todayMealsAsync;
  final AsyncValue<UserProfile?> profileAsync;
  final AsyncValue<dynamic> planAsync;

  const _DailyProgressCard({
    required this.checkInsAsync,
    required this.todayMealsAsync,
    required this.profileAsync,
    required this.planAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checkIns = checkInsAsync.valueOrNull ?? [];
    final todayMeals = todayMealsAsync.valueOrNull ?? [];
    final profile = profileAsync.valueOrNull;
    final plan = planAsync.valueOrNull;

    // Get today's steps from health platform
    final todaySteps = ref.watch(todayStepsProvider).valueOrNull ?? 0;

    // Get today's calories from logged meals
    int todayCalories = 0;
    for (final meal in todayMeals) {
      todayCalories += meal.calories;
    }

    // Calculate TDEE if profile available
    int tdee = 2000; // Default
    int deficit = 0;
    String deficitLabel = 'On target';
    Color deficitColor = AppColors.workoutsRing;

    if (profile != null) {
      // Use latest weight from check-ins if available, otherwise profile weight
      double currentWeight = profile.weightKg;
      if (checkIns.isNotEmpty) {
        currentWeight = (checkIns.first.weightKg as double?) ?? profile.weightKg;
      }

      final bmr = calculateBMR(
        weightKg: currentWeight,
        heightCm: profile.heightCm,
        age: profile.age,
        sex: profile.sex,
      );

      tdee = calculateTDEE(
        bmr: bmr,
        trainingDaysPerWeek: profile.trainingDaysPerWeek,
      ).round();

      // Calculate deficit/surplus
      deficit = tdee - todayCalories;

      if (deficit > 200) {
        deficitLabel = '-${deficit}cal deficit';
        deficitColor = Colors.green;
      } else if (deficit < -200) {
        deficitLabel = '+${deficit.abs()}cal surplus';
        deficitColor = Colors.orange;
      } else {
        deficitLabel = 'On target';
        deficitColor = AppColors.workoutsRing;
      }
    }

    // Get target calories from plan or use TDEE
    final targetCalories = plan?.calories ?? tdee;
    final targetSteps = plan?.stepTarget ?? 10000;

    // Calculate progress for deficit ring (inverted - full when on target)
    final deficitProgress = todayCalories > 0
        ? (1 - (deficit.abs() / tdee)).clamp(0.0, 1.0)
        : 0.0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // TDEE badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TDEE: $tdee',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Progress rings stacked
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressRing(
                      progress: (todaySteps / targetSteps).clamp(0.0, 1.0),
                      size: 120,
                      strokeWidth: 10,
                      progressColor: AppColors.stepsRing,
                      backgroundColor: AppColors.stepsRing.withOpacity(0.2),
                    ),
                    CircularProgressRing(
                      progress: (todayCalories / targetCalories).clamp(0.0, 1.0),
                      size: 90,
                      strokeWidth: 10,
                      progressColor: AppColors.caloriesRing,
                      backgroundColor: AppColors.caloriesRing.withOpacity(0.2),
                    ),
                    CircularProgressRing(
                      progress: deficitProgress,
                      size: 60,
                      strokeWidth: 10,
                      progressColor: deficitColor,
                      backgroundColor: deficitColor.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressLabel(
                      color: deficitColor,
                      label: 'Balance',
                      value: deficitLabel,
                      target: '',
                      showSlash: false,
                    ),
                    const SizedBox(height: 12),
                    _ProgressLabel(
                      color: AppColors.caloriesRing,
                      label: 'Calories',
                      value: '$todayCalories',
                      target: '$targetCalories',
                    ),
                    const SizedBox(height: 12),
                    _ProgressLabel(
                      color: AppColors.stepsRing,
                      label: 'Steps',
                      value: '$todaySteps',
                      target: '$targetSteps',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String target;
  final bool showSlash;

  const _ProgressLabel({
    required this.color,
    required this.label,
    required this.value,
    required this.target,
    this.showSlash = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          showSlash ? '$value/' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showSlash && target.isNotEmpty)
          Text(
            target,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Weight trend chart card
class _WeightChartCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> checkInsAsync;

  const _WeightChartCard({required this.checkInsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkIns = (checkInsAsync.valueOrNull ?? []).take(7).toList();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: checkIns.isEmpty
                ? Center(
                    child: Text(
                      'Check in to see trends',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : _SimpleLineChart(
                    data: checkIns
                        .map((c) => (c.weightKg as double))
                        .toList()
                        .reversed
                        .toList(),
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Simple line chart widget
class _SimpleLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _SimpleLineChart({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _LineChartPainter(
        data: data,
        color: color,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final minVal = data.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxVal = data.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = maxVal - minVal;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1).clamp(1, data.length);
      final y = size.height - (size.height * (data[i] - minVal) / range);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
          point, 6, Paint()..color = color.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

/// Consistency bar chart card
class _ConsistencyCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> sessionsAsync;

  const _ConsistencyCard({required this.sessionsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Placeholder data for 4 weeks
    final weekData = [3, 4, 3, 2]; // workouts per week

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (i) {
                final count = weekData[i];
                final height = (count / 5) * 80; // Max 5 workouts
                final isCurrentWeek = i == weekData.length - 1;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isCurrentWeek)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count workouts',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    if (isCurrentWeek) const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: height.clamp(10.0, 80.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(isCurrentWeek ? 1 : 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'W${i + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
