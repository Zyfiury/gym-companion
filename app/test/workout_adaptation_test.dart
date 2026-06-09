import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/workout_adaptation_service.dart';

void main() {
  test('knee injury substitutes squats', () {
    final user = UserData.defaults()..disabilities = ['knee_injury'];
    final plan = WorkoutAdaptationService.buildWeeklyPlan(user);
    final tue = plan.workouts.where((w) => w.day == 'Tue').first;
    expect(tue.exercises.any((e) => e.contains('Leg Press') || e.contains('Step-ups')), isTrue);
    expect(plan.adaptations.any((a) => a.contains('knee') || a.contains('Squat')), isTrue);
  });

  test('pregnancy removes heavy deadlifts', () {
    final user = UserData.defaults()..pregnant = true;
    final plan = WorkoutAdaptationService.buildWeeklyPlan(user);
    final fri = plan.workouts.where((w) => w.day == 'Fri').first;
    expect(fri.exercises.any((e) => e.toLowerCase().contains('deadlift 4×5')), isFalse);
  });

  test('wheelchair user gets seated plan without leg press or bench press', () {
    final user = UserData.defaults()..disabilities = ['wheelchair'];
    final plan = WorkoutAdaptationService.buildWeeklyPlan(user);
    final allExercises = plan.workouts.expand((w) => w.exercises).join(' ').toLowerCase();
    expect(allExercises.contains('leg press'), isFalse);
    expect(allExercises.contains('bench press'), isFalse);
    expect(allExercises.contains('deadlift'), isFalse);
    expect(allExercises.contains('seated cable row'), isTrue);
    expect(plan.adaptations.any((a) => a.toLowerCase().contains('seated')), isTrue);
  });

  test('planContainsBlockedExercises detects stale wheelchair plans', () {
    final user = UserData.defaults()..disabilities = ['wheelchair'];
    expect(WorkoutAdaptationService.planContainsBlockedExercises(user), isTrue);
    final plan = WorkoutAdaptationService.buildWeeklyPlan(user);
    user.weeklyPlan = WeeklyPlan(
      macros: user.weeklyPlan.macros,
      workouts: plan.workouts,
      meals: user.weeklyPlan.meals,
    );
    expect(WorkoutAdaptationService.planContainsBlockedExercises(user), isFalse);
  });
}
