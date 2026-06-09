import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/allergy_guard.dart';
import 'package:gym_companion/services/chat_service.dart';
import 'package:gym_companion/services/meal_variety_service.dart';

void main() {
  test('blocks dairy yogurt for dairy allergy', () {
    final user = UserData.defaults()..allergies = ['dairy'];
    final guard = AllergyGuard.checkText('greek yogurt', UserAllergies.fromUser(user));
    expect(guard.isSafe, false);
    expect(guard.message, contains('dairy'));
  });

  test('chat blocks logging yogurt', () {
    final user = UserData.defaults()..allergies = ['dairy'];
    final result = ChatService().process('log 200g greek yogurt', user);
    expect(result.reply, contains('Blocked'));
    expect(result.updatedUser, isNull);
  });

  test('chat swaps lunch', () {
    final user = UserData.defaults()..allergies = ['dairy'];
    user.weeklyPlan = WeeklyPlan(
      macros: user.weeklyPlan.macros,
      workouts: user.weeklyPlan.workouts,
      meals: MealVarietyService.generateDailyPlan(user),
      shoppingList: user.weeklyPlan.shoppingList,
    );
    final before = user.weeklyPlan.meals.firstWhere((m) => m.mealType == 'Lunch').name;
    final result = ChatService().process('swap my lunch', user);
    expect(result.reply, contains('Swapped'));
    expect(result.updatedUser, isNotNull);
    final after = result.updatedUser!.weeklyPlan.meals.firstWhere((m) => m.mealType == 'Lunch').name;
    expect(after, isNot(equals(before)));
  });
}
