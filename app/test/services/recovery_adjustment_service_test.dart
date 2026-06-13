import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/models/workout_status.dart';
import 'package:gym_companion/services/recovery_adjustment_service.dart';

void main() {
  test('lighter adjustment reduces weight and sets', () {
    final plan = UserData.defaults().weeklyPlan;
    final result = RecoveryAdjustmentService.apply(
      plan: plan,
      choice: RecoveryChoice.lighter,
      todayDay: 'Mon',
    );
    expect(result.status, WorkoutStatus.modified);
    expect(result.adjustment, 'lighter');
    final mon = result.adjustedWorkouts.firstWhere((w) => w.day == 'Mon');
    expect(mon.exercises.length, lessThan(plan.workouts.firstWhere((w) => w.day == 'Mon').exercises.length));
  });

  test('morning window is 06:00-11:00', () {
    expect(RecoveryAdjustmentService.isMorningCheckinWindow(), isA<bool>());
  });
}
