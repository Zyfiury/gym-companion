import '../data/uk_grocery_prices.dart';
import '../models/user_data.dart';
import 'backend_config.dart';
import 'food_api_service.dart';
import 'location_service.dart';
import 'meal_variety_service.dart';
import 'places_service.dart';

enum PlanDuration { daily, weekly, monthly }

class CheapMealPlanResult {
  final List<Meal> meals;
  final Map<String, dynamic> shoppingList;
  final String supermarket;
  final String reply;
  final PlanDuration duration;
  final MonthlyPlan? monthlyPlan;

  CheapMealPlanResult({
    required this.meals,
    required this.shoppingList,
    required this.supermarket,
    required this.reply,
    required this.duration,
    this.monthlyPlan,
  });
}

class CheapMealPlanService {
  static PlanDuration? parseDuration(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'plan\s+for\s+1\s+day|plan\s+for\s+a\s+day|daily\s+meal\s+plan|1\s+day\s+plan').hasMatch(lower)) {
      return PlanDuration.daily;
    }
    if (RegExp(r'plan\s+for\s+1\s+month|plan\s+for\s+a\s+month|monthly\s+meal\s+plan|1\s+month\s+plan').hasMatch(lower)) {
      return PlanDuration.monthly;
    }
    if (RegExp(r'plan\s+for\s+1\s+week|plan\s+for\s+a\s+week|weekly\s+meal\s+plan|1\s+week\s+plan|plan\s+meals').hasMatch(lower)) {
      return PlanDuration.weekly;
    }
    return null;
  }

  static Future<CheapMealPlanResult> generate(UserData user, PlanDuration duration) async {
    if (!BackendConfig.hasGooglePlaces) {
      return CheapMealPlanResult(
        meals: const [],
        shoppingList: const {},
        supermarket: '',
        duration: duration,
        reply: '⚠️ Add GOOGLE_PLACES_API_KEY to your .env to find real supermarkets near you.\n'
            'Enable Places API in Google Cloud Console, then try again.',
      );
    }

    var location = await LocationService.getCurrentLocation();
    if (location == null) {
      final granted = await LocationService.requestPermission();
      if (granted) location = await LocationService.getCurrentLocation();
    }
    if (location == null) {
      return CheapMealPlanResult(
        meals: const [],
        shoppingList: const {},
        supermarket: '',
        duration: duration,
        reply: '📍 I need your location to find nearby supermarkets.\n'
            'Enable location permission in Settings, then try again.',
      );
    }

    final supermarkets = await PlacesService.findSupermarkets(location);
    if (supermarkets.isEmpty) {
      return CheapMealPlanResult(
        meals: const [],
        shoppingList: const {},
        supermarket: '',
        duration: duration,
        reply: '😕 No supermarkets found within 5 km of your location.',
      );
    }

    final dayCount = duration == PlanDuration.daily ? 1 : duration == PlanDuration.weekly ? 7 : 28;
    final meals = <Meal>[];
    for (var d = 0; d < dayCount; d++) {
      meals.addAll(MealVarietyService.generateDailyPlan(user));
    }

    final ingredients = <String>{};
    for (final m in meals) {
      ingredients.addAll(m.ingredients);
      if (m.ingredients.isEmpty) ingredients.add(m.name.split(' ').first.toLowerCase());
    }
    final basket = ingredients.take(12).toList();

    final storeQuotes = <Map<String, dynamic>>[];
    for (final store in supermarkets.take(4)) {
      final quote = await _priceBasketAtStore(store.name, basket);
      storeQuotes.add({'store': store.name, ...quote});
    }
    storeQuotes.sort((a, b) => (a['total'] as double).compareTo(b['total'] as double));

    var chosen = storeQuotes.first;
    final budgetCap = user.weeklyBudget * (duration == PlanDuration.monthly ? 4 : duration == PlanDuration.weekly ? 1 : 0.15);
    for (final q in storeQuotes) {
      if ((q['total'] as double) <= budgetCap) {
        chosen = q;
        break;
      }
    }

    final allVerified = (chosen['items'] as List).every((i) => i['source'] != 'estimate');
    final shoppingList = {
      'supermarket': chosen['store'],
      'totalEstimatedCost': '£${(chosen['total'] as double).toStringAsFixed(2)}',
      'items': chosen['items'],
      'estimated': !allVerified,
      'priceSource': allVerified ? 'uk_retail_averages' : 'uk_retail_averages_mixed',
    };

    final storeName = chosen['store'] as String;
    final durationLabel = duration == PlanDuration.daily ? '1 day' : duration == PlanDuration.weekly ? '1 week' : '1 month';

    MonthlyPlan? monthly;
    if (duration == PlanDuration.monthly) {
      monthly = MonthlyPlan(meals: meals, shoppingList: shoppingList, supermarket: storeName);
    }

    final priceNote = allVerified
        ? 'Priced using UK retail averages at your nearest store'
        : 'Priced using UK retail averages (some items approximate)';

    return CheapMealPlanResult(
      meals: duration == PlanDuration.daily ? meals.take(3).toList() : meals,
      shoppingList: shoppingList,
      supermarket: storeName,
      duration: duration,
      monthlyPlan: monthly,
      reply: '✅ $durationLabel meal plan from **$storeName** (nearest/cheapest option).\n'
          '$priceNote: ${shoppingList['totalEstimatedCost']}.\n'
          '${meals.take(6).map((m) => '• ${m.mealType}: ${m.name}').join('\n')}'
          '${meals.length > 6 ? '\n…and ${meals.length - 6} more meals' : ''}\n'
          'Check the Food tab for your full plan.',
    );
  }

  static Future<Map<String, dynamic>> _priceBasketAtStore(String store, List<String> basket) async {
    final multiplier = UkGroceryPrices.storeMultiplier(store);
    final items = <Map<String, dynamic>>[];
    var total = 0.0;
    var estimatedCount = 0;

    for (final ingredient in basket) {
      final offHits = await FoodApiService.searchFood(ingredient);
      final offName = offHits.isNotEmpty ? offHits.first['name'] as String? : null;
      final base = UkGroceryPrices.lookupGbp(ingredient);
      final price = (base ?? 2.20) * multiplier;
      if (base == null) estimatedCount++;

      items.add({
        'item': offName ?? ingredient,
        'quantity': '1',
        'price': '£${price.toStringAsFixed(2)}',
        'source': base != null ? 'uk_average' : 'estimate',
      });
      total += price;
    }

    return {
      'items': items,
      'total': double.parse(total.toStringAsFixed(2)),
      'estimatedCount': estimatedCount,
    };
  }
}
