import 'package:isar/isar.dart';

part 'coach_message.g.dart';

@collection
class CoachMessage {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;

  /// 'user' or 'assistant'
  late String role;

  /// The message text content
  late String content;

  /// JSON-encoded snapshot of context sent with this message
  String? contextSnapshot;

  /// Whether this message is still being generated
  bool isLoading = false;
}
