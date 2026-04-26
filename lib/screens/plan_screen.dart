import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prime_plan.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../widgets/generating_overlay.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  String _sex = 'male';
  String _goal = 'cut';
  int _daysPerWeek = 4;
  String _equipment = 'gym access';

  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ageCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _initializeFromProfile() {
    if (_initialized) return;

    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _ageCtrl.text = profile.age.toString();
      _heightCtrl.text = profile.heightCm.toString();
      _weightCtrl.text = profile.weightKg.toString();
      _sex = profile.sex;
      _goal = profile.goal;
      _daysPerWeek = profile.trainingDaysPerWeek;
      _equipment = profile.equipment;

      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Show generating overlay while AI works
      final data = await showGeneratingOverlay<Map<String, dynamic>>(
        context: context,
        title: 'Creating Your Nutrition Plan',
        subtitle: 'Our AI is crafting a personalized plan based on your goals',
        tips: [
          'Calculating your daily calorie needs...',
          'Optimizing macro ratios for $_goal...',
          'Adjusting for ${_daysPerWeek}x training...',
          'Personalizing step targets...',
          'Fine-tuning protein requirements...',
        ],
        task: () async {
          final callable = FirebaseFunctions.instance.httpsCallable('generatePlan');
          final res = await callable.call({
            "age": int.parse(_ageCtrl.text.trim()),
            "sex": _sex,
            "heightCm": int.parse(_heightCtrl.text.trim()),
            "weightKg": double.parse(_weightCtrl.text.trim()),
            "goal": _goal,
            "daysPerWeek": _daysPerWeek,
            "equipment": _equipment,
          });
          return Map<String, dynamic>.from(res.data as Map);
        },
      );

      setState(() => _loading = false);

      if (data?["ok"] == true) {
        final planJson = Map<String, dynamic>.from(data!["plan"] as Map);

        // Track analytics
        final analytics = AnalyticsService();
        await analytics.logNutritionPlanGenerated(
          goal: _goal,
          calories: planJson['calories'] ?? 0,
          trainingDays: _daysPerWeek,
        );

        // Show plan in popup dialog
        if (mounted) {
          final shouldSave = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _PlanPreviewDialog(planJson: planJson),
          );

          if (shouldSave == true) {
            await _savePlan(planJson);
          }
        }
      } else {
        // Show error
        final raw = (data?["raw"] ?? "Unknown error").toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generation failed: $raw')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _savePlan(Map<String, dynamic> planJson) async {
    num n(dynamic v, num fallback) =>
        v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;

    final macros = Map<String, dynamic>.from(planJson["macros"] as Map? ?? {});

    final plan = PrimePlan()
      ..createdAt = DateTime.now()
      ..planName = (planJson["plan_name"] ?? "Prime Plan").toString()
      ..trainingDays = (planJson["training_days"] as num?)?.round() ?? _daysPerWeek
      ..calories = n(planJson["calories"], 2000).round()
      ..proteinG = n(macros["protein_g"], 160).round()
      ..carbsG = n(macros["carbs_g"], 200).round()
      ..fatG = n(macros["fat_g"], 60).round()
      ..stepTarget = n(planJson["step_target"], 8000).round();

    final repo = ref.read(lyvaRepoProvider);
    await repo.upsertPlan(plan);

    // Track analytics
    final analytics = AnalyticsService();
    await analytics.logNutritionPlanSaved(
      planName: plan.planName,
      calories: plan.calories,
    );

    ref.invalidate(activePlanProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan saved! ✅')),
    );
    Navigator.pop(context); // Go back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _initializeFromProfile();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Nutrition Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Generate your plan with AI',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your profile and goals',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _sex = v ?? 'male'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: const [
                  DropdownMenuItem(value: 'cut', child: Text('Fat Loss')),
                  DropdownMenuItem(
                    value: 'recomp',
                    child: Text('Recomposition'),
                  ),
                  DropdownMenuItem(
                    value: 'bulk',
                    child: Text('Muscle Gain'),
                  ),
                ],
                onChanged: (v) => setState(() => _goal = v ?? 'cut'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _daysPerWeek,
                decoration: const InputDecoration(
                  labelText: 'Training days / week',
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 6, child: Text('6')),
                ],
                onChanged: (v) => setState(() => _daysPerWeek = v ?? 4),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _equipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                onChanged: (v) => _equipment = v,
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _generatePlan,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _loading ? 'Generating...' : 'Generate with AI',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Plan Preview Dialog (Popup)
class _PlanPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> planJson;

  const _PlanPreviewDialog({required this.planJson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your Plan is Ready!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Name
                    Text(
                      planJson['plan_name']?.toString() ?? 'Your Plan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Training ${planJson['training_days'] ?? '?'} days per week',
                      style: theme.textTheme.bodyMedium,
                    ),
                    
                    const SizedBox(height: 20),

                    // Daily Calories (Big)
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
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Macros
                    Text(
                      'Macros',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _MacroChip(
                            label: 'Protein',
                            value: '${planJson['macros']?['protein_g'] ?? 0}g',
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroChip(
                            label: 'Carbs',
                            value: '${planJson['macros']?['carbs_g'] ?? 0}g',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroChip(
                            label: 'Fat',
                            value: '${planJson['macros']?['fat_g'] ?? 0}g',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Steps
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Step Target',
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${planJson['step_target'] ?? 8000} steps',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Save This Plan'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Regenerate'),
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
        border: Border.all(color: color.withOpacity(0.3)),
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