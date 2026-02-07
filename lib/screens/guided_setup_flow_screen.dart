import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prime_plan.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/generating_overlay.dart';

/// Guided setup flow that walks users through:
/// 1. Creating nutrition plan
/// 2. Creating workout plan
/// Then navigates to the home screen
class GuidedSetupFlowScreen extends ConsumerStatefulWidget {
  const GuidedSetupFlowScreen({super.key});

  @override
  ConsumerState<GuidedSetupFlowScreen> createState() =>
      _GuidedSetupFlowScreenState();
}

class _GuidedSetupFlowScreenState extends ConsumerState<GuidedSetupFlowScreen> {
  int _currentStep = 0; // 0 = nutrition, 1 = workout, 2 = complete

  // Nutrition plan state
  bool _nutritionGenerated = false;
  Map<String, dynamic>? _nutritionPlanJson;

  // Workout plan state
  bool _workoutGenerated = false;
  Map<String, dynamic>? _workoutResponse;

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        automaticallyImplyLeading: false,
        actions: [
          if (_currentStep < 2)
            TextButton(
              onPressed: _skipToHome,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _StepProgressIndicator(currentStep: _currentStep),

            // Content
            Expanded(
              child: _buildStepContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1: Nutrition Plan';
      case 1:
        return 'Step 2: Workout Plan';
      case 2:
        return 'All Set!';
      default:
        return 'Setup';
    }
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _NutritionPlanStep(
          generated: _nutritionGenerated,
          planJson: _nutritionPlanJson,
          loading: _loading,
          onGenerate: _generateNutritionPlan,
          onSave: _saveNutritionPlan,
          onNext: () => setState(() => _currentStep = 1),
        );
      case 1:
        return _WorkoutPlanStep(
          generated: _workoutGenerated,
          response: _workoutResponse,
          loading: _loading,
          onGenerate: _generateWorkoutPlan,
          onSave: _saveWorkoutPlan,
          onNext: () => setState(() => _currentStep = 2),
        );
      case 2:
        return _CompletionStep(onFinish: _goToHome);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _generateNutritionPlan() async {
    setState(() => _loading = true);

    try {
      final profile = ref.read(userProfileProvider).value;
      if (profile == null) {
        throw Exception('Profile not found');
      }

      final data = await showGeneratingOverlay<Map<String, dynamic>>(
        context: context,
        title: 'Creating Your Nutrition Plan',
        subtitle: 'Our AI is crafting a personalized plan based on your goals',
        tips: [
          'Calculating your daily calorie needs...',
          'Optimizing macro ratios for ${profile.goal}...',
          'Adjusting for ${profile.trainingDaysPerWeek}x training...',
          'Personalizing step targets...',
          'Fine-tuning protein requirements...',
        ],
        task: () async {
          final callable =
              FirebaseFunctions.instance.httpsCallable('generatePlan');
          final res = await callable.call({
            "age": profile.age,
            "sex": profile.sex,
            "heightCm": profile.heightCm,
            "weightKg": profile.weightKg,
            "goal": profile.goal,
            "daysPerWeek": profile.trainingDaysPerWeek,
            "equipment": profile.equipment,
          });
          return Map<String, dynamic>.from(res.data as Map);
        },
      );

      if (data?["ok"] == true) {
        final planJson = Map<String, dynamic>.from(data!["plan"] as Map);

        final analytics = AnalyticsService();
        await analytics.logNutritionPlanGenerated(
          goal: profile.goal,
          calories: planJson['calories'] ?? 0,
          trainingDays: profile.trainingDaysPerWeek,
        );

        setState(() {
          _nutritionPlanJson = planJson;
          _nutritionGenerated = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Generation failed: ${data?["raw"] ?? "Unknown error"}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNutritionPlan() async {
    if (_nutritionPlanJson == null) return;

    num n(dynamic v, num fallback) =>
        v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;

    final macros =
        Map<String, dynamic>.from(_nutritionPlanJson!["macros"] as Map? ?? {});
    final profile = ref.read(userProfileProvider).value;

    final plan = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = (_nutritionPlanJson!["plan_name"] ?? "Prime Plan").toString()
      ..trainingDays = (_nutritionPlanJson!["training_days"] as num?)?.round() ??
          profile?.trainingDaysPerWeek ??
          4
      ..calories = n(_nutritionPlanJson!["calories"], 2000).round()
      ..proteinG = n(macros["protein_g"], 160).round()
      ..carbsG = n(macros["carbs_g"], 200).round()
      ..fatG = n(macros["fat_g"], 60).round()
      ..stepTarget = n(_nutritionPlanJson!["step_target"], 8000).round();

    final repo = ref.read(primeRepoProvider);
    await repo.upsertPlan(plan);

    final analytics = AnalyticsService();
    await analytics.logNutritionPlanSaved(
      planName: plan.planName,
      calories: plan.calories,
    );

    ref.invalidate(activePlanProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrition plan saved!'),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _generateWorkoutPlan() async {
    setState(() => _loading = true);

    try {
      final profile = ref.read(userProfileProvider).value;
      if (profile == null) {
        throw Exception('Profile not found');
      }

      final repo = ref.read(primeRepoProvider);

      final res = await showGeneratingOverlay<Map<String, dynamic>>(
        context: context,
        title: 'Creating Your Workout Plan',
        subtitle: 'Our AI is designing a personalized program for you',
        tips: [
          'Analyzing your experience level...',
          'Selecting exercises for ${profile.equipment}...',
          'Building ${profile.trainingDaysPerWeek}-day split...',
          'Optimizing volume and intensity...',
          'Adding progression protocols...',
          'Balancing muscle groups...',
        ],
        task: () async {
          return await repo.generateWorkoutTemplate(
            sex: profile.sex,
            level: profile.level,
            equipment: profile.equipment,
            daysPerWeek: profile.trainingDaysPerWeek,
            sessionDurationMin: 60,
            constraints: 'none',
          );
        },
      );

      if (res?['ok'] == true) {
        final analytics = AnalyticsService();
        await analytics.logWorkoutPlanGenerated(
          level: profile.level,
          equipment: profile.equipment,
          daysPerWeek: profile.trainingDaysPerWeek,
        );

        setState(() {
          _workoutResponse = res;
          _workoutGenerated = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Generation failed: ${res?["raw"] ?? "Unknown error"}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveWorkoutPlan() async {
    if (_workoutResponse == null) return;

    final profile = ref.read(userProfileProvider).value;
    final repo = ref.read(primeRepoProvider);

    await repo.saveWorkoutTemplateFromResponse(
      response: _workoutResponse!,
      sex: profile?.sex ?? 'male',
    );

    ref.invalidate(latestWorkoutTemplateProvider);

    final analytics = AnalyticsService();
    await analytics.logWorkoutPlanSaved(
      planName: 'Workout Plan',
      daysPerWeek: profile?.trainingDaysPerWeek ?? 4,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout plan saved!'),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() => _currentStep = 2);
    }
  }

  void _skipToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

// Progress indicator showing current step
class _StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const _StepProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _StepDot(
            label: 'Nutrition',
            isActive: currentStep == 0,
            isCompleted: currentStep > 0,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: currentStep > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          _StepDot(
            label: 'Workout',
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: currentStep > 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          _StepDot(
            label: 'Done',
            isActive: currentStep == 2,
            isCompleted: false,
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepDot({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isCompleted || isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: isCompleted
              ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive || isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// Nutrition Plan Step
class _NutritionPlanStep extends StatelessWidget {
  final bool generated;
  final Map<String, dynamic>? planJson;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onSave;
  final VoidCallback onNext;

  const _NutritionPlanStep({
    required this.generated,
    required this.planJson,
    required this.loading,
    required this.onGenerate,
    required this.onSave,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Your Nutrition Plan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Our AI will calculate your personalized calories and macros based on your goals.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Generated plan preview
          if (generated && planJson != null) ...[
            _NutritionPlanPreview(planJson: planJson!),
            const SizedBox(height: 24),
          ],

          // Action buttons
          if (!generated)
            FilledButton(
              onPressed: loading ? null : onGenerate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(loading ? 'Generating...' : 'Generate My Plan'),
              ),
            )
          else ...[
            FilledButton(
              onPressed: onSave,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save & Continue'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: loading ? null : onGenerate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(loading ? 'Generating...' : 'Regenerate'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Nutrition Plan Preview Card
class _NutritionPlanPreview extends StatelessWidget {
  final Map<String, dynamic> planJson;

  const _NutritionPlanPreview({required this.planJson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final macros = planJson['macros'] as Map? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary),
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
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Your Plan is Ready!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calories
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Daily Target',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${planJson['calories'] ?? 0} kcal',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Macros row
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: 'Protein',
                  value: '${macros['protein_g'] ?? 0}g',
                  color: AppColors.proteinGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Carbs',
                  value: '${macros['carbs_g'] ?? 0}g',
                  color: AppColors.carbsYellow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Fat',
                  value: '${macros['fat_g'] ?? 0}g',
                  color: AppColors.fatPink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Steps
          Row(
            children: [
              Icon(Icons.directions_walk, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${planJson['step_target'] ?? 8000} steps/day',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Workout Plan Step
class _WorkoutPlanStep extends StatelessWidget {
  final bool generated;
  final Map<String, dynamic>? response;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onSave;
  final VoidCallback onNext;

  const _WorkoutPlanStep({
    required this.generated,
    required this.response,
    required this.loading,
    required this.onGenerate,
    required this.onSave,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Your Workout Plan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Our AI will design a personalized training program based on your experience and equipment.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Generated plan preview
          if (generated && response != null && response!['ok'] == true) ...[
            _WorkoutPlanPreview(response: response!),
            const SizedBox(height: 24),
          ],

          // Action buttons
          if (!generated)
            FilledButton(
              onPressed: loading ? null : onGenerate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(loading ? 'Generating...' : 'Generate My Plan'),
              ),
            )
          else ...[
            FilledButton(
              onPressed: onSave,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save & Finish'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: loading ? null : onGenerate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(loading ? 'Generating...' : 'Regenerate'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Workout Plan Preview Card
class _WorkoutPlanPreview extends StatelessWidget {
  final Map<String, dynamic> response;

  const _WorkoutPlanPreview({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = response['template'] as Map?;
    final days = (template?['days'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary),
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
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Your Plan is Ready!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${days.length} training days per week',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Show each day
          ...days.take(4).map((day) {
            final dayMap = day as Map;
            final title = dayMap['title']?.toString() ?? 'Workout';
            final exercises = (dayMap['exercises'] as List?) ?? [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${exercises.length} exercises',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (days.length > 4)
            Text(
              '+${days.length - 4} more days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// Completion Step
class _CompletionStep extends StatelessWidget {
  final VoidCallback onFinish;

  const _CompletionStep({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re All Set!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your nutrition and workout plans are ready. Let\'s start your fitness journey!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remember: Consistency is key! Stick with your plan for at least 2 weeks before making changes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onFinish,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text(
              'Start Training',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Macro chip widget
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
