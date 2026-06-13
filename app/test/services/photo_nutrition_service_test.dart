import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/photo_nutrition_service.dart';

void main() {
  test('scales portion multipliers', () {
    const base = PhotoNutritionResult(
      mealName: 'Chicken rice',
      estimatedCalories: 500,
      confidence: PhotoConfidence.medium,
      protein: 40,
      carbs: 50,
      fat: 10,
      items: [PhotoNutritionItem(name: 'Chicken', estimatedGrams: 150, calories: 300)],
    );
    final scaled = PhotoNutritionService.scale(base, 1.5);
    expect(scaled.estimatedCalories, 750);
    expect(scaled.protein, 60);
    expect(scaled.fiber, 0);
  });
}
