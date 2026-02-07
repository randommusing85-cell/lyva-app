import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../models/workout_template_doc.dart';

class MyWorkoutPlanScreen extends ConsumerStatefulWidget {
  const MyWorkoutPlanScreen({super.key});

  @override
  ConsumerState<MyWorkoutPlanScreen> createState() => _MyWorkoutPlanScreenState();
}

class _MyWorkoutPlanScreenState extends ConsumerState<MyWorkoutPlanScreen> {
  WorkoutTemplateDoc? _currentDoc;
  Map<String, dynamic>? _templateData;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final asyncDoc = ref.watch(latestWorkoutTemplateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout Plan'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body: asyncDoc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doc) {
          if (doc == null) {
            return const Center(child: Text('No workout plan saved yet.'));
          }

          // Initialize template data if not done yet or if doc changed
          if (_currentDoc?.id != doc.id) {
            _currentDoc = doc;
            try {
              _templateData = jsonDecode(doc.json) as Map<String, dynamic>;
            } catch (_) {
              return const Center(child: Text('Saved plan is corrupted.'));
            }
          }

          if (_templateData == null) {
            return const Center(child: Text('Saved plan is corrupted.'));
          }

          final rawDays = _templateData!['days'];
          if (rawDays is! List) {
            return const Center(child: Text('Saved plan is missing days.'));
          }

          final days = rawDays
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Plan header
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
                      doc.planName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: doc.sex),
                        _InfoChip(label: doc.level),
                        _InfoChip(label: doc.equipment.replaceAll('_', ' ')),
                        _InfoChip(label: '${doc.daysPerWeek} days/week'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Edit hint
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap an exercise to edit or swap it',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Day cards
              ...days.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final day = entry.value;
                final title = day['title']?.toString() ?? 'Day ${dayIndex + 1}';

                final rawExercises = day['exercises'];
                if (rawExercises is! List) {
                  return _DayCard(
                    title: title,
                    child: const Text('Missing exercises data'),
                  );
                }

                final exercises = rawExercises
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();

                return _DayCard(
                  title: title,
                  onAddExercise: () => _showAddExerciseDialog(dayIndex),
                  child: Column(
                    children: exercises.asMap().entries.map((exEntry) {
                      final exIndex = exEntry.key;
                      final ex = exEntry.value;

                      return _ExerciseRow(
                        exercise: ex,
                        onTap: () => _showEditExerciseDialog(
                          dayIndex: dayIndex,
                          exerciseIndex: exIndex,
                          exercise: ex,
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showAddExerciseDialog(int dayIndex) {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repMinController = TextEditingController(text: '8');
    final repMaxController = TextEditingController(text: '12');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Dumbbell Bench Press',
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: 'Working Sets',
                  hintText: 'e.g., 3',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repMinController,
                      decoration: const InputDecoration(
                        labelText: 'Min Reps',
                        hintText: 'e.g., 8',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: repMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Max Reps',
                        hintText: 'e.g., 12',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an exercise name')),
                );
                return;
              }
              _addExercise(
                dayIndex: dayIndex,
                name: name,
                sets: int.tryParse(setsController.text) ?? 3,
                repMin: int.tryParse(repMinController.text) ?? 8,
                repMax: int.tryParse(repMaxController.text) ?? 12,
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog({
    required int dayIndex,
    required int exerciseIndex,
    required Map<String, dynamic> exercise,
  }) {
    final nameController = TextEditingController(
      text: exercise['name']?.toString() ?? '',
    );
    final setsController = TextEditingController(
      text: exercise['workingSets']?.toString() ?? '3',
    );

    final repRange = exercise['repRange'];
    int? repMin;
    int? repMax;
    if (repRange is Map) {
      repMin = (repRange['min'] as num?)?.toInt();
      repMax = (repRange['max'] as num?)?.toInt();
    }

    final repMinController = TextEditingController(
      text: repMin?.toString() ?? '8',
    );
    final repMaxController = TextEditingController(
      text: repMax?.toString() ?? '12',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Dumbbell Bench Press',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: 'Working Sets',
                  hintText: 'e.g., 3',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repMinController,
                      decoration: const InputDecoration(
                        labelText: 'Min Reps',
                        hintText: 'e.g., 8',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: repMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Max Reps',
                        hintText: 'e.g., 12',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteExercise(dayIndex, exerciseIndex);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _updateExercise(
                dayIndex: dayIndex,
                exerciseIndex: exerciseIndex,
                name: nameController.text.trim(),
                sets: int.tryParse(setsController.text) ?? 3,
                repMin: int.tryParse(repMinController.text) ?? 8,
                repMax: int.tryParse(repMaxController.text) ?? 12,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addExercise({
    required int dayIndex,
    required String name,
    required int sets,
    required int repMin,
    required int repMax,
  }) {
    if (_templateData == null) return;

    setState(() {
      final days = _templateData!['days'] as List;
      final day = Map<String, dynamic>.from(days[dayIndex] as Map);
      final exercises = List<Map<String, dynamic>>.from(
        (day['exercises'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      exercises.add({
        'name': name,
        'workingSets': sets,
        'repRange': {'min': repMin, 'max': repMax},
      });

      day['exercises'] = exercises;
      days[dayIndex] = day;
      _templateData!['days'] = days;
      _hasChanges = true;
    });
  }

  void _updateExercise({
    required int dayIndex,
    required int exerciseIndex,
    required String name,
    required int sets,
    required int repMin,
    required int repMax,
  }) {
    if (_templateData == null) return;

    setState(() {
      final days = _templateData!['days'] as List;
      final day = Map<String, dynamic>.from(days[dayIndex] as Map);
      final exercises = List<Map<String, dynamic>>.from(
        (day['exercises'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      exercises[exerciseIndex] = {
        ...exercises[exerciseIndex],
        'name': name,
        'workingSets': sets,
        'repRange': {'min': repMin, 'max': repMax},
      };

      day['exercises'] = exercises;
      days[dayIndex] = day;
      _templateData!['days'] = days;
      _hasChanges = true;
    });
  }

  void _deleteExercise(int dayIndex, int exerciseIndex) {
    if (_templateData == null) return;

    setState(() {
      final days = _templateData!['days'] as List;
      final day = Map<String, dynamic>.from(days[dayIndex] as Map);
      final exercises = List<Map<String, dynamic>>.from(
        (day['exercises'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      exercises.removeAt(exerciseIndex);

      day['exercises'] = exercises;
      days[dayIndex] = day;
      _templateData!['days'] = days;
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_currentDoc == null || _templateData == null) return;

    try {
      final repo = ref.read(primeRepoProvider);
      await repo.updateWorkoutTemplateJson(
        _currentDoc!.id,
        jsonEncode(_templateData),
      );

      setState(() {
        _hasChanges = false;
      });

      ref.invalidate(latestWorkoutTemplateProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan updated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onAddExercise;

  const _DayCard({
    required this.title,
    required this.child,
    this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onAddExercise != null)
                  IconButton(
                    onPressed: onAddExercise,
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: AppColors.primary,
                    tooltip: 'Add exercise',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;

  const _ExerciseRow({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = exercise['name']?.toString() ?? 'Exercise';
    final sets = exercise['workingSets'] ?? '?';

    final repRaw = exercise['repRange'];
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
        ? '$repMin–$repMax'
        : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sets x $repText reps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
