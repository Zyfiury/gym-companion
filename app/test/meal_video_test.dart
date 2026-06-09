import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/meal_variety_service.dart';

void main() {
  test('meals include cooking steps', () {
    final user = UserData.defaults();
    final meal = MealVarietyService.pickMeal('Lunch', user);
    expect(meal.steps.length, greaterThanOrEqualTo(3));
    expect(meal.steps.last, contains('serving'));
  });

  test('nutrition score is within range', () {
    final score = MealVarietyService.nutritionScore({'calories': 500, 'protein': 40});
    expect(score, inInclusiveRange(40, 99));
  });

  test('enrichWithVideo returns meal unchanged without API', () async {
    final meal = Meal(mealType: 'Lunch', name: 'Test Bowl', description: 'Test', macros: {'calories': 400, 'protein': 30, 'carbs': 40, 'fat': 10});
    final enriched = await MealVarietyService.enrichWithVideo(meal);
    expect(enriched.name, 'Test Bowl');
  });
}
