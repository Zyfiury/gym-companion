import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/cheap_meal_plan_service.dart';
import 'package:gym_companion/services/meal_variety_service.dart';

void main() {
  test('monthly duration produces 28 days of meals', () {
    final user = UserData.defaults()..userId = 'test';
    final meals = <Meal>[];
    for (var d = 0; d < 28; d++) {
      meals.addAll(MealVarietyService.generateDailyPlan(user));
    }
    final monthly = MonthlyPlan(meals: meals, supermarket: 'Tesco');
    expect(monthly.meals.length, 84);
    user.monthlyPlan = monthly;
    user.weeklyPlan = WeeklyPlan(
      macros: user.weeklyPlan.macros,
      workouts: user.weeklyPlan.workouts,
      meals: monthly.meals.take(3).toList(),
      shoppingList: user.weeklyPlan.shoppingList,
    );
    expect(user.monthlyPlan!.meals.length, greaterThan(20));
    expect(user.weeklyPlan.meals.length, 3);
  });

  test('parseDuration detects monthly plans', () {
    expect(CheapMealPlanService.parseDuration('plan for 1 month'), PlanDuration.monthly);
  });
}
