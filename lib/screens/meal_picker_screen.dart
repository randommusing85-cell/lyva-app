import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_portion.dart';
import '../state/providers.dart';

/// Local-only picker. Saved/Search refer to food records already on this device.
class MealPickerScreen extends ConsumerStatefulWidget {
  const MealPickerScreen({super.key});
  @override
  ConsumerState<MealPickerScreen> createState() => _MealPickerScreenState();
}

class _MealPickerScreenState extends ConsumerState<MealPickerScreen> {
  String tab = 'Recent', query = '', mealType = 'breakfast';
  final portions = TextEditingController(text: '1');
  List<MealPortion> items = [];
  Map<MealPortion, String> recentTypes = {};
  MealPortion? selected;
  bool loading = true, saving = false;
  int generation = 0, unavailable = 0;
  String? failure;
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    generation++;
    debounce?.cancel();
    portions.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final request = ++generation;
    setState(() {
      loading = true;
      failure = null;
    });
    try {
      final repo = ref.read(lyvaRepoProvider);
      final result = <MealPortion>[];
      final types = <MealPortion, String>{};
      var invalid = 0;
      if (tab == 'Recent') {
        for (final meal in await repo.getRecentMeals()) {
          try {
            final portion = MealPortion.fromMeal(meal);
            result.add(portion);
            if ([
              'breakfast',
              'lunch',
              'dinner',
              'snack',
            ].contains(meal.mealType)) {
              types[portion] = meal.mealType;
            }
          } catch (_) {
            invalid++;
          }
        }
      } else {
        for (final food in await repo.searchFoodItems(
          tab == 'Search' ? query.trim() : '',
        )) {
          try {
            result.add(MealPortion.fromFood(food));
          } catch (_) {
            invalid++;
          }
        }
      }
      if (!mounted || request != generation) return;
      setState(() {
        items = result;
        recentTypes = types;
        unavailable = invalid;
        loading = false;
      });
    } catch (_) {
      if (!mounted || request != generation) return;
      setState(() {
        failure = 'Could not load saved meals. Try again.';
        loading = false;
      });
    }
  }

  MealPortion? get preview {
    final n = double.tryParse(portions.text.trim());
    if (selected == null || n == null) return null;
    try {
      return selected!.withPortions(n);
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    if (saving || preview == null) return;
    final meal = preview!.toMeal(when: DateTime.now(), mealType: mealType);
    setState(() {
      saving = true;
      failure = null;
    });
    try {
      await ref.read(lyvaRepoProvider).addMealLog(meal);
      if (!mounted) return;
      ref.invalidate(todayMealsStreamProvider);
      ref.invalidate(weeklyMacroTotalsProvider);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          failure =
              'Meal was not saved. Your portions are still here; try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = preview;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Log a meal')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (selected == null) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final name in ['Recent', 'Saved', 'Search'])
                    ChoiceChip(
                      label: Text(name),
                      selected: tab == name,
                      onSelected: (_) {
                        debounce?.cancel();
                        setState(() {
                          tab = name;
                        });
                        load();
                      },
                    ),
                ],
              ),
              const Text(
                'Local records only. Saved and Search show foods already stored on this device (up to 20 matches).',
              ),
              if (tab == 'Search')
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search stored foods',
                  ),
                  onChanged: (value) {
                    query = value;
                    generation++;
                    debounce?.cancel();
                    setState(() {
                      loading = true;
                    });
                    debounce = Timer(const Duration(milliseconds: 300), load);
                  },
                ),
              if (loading)
                const LinearProgressIndicator(
                  semanticsLabel: 'Loading saved meals',
                ),
              if (!loading && failure == null && items.isEmpty)
                const Text(
                  'No matching saved entries. You can enter a meal manually.',
                ),
              if (unavailable > 0 && !loading)
                Text(
                  '$unavailable entries have unusable nutrition data and were not offered.',
                ),
              if (!loading && failure == null)
                for (final item in items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.referenceLabel}\nEstimated ${item.calories} kcal for ${item.portions} portion(s)',
                    ),
                    onTap: () {
                      generation++;
                      debounce?.cancel();
                      setState(() {
                        selected = item;
                        mealType = recentTypes[item] ?? mealType;
                        portions.text = item.portions.toString();
                        failure = null;
                      });
                    },
                  ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'manual'),
                child: const Text('Enter manually or scan'),
              ),
            ] else ...[
              Text(
                selected!.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(selected!.referenceLabel),
              const Text(
                'Estimates from saved data. Check the reference amount against your food or label; portions are amounts you ate, not recommendations.',
              ),
              TextField(
                controller: portions,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Number of portions',
                  errorText: p == null
                      ? 'Enter an amount greater than 0 and at most 100.'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (p != null) ...[
                if (p.grams != null)
                  Text(
                    '${(p.grams! * p.portions).toStringAsFixed(1)} g total, from saved reference',
                  ),
                Text('Estimated ${p.calories} kcal'),
                Text(
                  'Protein ${p.totalProtein} g · Carbs ${p.totalCarbs} g · Fat ${p.totalFat} g',
                ),
                const Text(
                  'Macros are rounded to whole grams after scaling; calories are calculated from those macros.',
                ),
              ],
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: mealType,
                decoration: const InputDecoration(labelText: 'Meal'),
                items: [
                  for (final type in ['breakfast', 'lunch', 'dinner', 'snack'])
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(() {
                        mealType = value!;
                      }),
              ),
              FilledButton(
                onPressed: saving || p == null ? null : save,
                child: Text(saving ? 'Saving…' : 'Log this meal'),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        setState(() {
                          selected = null;
                          failure = null;
                        });
                        load();
                      },
                child: const Text('Choose a different entry'),
              ),
            ],
            if (failure != null) ...[
              Semantics(liveRegion: true, child: Text(failure!)),
              if (selected == null)
                TextButton(onPressed: load, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
