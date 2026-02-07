import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/food_item.dart';

/// Parses nutrition information from a photo of a nutrition label using OCR.
class FoodScannerService {
  final _textRecognizer = TextRecognizer();

  /// Run OCR on an image file and attempt to extract macros.
  /// Returns a partially-filled FoodItem, or null if parsing fails.
  Future<FoodItem?> scanNutritionLabel(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _textRecognizer.processImage(inputImage);
    final text = recognized.text;

    if (text.isEmpty) return null;

    final protein = _extractMacro(text, [
      r'protein[s]?\s*[:\-]?\s*(\d+\.?\d*)\s*g',
      r'(\d+\.?\d*)\s*g\s*protein',
    ]);
    final carbs = _extractMacro(text, [
      r'carbohydrate[s]?\s*[:\-]?\s*(\d+\.?\d*)\s*g',
      r'total\s+carb[s]?\s*[:\-]?\s*(\d+\.?\d*)\s*g',
      r'carbs?\s*[:\-]?\s*(\d+\.?\d*)\s*g',
      r'(\d+\.?\d*)\s*g\s*carb',
    ]);
    final fat = _extractMacro(text, [
      r'total\s+fat\s*[:\-]?\s*(\d+\.?\d*)\s*g',
      r'fat\s*[:\-]?\s*(\d+\.?\d*)\s*g',
      r'(\d+\.?\d*)\s*g\s*fat',
    ]);
    final servingSize = _extractMacro(text, [
      r'serving\s+size\s*[:\-]?\s*(\d+)\s*g',
      r'per\s+(\d+)\s*g',
    ]);

    // Need at least one macro to be useful
    if (protein == null && carbs == null && fat == null) return null;

    return FoodItem()
      ..name = 'Scanned Item'
      ..servingSizeG = servingSize ?? 100
      ..proteinG = protein ?? 0
      ..carbsG = carbs ?? 0
      ..fatG = fat ?? 0
      ..source = 'scan_ocr'
      ..addedAt = DateTime.now();
  }

  /// Try multiple regex patterns (case-insensitive) and return the first match.
  int? _extractMacro(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1)!)?.round();
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
