import 'food_api_service.dart';

/// Shared barcode lookup (demo codes + Open Food Facts).
class BarcodeLookup {
  BarcodeLookup._();

  static const demoFoods = {
    '5012345678901': (name: 'Chicken Breast 100g', cal: 165, p: 31, c: 0, f: 4, allergens: <String>[]),
    '5000112588103': (name: 'Greek Yogurt 500g', cal: 120, p: 10, c: 8, f: 5, allergens: ['milk', 'dairy', 'yogurt']),
    '5000119000000': (name: 'Protein Bar', cal: 220, p: 20, c: 25, f: 8, allergens: ['milk', 'soy']),
  };

  static Future<Map<String, dynamic>?> lookup(String code) async {
    if (demoFoods.containsKey(code)) {
      final demo = demoFoods[code]!;
      return {
        'name': demo.name,
        'brand': '',
        'calories': demo.cal.toDouble(),
        'protein': demo.p.toDouble(),
        'carbs': demo.c.toDouble(),
        'fat': demo.f.toDouble(),
        'allergens': demo.allergens,
      };
    }
    return FoodApiService.lookupBarcode(code);
  }
}
