import 'package:dio/dio.dart';

class FoodApiService {
  static final _dio = Dio();

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
        'allergens': List<String>.from((product['allergens_tags'] as List?)?.map((e) => e.toString()) ?? []),
        'per_100g': true,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> searchFood(String query) async {
    try {
      final response = await _dio.get(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': 10,
        },
      );
      final products = response.data['products'] as List? ?? [];
      final mapped = products.map((p) {
        final n = p['nutriments'] ?? {};
        return {
          'name': p['product_name'] ?? 'Unknown',
          'brand': p['brands'] ?? '',
          'calories': (n['energy-kcal_100g'] ?? 0).toDouble(),
          'protein': (n['proteins_100g'] ?? 0).toDouble(),
          'carbs': (n['carbohydrates_100g'] ?? 0).toDouble(),
          'fat': (n['fat_100g'] ?? 0).toDouble(),
          'allergens': List<String>.from((p['allergens_tags'] as List?)?.map((e) => e.toString()) ?? []),
        };
      }).where((p) => (p['calories'] as double) > 0).toList();
      mapped.sort((a, b) => (b['protein'] as double).compareTo(a['protein'] as double));
      return mapped;
    } catch (_) {
      return [];
    }
  }
}
