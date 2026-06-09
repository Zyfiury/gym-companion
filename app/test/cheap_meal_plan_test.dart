import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/cheap_meal_plan_service.dart';

void main() {
  test('parseDuration detects day week month', () {
    expect(CheapMealPlanService.parseDuration('plan for 1 day'), PlanDuration.daily);
    expect(CheapMealPlanService.parseDuration('Plan for 1 week please'), PlanDuration.weekly);
    expect(CheapMealPlanService.parseDuration('monthly meal plan'), PlanDuration.monthly);
    expect(CheapMealPlanService.parseDuration('hello'), isNull);
  });
}
