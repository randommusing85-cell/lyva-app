import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../models/meal_log.dart';
import '../services/premium_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/cycle_phase_card.dart';
import '../widgets/today_action_card.dart';
import '../widgets/diet_phase_card.dart';
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
    ref.invalidate(todayActionProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateStr = DateFormat('MMMM d').format(now);

    final profileAsync = ref.watch(userProfileProvider);
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);
    final weekSessionsAsync = ref.watch(thisWeekSessionsProvider);
    final planAsync = ref.watch(activePlanProvider);
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
                            'assets/logo/Lyva/symbol-only.svg',
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Lyva',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _CyclePhaseBadge(tracking: profileAsync.valueOrNull?.trackCycle == true),
                    ],
                  ),

                  const SizedBox(height: 20),

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

                  if (ref.watch(personalizationDecisionProvider).asData?.value.allowed == true)
                    const TodayActionCard()
                  else
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text(
                      'Personalized workout guidance is unavailable. Your saved records are preserved; check-ins and meal logging remain available.'))),
                  const SizedBox(height: 12),
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

                  // Cycle Phase (moved here - shows if tracking cycles)
                  const CyclePhaseCard(),

                  const SizedBox(height: 12),

                  // Diet Phase (shows for cutting users: plateau alerts, refeed status)
                  const DietPhaseCard(),

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
    final guidanceAllowed = ref.watch(personalizationDecisionProvider).asData?.value.allowed == true;

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
            progress: guidanceAllowed ? (todayCalories / targetCalories).clamp(0.0, 1.0) : 0,
            color: AppColors.caloriesRing,
          ),
          _ProgressRingItem(
            value: _formatSteps(todaySteps),
            label: 'steps',
            progress: guidanceAllowed ? (todaySteps / 8000).clamp(0.0, 1.0) : 0,
            color: AppColors.stepsRing,
          ),
          _ProgressRingItem(
            value: guidanceAllowed ? '$completedWorkouts / $targetWorkouts' : '$completedWorkouts',
            label: 'workouts',
            progress: guidanceAllowed ? (completedWorkouts / targetWorkouts).clamp(0.0, 1.0) : 0,
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

/// Tracking preference badge, independent of phase/period calculations.
class _CyclePhaseBadge extends StatelessWidget {
 final bool tracking;
 const _CyclePhaseBadge({required this.tracking});
 @override Widget build(BuildContext context) => tracking ? const Chip(
   avatar:Icon(Icons.calendar_today,size:16),label:Text('Cycle tracking')) : const SizedBox.shrink();
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
