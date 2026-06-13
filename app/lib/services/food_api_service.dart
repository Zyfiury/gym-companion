import 'package:dio/dio.dart';

import '../data/common_foods_database.dart';

class FoodApiService {
  static final _dio = Dio();

  /// Unified search: curated common foods first, then Open Food Facts.
  static Future<List<Map<String, dynamic>>> searchFood(String query) async {
    final common = CommonFoodsDatabase.search(query);
    final off = await _searchOpenFoodFacts(query);
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final item in [...common, ...off]) {
      final key = '${item['name']}'.toLowerCase();
      if (seen.add(key)) merged.add(item);
    }
    return merged.take(20).toList();
  }

  static Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    try {
      final response = await _dio.get('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      if (response.data['status'] != 1) return null;
      final product = response.data['product'];
      final nutriments = product['nutriments'] ?? {};
      return {
        'name': product['product_name'] ?? 'Unknown Product',
        'brand': product['brands'] ?? '',
        'imageUrl': product['image_front_url'] as String?,
        'calories': (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
        'protein': (nutriments['proteins_100g'] ?? 0).toDouble(),
        'carbs': (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
        'fat': (nutriments['fat_100g'] ?? 0).toDouble(),
        'fiber': (nutriments['fiber_100g'] ?? 0).toDouble(),
        'sugar': (nutriments['sugars_100g'] ?? 0).toDouble(),
        'sodiumMg': ((nutriments['sodium_100g'] ?? 0) as num).toDouble() * 1000,
        'allergens': List<String>.from((product['allergens_tags'] as List?)?.map((e) => e.toString()) ?? []),
        'per_100g': true,
        'verified': true,
        'source': 'open_food_facts',
        'barcode': barcode,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _searchOpenFoodFacts(String query) async {
    try {
      final response = await _dio.get(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': 15,
        },
      );
      final products = response.data['products'] as List? ?? [];
      final mapped = products.map((p) {
        final n = p['nutriments'] ?? {};
        return {
          'name': p['product_name'] ?? 'Unknown',
          'brand': p['brands'] ?? '',
          'imageUrl': p['image_front_url'] as String?,
          'calories': (n['energy-kcal_100g'] ?? 0).toDouble(),
          'protein': (n['proteins_100g'] ?? 0).toDouble(),
          'carbs': (n['carbohydrates_100g'] ?? 0).toDouble(),
          'fat': (n['fat_100g'] ?? 0).toDouble(),
          'fiber': (n['fiber_100g'] ?? 0).toDouble(),
          'sugar': (n['sugars_100g'] ?? 0).toDouble(),
          'sodiumMg': ((n['sodium_100g'] ?? 0) as num).toDouble() * 1000,
          'allergens': List<String>.from((p['allergens_tags'] as List?)?.map((e) => e.toString()) ?? []),
          'per_100g': true,
          'verified': true,
          'source': 'open_food_facts',
        };
      }).where((p) => (p['calories'] as double) > 0).toList();
      mapped.sort((a, b) => (b['protein'] as double).compareTo(a['protein'] as double));
      return mapped;
    } catch (_) {
      return [];
    }
  }
}
