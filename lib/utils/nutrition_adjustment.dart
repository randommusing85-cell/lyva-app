import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/prime_plan.dart';

/// Creates a new target version without transitioning the diet phase.
/// Refeed timing and the eventual resume target belong to explicit phase actions.
PrimePlan adjustedNutritionPlan({
  required PrimePlan current,
  required int calorieDelta,
  required int stepDelta,
  required DateTime createdAt,
}) {
  final calories = calorieDelta == 0
      ? current.calories
      : (current.calories + calorieDelta).clamp(1200, 4500);
  final appliedCalories = calories - current.calories;
  return PrimePlan()
    ..createdAt = createdAt
    ..planName = '${current.planName} (Adjusted)'
    ..trainingDays = current.trainingDays
    ..calories = calories
    ..proteinG = current.proteinG
    ..carbsG = appliedCalories == 0
        ? current.carbsG
        : (current.carbsG + (appliedCalories / 4).round()).clamp(0, 9999)
    ..fatG = current.fatG
    ..stepTarget = stepDelta == 0
        ? current.stepTarget
        : (current.stepTarget + stepDelta).clamp(0, 50000)
    ..phase = current.phase
    ..phaseStartedAt = current.phaseStartedAt
    ..preRefeedCalories = current.preRefeedCalories;
}

/// Identifies every stored field used to review and apply a nutrition change.
String nutritionPlanRevision(PrimePlan p) => sha256
    .convert(
      utf8.encode(
        jsonEncode([
          p.id,
          p.createdAt.toUtc().toIso8601String(),
          p.planName,
          p.trainingDays,
          p.calories,
          p.proteinG,
          p.carbsG,
          p.fatG,
          p.stepTarget,
          p.phase,
          p.phaseStartedAt?.toUtc().toIso8601String(),
          p.preRefeedCalories,
        ]),
      ),
    )
    .toString();
