import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/fun_facts_service.dart';

void main() {
  test('dailyFact is stable for same day', () {
    final user = UserData.defaults()
      ..userId = 'u1'
      ..gamification = {'xp': 125, 'level': 2, 'streak': 5}
      ..foodLog = [
        {'food': 'Chicken breast', 'calories': 330},
        {'food': 'Chicken breast', 'calories': 330},
      ];
    final a = FunFactsService.dailyFact(user: user);
    final b = FunFactsService.dailyFact(user: user);
    expect(a?.text, b?.text);
  });

  test('eventFact on first food log', () {
    final user = UserData.defaults()..foodLog = [{'food': 'Oats', 'calories': 300}];
    final fact = FunFactsService.eventFact(user: user, event: 'food_log');
    expect(fact?.text, contains('First meal'));
  });

  test('weeklyFacts returns up to three items', () {
    final user = UserData.defaults()..goal = 'cut';
    final facts = FunFactsService.weeklyFacts(
      user: user,
      dailyLogsHistory: [
        {
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'protein_logged': 150,
          'workout_status': 'completed',
        },
      ],
    );
    expect(facts.length <= 3, isTrue);
    expect(facts, isNotEmpty);
  });
}
