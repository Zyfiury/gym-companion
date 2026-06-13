import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';

void main() {
  test('mealsLoggedToday resets on new day', () {
    final u = UserData.defaults();
    u.mealsLoggedDate = '2000-01-01';
    u.mealsLoggedToday = ['Breakfast'];
    expect(u.resetMealsLoggedIfNewDay(), isTrue);
    expect(u.mealsLoggedToday, isEmpty);
  });

  test('daily macros, food log and water reset on new day', () {
    final u = UserData.defaults();
    u.dailyLogDate = '2000-01-01';
    u.dailyMacrosLogged = MacroLog(calories: 1200, protein: 90, carbs: 100, fat: 40);
    u.foodLog = [
      {'food': 'Chicken rice', 'calories': 700, 'protein': 45},
    ];
    u.water = 1500;

    expect(u.resetDailyLogIfNewDay(), isTrue);

    expect(u.dailyMacrosLogged.calories, 0);
    expect(u.dailyMacrosLogged.protein, 0);
    expect(u.dailyMacrosLogged.carbs, 0);
    expect(u.dailyMacrosLogged.fat, 0);
    expect(u.foodLog, isEmpty);
    expect(u.water, 0);
    expect(u.steps, 0);
  });

  test('daily macro reset is a no-op for same day', () {
    final u = UserData.defaults();
    u.dailyLogDate = DateTime.now().toIso8601String().substring(0, 10);
    u.dailyMacrosLogged = MacroLog(calories: 500, protein: 30);

    expect(u.resetDailyLogIfNewDay(), isFalse);
    expect(u.dailyMacrosLogged.calories, 500);
    expect(u.dailyMacrosLogged.protein, 30);
  });

  test('activeCustomWorkout returns active routine', () {
    final u = UserData.defaults();
    u.customWorkouts = [
      CustomWorkout(id: 'a', name: 'A'),
      CustomWorkout(id: 'b', name: 'B', isActive: true),
    ];
    expect(u.activeCustomWorkout?.id, 'b');
  });

  test('custom workout completedToday clears on new day', () {
    final u = UserData.defaults();
    u.dailyLogDate = '2000-01-01';
    u.customWorkouts = [
      CustomWorkout(id: 'a', name: 'A', isActive: true, completedToday: ['Squat']),
    ];
    expect(u.resetDailyLogIfNewDay(), isTrue);
    expect(u.customWorkouts.first.completedToday, isEmpty);
  });

  test('daily log archives yesterday before reset', () {
    final u = UserData.defaults();
    u.dailyLogDate = '2000-01-01';
    u.dailyMacrosLogged = MacroLog(calories: 800, protein: 60);
    u.resetDailyLogIfNewDay(activitySnapshot: {'workout_status': 'completed'});
    expect(u.dailyLogArchive.length, 1);
    expect(u.dailyLogArchive.first['date'], '2000-01-01');
    expect(u.dailyLogArchive.first['calories_logged'], 800);
    expect(u.dailyLogArchive.first['workout_status'], 'completed');
  });
}
