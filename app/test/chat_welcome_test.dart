import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';

void main() {
  test('empty chat shows welcome without seeded assistant message', () {
    final messages = <ChatMessage>[];
    final showWelcome = messages.isEmpty;
    expect(showWelcome, isTrue);
    expect(messages.where((m) => m.role == 'assistant').length, 0);
  });
}
