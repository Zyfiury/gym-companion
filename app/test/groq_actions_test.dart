import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/groq_chat_service.dart';

void main() {
  test('parses LOG_FOOD action', () {
    final raw = 'Logged!\nACTION:LOG_FOOD:Chicken:165:31:0:4';
    final actions = GroqChatService.parseActions(raw);
    expect(actions, hasLength(1));
    expect(actions.first.type, 'LOG_FOOD');
    expect(actions.first.data['name'], 'Chicken');
    expect(actions.first.data['calories'], 165.0);
  });

  test('parses multiple actions', () {
    final raw = '''
Great session!
ACTION:ADD_XP:25
ACTION:UPDATE_WEIGHT:76.5
''';
    final actions = GroqChatService.parseActions(raw);
    expect(actions, hasLength(2));
    expect(actions.any((a) => a.type == 'ADD_XP' && a.data['amount'] == 25), isTrue);
    expect(actions.any((a) => a.type == 'UPDATE_WEIGHT' && a.data['weight_kg'] == 76.5), isTrue);
  });

  test('strips action lines from display text', () {
    final raw = 'Done!\nACTION:UPDATE_GOAL:cut\nStay consistent.';
    expect(GroqChatService.cleanDisplayText(raw), 'Done!\nStay consistent.');
  });

  test('parses UPDATE_WORKOUT and health actions', () {
    final raw = '''
Adapted your plan!
ACTION:UPDATE_WORKOUT
ACTION:ADD_DISABILITY:knee_injury
ACTION:SET_PREGNANT:false
ACTION:SET_PERIOD:menstrual
''';
    final actions = GroqChatService.parseActions(raw);
    expect(actions.any((a) => a.type == 'UPDATE_WORKOUT'), isTrue);
    expect(actions.any((a) => a.type == 'ADD_DISABILITY' && a.data['tag'] == 'knee_injury'), isTrue);
    expect(actions.any((a) => a.type == 'SET_PREGNANT' && a.data['value'] == false), isTrue);
    expect(actions.any((a) => a.type == 'SET_PERIOD' && a.data['phase'] == 'menstrual'), isTrue);
  });
}
