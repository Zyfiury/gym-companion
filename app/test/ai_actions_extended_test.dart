import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/groq_chat_service.dart';

void main() {
  test('parses SWAP_MEAL LOG_PR COMPLETE_WORKOUT actions', () {
    const raw = '''
Great work!
ACTION:SWAP_MEAL:Lunch:Turkey Wrap
ACTION:LOG_PR:Bench Press:100:kg
ACTION:COMPLETE_WORKOUT:Push Day
''';
    final actions = GroqChatService.parseActions(raw);
    expect(actions.any((a) => a.type == 'SWAP_MEAL'), isTrue);
    expect(actions.any((a) => a.type == 'LOG_PR'), isTrue);
    expect(actions.any((a) => a.type == 'COMPLETE_WORKOUT'), isTrue);
  });

  test('parses LOG_WEIGHT alias', () {
    const raw = 'ACTION:LOG_WEIGHT:75.5';
    final actions = GroqChatService.parseActions(raw);
    expect(actions.first.type, 'UPDATE_WEIGHT');
    expect(actions.first.data['weight_kg'], 75.5);
  });
}
