import 'package:isar/isar.dart';

part 'ai_insight.g.dart';

@collection
class AiInsight {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;

  /// Category: 'training_preference', 'nutrition_pattern',
  /// 'recovery_need', 'motivation_style', 'cycle_pattern'
  @Index()
  late String category;

  /// Human-readable insight text
  late String content;

  /// 0.0 to 1.0 confidence level from the AI
  late double confidence;

  /// Which coaching message generated this insight
  int? sourceMessageId;

  /// Whether user has dismissed this insight
  bool dismissed = false;
}
