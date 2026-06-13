import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/groq_chat_service.dart';

void main() {
  test('isErrorOrEmpty detects API failures', () {
    expect(GroqChatService.isErrorOrEmpty(''), isTrue);
    expect(GroqChatService.isErrorOrEmpty('❌ Invalid Groq API key.'), isTrue);
    expect(GroqChatService.isErrorOrEmpty('Connection error. Check internet.'), isTrue);
    expect(GroqChatService.isErrorOrEmpty('You have 45g protein left today.'), isFalse);
  });
}
