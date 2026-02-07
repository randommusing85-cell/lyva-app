import 'package:isar/isar.dart';

part 'food_item.g.dart';

@collection
class FoodItem {
  Id id = Isar.autoIncrement;

  /// Searchable food name (e.g. "Chicken Rice", "Milo 3-in-1")
  @Index()
  late String name;

  /// EAN/UPC barcode — null for manual or OCR entries
  @Index(unique: true, replace: true)
  String? barcode;

  /// Serving size in grams
  late int servingSizeG;

  /// Macros per serving
  late int proteinG;
  late int carbsG;
  late int fatG;

  /// Optional brand name
  String? brand;

  /// Category tag: 'hawker', 'packaged', 'drink', 'snack', etc.
  String? category;

  /// How this entry was created: 'api', 'scan_ocr', 'manual'
  late String source;

  /// When this entry was added/last updated
  late DateTime addedAt;

  /// Calculated calories per serving
  int get calories => (proteinG * 4) + (carbsG * 4) + (fatG * 9);
}
