import '../models/user_data.dart';

/// Maintenance + goal-adjusted calorie targets from body metrics.
class CaloriePlan {
  final int maintenance;
  final int target;
  final String goal;

  const CaloriePlan({
    required this.maintenance,
    required this.target,
    required this.goal,
  });
}

class TdeeService {
  /// Light exercise 1–3 days/week — realistic default before activity is set in profile.
  static const double defaultActivityMultiplier = 1.375;

  /// Mifflin-St Jeor BMR (activity applied separately in [calculateTdee]).
  static int calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    String genderAtBirth = 'prefer_not_to_say',
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    if (genderAtBirth == 'female') return (base - 161).round();
    return (base + 5).round(); // male or default
  }

  static int calculateTdee({
    required double weightKg,
    required double heightCm,
    required int age,
    String genderAtBirth = 'prefer_not_to_say',
    double activityMultiplier = defaultActivityMultiplier,
  }) {
    return (calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      genderAtBirth: genderAtBirth,
    ) * activityMultiplier).round();
  }

  static int applyGoalOffset(int maintenance, String goal) {
    if (goal == 'cut') return (maintenance * 0.8).round().clamp(1200, 10000);
    if (goal == 'bulk') return (maintenance * 1.15).round();
    return maintenance;
  }

  /// Recalculate maintenance + target + macros from current profile weight.
  static ({CaloriePlan plan, Map<String, int> macros}) recalculateFromUser(UserData u) {
    final caloriePlan = plan(
      weightKg: u.weight,
      heightCm: u.height,
      age: u.age,
      goal: u.goal.isEmpty ? 'maintain' : u.goal,
      genderAtBirth: u.genderAtBirth,
    );
    final macros = deriveMacros(calories: caloriePlan.target, weightKg: u.weight);
    return (plan: caloriePlan, macros: macros);
  }

  /// Mifflin-St Jeor maintenance TDEE, then goal offset for daily target.
  static CaloriePlan plan({
    required double weightKg,
    required double heightCm,
    required int age,
    String goal = 'maintain',
    String genderAtBirth = 'prefer_not_to_say',
    double activityMultiplier = defaultActivityMultiplier,
  }) {
    final maintenance = calculateTdee(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      genderAtBirth: genderAtBirth,
      activityMultiplier: activityMultiplier,
    );
    final resolvedGoal = goal.isEmpty ? 'maintain' : goal;
    return CaloriePlan(
      maintenance: maintenance,
      target: applyGoalOffset(maintenance, resolvedGoal),
      goal: resolvedGoal,
    );
  }

  static String goalLabel(String goal) {
    switch (goal) {
      case 'cut':
        return 'Cut target';
      case 'bulk':
        return 'Bulk target';
      default:
        return 'Maintenance';
    }
  }

  static String inputsSummary({
    required double weightKg,
    required double heightCm,
    required int age,
    String genderAtBirth = 'prefer_not_to_say',
  }) {
    final sex = genderAtBirth == 'female' ? 'female' : 'male';
    return '${weightKg.round()} kg · ${heightCm.round()} cm · age $age · $sex';
  }

  static String planSubtitle(CaloriePlan plan) {
    if (plan.goal == 'cut') {
      return 'Maintenance ${plan.maintenance} kcal · −20% for cut';
    }
    if (plan.goal == 'bulk') {
      return 'Maintenance ${plan.maintenance} kcal · +15% for bulk';
    }
    return 'Based on ${plan.maintenance} kcal maintenance (Mifflin-St Jeor)';
  }

  static Map<String, int> deriveMacros({
    required int calories,
    required double weightKg,
  }) {
    final protein = (weightKg * 2).round();
    final proteinCal = protein * 4;
    final fat = (calories * 0.25 / 9).round();
    final fatCal = fat * 9;
    final carbs = ((calories - proteinCal - fatCal) / 4).round().clamp(50, 400);
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
