import 'package:isar/isar.dart';

part 'prime_plan.g.dart';

@collection
class PrimePlan {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime createdAt;

  late String planName;
  late int trainingDays;

  late int calories;
  late int proteinG;
  late int carbsG;
  late int fatG;

  late int stepTarget;

  // ===== DIET PHASE TRACKING =====

  /// Diet phase: 'deficit', 'refeed', 'resumed_deficit'
  /// Defaults to 'deficit' for backward compatibility with existing plans
  String phase = 'deficit';

  /// When this phase started (for tracking duration)
  DateTime? phaseStartedAt;

  /// Calories at deficit before entering refeed (to restore after refeed ends)
  int? preRefeedCalories;
}
