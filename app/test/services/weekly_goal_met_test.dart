import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/weekly_goal.dart';

/// Mirrors AppState._goalMetForDay logic for unit tests.
bool goalMetFromLog(WeeklyGoal g, Map<String, dynamic>? log, {double steps = 0, double weight = 80}) {
  return switch (g.type) {
    GoalType.protein =>
      log != null && ((log['protein_logged'] as num?)?.toInt() ?? 0) >= g.targetValue,
    GoalType.calories =>
      log != null && ((log['calories_logged'] as num?)?.toInt() ?? 0) <= g.targetValue,
    GoalType.workouts => log != null && log['workout_status'] == 'completed',
    GoalType.water =>
      log != null && ((log['water_ml'] as num?)?.toDouble() ?? 0) >= g.targetValue * 1000,
    GoalType.steps =>
      ((log != null ? (log['steps'] as num?)?.toDouble() : null) ?? steps) >= g.targetValue,
    GoalType.streak => false,
    GoalType.weight => weight <= g.targetValue,
  };
}

void main() {
  test('protein goal uses yesterday log not today macros', () {
    final goal = WeeklyGoal(
      id: 'g1',
      type: GoalType.protein,
      targetValue: 150,
      targetDays: 5,
      weekStart: DateTime(2026, 6, 1),
    );
    final yLog = {'protein_logged': 160, 'calories_logged': 2000};
    expect(goalMetFromLog(goal, yLog), isTrue);
    expect(goalMetFromLog(goal, {'protein_logged': 100}), isFalse);
    expect(goalMetFromLog(goal, null), isFalse);
  });

  test('workout goal reads workout_status from daily log', () {
    final goal = WeeklyGoal(
      id: 'g2',
      type: GoalType.workouts,
      targetValue: 1,
      targetDays: 4,
      weekStart: DateTime(2026, 6, 1),
    );
    expect(goalMetFromLog(goal, {'workout_status': 'completed'}), isTrue);
    expect(goalMetFromLog(goal, {'workout_status': 'skipped'}), isFalse);
  });
}
