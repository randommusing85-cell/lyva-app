import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/models/food_item.dart';
import 'package:lyva_app/models/meal_log.dart';
import 'package:lyva_app/repos/lyva_repo.dart';
import 'package:lyva_app/screens/meal_picker_screen.dart';
import 'package:lyva_app/state/providers.dart';
import 'meal_portion_test.dart' show food, legacy;

class PickerRepo extends LyvaRepo {
  List<MealLog> recent = [legacy()];
  List<FoodItem> foods = [food()];
  final List<MealLog> saved = [];
  bool failLoad = false, failSave = false;
  Completer<void>? pendingSave;
  final Map<String, Completer<List<FoodItem>>> pendingSearch = {};
  int writes = 0;
  @override
  Future<List<MealLog>> getRecentMeals({int limit = 30}) async { if (failLoad) throw StateError('offline'); return recent; }
  @override
  Future<List<FoodItem>> searchFoodItems(String query) async => pendingSearch[query]?.future ?? Future.value(foods);
  @override
  Future<void> addMealLog(MealLog meal) async {
    writes++; if (pendingSave != null) await pendingSave!.future;
    if (failSave) throw StateError('storage failed'); saved.add(meal);
  }
}
void main() {
  Future<void> render(WidgetTester tester, PickerRepo repo) async {
    await tester.pumpWidget(ProviderScope(overrides: [lyvaRepoProvider.overrideWithValue(repo)], child: MaterialApp(
      home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const MealPickerScreen())), child: const Text('Open picker')))))));
    await tester.tap(find.text('Open picker')); await tester.pumpAndSettle();
  }
  testWidgets('recent repeat exposes unknown weight, scales and saves a new record', (tester) async {
    final repo = PickerRepo(); await render(tester, repo);
    expect(find.textContaining('weight not recorded'), findsOneWidget);
    await tester.tap(find.text('Earlier meal')); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2'); await tester.pumpAndSettle();
    expect(find.textContaining('Protein 22 g'), findsOneWidget);
    await tester.tap(find.text('Log this meal')); await tester.pumpAndSettle();
    expect(repo.saved.single.mealType, 'dinner'); expect(repo.saved.single.carbsG, 50); expect(repo.recent.single.carbsG, 25);
    expect(repo.saved.single.ts.year, DateTime.now().year); expect(find.text('Open picker'), findsOneWidget);
  });
  testWidgets('saved reference, fractional preview and invalid amounts are explicit', (tester) async {
    final repo = PickerRepo(); await render(tester, repo);
    await tester.tap(find.text('Saved')); await tester.pumpAndSettle();
    expect(find.textContaining('80 g, as saved'), findsOneWidget);
    await tester.tap(find.text('Fixture food')); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0.5'); await tester.pumpAndSettle();
    expect(find.text('Estimated 62 kcal'), findsOneWidget); expect(find.textContaining('40.0 g total'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'NaN'); await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Log this meal')).onPressed, isNull);
    expect(repo.writes, 0);
  });
  testWidgets('save failure retains selection and portions for retry; pending save disables duplicate taps', (tester) async {
    final repo = PickerRepo()..failSave = true; await render(tester, repo);
    await tester.tap(find.text('Earlier meal')); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1.5'); await tester.pumpAndSettle();
    await tester.tap(find.text('Log this meal')); await tester.pumpAndSettle();
    expect(find.textContaining('Meal was not saved'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '1.5');
    repo.failSave = false; repo.pendingSave = Completer<void>();
    await tester.tap(find.text('Log this meal')); await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving…')).onPressed, isNull);
    repo.pendingSave!.complete(); await tester.pumpAndSettle();
    expect(repo.saved.length, 1); expect(repo.saved.single.proteinG, 17);
  });
  testWidgets('loading error offers retry and empty data offers manual entry', (tester) async {
    final repo = PickerRepo()..failLoad = true; await render(tester, repo);
    expect(find.text('Could not load saved meals. Try again.'), findsOneWidget);
    repo.failLoad = false; repo.recent = [];
    await tester.tap(find.text('Retry')); await tester.pumpAndSettle();
    expect(find.textContaining('No matching saved entries'), findsOneWidget);
    expect(find.text('Enter manually or scan'), findsOneWidget);
  });
  testWidgets('late search results cannot replace a newer query', (tester) async {
    final repo = PickerRepo(); await render(tester, repo);
    await tester.tap(find.text('Search')); await tester.pumpAndSettle();
    repo.pendingSearch['old'] = Completer<List<FoodItem>>(); repo.pendingSearch['new'] = Completer<List<FoodItem>>();
    await tester.enterText(find.byType(TextField), 'old'); await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'new'); await tester.pump(const Duration(milliseconds: 350));
    repo.pendingSearch['new']!.complete([food()..name = 'New result']); await tester.pumpAndSettle();
    repo.pendingSearch['old']!.complete([food()..name = 'Old result']); await tester.pumpAndSettle();
    expect(find.text('New result'), findsOneWidget); expect(find.text('Old result'), findsNothing);
    expect(repo.writes, 0);
  });
}
