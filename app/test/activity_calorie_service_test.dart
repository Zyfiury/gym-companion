import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/activity_calorie_service.dart';

void main() {
  test('stepsToCalories uses MET formula', () {
    // 6500 steps → 5 hours at 1300/h → MET 3.5 * 70 * 5 = 1225
    final kcal = ActivityCalorieService.stepsToCalories(6500, 70);
    expect(kcal, closeTo(1225, 1));
  });

  test('stepsToCalories returns zero for invalid input', () {
    expect(ActivityCalorieService.stepsToCalories(0, 70), 0);
    expect(ActivityCalorieService.stepsToCalories(5000, 0), 0);
  });

  test('workoutCalories uses MET and duration', () {
    // MET 5 * 80kg * 1 hour = 400
    final kcal = ActivityCalorieService.workoutCalories(met: 5, weightKg: 80, durationMinutes: 60);
    expect(kcal, 400);
  });

  test('metForExercise classifies strength and cardio', () {
    expect(ActivityCalorieService.metForExercise('Bench Press'), 5.0);
    expect(ActivityCalorieService.metForExercise('Morning Run'), 8.0);
    expect(ActivityCalorieService.metForExercise('Stretching'), 4.0);
  });

  test('estimateSessionCalories averages exercise METs', () {
    final kcal = ActivityCalorieService.estimateSessionCalories(
      exerciseNames: ['Bench Press', 'Morning Run'],
      weightKg: 75,
      durationMinutes: 60,
    );
    expect(kcal, greaterThan(300));
    expect(kcal, lessThan(700));
  });
}
