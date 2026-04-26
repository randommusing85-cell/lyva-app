import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class FoodApiService {
  static const _baseUrl = 'https://world.openfoodfacts.org';

  /// Look up a product by barcode from Open Food Facts.
  Future<FoodItem?> lookupBarcode(String barcode) async {
    final url = Uri.parse('$_baseUrl/api/v2/product/$barcode.json');
    final response = await http.get(url, headers: {
      'User-Agent': 'LyvaApp/1.0 (Flutter)',
    });

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;

    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return _parseProduct(product, barcode: barcode);
  }

  /// Search Open Food Facts by text query.
  Future<List<FoodItem>> searchFoods(String query) async {
    final url = Uri.parse(
      '$_baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}'
      '&search_simple=1&action=process&json=1&page_size=15',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'LyvaApp/1.0 (Flutter)',
    });

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final products = json['products'] as List<dynamic>? ?? [];

    final results = <FoodItem>[];
    for (final p in products) {
      final item = _parseProduct(p as Map<String, dynamic>);
      if (item != null) results.add(item);
    }
    return results;
  }

  /// Parse an Open Food Facts product JSON into a FoodItem.
  /// Nutriments are per 100g; we store per-serving if serving size is available.
  FoodItem? _parseProduct(Map<String, dynamic> product, {String? barcode}) {
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    if (nutriments == null) return null;

    // Try per-serving first, fall back to per-100g
    final hasServing = nutriments['proteins_serving'] != null;
    final suffix = hasServing ? '_serving' : '_100g';

    final protein = _toInt(nutriments['proteins$suffix']);
    final carbs = _toInt(nutriments['carbohydrates$suffix']);
    final fat = _toInt(nutriments['fat$suffix']);

    // Skip items with no useful nutrition data
    if (protein == 0 && carbs == 0 && fat == 0) return null;

    final servingSize = hasServing
        ? _parseServingSizeG(product['serving_size']?.toString())
        : 100;

    final name = product['product_name']?.toString();
    if (name == null || name.isEmpty) return null;

    return FoodItem()
      ..name = name
      ..barcode = barcode ?? product['code']?.toString()
      ..servingSizeG = servingSize
      ..proteinG = protein
      ..carbsG = carbs
      ..fatG = fat
      ..brand = product['brands']?.toString()
      ..category = 'packaged'
      ..source = 'api'
      ..addedAt = DateTime.now();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return double.tryParse(value.toString())?.round() ?? 0;
  }

  int _parseServingSizeG(String? servingSize) {
    if (servingSize == null) return 100;
    final match = RegExp(r'(\d+)').firstMatch(servingSize);
    if (match != null) return int.tryParse(match.group(1)!) ?? 100;
    return 100;
  }
}
