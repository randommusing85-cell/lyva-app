import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../widgets/workout_calendar.dart';
import '../data/exercise_alternatives.dart';
import '../theme/app_theme.dart';
import 'workout_completion_screen.dart';

class TodayWorkoutScreen extends ConsumerStatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  // Track completion checkboxes locally (Phase 1.5 only)
  final Map<String, bool> _done = {};

  // Track exercise swaps (original exercise key -> new exercise name)
  final Map<String, String> _swappedExercises = {};

  Timer? _timer;
  int? _restLeftSec;
  String? _restLabel;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRest({required int seconds, required String label}) {
    _timer?.cancel();
    setState(() {
      _restLeftSec = seconds;
      _restLabel = label;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final left = _restLeftSec ?? 0;
      if (left <= 1) {
        t.cancel();
        setState(() => _restLeftSec = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rest done — $label')),
        );
        return;
      }
      setState(() => _restLeftSec = left - 1);
    });
  }

  void _stopRest() {
    _timer?.cancel();
    setState(() {
      _restLeftSec = null;
      _restLabel = null;
    });
  }

  String _formatMmSs(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Show skip workout dialog
  Future<void> _showSkipWorkoutDialog({
    required BuildContext context,
    required int dayIndex,
    required String workoutTitle,
  }) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SkipWorkoutSheet(workoutTitle: workoutTitle),
    );

    if (result != null && mounted) {
      final repo = ref.read(lyvaRepoProvider);
      await repo.skipSession(dayIndex: dayIndex, reason: result);

      // Track analytics
      final analytics = AnalyticsService();
      await analytics.logFeatureUsed(featureName: 'workout_skipped');

      ref.invalidate(todayWorkoutDayProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout skipped. Rest up and come back stronger!'),
          ),
        );
        Navigator.of(context).pop(); // Go back to home
      }
    }
  }

  /// Show alternatives dialog for an exercise
  /// If aiAlternatives is provided (from the workout template), use those first.
  /// Otherwise fall back to the static alternatives database.
  Future<void> _showAlternativesDialog({
    required String exerciseKey,
    required String originalName,
    List<Map<String, dynamic>>? aiAlternatives,
  }) async {
    // Prefer AI-generated alternatives if available
    List<ExerciseOption> alternatives;
    if (aiAlternatives != null && aiAlternatives.isNotEmpty) {
      alternatives = aiAlternatives.map((alt) => ExerciseOption(
        alt['name']?.toString() ?? 'Alternative',
        alt['reason']?.toString() ?? 'Similar movement pattern',
      )).toList();
    } else {
      alternatives = ExerciseAlternatives.findAlternatives(originalName) ??
          ExerciseAlternatives.getDefaultAlternatives(originalName);
    }

    final currentName = _swappedExercises[exerciseKey] ?? originalName;
    final isSwapped = _swappedExercises.containsKey(exerciseKey);

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ExerciseAlternativesSheet(
        originalName: originalName,
        currentName: currentName,
        alternatives: alternatives,
        isSwapped: isSwapped,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result == '__RESET__') {
          _swappedExercises.remove(exerciseKey);
        } else {
          _swappedExercises[exerciseKey] = result;
        }
      });

      // Track analytics
      final analytics = AnalyticsService();
      if (result == '__RESET__') {
        // Could add an analytics event for resetting exercise
      } else {
        await analytics.logFeatureUsed(featureName: 'exercise_swap');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(lyvaRepoProvider);

    final asyncTemplate = ref.watch(latestWorkoutTemplateProvider);
    final asyncDayIndex = ref.watch(todayWorkoutDayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Today's Workout",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          asyncTemplate.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(
              child: Text('Something went wrong loading your workout plan.'),
            ),
            data: (doc) {
              if (doc == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                            Icons.fitness_center,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No workout plan saved yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a personalized workout plan to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/workout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Create Workout Plan'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Decode template JSON safely
              final decoded = jsonDecode(doc.json);
              if (decoded is! Map) {
                return const Center(
                  child: Text('Saved workout plan is corrupted.'),
                );
              }
              final template = Map<String, dynamic>.from(decoded);

              final rawDays = template['days'];
              if (rawDays is! List) {
                return const Center(
                  child: Text('Saved workout plan is missing days.'),
                );
              }
              final days = rawDays
                  .whereType<Map>()
                  .map((d) => Map<String, dynamic>.from(d))
                  .toList();

              // Warm-up protocol (optional display)
              final warmup = template['globalDefaults']?['warmup'];
              final warmupEnabled = warmup is Map && warmup['enabled'] == true;

              return asyncDayIndex.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(
                  child: Text('Something went wrong loading today\'s workout.'),
                ),
                data: (dayIndex) {
                  if (dayIndex == null) {
                    return const Center(child: Text('No workout plan found.'));
                  }

                  // Find matching day by dayIndex, fallback to array position
                  Map<String, dynamic>? day;
                  for (final d in days) {
                    final di = d['dayIndex'];
                    if (di is num && di.toInt() == dayIndex) {
                      day = d;
                      break;
                    }
                  }
                  day ??= (dayIndex - 1 < days.length)
                      ? days[dayIndex - 1]
                      : days.first;

                  final title = day['title']?.toString() ?? 'Day $dayIndex';

                  final rawExercises = day['exercises'];
                  if (rawExercises is! List) {
                    return const Center(
                      child: Text('This workout day has no exercises.'),
                    );
                  }
                  final exercises = rawExercises
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  // Count checked for summary
                  int checkedCount = 0;
                  for (final ex in exercises) {
                    final id = (ex['exerciseId'] ?? '').toString();
                    final k = 'd$dayIndex:$id';
                    if ((_done[k] ?? false) == true) checkedCount++;
                  }

                  Future<void> completeWorkout() async {
                    // Show completion dialog with optional notes
                    final result = await showModalBottomSheet<Map<String, dynamic>?>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => _CompleteWorkoutSheet(
                        workoutTitle: title,
                        checkedCount: checkedCount,
                        totalExercises: exercises.length,
                      ),
                    );

                    if (result == null) return;

                    final notes = result['notes'] as String?;

                    bool sameDay(DateTime a, DateTime b) =>
                        a.year == b.year && a.month == b.month && a.day == b.day;

                    final now = DateTime.now();
                    final last = await repo.getLatestWorkoutSession();

                    // If there's already an open session today, complete it instead of creating another.
                    if (last != null && sameDay(last.date, now) && last.completed == false) {
                      await repo.completeSession(last.id, notes: notes);
                    } else {
                      final session = await repo.startTodaySession(dayIndex: dayIndex);
                      await repo.completeSession(session.id, notes: notes);
                    }

                    // Track analytics
                    final analytics = AnalyticsService();
                    await analytics.logWorkoutCompleted(
                      dayIndex: dayIndex,
                      totalDays: doc.daysPerWeek,
                      exercisesCompleted: checkedCount,
                      totalExercises: exercises.length,
                    );

                    ref.invalidate(todayWorkoutDayProvider);

                    if (mounted) {
                      // Navigate to completion screen
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutCompletionScreen(
                            dayIndex: dayIndex,
                            totalDays: doc.daysPerWeek,
                            completedExercises: checkedCount,
                            totalExercises: exercises.length,
                            workoutTitle: title,
                          ),
                        ),
                      );

                      // Refresh when coming back
                      ref.invalidate(todayWorkoutDayProvider);
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // Workout Calendar
                        WorkoutCalendar(
                          trainingDaysPerWeek: doc.daysPerWeek,
                        ),
                        const SizedBox(height: 20),

                        // Header Card with day info
                        Container(
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Day $dayIndex of ${doc.daysPerWeek}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$checkedCount/${exercises.length}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doc.planName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (warmupEnabled) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.whatshot,
                                        size: 16,
                                        color: AppColors.primary.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Warm-up: 50% x 6, 70% x 4, 85% x 2',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Exercises section header
                        const Text(
                          'Exercises',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Exercises list with numbered badges
                        ...List.generate(exercises.length, (i) {
                          final ex = exercises[i];

                          final id = (ex['exerciseId'] ?? 'ex_$i').toString();
                          final key = 'd$dayIndex:$id';

                          final originalName = ex['name']?.toString() ?? 'Exercise';
                          final displayName = _swappedExercises[key] ?? originalName;
                          final isSwapped = _swappedExercises.containsKey(key);
                          final sets = ex['workingSets'] ?? '?';

                          final repRaw = ex['repRange'];
                          int? repMin;
                          int? repMax;
                          if (repRaw is Map) {
                            final rep = Map<String, dynamic>.from(repRaw);
                            final minVal = rep['min'];
                            final maxVal = rep['max'];
                            if (minVal is num) repMin = minVal.toInt();
                            if (maxVal is num) repMax = maxVal.toInt();
                          }
                          final repText = (repMin != null && repMax != null)
                              ? '$repMin-$repMax'
                              : '?';

                          final liftClass = ex['liftClass']?.toString() ?? 'accessory';

                          // Rest seconds (prefer per-exercise, fallback by class)
                          int restSec = (liftClass == 'main' || liftClass == 'secondary')
                              ? 150
                              : 90;
                          final restRaw = ex['restSeconds'];
                          if (restRaw is num) {
                            restSec = restRaw.toInt();
                          }

                          final checked = _done[key] ?? false;

                          // Extract AI-generated alternatives if available
                          List<Map<String, dynamic>>? aiAlternatives;
                          final rawAlts = ex['alternatives'];
                          if (rawAlts is List && rawAlts.isNotEmpty) {
                            aiAlternatives = rawAlts
                                .whereType<Map>()
                                .map((a) => Map<String, dynamic>.from(a))
                                .toList();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ExerciseCard(
                              exerciseNumber: i + 1,
                              exerciseName: displayName,
                              originalName: isSwapped ? originalName : null,
                              sets: sets.toString(),
                              reps: repText,
                              restSeconds: restSec,
                              isCompleted: checked,
                              isSwapped: isSwapped,
                              onToggleComplete: () {
                                setState(() => _done[key] = !checked);
                              },
                              onStartRest: () => _startRest(
                                seconds: restSec,
                                label: displayName,
                              ),
                              onTapAlternatives: () => _showAlternativesDialog(
                                exerciseKey: key,
                                originalName: originalName,
                                aiAlternatives: aiAlternatives,
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Action buttons
                        ElevatedButton(
                          onPressed: completeWorkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Complete Workout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _showSkipWorkoutDialog(
                            context: context,
                            dayIndex: dayIndex,
                            workoutTitle: title,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppColors.textMuted,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Skip Today',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 100), // Extra space for bottom navigation
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Rest banner (bottom)
          if (_restLeftSec != null && _restLabel != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          _formatMmSs((_restLeftSec ?? 0).clamp(0, 10 * 60)),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Rest Timer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _restLabel!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _stopRest,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Exercise card widget with numbered badge and completion state
class _ExerciseCard extends StatelessWidget {
  final int exerciseNumber;
  final String exerciseName;
  final String? originalName;
  final String sets;
  final String reps;
  final int restSeconds;
  final bool isCompleted;
  final bool isSwapped;
  final VoidCallback onToggleComplete;
  final VoidCallback onStartRest;
  final VoidCallback onTapAlternatives;

  const _ExerciseCard({
    required this.exerciseNumber,
    required this.exerciseName,
    this.originalName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.isCompleted,
    required this.isSwapped,
    required this.onToggleComplete,
    required this.onStartRest,
    required this.onTapAlternatives,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
            : null,
        boxShadow: isCompleted ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTapAlternatives,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number badge / checkmark
                GestureDetector(
                  onTap: onToggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: AppColors.textMuted.withOpacity(0.3),
                              width: 1,
                            ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 20,
                              color: Colors.white,
                            )
                          : Text(
                              '$exerciseNumber',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exerciseName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (isSwapped)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.repeat,
                            label: '$sets sets',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.fitness_center,
                            label: '$reps reps',
                          ),
                        ],
                      ),
                      if (originalName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Originally: $originalName',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Rest button
                IconButton(
                  onPressed: onStartRest,
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        '${restSeconds}s',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  tooltip: 'Start rest timer',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small info chip for sets/reps display
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting exercise alternatives
class _ExerciseAlternativesSheet extends StatelessWidget {
  final String originalName;
  final String currentName;
  final List<ExerciseOption> alternatives;
  final bool isSwapped;

  const _ExerciseAlternativesSheet({
    required this.originalName,
    required this.currentName,
    required this.alternatives,
    required this.isSwapped,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exercise Alternatives',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose an alternative for $originalName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Current selection indicator
            if (isSwapped) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Currently using: $currentName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Reset option (if swapped)
            if (isSwapped)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.undo,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Reset to Original',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Go back to $originalName',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, '__RESET__'),
              ),

            if (isSwapped) const Divider(height: 24),

            // Alternatives list
            const Text(
              'Available Alternatives',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            ...alternatives.map((alt) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              title: Text(
                alt.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: currentName == alt.name
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                alt.description,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: currentName == alt.name
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, alt.name),
            )),

            const SizedBox(height: 16),

            // Info footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swapping exercises helps you work around equipment availability or comfort level.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for completing a workout with optional notes
class _CompleteWorkoutSheet extends StatefulWidget {
  final String workoutTitle;
  final int checkedCount;
  final int totalExercises;

  const _CompleteWorkoutSheet({
    required this.workoutTitle,
    required this.checkedCount,
    required this.totalExercises,
  });

  @override
  State<_CompleteWorkoutSheet> createState() => _CompleteWorkoutSheetState();
}

class _CompleteWorkoutSheetState extends State<_CompleteWorkoutSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completionPercent =
        (widget.checkedCount / widget.totalExercises * 100).round();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Workout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.workoutTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${widget.checkedCount}/${widget.totalExercises}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Exercises',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textMuted.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$completionPercent%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: completionPercent >= 80
                                ? AppColors.success
                                : completionPercent >= 50
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                        ),
                        const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Notes field
            const Text(
              'How did it go? (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText:
                    'e.g. Felt strong today, increased weight on squats...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                      });
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for skipping a workout with a reason
class _SkipWorkoutSheet extends StatefulWidget {
  final String workoutTitle;

  const _SkipWorkoutSheet({required this.workoutTitle});

  @override
  State<_SkipWorkoutSheet> createState() => _SkipWorkoutSheetState();
}

class _SkipWorkoutSheetState extends State<_SkipWorkoutSheet> {
  String? _selectedReason;
  final _customReasonCtrl = TextEditingController();

  static const _skipReasons = [
    ('sick', 'Feeling sick', Icons.sick),
    ('tired', 'Too tired / fatigued', Icons.bedtime),
    ('busy', 'No time today', Icons.schedule),
    ('injury', 'Injury / pain', Icons.healing),
    ('rest', 'Need extra rest', Icons.self_improvement),
    ('travel', 'Traveling', Icons.flight),
    ('other', 'Other reason', Icons.edit),
  ];

  @override
  void dispose() {
    _customReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skip Workout?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.workoutTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'It\'s okay to skip sometimes. Consistency over time matters more than perfection.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Why are you skipping today?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Reason chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skipReasons.map((reason) {
                final (id, label, icon) = reason;
                final isSelected = _selectedReason == id;

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16),
                      const SizedBox(width: 6),
                      Text(label),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  onSelected: (selected) {
                    setState(() {
                      _selectedReason = selected ? id : null;
                    });
                  },
                );
              }).toList(),
            ),

            // Custom reason field (if "other" is selected)
            if (_selectedReason == 'other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customReasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Tell us more (optional)',
                  hintText: 'What\'s going on?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedReason == null
                        ? null
                        : () {
                            String reason = _selectedReason!;
                            if (_selectedReason == 'other' &&
                                _customReasonCtrl.text.isNotEmpty) {
                              reason = _customReasonCtrl.text;
                            }
                            Navigator.pop(context, reason);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.textMuted.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip Workout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
