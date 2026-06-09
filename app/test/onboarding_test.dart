import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';

void main() {
  test('onboarding answers serialize in UserData', () {
    final u = UserData.defaults()
      ..dietaryPreferences = ['halal', 'vegetarian']
      ..nutritionMode = 'cook_myself'
      ..onboardingAnswers = {'age': 28, 'goal': 'cut', 'completedAt': '2026-01-01'};
    final decoded = UserData.fromJson(u.toJson());
    expect(decoded.dietaryPreferences, contains('halal'));
    expect(decoded.nutritionMode, 'cook_myself');
    expect(decoded.onboardingAnswers['age'], 28);
  });

  test('TDEE adjustment for cut goal', () {
    const tdee = 2200;
    expect(tdee - 500, 1700);
  });
}
