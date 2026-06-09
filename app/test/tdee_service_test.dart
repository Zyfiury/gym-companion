import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/tdee_service.dart';

void main() {
  test('Mifflin-St Jeor TDEE for male 70kg 175cm age 30', () {
    final bmr = TdeeService.calculateBmr(weightKg: 70, heightCm: 175, age: 30, genderAtBirth: 'male');
    expect(bmr, greaterThan(1500));
    expect(bmr, lessThan(2000));
    final tdee = TdeeService.calculateTdee(weightKg: 70, heightCm: 175, age: 30, genderAtBirth: 'male');
    expect(tdee, greaterThan(bmr));
  });

  test('goal offset cut reduces calories', () {
    expect(TdeeService.applyGoalOffset(2200, 'cut'), 1700);
    expect(TdeeService.applyGoalOffset(2200, 'bulk'), 2500);
  });

  test('plan applies Mifflin-St Jeor then goal offset', () {
    final plan = TdeeService.plan(
      weightKg: 70,
      heightCm: 175,
      age: 30,
      goal: 'cut',
      genderAtBirth: 'male',
    );
    expect(plan.maintenance, greaterThan(1800));
    expect(plan.maintenance, lessThan(2400));
    expect(plan.target, plan.maintenance - 500);
    expect(plan.target, lessThan(plan.maintenance));
  });

  test('female BMR is lower than male at same stats', () {
    final male = TdeeService.calculateTdee(
      weightKg: 70,
      heightCm: 175,
      age: 30,
      genderAtBirth: 'male',
    );
    final female = TdeeService.calculateTdee(
      weightKg: 70,
      heightCm: 175,
      age: 30,
      genderAtBirth: 'female',
    );
    expect(female, lessThan(male));
    expect(male - female, greaterThan(100));
  });

  test('macros derived from weight', () {
    final m = TdeeService.deriveMacros(calories: 2000, weightKg: 75);
    expect(m['protein'], 150);
    expect(m['calories'], 2000);
    expect(m['carbs']!, greaterThan(0));
  });
}
