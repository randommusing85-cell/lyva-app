import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/food_item.dart';
import '../models/meal_log.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/premium_gate.dart';
import 'food_scanner_screen.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(activePlanProvider);
    ref.invalidate(todayMealsStreamProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activePlanProvider);
    final mealsAsync = ref.watch(todayMealsStreamProvider);
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nutrition',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Date header
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Daily Summary Card
              planAsync.when(
                data: (plan) => mealsAsync.when(
                  data: (meals) => _DailySummaryCard(
                    plan: plan,
                    meals: meals,
                  ),
                  loading: () => const _LoadingCard(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Meals section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Meals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddMealSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Meal Log List
              mealsAsync.when(
                data: (meals) => _MealLogList(meals: meals),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              // Premium: Meal Scanner
              PremiumFeatureCard(
                feature: PremiumFeature.mealScanner,
                icon: Icons.camera_alt_outlined,
                title: 'Meal Scanner',
                description: 'Scan your meals for instant nutrition info',
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAddMealSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddMealSheet(),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Daily Summary Card showing progress toward targets
class _DailySummaryCard extends StatelessWidget {
  final dynamic plan;
  final List<MealLog> meals;

  const _DailySummaryCard({
    required this.plan,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate today's totals
    final totalProtein = meals.fold<int>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = meals.fold<int>(0, (sum, m) => sum + m.carbsG);
    final totalFat = meals.fold<int>(0, (sum, m) => sum + m.fatG);
    final totalCals = (totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9);

    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(24),
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
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No nutrition plan yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a plan to track your macros',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Plan'),
            ),
          ],
        ),
      );
    }

    final targetCals = plan.calories;
    final targetProtein = plan.proteinG;
    final targetCarbs = plan.carbsG;
    final targetFat = plan.fatG;

    final calProgress = targetCals > 0 ? (totalCals / targetCals).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          // Calorie ring and info
          Row(
            children: [
              CircularProgressRing(
                progress: calProgress,
                progressColor: AppColors.caloriesRing,
                size: 80,
                strokeWidth: 8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalCals',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$targetCals kcal',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${targetCals - totalCals} remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: totalCals > targetCals
                            ? AppColors.error
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Macros row with colored boxes
          Row(
            children: [
              Expanded(
                child: _MacroBox(
                  label: 'Protein',
                  current: totalProtein,
                  target: targetProtein,
                  color: AppColors.proteinGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroBox(
                  label: 'Carbs',
                  current: totalCarbs,
                  target: targetCarbs,
                  color: AppColors.carbsYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroBox(
                  label: 'Fat',
                  current: totalFat,
                  target: targetFat,
                  color: AppColors.fatPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _MacroBox({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${current}g',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${target}g',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// Meal Log List
class _MealLogList extends StatelessWidget {
  final List<MealLog> meals;

  const _MealLogList({required this.meals});

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No meals logged today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to log your first meal',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group by meal type
    final breakfast = meals.where((m) => m.mealType == 'breakfast').toList();
    final lunch = meals.where((m) => m.mealType == 'lunch').toList();
    final dinner = meals.where((m) => m.mealType == 'dinner').toList();
    final snacks = meals.where((m) => m.mealType == 'snack').toList();

    return Column(
      children: [
        if (breakfast.isNotEmpty) _MealSection('Breakfast', Icons.wb_sunny_outlined, breakfast),
        if (lunch.isNotEmpty) _MealSection('Lunch', Icons.lunch_dining, lunch),
        if (dinner.isNotEmpty) _MealSection('Dinner', Icons.dinner_dining, dinner),
        if (snacks.isNotEmpty) _MealSection('Snacks', Icons.fastfood_outlined, snacks),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MealLog> meals;

  const _MealSection(this.title, this.icon, this.meals);

  @override
  Widget build(BuildContext context) {
    final totalProtein = meals.fold<int>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = meals.fold<int>(0, (sum, m) => sum + m.carbsG);
    final totalFat = meals.fold<int>(0, (sum, m) => sum + m.fatG);
    final totalCals = (totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$totalCals kcal',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        ...meals.map((meal) => _MealCard(meal: meal)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MealCard extends ConsumerWidget {
  final MealLog meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEditMealSheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.description ?? 'Meal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MacroChip('P', meal.proteinG, AppColors.proteinGreen),
                          const SizedBox(width: 8),
                          _MacroChip('C', meal.carbsG, AppColors.carbsYellow),
                          const SizedBox(width: 8),
                          _MacroChip('F', meal.fatG, AppColors.fatPink),
                          const SizedBox(width: 12),
                          Text(
                            '${meal.calories} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  onPressed: () => _showMealOptions(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _MacroChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value}g',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showEditMealSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditMealSheet(meal: meal),
    );
  }

  Future<void> _showMealOptions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                ),
                title: const Text('Edit Meal'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditMealSheet(context, ref);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: AppColors.error, size: 20),
                ),
                title: const Text('Delete Meal'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete meal?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final analytics = ref.read(analyticsProvider);
      await analytics.logMealDeleted(mealType: meal.mealType);

      final repo = ref.read(primeRepoProvider);
      await repo.deleteMealLog(meal.id);
      ref.invalidate(todayMealsStreamProvider);
    }
  }
}

// Add Meal Sheet
class _AddMealSheet extends ConsumerStatefulWidget {
  const _AddMealSheet();

  @override
  ConsumerState<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<_AddMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String _mealType = 'breakfast';
  bool _saving = false;

  // Food search state
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _descCtrl.removeListener(_onDescriptionChanged);
    _descCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    _debounce?.cancel();
    final query = _descCtrl.text.trim();
    if (query.length < 2) {
      if (_searchResults.isNotEmpty) {
        setState(() => _searchResults = []);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(primeRepoProvider);
      // Search local first
      var results = await repo.searchFoodItems(query);
      if (results.isEmpty) {
        // Fall back to API
        final api = ref.read(foodApiServiceProvider);
        results = await api.searchFoods(query);
        // Cache
        for (final item in results) {
          await repo.saveFoodItem(item);
        }
      }
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('Food search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectFood(FoodItem item) {
    _descCtrl.removeListener(_onDescriptionChanged);
    _descCtrl.text = item.name;
    _descCtrl.addListener(_onDescriptionChanged);
    _proteinCtrl.text = item.proteinG.toString();
    _carbsCtrl.text = item.carbsG.toString();
    _fatCtrl.text = item.fatG.toString();
    setState(() => _searchResults = []);
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<FoodScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const FoodScannerScreen()),
    );
    if (result != null && mounted) {
      _descCtrl.removeListener(_onDescriptionChanged);
      _descCtrl.text = result.name;
      _descCtrl.addListener(_onDescriptionChanged);
      _proteinCtrl.text = result.proteinG.toString();
      _carbsCtrl.text = result.carbsG.toString();
      _fatCtrl.text = result.fatG.toString();
      setState(() => _searchResults = []);
    }
  }

  int? _tryInt(String s) => int.tryParse(s.trim());

  int get _previewCalories {
    final protein = _tryInt(_proteinCtrl.text) ?? 0;
    final carbs = _tryInt(_carbsCtrl.text) ?? 0;
    final fat = _tryInt(_fatCtrl.text) ?? 0;
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final meal = MealLog()
        ..ts = DateTime.now()
        ..mealType = _mealType
        ..proteinG = int.parse(_proteinCtrl.text.trim())
        ..carbsG = int.parse(_carbsCtrl.text.trim())
        ..fatG = int.parse(_fatCtrl.text.trim())
        ..description = _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim();

      final repo = ref.read(primeRepoProvider);
      await repo.addMealLog(meal);

      final analytics = ref.read(analyticsProvider);
      await analytics.logMealLogged(
        mealType: meal.mealType,
        proteinG: meal.proteinG,
        carbsG: meal.carbsG,
        fatG: meal.fatG,
        hasDescription: meal.description != null,
      );
      ref.invalidate(todayMealsStreamProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal logged!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Log Meal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Meal type selector
                const Text(
                  'Meal Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MealTypeChip('breakfast', 'Breakfast', Icons.wb_sunny_outlined),
                    const SizedBox(width: 8),
                    _MealTypeChip('lunch', 'Lunch', Icons.lunch_dining),
                    const SizedBox(width: 8),
                    _MealTypeChip('dinner', 'Dinner', Icons.dinner_dining),
                    const SizedBox(width: 8),
                    _MealTypeChip('snack', 'Snack', Icons.fastfood_outlined),
                  ],
                ),

                const SizedBox(height: 20),

                // Description + Scan button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Search food or describe',
                          hintText: 'e.g. Chicken rice',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _openScanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Icon(Icons.qr_code_scanner, size: 22),
                      ),
                    ),
                  ],
                ),

                // Search results dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _searchResults[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'P:${item.proteinG}g  C:${item.carbsG}g  F:${item.fatG}g  •  ${item.calories} kcal',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: item.brand != null
                              ? Text(
                                  item.brand!,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                )
                              : null,
                          onTap: () => _selectFood(item),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Macros row
                Row(
                  children: [
                    Expanded(
                      child: _MacroInput(
                        controller: _proteinCtrl,
                        label: 'Protein',
                        color: AppColors.proteinGreen,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final n = _tryInt(v ?? '');
                          if (n == null) return 'Req';
                          if (n < 0 || n > 300) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroInput(
                        controller: _carbsCtrl,
                        label: 'Carbs',
                        color: AppColors.carbsYellow,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final n = _tryInt(v ?? '');
                          if (n == null) return 'Req';
                          if (n < 0 || n > 500) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroInput(
                        controller: _fatCtrl,
                        label: 'Fat',
                        color: AppColors.fatPink,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final n = _tryInt(v ?? '');
                          if (n == null) return 'Req';
                          if (n < 0 || n > 200) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Calorie preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.caloriesRing,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_previewCalories kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Log Meal',
                            style: TextStyle(
                              fontSize: 16,
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

  Widget _MealTypeChip(String value, String label, IconData icon) {
    final isSelected = _mealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mealType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textMuted.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  final VoidCallback onChanged;
  final String? Function(String?)? validator;

  const _MacroInput({
    required this.controller,
    required this.label,
    required this.color,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
            validator: validator,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.3),
              ),
              suffixText: 'g',
              suffixStyle: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.7),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              errorStyle: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// Edit Meal Sheet
class _EditMealSheet extends ConsumerStatefulWidget {
  final MealLog meal;

  const _EditMealSheet({required this.meal});

  @override
  ConsumerState<_EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends ConsumerState<_EditMealSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;

  late String _mealType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mealType = widget.meal.mealType;
    _descCtrl = TextEditingController(text: widget.meal.description ?? '');
    _proteinCtrl = TextEditingController(text: widget.meal.proteinG.toString());
    _carbsCtrl = TextEditingController(text: widget.meal.carbsG.toString());
    _fatCtrl = TextEditingController(text: widget.meal.fatG.toString());
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  int? _tryInt(String s) => int.tryParse(s.trim());

  int get _previewCalories {
    final protein = _tryInt(_proteinCtrl.text) ?? 0;
    final carbs = _tryInt(_carbsCtrl.text) ?? 0;
    final fat = _tryInt(_fatCtrl.text) ?? 0;
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updatedMeal = MealLog()
        ..id = widget.meal.id
        ..ts = widget.meal.ts
        ..mealType = _mealType
        ..proteinG = int.parse(_proteinCtrl.text.trim())
        ..carbsG = int.parse(_carbsCtrl.text.trim())
        ..fatG = int.parse(_fatCtrl.text.trim())
        ..description = _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim();

      final repo = ref.read(primeRepoProvider);
      await repo.updateMealLog(updatedMeal);

      final analytics = ref.read(analyticsProvider);
      await analytics.logFeatureUsed(featureName: 'meal_edited');

      ref.invalidate(todayMealsStreamProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal updated!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Edit Meal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Meal type selector
                const Text(
                  'Meal Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MealTypeChip('breakfast', 'Breakfast', Icons.wb_sunny_outlined),
                    const SizedBox(width: 8),
                    _MealTypeChip('lunch', 'Lunch', Icons.lunch_dining),
                    const SizedBox(width: 8),
                    _MealTypeChip('dinner', 'Dinner', Icons.dinner_dining),
                    const SizedBox(width: 8),
                    _MealTypeChip('snack', 'Snack', Icons.fastfood_outlined),
                  ],
                ),

                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Chicken rice',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Macros row
                Row(
                  children: [
                    Expanded(
                      child: _MacroInput(
                        controller: _proteinCtrl,
                        label: 'Protein',
                        color: AppColors.proteinGreen,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final n = _tryInt(v ?? '');
                          if (n == null) return 'Req';
                          if (n < 0 || n > 300) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroInput(
                        controller: _carbsCtrl,
                        label: 'Carbs',
                        color: AppColors.carbsYellow,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final n = _tryInt(v ?? '');
                          if (n == null) return 'Req';
                          if (n < 0 || n > 500) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroInput(
                        controller: _fatCtrl,
                        label: 'Fat',
                        color: AppColors.fatPink,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final n = _tryInt(v ?? '');
                          if (n == null) return 'Req';
                          if (n < 0 || n > 200) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Calorie preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.caloriesRing,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_previewCalories kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Update button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Meal',
                            style: TextStyle(
                              fontSize: 16,
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

  Widget _MealTypeChip(String value, String label, IconData icon) {
    final isSelected = _mealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mealType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textMuted.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
