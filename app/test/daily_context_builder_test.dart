import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/daily_context.dart';
import 'package:gym_companion/models/workout_status.dart';

void main() {
  test('DailyContext toJson includes burn and macro fields', () {
    final ctx = DailyContext(
      date: '2026-06-11',
      goal: 'cut',
      targetCalories: 2200,
      caloriesEaten: 1767,
      caloriesRemaining: 433,
      activeCaloriesBurned: 412.4,
      netCalories: 1354.6,
      macros: {
        'protein': {'target': 150, 'eaten': 120},
        'carbs': {'target': 200, 'eaten': 180},
        'fat': {'target': 60, 'eaten': 45},
      },
      workoutToday: DailyContext.workoutTodayJson(
        name: 'Upper Push',
        status: WorkoutStatus.completed,
        completedAt: '2026-06-11T10:00:00',
        exercisesLogged: 5,
        caloriesBurned: 214,
      ),
      steps: 7421,
      stepCaloriesBurned: 198.2,
      water: 1.5,
      streak: 3,
      recentPRs: ['Bench Press 85kg'],
    );

    final json = ctx.toJson();
    expect(json['date'], '2026-06-11');
    expect(json['activeCaloriesBurned'], 412);
    expect(json['netCalories'], 1355);
    expect(json['stepCaloriesBurned'], 198);
    expect(json['workoutToday'], isNotNull);
    expect(json['workoutToday']['status'], 'completed');
    expect(json['recentPRs'], ['Bench Press 85kg']);
  });

  test('workoutTodayJson returns null for unlogged rest day', () {
    expect(
      DailyContext.workoutTodayJson(
        name: null,
        status: WorkoutStatus.planned,
        completedAt: null,
        exercisesLogged: 0,
        caloriesBurned: 0,
      ),
      isNull,
    );
  });
}
