import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';

void main() {
  String dayKey(DateTime d) => d.toIso8601String().substring(0, 10);

  test('free messages refill to 10 on a new day', () {
    final u = UserData.defaults();
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    u.gamification = {
      ...u.gamification,
      'freeMessagesRemaining': 0,
      'freeMessagesDate': yesterday,
    };

    expect(u.freeMessagesRemaining, 10);
    expect(u.gamification['freeMessagesDate'], dayKey(DateTime.now()));
  });

  test('free messages do not refill on the same day', () {
    final u = UserData.defaults();
    u.gamification = {
      ...u.gamification,
      'freeMessagesRemaining': 3,
      'freeMessagesDate': dayKey(DateTime.now()),
    };

    expect(u.freeMessagesRemaining, 3);
  });

  test('legacy user with no date key gets a refill', () {
    final u = UserData.defaults();
    u.gamification = {...u.gamification, 'freeMessagesRemaining': 0};
    u.gamification.remove('freeMessagesDate');

    expect(u.freeMessagesRemaining, 10);
  });

  test('daily macros, food log and water reset on a new day', () {
    final u = UserData.defaults();
    u.dailyMacrosLogged = MacroLog(calories: 1800, protein: 120, carbs: 150, fat: 60, fiber: 20);
    u.foodLog = [
      {'date': '2026-06-12', 'food': 'Chicken wrap', 'calories': 450},
    ];
    u.water = 1500;
    u.dailyLogDate = dayKey(DateTime.now().subtract(const Duration(days: 1)));

    u.resetDailyLogIfNewDay();

    expect(u.dailyMacrosLogged.calories, 0);
    expect(u.dailyMacrosLogged.fiber, 0);
    expect(u.foodLog, isEmpty);
    expect(u.water, 0);
    expect(u.dailyLogDate, dayKey(DateTime.now()));
  });

  test('daily log untouched within the same day', () {
    final u = UserData.defaults();
    u.dailyMacrosLogged = MacroLog(calories: 900, protein: 70);
    u.foodLog = [
      {'date': dayKey(DateTime.now()), 'food': 'Oats', 'calories': 350},
    ];
    u.water = 500;
    u.dailyLogDate = dayKey(DateTime.now());

    u.resetDailyLogIfNewDay();

    expect(u.dailyMacrosLogged.calories, 900);
    expect(u.foodLog.length, 1);
    expect(u.water, 500);
  });
}
