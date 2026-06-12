import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/meal_variety_service.dart';
import 'package:gym_companion/services/shopping_list_service.dart';

void main() {
  test('builds shopping list from all meal ingredients', () {
    final meals = MealVarietyService.generateDailyPlan(UserData.defaults());
    final list = ShoppingListService.buildFromMeals(meals, store: 'Tesco');

    final items = (list['items'] as List).map((e) => (e as Map)['item'] as String).toList();
    expect(items.length, greaterThanOrEqualTo(7));
    expect(items.any((i) => i.toLowerCase().contains('yogurt')), isTrue);
    expect(items.any((i) => i.toLowerCase().contains('chicken')), isTrue);
    expect(list['totalEstimatedCost'], isNotEmpty);
  });

  test('falls back to template ingredients when meal list is empty', () {
    final meal = Meal(
      mealType: 'Breakfast',
      name: 'Greek Yogurt Bowl',
      description: 'High protein start',
      macros: {'calories': 420, 'protein': 35, 'carbs': 45, 'fat': 10},
    );

    final ingredients = MealVarietyService.ingredientsFor(meal);
    expect(ingredients, contains('greek yogurt'));
    expect(ingredients, contains('berries'));
    expect(ingredients, contains('oats'));
  });

  test('default user plan includes full ingredient basket', () {
    final user = UserData.defaults();
    final items = user.weeklyPlan.shoppingList?['items'] as List? ?? [];
    expect(items.length, greaterThanOrEqualTo(7));
  });
}
