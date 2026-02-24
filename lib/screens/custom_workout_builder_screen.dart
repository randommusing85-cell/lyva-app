import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../models/workout_template_doc.dart';
import '../state/providers.dart';
import '../widgets/premium_gate.dart';
import '../services/premium_service.dart';
import 'exercise_picker_screen.dart';

class CustomWorkoutBuilderScreen extends ConsumerStatefulWidget {
  const CustomWorkoutBuilderScreen({super.key});

  @override
  ConsumerState<CustomWorkoutBuilderScreen> createState() =>
      _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState
    extends ConsumerState<CustomWorkoutBuilderScreen>
    with SingleTickerProviderStateMixin {
  // Step tracking
  int _currentStep = 0; // 0=setup, 1=day builder, 2=review

  // Step 0: Setup
  final _planNameController = TextEditingController(text: 'My Custom Plan');
  int _daysPerWeek = 3;

  // Step 1: Day builder
  late TabController _tabController;
  late List<String> _dayNames;
  late List<TextEditingController> _dayNameControllers;
  late List<List<Map<String, dynamic>>> _dayExercises;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initDays();
  }

  void _initDays() {
    _dayNames = List.generate(
      _daysPerWeek,
      (i) => _defaultDayName(i),
    );
    _dayNameControllers = List.generate(
      _daysPerWeek,
      (i) => TextEditingController(text: _dayNames[i]),
    );
    _dayExercises = List.generate(_daysPerWeek, (_) => []);
    _tabController = TabController(length: _daysPerWeek, vsync: this);
  }

  void _updateDaysPerWeek(int newDays) {
    setState(() {
      _daysPerWeek = newDays;
      // Preserve existing data where possible
      while (_dayNames.length < newDays) {
        final name = _defaultDayName(_dayNames.length);
        _dayNames.add(name);
        _dayNameControllers.add(TextEditingController(text: name));
        _dayExercises.add([]);
      }
      while (_dayNames.length > newDays) {
        _dayNames.removeLast();
        _dayNameControllers.removeLast().dispose();
        _dayExercises.removeLast();
      }
      _tabController.dispose();
      _tabController = TabController(length: _daysPerWeek, vsync: this);
    });
  }

  String _defaultDayName(int index) {
    const defaults = [
      'Push', 'Pull', 'Legs', 'Upper', 'Lower', 'Full Body', 'Cardio'
    ];
    return index < defaults.length ? defaults[index] : 'Day ${index + 1}';
  }

  @override
  void dispose() {
    _planNameController.dispose();
    for (final c in _dayNameControllers) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepTitle),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
        ],
      ),
      body: PremiumGate(
        feature: PremiumFeature.customWorkouts,
        child: _buildCurrentStep(),
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'New Workout Plan';
      case 1:
        return 'Build Your Days';
      case 2:
        return 'Review & Save';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSetupStep();
      case 1:
        return _buildDayBuilderStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // =================== STEP 0: SETUP ===================

  Widget _buildSetupStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Name
          const Text(
            'Plan Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _planNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Upper/Lower Split',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Days per week
          const Text(
            'Days Per Week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How many days per week will you train?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isSelected = _daysPerWeek == day;
              return ChoiceChip(
                label: Text('$day'),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                onSelected: (_) => _updateDaysPerWeek(day),
              );
            }),
          ),

          const SizedBox(height: 48),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _planNameController.text.trim().isNotEmpty
                  ? () => setState(() => _currentStep = 1)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Next: Add Exercises',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================== STEP 1: DAY BUILDER ===================

  Widget _buildDayBuilderStep() {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: _daysPerWeek > 4,
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: List.generate(
              _daysPerWeek,
              (i) => Tab(text: 'Day ${i + 1}'),
            ),
          ),
        ),

        // Tab view
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(
              _daysPerWeek,
              (dayIndex) => _buildDayTab(dayIndex),
            ),
          ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasAnyExercises
                    ? () => setState(() => _currentStep = 2)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Review & Save',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _hasAnyExercises =>
      _dayExercises.any((day) => day.isNotEmpty);

  Widget _buildDayTab(int dayIndex) {
    final exercises = _dayExercises[dayIndex];

    return Column(
      children: [
        // Day name field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _dayNameControllers[dayIndex],
            onChanged: (v) => _dayNames[dayIndex] = v,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Day Name',
              hintText: 'e.g. Upper Body, Leg Day',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Exercise list
        Expanded(
          child: exercises.isEmpty
              ? _buildEmptyDayState(dayIndex)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exercises.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = exercises.removeAt(oldIndex);
                      exercises.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    return _ExerciseRow(
                      key: ValueKey('day${dayIndex}_ex$index'),
                      exercise: ex,
                      onEdit: () => _editExercise(dayIndex, index),
                      onDelete: () {
                        setState(() => exercises.removeAt(index));
                      },
                    );
                  },
                ),
        ),

        // Add exercise button
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _addExercise(dayIndex),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Exercise'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayState(int dayIndex) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No exercises yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Add Exercise" to get started',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise(int dayIndex) async {
    final result = await Navigator.push<ExercisePickerResult>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _dayExercises[dayIndex].add({
          'name': result.name,
          'sets': result.sets,
          'reps': '${result.reps}',
          'rest': '${result.restSeconds}s',
        });
      });
    }
  }

  void _editExercise(int dayIndex, int exIndex) {
    final ex = _dayExercises[dayIndex][exIndex];
    int sets = ex['sets'] as int? ?? 3;
    int reps = int.tryParse('${ex['reps']}') ?? 10;
    int restSeconds = int.tryParse('${ex['rest']}'.replaceAll('s', '')) ?? 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  ex['name'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildEditConfigRow('Sets', sets, 1, 10, (v) {
                  setSheetState(() => sets = v);
                }),
                const SizedBox(height: 16),
                _buildEditConfigRow('Reps', reps, 1, 50, (v) {
                  setSheetState(() => reps = v);
                }),
                const SizedBox(height: 16),
                const Text(
                  'Rest Between Sets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [30, 60, 90, 120].map((seconds) {
                    final isSelected = restSeconds == seconds;
                    return ChoiceChip(
                      label: Text('${seconds}s'),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      onSelected: (_) =>
                          setSheetState(() => restSeconds = seconds),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _dayExercises[dayIndex][exIndex] = {
                          'name': ex['name'],
                          'sets': sets,
                          'reps': '$reps',
                          'rest': '${restSeconds}s',
                        };
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditConfigRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 28,
          color: AppColors.primary,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 28,
          color: AppColors.primary,
        ),
      ],
    );
  }

  // =================== STEP 2: REVIEW ===================

  Widget _buildReviewStep() {
    final totalExercises = _dayExercises.fold<int>(
      0,
      (sum, day) => sum + day.length,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
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
                Text(
                  _planNameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ReviewChip(
                      icon: Icons.calendar_today_outlined,
                      label: '$_daysPerWeek days/week',
                    ),
                    const SizedBox(width: 12),
                    _ReviewChip(
                      icon: Icons.fitness_center_outlined,
                      label: '$totalExercises exercises',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Day breakdown
          ...List.generate(_daysPerWeek, (i) {
            final exercises = _dayExercises[i];
            if (exercises.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${i + 1}: ${_dayNames[i]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exercises.map((ex) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ex['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${ex['sets']} x ${ex['reps']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveTemplate,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving ? 'Saving...' : 'Save Workout Plan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    setState(() => _saving = true);

    try {
      // Build JSON matching the existing WorkoutTemplateDoc format
      final days = <Map<String, dynamic>>[];
      for (var i = 0; i < _daysPerWeek; i++) {
        days.add({
          'dayName': _dayNames[i],
          'exercises': _dayExercises[i],
        });
      }

      final jsonData = jsonEncode({
        'planName': _planNameController.text.trim(),
        'daysPerWeek': _daysPerWeek,
        'days': days,
      });

      final template = WorkoutTemplateDoc()
        ..createdAt = DateTime.now()
        ..planName = _planNameController.text.trim()
        ..level = 'custom'
        ..equipment = 'mixed'
        ..daysPerWeek = _daysPerWeek
        ..sex = 'any'
        ..isCustom = true
        ..json = jsonData;

      final repo = ref.read(primeRepoProvider);
      await repo.saveWorkoutTemplate(template);

      // Track analytics
      final totalExercises = _dayExercises.fold<int>(
        0,
        (sum, day) => sum + day.length,
      );
      ref.read(analyticsProvider).logCustomWorkoutCreated(
            daysPerWeek: _daysPerWeek,
            totalExercises: totalExercises,
          );

      // Invalidate providers
      ref.invalidate(latestWorkoutTemplateProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan saved!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ExerciseRow extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        title: Text(
          exercise['name'] as String,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${exercise['sets']} sets x ${exercise['reps']} reps \u2022 ${exercise['rest']} rest',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textMuted,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.error,
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
