import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/chat_service.dart';

UserData _user() {
  return UserData(
    goal: 'cut',
    weight: 80,
    height: 180,
    age: 25,
    tdee: 2200,
    weeklyBudget: 50,
    dailyMacrosLogged: MacroLog(
      calories: 1200,
      protein: 95,
      carbs: 120,
      fat: 40,
    ),
    weeklyPlan: WeeklyPlan(
      macros: {'calories': 2200, 'protein': 160, 'carbs': 200, 'fat': 65},
      workouts: [],
      meals: [],
    ),
    gamification: {'streak': 7, 'level': 2, 'xp': 120},
  );
}

void main() {
  final chat = ChatService();

  test('macro snapshot uses live numbers and protein gap', () {
    final r = chat.process('How are my macros looking?', _user());
    expect(r.reply, contains('1200 / 2200'));
    expect(r.reply, contains('95g / 160g'));
    expect(r.reply, contains('65g protein'));
  });

  test('protein insight names the gap', () {
    final r = chat.process('how much protein have I eaten?', _user());
    expect(r.reply, contains('95g / 160g'));
    expect(r.reply, contains('65g'));
  });

  test('streak insight references streak days', () {
    final r = chat.process('what is my streak?', _user());
    expect(r.reply, contains('7'));
    expect(r.reply, contains('Level 2'));
  });

  test('budget query uses weekly budget fields', () {
    final u = _user();
    u.budgetSpent = 12.5;
    final r = chat.process('how much food budget have I spent?', u);
    expect(r.reply, contains('12.50'));
    expect(r.reply, contains('50'));
  });
}
