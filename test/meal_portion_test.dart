import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/food_item.dart';
import 'package:lyva_app/models/meal_log.dart';
import 'package:lyva_app/models/meal_portion.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'fixtures/legacy_meal_log.dart';

FoodItem food() => FoodItem()
  ..name = 'Fixture food'
  ..servingSizeG = 80
  ..proteinG = 7
  ..carbsG = 13
  ..fatG = 3
  ..source = 'manual'
  ..addedAt = DateTime(2026);
MealLog legacy() => MealLog()
  ..ts = DateTime(2025, 1, 1)
  ..mealType = 'dinner'
  ..description = 'Earlier meal'
  ..proteinG = 11
  ..carbsG = 25
  ..fatG = 4;
void main() {
  test(
    'fractional portions scale original base once and derive consistent calories',
    () {
      final base = MealPortion.fromFood(food());
      final half = base.withPortions(0.5);
      expect([half.totalProtein, half.totalCarbs, half.totalFat], [4, 7, 2]);
      expect(half.calories, 62);
      final twice = half.withPortions(2);
      expect(
        [twice.totalProtein, twice.totalCarbs, twice.totalFat],
        [14, 26, 6],
      );
      expect(base.portions, 1);
    },
  );
  test(
    'new repeat preserves base and portion instead of compounding rounded totals',
    () {
      final original =
          MealPortion.fromFood(
              food(),
            ).withPortions(0.5).toMeal(when: DateTime(2026), mealType: 'lunch')
            ..id = 99;
      final repeat = MealPortion.fromMeal(
        original,
      ).withPortions(2).toMeal(when: DateTime(2026, 2), mealType: 'snack');
      expect(repeat.id, isNot(original.id));
      expect(repeat.proteinG, 14);
      expect(original.proteinG, 4);
      expect(MealPortion.fromMeal(original).portions, 0.5);
      expect(original.ts, DateTime(2026));
    },
  );
  test('legacy records use prior amount without inventing grams', () {
    final p = MealPortion.fromMeal(legacy());
    expect(p.grams, isNull);
    expect(p.referenceLabel, contains('previously logged amount'));
    expect(p.withPortions(2).totalCarbs, 50);
  });
  test('changed totals or malformed metadata fall back to recorded totals', () {
    final meal = MealPortion.fromFood(
      food(),
    ).toMeal(when: DateTime(2026), mealType: 'lunch')..proteinG = 20;
    expect(MealPortion.fromMeal(meal).grams, isNull);
    expect(MealPortion.fromMeal(meal).protein, 20);
    meal.portionJson = '{broken';
    expect(MealPortion.fromMeal(meal).protein, 20);
    meal.portionJson = jsonEncode({'version': 99});
    expect(MealPortion.fromMeal(meal).portions, 1);
  });
  test(
    'invalid portions and missing or negative nutrition do not become zero estimates',
    () {
      final p = MealPortion.fromFood(food());
      for (final value in [0.0, -1.0, double.nan, double.infinity, 101.0]) {
        expect(() => p.withPortions(value), throwsFormatException);
      }
      expect(
        () => MealPortion.fromFood(food()..proteinG = -1),
        throwsFormatException,
      );
      expect(
        () => p.toMeal(when: DateTime(2026), mealType: 'unknown'),
        throwsArgumentError,
      );
    },
  );
  group('isolated persisted meals', () {
    late Directory directory;
    late Isar db;
    late LyvaRepo repo;
    Future<Isar> open() => Isar.open(
      [MealLogSchema, FoodItemSchema],
      directory: directory.path,
      name: 'portions',
      inspector: false,
    );
    setUpAll(() async {
      await Isar.initializeIsarCore(
        libraries: {
          Abi.windowsX64: File(
            'vendor/isar_flutter_libs/windows/isar.dll',
          ).absolute.path,
          Abi.linuxX64: File(
            'vendor/isar_flutter_libs/linux/libisar.so',
          ).absolute.path,
          Abi.macosX64: File(
            'vendor/isar_flutter_libs/macos/libisar.dylib',
          ).absolute.path,
          Abi.macosArm64: File(
            'vendor/isar_flutter_libs/macos/libisar.dylib',
          ).absolute.path,
        },
      );
    });
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('lyva_portions_');
      db = await open();
      repo = LyvaRepo(checkPersonalization: (_) async {}, openDatabase: () async => db);
    });
    tearDown(() async {
      if (db.isOpen) await db.close(deleteFromDisk: true);
      await directory.delete(recursive: true);
    });
    test(
      'historical repeat adds a new current record, preserving old record through reopen',
      () async {
        final old = legacy();
        await repo.addMealLog(old);
        final now = DateTime.now();
        final repeat = MealPortion.fromMeal(
          old,
        ).withPortions(1.5).toMeal(when: now, mealType: 'lunch');
        await repo.addMealLog(repeat);
        await db.close();
        db = await open();
        final restored = await repo.getRecentMeals();
        expect(restored.length, 2);
        expect(restored.first.ts, now);
        expect(restored.first.proteinG, 17);
        expect(MealPortion.fromMeal(restored.first).portions, 1.5);
        expect(restored.last.id, old.id);
        expect(restored.last.ts, DateTime(2025, 1, 1));
        expect(restored.last.proteinG, 11);
        expect(restored.last.portionJson, isNull);
      },
    );
    test(
      'future meals excluded; stored food search never mutates meals',
      () async {
        await repo.addMealLog(
          legacy()..ts = DateTime.now().add(const Duration(days: 1)),
        );
        await repo.saveFoodItem(food());
        expect(await repo.getRecentMeals(), isEmpty);
        expect((await repo.searchFoodItems('fixture')).single.servingSizeG, 80);
        expect(await db.mealLogs.count(), 1);
      },
    );
    test('pre-portion schema upgrades without changing historical totals or dates', () async {
      await db.close(deleteFromDisk: true);
      final oldDb = await Isar.open([legacyMealLogSchema], directory: directory.path, name: 'portions', inspector: false);
      final old = LegacyMealLog()..ts = DateTime(2024, 5, 6, 23, 50)..mealType = 'dinner'..description = 'Historical'..proteinG = 13..carbsG = 27..fatG = 8;
      await oldDb.writeTxn(() async { await oldDb.collection<LegacyMealLog>().put(old); });
      await oldDb.close(); db = await open();
      final stored = (await db.mealLogs.get(old.id))!;
      expect(stored.ts, old.ts); expect(stored.description, 'Historical');
      expect([stored.proteinG, stored.carbsG, stored.fatG], [13, 27, 8]);
      expect(stored.portionJson, isNull); expect(MealPortion.fromMeal(stored).grams, isNull);
    });
  });
}
