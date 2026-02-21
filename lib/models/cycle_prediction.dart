import 'package:isar/isar.dart';

part 'cycle_prediction.g.dart';

@collection
class CyclePrediction {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;

  /// Predicted start date of next period
  late DateTime predictedPeriodDate;

  /// Predicted ovulation date
  late DateTime predictedOvulation;

  /// Predicted fertile window start
  late DateTime fertileWindowStart;

  /// Predicted fertile window end
  late DateTime fertileWindowEnd;

  /// Predicted cycle length for this cycle
  late int predictedCycleLength;

  /// Confidence score 0.0-1.0
  late double confidence;

  /// JSON of factors that influenced the prediction
  String? factorsJson;

  /// Whether this prediction has been verified
  bool verified = false;

  /// Actual period start date (filled when user confirms)
  DateTime? actualPeriodDate;
}
