import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/weekly_goal.dart';

void main() {
  test('week end is seven days after week start', () {
    final goal = WeeklyGoal(
      id: 'g1',
      type: GoalType.protein,
      targetValue: 150,
      targetDays: 5,
      daysAchieved: 5,
      weekStart: DateTime(2026, 6, 1),
    );
    final weekEnd = goal.weekStart.add(const Duration(days: 7));
    expect(weekEnd, DateTime(2026, 6, 8));
    expect(goal.progress, 1.0);
  });
}
