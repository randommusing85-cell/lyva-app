import 'package:flutter/material.dart';

import '../data/exercise_library.dart';
import '../theme/app_theme.dart';

/// Result from exercise picker: exercise name + configuration.
class ExercisePickerResult {
  final String name;
  final int sets;
  final int reps;
  final int restSeconds;

  ExercisePickerResult({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds = 60,
  });
}

/// Full-screen modal for selecting and configuring an exercise.
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Exercise'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: _showCustomExerciseDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Custom'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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
            child: _searchQuery.isNotEmpty ? _buildSearchResults() : _buildCategoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = ExerciseLibrary.search(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No exercises found for "$_searchQuery"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showCustomExerciseDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Custom Exercise'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _ExerciseTile(
          exercise: result.value,
          category: result.key,
          onTap: () => _showConfigSheet(result.value),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    final categories = ExerciseLibrary.byCategory.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isExpanded = _expandedCategories.contains(category.key);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
            children: [
              // Category header
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCategories.remove(category.key);
                    } else {
                      _expandedCategories.add(category.key);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _categoryEmoji(category.key),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${category.value.length} exercises',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise list (expanded)
              if (isExpanded)
                ...category.value.map(
                  (exercise) => _ExerciseTile(
                    exercise: exercise,
                    onTap: () => _showConfigSheet(exercise),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Chest':
        return '\u{1F4AA}'; // flexed bicep
      case 'Back':
        return '\u{1F9D7}'; // person climbing
      case 'Shoulders':
        return '\u{1F3CB}'; // person lifting weights
      case 'Legs':
        return '\u{1F9B5}'; // leg
      case 'Glutes':
        return '\u{1F351}'; // peach
      case 'Arms':
        return '\u{1F4AA}'; // flexed bicep
      case 'Core':
        return '\u{1F9D8}'; // person in lotus position
      case 'Full Body':
        return '\u{26A1}'; // lightning bolt
      default:
        return '\u{1F3CB}';
    }
  }

  void _showConfigSheet(String exerciseName) {
    int sets = 3;
    int reps = 10;
    int restSeconds = 60;

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
                // Handle
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
                  exerciseName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Sets
                _ConfigRow(
                  label: 'Sets',
                  value: sets,
                  min: 1,
                  max: 10,
                  onChanged: (v) => setSheetState(() => sets = v),
                ),
                const SizedBox(height: 16),

                // Reps
                _ConfigRow(
                  label: 'Reps',
                  value: reps,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setSheetState(() => reps = v),
                ),
                const SizedBox(height: 16),

                // Rest
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
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      onSelected: (_) =>
                          setSheetState(() => restSeconds = seconds),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx); // Close sheet
                      Navigator.pop(context, ExercisePickerResult(
                        name: exerciseName,
                        sets: sets,
                        reps: reps,
                        restSeconds: restSeconds,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Add $sets x $reps $exerciseName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomExerciseDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Exercise'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Exercise name',
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _showConfigSheet(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String exercise;
  final String? category;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.exercise,
    this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (category != null)
                    Text(
                      category!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _ConfigRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          disabledColor: AppColors.textMuted.withOpacity(0.3),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 28,
          color: AppColors.primary,
          disabledColor: AppColors.textMuted.withOpacity(0.3),
        ),
      ],
    );
  }
}
