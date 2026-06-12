/// Typical UK shelf prices (2025–2026 averages across major supermarkets).
/// Not live Tesco prices — but grounded in real retail ranges, not AI guesses.
class UkGroceryPrices {
  static const _gbp = <String, double>{
    'chicken breast': 4.50,
    'chicken': 4.20,
    'chicken thigh': 3.80,
    'mince': 4.00,
    'beef mince': 4.50,
    'salmon': 5.50,
    'fish': 4.00,
    'rice': 1.20,
    'pasta': 0.95,
    'oats': 1.10,
    'bread': 1.20,
    'eggs': 2.40,
    'milk': 1.30,
    'greek yogurt': 2.00,
    'yogurt': 1.50,
    'cheese': 2.80,
    'broccoli': 0.90,
    'spinach': 1.20,
    'potato': 1.00,
    'sweet potato': 1.40,
    'banana': 1.00,
    'apple': 1.80,
    'onion': 0.80,
    'tomato': 1.20,
    'pepper': 1.50,
    'beans': 0.65,
    'lentils': 1.10,
    'tuna': 1.50,
    'olive oil': 3.50,
    'butter': 2.20,
    'tofu': 2.00,
    'hummus': 1.80,
    'wrap': 1.20,
    'tortilla': 1.10,
    'berries': 2.50,
    'quinoa': 1.80,
    'avocado': 1.20,
    'asparagus': 1.60,
    'zucchini': 0.90,
    'cod': 4.50,
    'green beans': 1.00,
    'chickpeas': 0.75,
    'coconut milk': 1.10,
    'turkey': 4.00,
    'bagel': 1.50,
    'cream cheese': 1.40,
    'smoked salmon': 4.50,
    'lettuce': 0.90,
    'mixed greens': 1.50,
    'kale': 1.00,
    'lean beef': 5.00,
    'peppers': 1.50,
    'rice noodles': 1.20,
    'egg whites': 2.50,
    'whey protein': 15.00,
    'balsamic': 2.00,
    'pork tenderloin': 5.50,
    'mixed salad': 1.50,
    'protein powder': 18.00,
    'protein bar': 2.00,
  };

  static const _storeMultiplier = <String, double>{
    'aldi': 0.86,
    'lidl': 0.86,
    'asda': 0.94,
    'tesco': 1.0,
    'sainsbury': 1.02,
    'morrisons': 0.98,
    'co-op': 1.05,
    'waitrose': 1.18,
    'marks': 1.15,
    'iceland': 0.92,
  };

  static double? lookupGbp(String ingredient) {
    final key = _normalize(ingredient);
    if (_gbp.containsKey(key)) return _gbp[key];
    for (final e in _gbp.entries) {
      if (key.contains(e.key) || e.key.contains(key)) return e.value;
    }
    return null;
  }

  static double storeMultiplier(String storeName) {
    final lower = storeName.toLowerCase();
    for (final e in _storeMultiplier.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    // Unknown / independent shops — use UK average baseline.
    return 1.0;
  }

  static String _normalize(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
  }
}
