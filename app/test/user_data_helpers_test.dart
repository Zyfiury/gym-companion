import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';

void main() {
  test('mealsLoggedToday resets on new day', () {
    final u = UserData.defaults();
    u.mealsLoggedDate = '2000-01-01';
    u.mealsLoggedToday = ['Breakfast'];
    u.resetMealsLoggedIfNewDay();
    expect(u.mealsLoggedToday, isEmpty);
  });

  test('activeCustomWorkout returns active routine', () {
    final u = UserData.defaults();
    u.customWorkouts = [
      CustomWorkout(id: 'a', name: 'A'),
      CustomWorkout(id: 'b', name: 'B', isActive: true),
    ];
    expect(u.activeCustomWorkout?.id, 'b');
  });
}
