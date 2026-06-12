import '../data/uk_grocery_prices.dart';
import '../models/user_data.dart';
import 'meal_variety_service.dart';
import 'store_service.dart';

/// Builds a priced shopping basket from planned meals and their ingredients.
class ShoppingListService {
  static Map<String, dynamic> buildFromMeals(
    List<Meal> meals, {
    String? store,
  }) {
    final storeName = store ?? StoreService.defaultLabel;
    final ingredients = <String>{};
    for (final meal in meals) {
      ingredients.addAll(MealVarietyService.ingredientsFor(meal));
    }

    final sorted = ingredients.toList()..sort();
    final multiplier = UkGroceryPrices.storeMultiplier(storeName);
    final items = <Map<String, dynamic>>[];
    var total = 0.0;
    var estimatedCount = 0;

    for (final ingredient in sorted) {
      final base = UkGroceryPrices.lookupGbp(ingredient);
      final price = (base ?? 2.20) * multiplier;
      if (base == null) estimatedCount++;

      items.add({
        'item': _displayName(ingredient),
        'quantity': '1',
        'price': '£${price.toStringAsFixed(2)}',
        'source': base != null ? 'uk_average' : 'estimate',
      });
      total += price;
    }

    final allVerified = estimatedCount == 0;
    return {
      'supermarket': storeName,
      'totalEstimatedCost': '£${total.toStringAsFixed(2)}',
      'total': double.parse(total.toStringAsFixed(2)),
      'items': items,
      'estimated': !allVerified,
      'priceSource': allVerified ? 'uk_retail_averages' : 'uk_retail_averages_mixed',
      'ingredientCount': items.length,
    };
  }

  static Map<String, dynamic> refreshForUser(UserData user) {
    return buildFromMeals(user.weeklyPlan.meals, store: StoreService.resolveStoreName(user));
  }

  static String _displayName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Item';
    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
}
