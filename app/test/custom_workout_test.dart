import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';

void main() {
  test('custom workout round-trip JSON', () {
    final w = CustomWorkout(
      id: 'cw1',
      name: 'Push Day',
      exercises: [CustomExercise(name: 'Bench Press', sets: 4, reps: 8, restSeconds: 90)],
    );
    final u = UserData.defaults()..customWorkouts = [w];
    final decoded = UserData.fromJson(u.toJson());
    expect(decoded.customWorkouts.length, 1);
    expect(decoded.customWorkouts.first.name, 'Push Day');
    expect(decoded.customWorkouts.first.exercises.first.sets, 4);
  });
}
