import 'package:isar/isar.dart';
part 'local_memory.g.dart';

@collection
class MemorySpace {
  Id id = Isar.autoIncrement;
  @Index()
  late String owner;
  bool enabled = false;
  int revision = 0;
}

@collection
class MemoryEntry {
  Id id = Isar.autoIncrement;
  @Index()
  late String owner;
  late String kind; // user_statement, preference, inference
  late String text;
  late String source;
  late DateTime createdAt;
  late DateTime updatedAt;
  List<int> sourceIds = [];
}
