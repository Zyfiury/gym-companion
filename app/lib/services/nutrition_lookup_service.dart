import '../data/uk_chain_menu.dart';
import 'allergy_guard.dart';
import 'food_api_service.dart';

enum NutritionSource { chainMenu, openFoodFacts, estimated }

class NutritionMatch {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String? priceGbp;
  final NutritionSource source;
  final String? brand;

  const NutritionMatch({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
    this.priceGbp,
    this.brand,
  });

  bool get isVerified => source == NutritionSource.chainMenu || source == NutritionSource.openFoodFacts;
}

class NutritionLookupService {
  /// Match a nearby restaurant to a published chain menu item.
  static NutritionMatch? fromChain(String restaurantName, {String goal = 'maintain'}) {
    final item = UkChainMenu.pickBestItem(restaurantName, goal: goal);
    if (item == null) return null;
    return NutritionMatch(
      name: item.name,
      calories: item.calories,
      protein: item.protein,
      carbs: item.carbs,
      fat: item.fat,
      priceGbp: item.priceGbp,
      source: NutritionSource.chainMenu,
      brand: UkChainMenu.matchRestaurant(restaurantName)?.namePatterns.first,
    );
  }

  /// Search Open Food Facts for a food name (optionally scoped to brand/chain).
  static Future<NutritionMatch?> fromOpenFoodFacts(String query, {String? brandHint}) async {
    final search = brandHint != null && brandHint.isNotEmpty ? '$brandHint $query' : query;
    final hits = await FoodApiService.searchFood(search);
    if (hits.isEmpty) return null;

    final best = hits.firstWhere(
      (h) => (h['calories'] as num? ?? 0) > 0,
      orElse: () => hits.first,
    );
    final cal100 = (best['calories'] as num?)?.toDouble() ?? 0;
    if (cal100 <= 0) return null;

    // Typical single serving ~250g for meals, 100g for snacks
    final servingG = _guessServingGrams(query);
    final factor = servingG / 100.0;

    return NutritionMatch(
      name: best['name'] as String? ?? query,
      calories: (cal100 * factor).round(),
      protein: ((best['protein'] as num? ?? 0) * factor).round(),
      carbs: ((best['carbs'] as num? ?? 0) * factor).round(),
      fat: ((best['fat'] as num? ?? 0) * factor).round(),
      source: NutritionSource.openFoodFacts,
      brand: best['brand'] as String?,
    );
  }

  /// Generic dish suggestion when chain/OFF data is missing or filtered out.
  static NutritionMatch genericSafeMeal({String goal = 'maintain', UserAllergies? prefs}) {
    final veg = prefs?.dietType == 'vegetarian' || prefs?.dietType == 'vegan';
    final name = veg
        ? 'Vegetable bowl or salad — confirm allergens with staff'
        : 'Grilled chicken or salad — confirm allergens with staff';
    final calories = switch (goal) {
      'cut' => 420,
      'bulk' => 780,
      _ => 550,
    };
    return NutritionMatch(
      name: name,
      calories: calories,
      protein: goal == 'cut' ? 38 : 32,
      carbs: 35,
      fat: 12,
      priceGbp: 'See menu',
      source: NutritionSource.estimated,
    );
  }

  /// Chain menu first, then Open Food Facts, then a generic safe estimate.
  static Future<NutritionMatch> forRestaurant({
    required String restaurantName,
    required List<String> placeTypes,
    String goal = 'maintain',
    UserAllergies? prefs,
  }) async {
    if (prefs != null) {
      final safeChain = UkChainMenu.pickBestSafeItem(restaurantName, goal: goal, prefs: prefs);
      if (safeChain != null) {
        return NutritionMatch(
          name: safeChain.name,
          calories: safeChain.calories,
          protein: safeChain.protein,
          carbs: safeChain.carbs,
          fat: safeChain.fat,
          priceGbp: safeChain.priceGbp,
          source: NutritionSource.chainMenu,
          brand: UkChainMenu.matchRestaurant(restaurantName)?.namePatterns.first,
        );
      }
    } else {
      final chain = fromChain(restaurantName, goal: goal);
      if (chain != null) return chain;
    }

    final cuisine = _primaryCuisine(placeTypes);
    final query = cuisine != null ? '$cuisine grilled chicken meal' : 'grilled chicken rice bowl';
    final off = await fromOpenFoodFacts(query, brandHint: restaurantName.split(' ').first);
    if (off != null && (prefs == null || AllergyGuard.checkText(off.name, prefs).isSafe)) {
      return off;
    }

    return genericSafeMeal(goal: goal, prefs: prefs);
  }

  static String? _primaryCuisine(List<String> types) {
    const map = {
      'indian': 'indian curry',
      'chinese': 'chinese chicken',
      'japanese': 'japanese chicken',
      'sushi': 'sushi salmon',
      'italian': 'italian pasta chicken',
      'pizza': 'pizza chicken',
      'mexican': 'mexican chicken bowl',
      'thai': 'thai chicken',
      'kebab': 'chicken kebab',
      'mediterranean': 'chicken souvlaki',
      'greek': 'chicken gyro',
      'turkish': 'chicken shish',
      'seafood': 'grilled fish',
      'burger': 'chicken burger',
      'sandwich': 'chicken sandwich',
      'fast_food': 'chicken wrap',
      'meal_takeaway': 'chicken takeaway',
    };
    for (final t in types) {
      for (final e in map.entries) {
        if (t.contains(e.key)) return e.value;
      }
    }
    return null;
  }

  static int _guessServingGrams(String query) {
    final q = query.toLowerCase();
    if (q.contains('salad') || q.contains('wrap') || q.contains('sandwich')) return 220;
    if (q.contains('pizza') || q.contains('burger') || q.contains('bowl')) return 280;
    if (q.contains('nugget') || q.contains('snack')) return 120;
    return 250;
  }
}
