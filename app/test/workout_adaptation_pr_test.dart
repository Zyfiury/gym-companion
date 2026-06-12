import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/workout_adaptation_service.dart';

void main() {
  test('applyPrProgression bumps target weight by 2.5kg', () {
    final workouts = [
      WorkoutDay(day: 'Mon', focus: 'Push', exercises: ['Bench Press 4×8 @ 80kg']),
    ];
    final updated = WorkoutAdaptationService.applyPrProgression(workouts, [
      {'exercise': 'Bench Press', 'value': 80, 'unit': 'kg'},
    ]);
    expect(updated.first.exercises.first, contains('@ 82.5kg'));
  });

  test('applyPrProgression adds weight suffix when missing', () {
    final workouts = [
      WorkoutDay(day: 'Tue', focus: 'Pull', exercises: ['Deadlift 4×5']),
    ];
    final updated = WorkoutAdaptationService.applyPrProgression(workouts, [
      {'exercise': 'Deadlift', 'value': 140, 'unit': 'kg'},
    ]);
    expect(updated.first.exercises.first, contains('@ 142.5kg'));
  });
}
