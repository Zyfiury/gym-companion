import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/constants/xp_rewards.dart';

void main() {
  test('feed XP tiers match spec', () {
    expect(XpRewards.feedGeneral, 5);
    expect(XpRewards.feedLinked, 10);
    expect(XpRewards.feedPrShare, 10);
  });

  test('workout and PR XP tiers match spec', () {
    expect(XpRewards.workoutComplete, 25);
    expect(XpRewards.customWorkoutLogged, 15);
    expect(XpRewards.prDetected, 50);
  });
}
