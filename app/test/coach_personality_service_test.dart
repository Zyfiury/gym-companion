import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/models/workout_status.dart';
import 'package:gym_companion/providers/app_state.dart';
import 'package:gym_companion/services/coach_personality_service.dart';

void main() {
  test('daily opener uses first name and workout context', () {
    final state = AppState()
      ..user = (UserData.defaults()
        ..profileComplete = true
        ..goal = 'cut'
        ..tdee = 2100
        ..weeklyPlan = WeeklyPlan(
          macros: {'calories': 2100, 'protein': 140, 'carbs': 200, 'fat': 60},
          workouts: [
            WorkoutDay(day: 'Fri', focus: 'Pull', exercises: ['Pull-ups', 'Curls']),
          ],
          meals: [],
        ))
      ..session = {'userId': 't1', 'displayName': 'Omar Test'};
    state.todayActivity.workoutStatus = WorkoutStatus.planned;
    state.todayActivity.workoutName = 'Pull';

    final opener = CoachPersonalityService.dailyOpener(state);
    expect(opener.contains('Omar'), isTrue);
    expect(opener.toLowerCase(), contains('pull'));
  });

  test('dynamic suggestions returns up to four unique items', () {
    final state = AppState()
      ..user = UserData.defaults()
      ..session = {'userId': 't1', 'displayName': 'Alex'};
    state.todayActivity.workoutStatus = WorkoutStatus.planned;

    final chips = CoachPersonalityService.dynamicSuggestions(state);
    expect(chips.length, lessThanOrEqualTo(4));
    expect(chips.length, greaterThanOrEqualTo(3));
    expect(chips.first.text, contains('workout'));
  });

  test('system prompt persona includes Mara and SOUL voice', () {
    final prompt = CoachPersonalityService.systemPromptPersona({'name': 'Omar'});
    expect(prompt.contains('Mara'), isTrue);
    expect(prompt.contains('bro-science'), isTrue);
  });
}
