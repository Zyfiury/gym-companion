import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/health_safety_service.dart';

void main() {
  test('pregnancy blocks heavy deadlift', () {
    final user = UserData.defaults()..pregnant = true;
    final check = HealthSafetyService.checkWorkoutSafe('Deadlift 4×5', user);
    expect(check.isSafe, isFalse);
  });

  test('period nutrition hint during menstrual phase', () {
    final user = UserData.defaults()
      ..tracksPeriod = true
      ..periodPhase = 'menstrual';
    expect(HealthSafetyService.periodNutritionHint(user), contains('Iron'));
  });

  test('parseDisabilityTag from natural language', () {
    expect(HealthSafetyService.parseDisabilityTag('I have a bad knee'), 'knee_injury');
    expect(HealthSafetyService.parseDisabilityTag('wheelchair user'), 'wheelchair');
  });

  test('video modifiers include seated for wheelchair', () {
    final user = UserData.defaults()..disabilities = ['wheelchair'];
    expect(HealthSafetyService.videoModifiers(user).join(' '), contains('wheelchair'));
  });

  test('videoSearchQuery maps leg press to seated alternative for wheelchair', () {
    final user = UserData.defaults()..disabilities = ['wheelchair'];
    final query = HealthSafetyService.videoSearchQuery('Leg Press 3×12', user);
    expect(query.toLowerCase(), isNot(contains('leg press form')));
    expect(query.toLowerCase(), contains('wheelchair'));
  });

  test('wheelchair blocks bench press in safety check', () {
    final user = UserData.defaults()..disabilities = ['wheelchair'];
    expect(HealthSafetyService.checkWorkoutSafe('Bench Press 4×6-8', user).isSafe, isFalse);
  });
}
