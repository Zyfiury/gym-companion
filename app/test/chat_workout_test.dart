import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/chat_service.dart';

void main() {
  test('change my workout updates weekly plan', () {
    final user = UserData.defaults();
    final before = user.weeklyPlan.workouts.first.exercises.first;
    final result = ChatService().process('change my workout', user);
    expect(result.updatedUser, isNotNull);
    expect(result.reply, contains('Updated your workout'));
    expect(result.updatedUser!.weeklyPlan.workouts, isNotEmpty);
    expect(result.updatedUser!.weeklyPlan.workouts.length, 7);
    // Plan is regenerated (may differ from defaults)
    expect(result.updatedUser!.weeklyPlan.workouts.first.exercises, isNotEmpty);
    expect(before, isNotEmpty); // sanity
  });

  test('adapt workout for bad knee adds disability and substitutes', () {
    final user = UserData.defaults();
    final result = ChatService().process('I have a bad knee', user);
    expect(result.updatedUser, isNotNull);
    expect(result.updatedUser!.disabilities, contains('knee_injury'));
    expect(result.reply, contains('knee injury'));
    final fri = result.updatedUser!.weeklyPlan.workouts.where((w) => w.day == 'Tue').first;
    expect(fri.exercises.any((e) => e.contains('Leg Press') || e.contains('Step-ups')), isTrue);
  });

  test("today's workout returns read-only plan", () {
    final user = UserData.defaults();
    final result = ChatService().process("Give me today's workout", user);
    expect(result.updatedUser, isNull);
    expect(result.reply, isNotEmpty);
  });
}
