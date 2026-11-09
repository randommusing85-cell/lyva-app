import '../widgets/recorded_week_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
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

              RecordedWeekCard(anchor: _selectedDate),
              const SizedBox(height: 16),
              ExpansionTile(title: const Text('Optional measurement and step charts'), children: [
              // Weight trend chart
              _WeightChartCard(checkInsAsync: checkInsAsync),

              const SizedBox(height: 24),

              // Steps trend chart (7-day)
              StepsTrendCard(anchor: _selectedDate),

              const SizedBox(height: 24),

              ]),
              const SizedBox(height: 16),
              // Cycle prediction summary (when cycle tracking + premium active)
              const _CyclePredictionSummary(),

              const SizedBox(height: 24),

              // Premium: Progress Photos
              PremiumFeatureCard(
                feature: PremiumFeature.progressPhotos,
                icon: Icons.camera_outlined,
                title: 'Progress Photos',
                description: 'View and manage your saved progress photos',
              ),

              const SizedBox(height: 12),

              // Premium: Advanced Analytics
              const _AdvancedAnalyticsTile(),

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
                        .map((c) => (c.weightKg as double?))
                        .toList()
                        .reversed
                        .toList(),
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: 8),
          const Text('Recorded check-ins in time order; gaps are unrecorded.'),
        ],
      ),
    );
  }
}

/// Simple line chart widget
class _SimpleLineChart extends StatelessWidget {
  final List<double?> data;
  final Color color;

  const _SimpleLineChart({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.whereType<double>().where((v) => v.isFinite && v > 0).isEmpty) return const Center(child: Text('No weight recorded'));

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
  final List<double?> data;
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

    final valid = data.whereType<double>().where((v) => v.isFinite && v > 0).toList();
    if (valid.isEmpty) return;
    final minVal = valid.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxVal = valid.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = maxVal - minVal;

    final path = Path();
    final points = <Offset>[];

    var connected = false;
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value == null || !value.isFinite || value <= 0) { connected = false; continue; }
      final x = size.width * i / (data.length - 1).clamp(1, data.length);
      final y = size.height - (size.height * (value - minVal) / range);
      points.add(Offset(x, y));

      if (!connected) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      connected = true;
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

/// Cycle prediction summary card (shows when cycle tracking + premium active)
class _CyclePredictionSummary extends ConsumerWidget {
 const _CyclePredictionSummary();
 @override Widget build(BuildContext context, WidgetRef ref) {
  final profile=ref.watch(userProfileProvider).valueOrNull;
  final access=ref.watch(premiumAccessProvider).valueOrNull;
  if(profile?.trackCycle != true || access?.canAccessFeature(PremiumFeature.cyclePredictions) != true) {
   return const SizedBox.shrink();
  }
  return Card(child:ListTile(leading:const Icon(Icons.calendar_today),
   title:const Text('Cycle tracker'),subtitle:const Text('Browse recorded events and clearly labeled calendar estimates.'),
   trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.pushNamed(context,'/cycle-insights')));
 }
}

/// Advanced Analytics: navigable tile when premium, feature card otherwise
class _AdvancedAnalyticsTile extends ConsumerWidget {
  const _AdvancedAnalyticsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accessAsync = ref.watch(premiumAccessProvider);
    final canAccess = accessAsync.valueOrNull
            ?.canAccessFeature(PremiumFeature.advancedAnalytics) ??
        false;

    if (canAccess) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/advanced-analytics'),
        child: Container(
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Analytics',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Body composition, macros, workout trends',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      );
    }

    return PremiumFeatureCard(
      feature: PremiumFeature.advancedAnalytics,
      icon: Icons.analytics_outlined,
      title: 'Advanced Analytics',
      description: 'Body composition trends, performance tracking, and detailed insights',
    );
  }
}
