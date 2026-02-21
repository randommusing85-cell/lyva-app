import 'package:isar/isar.dart';

part 'progress_photo.g.dart';

@collection
class ProgressPhoto {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime ts;

  /// File path to the stored image on device
  late String imagePath;

  /// Optional tag: 'front', 'side', 'back'
  String? pose;

  /// JSON string of AI analysis results
  String? analysisJson;

  /// Whether analysis has been requested
  bool analysisRequested = false;

  /// Whether analysis is complete
  bool analysisComplete = false;

  /// Optional user notes
  String? notes;
}
