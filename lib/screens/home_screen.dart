import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../models/meal_log.dart';
import '../models/workout_template_doc.dart';
import '../services/premium_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/cycle_phase_card.dart';
import '../widgets/postpartum_status_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Motivational quotes - rotates randomly each time user visits
  static const List<String> _quotes = [
    "Movement is medicine",
    "You've got this!",
    "Listen to your body",
    "Progress, not perfection",
    "One day at a time",
    "Strength comes from within",
    "Every step counts",
    "Trust the process",
    "Small steps, big results",
    "Your body is capable",
    "Consistency over intensity",
    "Breathe and believe",
    "Honor your journey",
    "Rest is productive too",
    "You are stronger than you think",
  ];

  // Daily greetings for regular users
  static const List<String> _dailyGreetings = [
    "Let's get it",
    "Ready to crush it",
    "Hey there",
    "Let's go",
    "Time to shine",
  ];

  late String _currentQuote;
  late String _greeting;
  bool _isReturningUser = false;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    _greeting = _dailyGreetings[Random().nextInt(_dailyGreetings.length)];

    // Update last login time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLastLogin();
    });
  }

  Future<void> _updateLastLogin() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      final lastLogin = profile.lastLoginAt;
      final now = DateTime.now();

      // Check if this is a returning user (hasn't logged in for 2+ days)
      if (lastLogin != null) {
        final daysSinceLastLogin = now.difference(lastLogin).inDays;
        if (daysSinceLastLogin >= 2) {
          setState(() {
            _isReturningUser = true;
          });
        }
      }

      // Update lastLoginAt
      profile.lastLoginAt = now;
      profile.updatedAt = now;
      final repo = ref.read(userProfileRepoProvider);
      await repo.saveProfile(profile);
    }
  }

  /// Extracts the first name from a full name string
  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  Future<void> _onRefresh() async {
    ref.invalidate(userProfileProvider);
    ref.invalidate(latestWorkoutTemplateProvider);
    ref.invalidate(latestCheckInsStreamProvider);
    ref.invalidate(todayMealsStreamProvider);
    ref.invalidate(thisWeekSessionsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateStr = DateFormat('MMMM d').format(now);

    final profileAsync = ref.watch(userProfileProvider);
    final workoutTemplateAsync = ref.watch(latestWorkoutTemplateProvider);
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);
    final weekSessionsAsync = ref.watch(thisWeekSessionsProvider);
    final planAsync = ref.watch(activePlanProvider);
    final cyclePhaseAsync = ref.watch(currentCyclePhaseProvider);
    final todayMealsAsync = ref.watch(todayMealsStreamProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header row: Logo + Season badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/logo/primeform_logo.svg',
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'PrimeForm',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _CyclePhaseBadge(cyclePhaseAsync: cyclePhaseAsync),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Motivational quote card (rotates each visit)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _currentQuote,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personalized Greeting
                  profileAsync.when(
                    data: (profile) {
                      final firstName = _getFirstName(profile?.name ?? '');
                      final greetingText = _isReturningUser
                          ? 'Welcome back${firstName.isNotEmpty ? ', $firstName' : ''}'
                          : firstName.isNotEmpty
                              ? '$_greeting, $firstName'
                              : _greeting;

                      return Text(
                        greetingText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 4),

                  // Day and Date
                  Text(
                    dayName,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cycle Phase (moved here - shows if tracking cycles)
                  const CyclePhaseCard(),

                  const SizedBox(height: 16),

                  // Progress rings row
                  _ProgressRingsRow(
                    checkInsAsync: checkInsAsync,
                    todayMealsAsync: todayMealsAsync,
                    weekSessionsAsync: weekSessionsAsync,
                    planAsync: planAsync,
                    profileAsync: profileAsync,
                  ),

                  const SizedBox(height: 20),

                  // Today's Workout Card
                  _TodayWorkoutCard(workoutTemplateAsync: workoutTemplateAsync),

                  const SizedBox(height: 16),

                  // Quick Actions Row (Check-in + Nutrition)
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          emoji: '😊',
                          label: 'Check-in',
                          onTap: () => Navigator.pushNamed(context, '/checkin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          emoji: '🥗',
                          label: 'Nutrition',
                          onTap: () => Navigator.pushNamed(context, '/nutrition'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Premium Quick Actions (AI Coach + Progress Photos)
                  const _PremiumQuickActions(),

                  const SizedBox(height: 16),

                  // Post-Partum Status (only shows if post-partum)
                  const PostPartumStatusCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress rings row showing calories, steps, workouts
class _ProgressRingsRow extends ConsumerWidget {
  final AsyncValue<List<dynamic>> checkInsAsync;
  final AsyncValue<List<MealLog>> todayMealsAsync;
  final AsyncValue<List<dynamic>> weekSessionsAsync;
  final AsyncValue<dynamic> planAsync;
  final AsyncValue<dynamic> profileAsync;

  const _ProgressRingsRow({
    required this.checkInsAsync,
    required this.todayMealsAsync,
    required this.weekSessionsAsync,
    required this.planAsync,
    required this.profileAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get today's calories from today's meals
    int todayCalories = 0;
    final todayMeals = todayMealsAsync.valueOrNull ?? [];
    for (final meal in todayMeals) {
      todayCalories += meal.calories;
    }

    final plan = planAsync.valueOrNull;
    final targetCalories = plan?.calories ?? 1500;

    // Get today's steps from health platform (Apple Health / Health Connect)
    final todaySteps = ref.watch(todayStepsProvider).valueOrNull ?? 0;

    // Get workouts this week
    final weekSessions = weekSessionsAsync.valueOrNull ?? [];
    final completedWorkouts = weekSessions.where((s) => s.completed == true).length;
    final targetWorkouts = profileAsync.valueOrNull?.trainingDaysPerWeek ?? 4;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ProgressRingItem(
            value: todayCalories.toString(),
            label: 'calories',
            progress: (todayCalories / targetCalories).clamp(0.0, 1.0),
            color: AppColors.caloriesRing,
          ),
          _ProgressRingItem(
            value: _formatSteps(todaySteps),
            label: 'steps',
            progress: (todaySteps / 8000).clamp(0.0, 1.0),
            color: AppColors.stepsRing,
          ),
          _ProgressRingItem(
            value: '$completedWorkouts / $targetWorkouts',
            label: 'workouts',
            progress: (completedWorkouts / targetWorkouts).clamp(0.0, 1.0),
            color: AppColors.workoutsRing,
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return steps.toString();
  }
}

class _ProgressRingItem extends StatelessWidget {
  final String value;
  final String label;
  final double progress;
  final Color color;

  const _ProgressRingItem({
    required this.value,
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressRing(
          progress: progress,
          progressColor: color,
          backgroundColor: color.withOpacity(0.2),
          size: 56,
          strokeWidth: 5,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Today's workout card matching Figma design
class _TodayWorkoutCard extends StatelessWidget {
  final AsyncValue<WorkoutTemplateDoc?> workoutTemplateAsync;

  const _TodayWorkoutCard({required this.workoutTemplateAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return workoutTemplateAsync.when(
      data: (templateDoc) {
        // Parse the JSON from the WorkoutTemplateDoc
        Map<String, dynamic>? templateData;
        if (templateDoc != null) {
          try {
            templateData = jsonDecode(templateDoc.json) as Map<String, dynamic>;
          } catch (_) {
            templateData = null;
          }
        }

        final workoutTitle = templateData != null
            ? (templateData['days']?[0]?['title'] ?? 'Upper Body')
            : 'No workout planned';
        final duration = templateData != null
            ? '${templateData['sessionDurationMin'] ?? 45} min'
            : '';
        final exerciseCount = templateData != null
            ? (templateData['days']?[0]?['exercises'] as List?)?.length ?? 4
            : 0;

        return Container(
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
          child: InkWell(
            onTap: () {
              if (templateData != null) {
                Navigator.pushNamed(context, '/today-workout');
              } else {
                Navigator.pushNamed(context, '/workout');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Workout",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  workoutTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (templateData != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$duration • $exerciseCount exercises',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tap to create your workout plan',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Quick action card (Check-in, Nutrition)
class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cycle phase badge with info icon
class _CyclePhaseBadge extends StatelessWidget {
  final AsyncValue<CyclePhase?> cyclePhaseAsync;

  const _CyclePhaseBadge({required this.cyclePhaseAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return cyclePhaseAsync.when(
      data: (phase) {
        if (phase == null) {
          // Not tracking cycles - show nothing or a simple badge
          return const SizedBox.shrink();
        }

        final phaseInfo = _getPhaseInfo(phase);

        return GestureDetector(
          onTap: () => _showCycleInfoDialog(context, phase, phaseInfo),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: phaseInfo.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(phaseInfo.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  phaseInfo.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: phaseInfo.color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: phaseInfo.color,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  _PhaseInfo _getPhaseInfo(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return _PhaseInfo(
          name: 'Menstrual',
          emoji: '🌙',
          color: const Color(0xFFB85C5C),
          description: 'Rest & recovery phase. Your body is shedding the uterine lining. '
              'Focus on gentle movement, stretching, and listening to your body. '
              'It\'s okay to reduce intensity.',
          tips: [
            'Prioritize rest and sleep',
            'Gentle yoga or walking',
            'Stay hydrated',
            'Iron-rich foods help',
          ],
        );
      case CyclePhase.follicular:
        return _PhaseInfo(
          name: 'Follicular',
          emoji: '🌱',
          color: const Color(0xFF5C9E5C),
          description: 'Energy rising phase. Estrogen increases, boosting mood and energy. '
              'Great time for trying new workouts, building strength, and pushing harder.',
          tips: [
            'Try new exercises',
            'Increase workout intensity',
            'Build strength & muscle',
            'Energy levels are high',
          ],
        );
      case CyclePhase.ovulation:
        return _PhaseInfo(
          name: 'Ovulation',
          emoji: '☀️',
          color: const Color(0xFFE6A23C),
          description: 'Peak energy phase. You\'re at your strongest! '
              'Testosterone and estrogen peak, making this ideal for high-intensity workouts and PRs.',
          tips: [
            'Go for personal records',
            'High-intensity training',
            'Peak strength & endurance',
            'Social workouts are great',
          ],
        );
      case CyclePhase.luteal:
        return _PhaseInfo(
          name: 'Luteal',
          emoji: '🍂',
          color: const Color(0xFF8B7355),
          description: 'Wind-down phase. Progesterone rises, which can affect mood and energy. '
              'Focus on steady-state cardio and maintenance. Be patient with yourself.',
          tips: [
            'Moderate intensity workouts',
            'Focus on form over weight',
            'Extra rest between sets',
            'Nourishing foods help',
          ],
        );
    }
  }

  void _showCycleInfoDialog(BuildContext context, CyclePhase phase, _PhaseInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              '${info.name} Phase',
              style: TextStyle(color: info.color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Tips for this phase:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...info.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: info.color)),
                    Expanded(child: Text(tip)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _PhaseInfo {
  final String name;
  final String emoji;
  final Color color;
  final String description;
  final List<String> tips;

  _PhaseInfo({
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
    required this.tips,
  });
}

/// Premium quick actions row (AI Coach + Progress Photos)
class _PremiumQuickActions extends ConsumerWidget {
  const _PremiumQuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(premiumAccessProvider);
    final access = accessAsync.valueOrNull;

    // AI Coach and Progress Photos are premium-tier features
    final canAccessCoach =
        access?.canAccessFeature(PremiumFeature.aiCoaching) ?? false;
    final canAccessPhotos =
        access?.canAccessFeature(PremiumFeature.progressPhotos) ?? false;

    if (!canAccessCoach && !canAccessPhotos) return const SizedBox.shrink();

    return Row(
      children: [
        if (canAccessCoach)
          Expanded(
            child: _QuickActionCard(
              emoji: '🤖',
              label: 'AI Coach',
              onTap: () => Navigator.pushNamed(context, '/ai-coaching'),
            ),
          ),
        if (canAccessCoach && canAccessPhotos) const SizedBox(width: 12),
        if (canAccessPhotos)
          Expanded(
            child: _QuickActionCard(
              emoji: '📸',
              label: 'Photos',
              onTap: () => Navigator.pushNamed(context, '/progress-photos'),
            ),
          ),
      ],
    );
  }
}
