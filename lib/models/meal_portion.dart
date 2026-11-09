import 'dart:convert';
import 'food_item.dart';
import 'meal_log.dart';

/// Frozen reference amount; calculations always scale this base, never rounded totals.
class MealPortion {
  final String name;
  final int protein, carbs, fat;
  final int? grams;
  final double portions;
  final String basis;
  MealPortion({
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.grams,
    this.portions = 1,
    required this.basis,
  }) {
    if (name.trim().isEmpty ||
        [protein, carbs, fat].any((v) => v < 0 || v > 10000) ||
        (grams != null && (grams! <= 0 || grams! > 100000)) ||
        !portions.isFinite ||
        portions <= 0 ||
        portions > 100) {
      throw const FormatException('Invalid reference amount or portions');
    }
  }
  factory MealPortion.fromFood(FoodItem food) => MealPortion(
    name: food.name,
    protein: food.proteinG,
    carbs: food.carbsG,
    fat: food.fatG,
    grams: food.servingSizeG > 0 ? food.servingSizeG : null,
    basis: 'stored food',
  );
  factory MealPortion.fromMeal(MealLog meal) {
    if (meal.portionJson != null) {
      try {
        final d = jsonDecode(meal.portionJson!);
        if (d['version'] != 1) {
          throw const FormatException('Unknown portion version');
        }
        final p = MealPortion(
          name: meal.description ?? 'Meal',
          protein: d['protein'],
          carbs: d['carbs'],
          fat: d['fat'],
          grams: d['grams'],
          portions: (d['portions'] as num).toDouble(),
          basis: d['basis'],
        );
        if (p.totalProtein == meal.proteinG &&
            p.totalCarbs == meal.carbsG &&
            p.totalFat == meal.fatG) {
          return p;
        }
      } catch (_) {
        /* Preserve legacy totals; never guess their reference weight. */
      }
    }
    return MealPortion(
      name: meal.description?.trim().isNotEmpty == true
          ? meal.description!
          : 'Meal',
      protein: meal.proteinG,
      carbs: meal.carbsG,
      fat: meal.fatG,
      basis: 'previously logged amount',
    );
  }
  static String describeMeal(MealLog meal) {
    try {
      final p = MealPortion.fromMeal(meal);
      return '${p.portions} portion(s) · ${p.referenceLabel}';
    } catch (_) {
      return 'Serving basis unavailable';
    }
  }

  MealPortion withPortions(double value) => MealPortion(
    name: name,
    protein: protein,
    carbs: carbs,
    fat: fat,
    grams: grams,
    portions: value,
    basis: basis,
  );
  int get totalProtein => (protein * portions).round();
  int get totalCarbs => (carbs * portions).round();
  int get totalFat => (fat * portions).round();
  int get calories => totalProtein * 4 + totalCarbs * 4 + totalFat * 9;
  String get referenceLabel => grams == null
      ? '1 portion = $basis (weight not recorded)'
      : '1 portion = $grams g, as saved';
  String get json => jsonEncode({
    'version': 1,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'grams': grams,
    'portions': portions,
    'basis': basis,
  });
  MealLog toMeal({required DateTime when, required String mealType}) {
    if (!['breakfast', 'lunch', 'dinner', 'snack'].contains(mealType)) {
      throw ArgumentError('Invalid meal type');
    }
    return MealLog()
      ..ts = when
      ..mealType = mealType
      ..description = name
      ..proteinG = totalProtein
      ..carbsG = totalCarbs
      ..fatG = totalFat
      ..portionJson = json;
  }
}
