import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/chat_service.dart';

void main() {
  test('lose 10kg does not set weight to 10kg', () {
    final user = UserData.defaults()..weight = 110;
    final result = ChatService().process('I want to lose 10kg by August if is that possible', user);
    expect(result.updatedUser, isNotNull);
    expect(result.updatedUser!.weight, 110);
    expect(result.updatedUser!.goal, 'cut');
    expect(result.reply, contains('cutting'));
    expect(result.reply, isNot(contains('10.0kg')));
    expect(result.reply, contains('100'));
  });

  test('stated weight and loss goal are parsed together', () {
    final user = UserData.defaults()..weight = 70;
    final result = ChatService().process('I weight 110 kg and I want to lose 10kg', user);
    expect(result.updatedUser!.weight, 110);
    expect(result.updatedUser!.goal, 'cut');
    expect(result.reply, contains('110'));
    expect(result.reply, contains('100'));
  });

  test('explicit weight update still works', () {
    final user = UserData.defaults();
    final result = ChatService().process('set my weight to 72kg', user);
    expect(result.updatedUser!.weight, 72);
    expect(result.reply, contains('72'));
  });
}
