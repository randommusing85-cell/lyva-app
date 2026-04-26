import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkin.dart';
import '../models/prime_plan.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../utils/plateau_detector.dart';
import '../widgets/ai_coach_card.dart';
import 'nutrition_lock_explanation_screen.dart';

class MyPlanScreen extends ConsumerStatefulWidget {
  const MyPlanScreen({super.key});

  @override
  ConsumerState<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends ConsumerState<MyPlanScreen> {
  bool coachLoading = false;
  Map<String, dynamic>? adjustment;
  String? coachError;

  num _n(dynamic v, num fallback) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;

  // ===== AI COACH LOCK METHODS =====
  bool _canAskCoach(PrimePlan plan) {
    final now = DateTime.now();
    final daysSince = now.difference(plan.createdAt).inDays;
    return daysSince >= 7;
  }

  int _daysUntilCoach(PrimePlan plan) {
    final now = DateTime.now();
    final daysSince = now.difference(plan.createdAt).inDays;
    final remaining = 7 - daysSince;
    return remaining < 0 ? 0 : remaining;
  }

  // ===== NUTRITION PLAN LOCK METHODS (NEW) =====
  bool _canRegeneratePlan(PrimePlan plan) {
    final now = DateTime.now();
    final daysSince = now.difference(plan.createdAt).inDays;
    return daysSince >= 14;
  }

  int _daysUntilRegenerate(PrimePlan plan) {
    final now = DateTime.now();
    final daysSince = now.difference(plan.createdAt).inDays;
    final remaining = 14 - daysSince;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _navigateToRegenerate(PrimePlan plan) async {
    // Check if plan can be regenerated
    if (!_canRegeneratePlan(plan)) {
      // Show lock explanation screen
      final shouldProceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => NutritionLockExplanationScreen(
            createdAt: plan.createdAt,
            lockDays: 14,
          ),
        ),
      );

      // If user didn't confirm or lock is still active, don't proceed
      if (shouldProceed != true) {
        return;
      }
    }

    // Lock is not active or user confirmed, proceed to regenerate
    if (mounted) {
      Navigator.pushNamed(context, '/plan');
    }
  }

  // ===== REFEED PHASE TRANSITION METHODS =====

  Future<void> _startRefeed(PrimePlan currentPlan) async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) return;

    final maintenanceCals = PlateauDetector.calculateMaintenanceCalories(
      profile: profile,
      trainingDaysPerWeek: currentPlan.trainingDays,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.restaurant, size: 40, color: AppColors.primary),
        title: const Text('Start Refeed Break?'),
        content: Text(
          'Your weight has plateaued. A 2-week maintenance break will help '
          'reset your metabolism.\n\n'
          'Your calories will increase from ${currentPlan.calories} to '
          '$maintenanceCals kcal/day (maintenance level).\n\n'
          'After 14 days, you\'ll return to your deficit.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Refeed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Calculate maintenance macros (keep protein stable, increase carbs)
    final calorieDiff = maintenanceCals - currentPlan.calories;
    final extraCarbs = (calorieDiff / 4).round(); // Push extra into carbs

    final refeedPlan = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = '${currentPlan.planName} (Refeed)'
      ..trainingDays = currentPlan.trainingDays
      ..calories = maintenanceCals
      ..proteinG = currentPlan.proteinG
      ..carbsG = (currentPlan.carbsG + extraCarbs).clamp(0, 9999)
      ..fatG = currentPlan.fatG
      ..stepTarget = currentPlan.stepTarget
      ..phase = 'refeed'
      ..phaseStartedAt = DateTime.now()
      ..preRefeedCalories = currentPlan.calories;

    final repo = ref.read(lyvaRepoProvider);
    await repo.upsertPlan(refeedPlan);

    ref.read(analyticsProvider).logRefeedStarted(
      maintenanceCalories: maintenanceCals,
      previousCalories: currentPlan.calories,
    );

    ref.invalidate(activePlanProvider);
    ref.invalidate(plateauStatusProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refeed break started! Enjoy the extra fuel.')),
      );
    }
  }

  Future<void> _resumeDeficit(PrimePlan currentPlan) async {
    final deficitCalories = currentPlan.preRefeedCalories ?? currentPlan.calories;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.trending_down, size: 40, color: AppColors.primary),
        title: const Text('Resume Deficit?'),
        content: Text(
          'Your refeed break is complete! Ready to get back to your cut?\n\n'
          'Calories will return to $deficitCalories kcal/day.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resume Deficit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Recalculate macro split for deficit calories
    final calorieDiff = deficitCalories - currentPlan.calories;
    final carbAdjust = (calorieDiff / 4).round();

    final resumedPlan = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = currentPlan.planName.replaceAll(' (Refeed)', '')
      ..trainingDays = currentPlan.trainingDays
      ..calories = deficitCalories
      ..proteinG = currentPlan.proteinG
      ..carbsG = (currentPlan.carbsG + carbAdjust).clamp(0, 9999)
      ..fatG = currentPlan.fatG
      ..stepTarget = currentPlan.stepTarget
      ..phase = 'resumed_deficit'
      ..phaseStartedAt = DateTime.now();

    final repo = ref.read(lyvaRepoProvider);
    await repo.upsertPlan(resumedPlan);

    ref.read(analyticsProvider).logRefeedCompleted(
      refeedDurationDays: PlateauDetector.refeedDurationDays,
    );
    ref.read(analyticsProvider).logDeficitResumed(
      resumedCalories: deficitCalories,
    );

    ref.invalidate(activePlanProvider);
    ref.invalidate(plateauStatusProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deficit resumed. Let\'s keep pushing!')),
      );
    }
  }

  Future<void> _askCoach({
    required PrimePlan plan,
    required List<CheckIn> checkIns,
  }) async {
    // Track analytics
    final analytics = ref.read(analyticsProvider);
    await analytics.logAiCoachQueried(
      type: 'nutrition',
      daysSincePlanCreated: DateTime.now().difference(plan.createdAt).inDays,
    );

    setState(() {
      coachLoading = true;
      adjustment = null;
      coachError = null;
    });

    try {
      final profile = await ref.read(userProfileProvider.future);

      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateAdjustment',
      );

      final res = await callable.call({
        "plan": {
          "plan_name": plan.planName,
          "calories": plan.calories,
          "stepTarget": plan.stepTarget,
          "macros": {
            "protein_g": plan.proteinG,
            "carbs_g": plan.carbsG,
            "fat_g": plan.fatG,
          },
          "training_days": plan.trainingDays,
          "goal": profile?.goal ?? "cut",
          "phase": plan.phase,
          "phase_days": plan.phaseStartedAt != null
              ? DateTime.now().difference(plan.phaseStartedAt!).inDays
              : null,
          "pre_refeed_calories": plan.preRefeedCalories,
        },
        "trends": buildTrendPayload(checkIns),
      });

      final data = Map<String, dynamic>.from(res.data as Map);

      if (data["ok"] == true) {
        setState(() {
          adjustment = Map<String, dynamic>.from(
            data["adjustment"] as Map? ?? {},
          );
        });
      } else {
        setState(() {
          coachError = (data["raw"] ?? "Unknown error").toString();
        });
      }
    } catch (e) {
      setState(() => coachError = "Error: $e");
    } finally {
      if (mounted) setState(() => coachLoading = false);
    }
  }

  Future<void> _applyAdjustment({
    required PrimePlan current,
    required Map<String, dynamic> adj,
  }) async {
    final action = (adj["action"] ?? "hold").toString();
    if (action != "adjust") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI says: hold steady (nothing to apply).'),
        ),
      );
      return;
    }

    final calorieDelta = _n(adj["calorie_delta"], 0).round();
    final stepDelta = _n(adj["step_delta"], 0).round();

    final newCalories = (current.calories + calorieDelta).clamp(1200, 4500);
    final newStepTarget = (current.stepTarget + stepDelta).clamp(0, 50000);

    // Keep protein/fat stable, push calorie delta mostly into carbs (simple + safe)
    final deltaCarbs = (calorieDelta / 4).round();
    final newCarbs = (current.carbsG + deltaCarbs).clamp(0, 9999);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply adjustment?'),
        content: Text(
          'This will save a NEW plan version.\n\n'
          'Calories: ${current.calories} -> $newCalories '
          '(${calorieDelta >= 0 ? "+" : ""}$calorieDelta)\n'
          'Carbs: ${current.carbsG} g -> $newCarbs g\n'
          'Step target: ${current.stepTarget} -> $newStepTarget '
          '(${stepDelta >= 0 ? "+" : ""}$stepDelta)\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updated = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = '${current.planName} (Adjusted)'
      ..trainingDays = current.trainingDays
      ..calories = newCalories
      ..proteinG = current.proteinG
      ..carbsG = newCarbs
      ..fatG = current.fatG
      ..stepTarget = newStepTarget;

    final repo = ref.read(lyvaRepoProvider);
    await repo.upsertPlan(updated);

    // Track analytics
    final analytics = ref.read(analyticsProvider);
    await analytics.logAiCoachAdjustmentApplied(
      type: 'nutrition',
      action: action,
      calorieDelta: calorieDelta,
    );

    ref.invalidate(activePlanProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan updated!')));

    setState(() {
      adjustment = null;
      coachError = null;
    });
  }

  Widget _buildPhaseBanner(PrimePlan plan, AsyncValue<PlateauStatus?> plateauAsync) {
    return plateauAsync.when(
      data: (status) {
        // Refeed in progress
        if (plan.phase == 'refeed') {
          final remaining = status?.daysRemainingInRefeed ?? 0;
          final elapsed = PlateauDetector.refeedDurationDays - remaining;
          final isComplete = remaining <= 0;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isComplete
                            ? 'Refeed Break Complete!'
                            : 'Refeed Break — Day $elapsed of ${PlateauDetector.refeedDurationDays}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!isComplete) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (elapsed / PlateauDetector.refeedDurationDays).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$remaining days remaining. Eating at maintenance to reset metabolism.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ] else ...[
                  Text(
                    'Your metabolism has had time to recover. Ready to resume your deficit?',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _resumeDeficit(plan),
                      icon: const Icon(Icons.trending_down, size: 18),
                      label: const Text('Resume Deficit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Plateau detected — show alert
        if (status != null && status.isPlateaued) {
          // Log plateau detection (fire-and-forget)
          ref.read(analyticsProvider).logPlateauDetected(
            weightChangeKg: status.weightChangeKg,
            daysInDeficit: status.daysInCurrentPhase,
          );

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_flat, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Weight Plateau Detected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  status.summary,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _startRefeed(plan),
                    icon: const Icon(Icons.restaurant, size: 18),
                    label: const Text('Start Refeed Break'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.seasonAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Resumed deficit — subtle confirmation
        if (plan.phase == 'resumed_deficit' && status != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Deficit resumed — ${status.daysInCurrentPhase} days since refeed',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        // Normal deficit — no banner
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activePlanProvider);
    final checkInsAsync = ref.watch(latestCheckInsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (plan) {
            if (plan == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No plan saved yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a plan first, then it will show up here.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(context, '/plan'),
                    child: const Text('Create Plan'),
                  ),
                ],
              );
            }

            final checkIns = checkInsAsync.value ?? <CheckIn>[];
            final plateauAsync = ref.watch(plateauStatusProvider);

            final canCoach = _canAskCoach(plan);
            final daysLeft = _daysUntilCoach(plan);
            final lockText = canCoach
                ? null
                : 'Coach check-in locked. Try again in $daysLeft day${daysLeft == 1 ? "" : "s"}.';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Active Plan', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Saved on: ${plan.createdAt}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),

                // ===== DIET PHASE BANNER =====
                _buildPhaseBanner(plan, plateauAsync),

                const SizedBox(height: 12),

                Text(plan.planName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Training days: ${plan.trainingDays}/week'),
                const SizedBox(height: 8),
                Text('Step target: ${plan.stepTarget}/day'),
                const SizedBox(height: 16),

                _StatCard(title: 'Calories', value: '${plan.calories} kcal'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Protein',
                        value: '${plan.proteinG} g',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Carbs',
                        value: '${plan.carbsG} g',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(title: 'Fat', value: '${plan.fatG} g'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                AiCoachCard(
                  loading: coachLoading,
                  errorText: coachError,
                  adjustment: adjustment,
                  currentCalories: plan.calories,
                  currentStepTarget: plan.stepTarget,
                  locked: !canCoach,
                  lockText: lockText,
                  onAsk: () => _askCoach(plan: plan, checkIns: checkIns),
                  onReask: () => _askCoach(plan: plan, checkIns: checkIns),
                  onApply: adjustment == null
                      ? null
                      : () => _applyAdjustment(current: plan, adj: adjustment!),
                ),

                const Spacer(),

                // ===== UPDATED BUTTON WITH LOCK =====
                FilledButton.tonal(
                  onPressed: () => _navigateToRegenerate(plan),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_canRegeneratePlan(plan))
                        const Icon(Icons.lock_outline, size: 18),
                      if (!_canRegeneratePlan(plan))
                        const SizedBox(width: 8),
                      Text(
                        _canRegeneratePlan(plan)
                            ? 'Regenerate / Update Plan'
                            : 'Update Plan (${_daysUntilRegenerate(plan)}d lock)',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact payload: last 14 check-ins -> last7 vs prev7 averages.
/// Keeps AI stable + cheap, avoids sending raw logs.
Map<String, dynamic> buildTrendPayload(List<CheckIn> items) {
  final last14 = items.take(14).toList();
  final last7 = last14.take(7).toList();
  final prev7 = last14.skip(7).take(7).toList();

  double avg(Iterable<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  return {
    "counts": {
      "last14": last14.length,
      "last7": last7.length,
      "prev7": prev7.length,
    },
    "weight": {
      "last7_avg": avg(last7.map((c) => c.weightKg)),
      "prev7_avg": avg(prev7.map((c) => c.weightKg)),
    },
    "waist": {
      "last7_avg": avg(last7.map((c) => c.waistCm)),
      "prev7_avg": avg(prev7.map((c) => c.waistCm)),
    },
    "steps": {
      "last7_avg": avg(last7.map((c) => c.stepsToday.toDouble())),
      "prev7_avg": avg(prev7.map((c) => c.stepsToday.toDouble())),
    },
  };
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}