/// Estimates active calories from steps and workouts using MET values.
class ActivityCalorieService {
  static const double defaultWalkingMet = 3.5;
  static const double stepsPerHour = 1300;

  /// Steps → kcal: durationHours = steps / 1300; kcal = MET * weightKg * durationHours
  static double stepsToCalories(int steps, double weightKg, {double met = defaultWalkingMet}) {
    if (steps <= 0 || weightKg <= 0) return 0;
    final durationHours = steps / stepsPerHour;
    return met * weightKg * durationHours;
  }

  /// Workout kcal = MET * weightKg * (durationMinutes / 60)
  static double workoutCalories({
    required double met,
    required double weightKg,
    required double durationMinutes,
  }) {
    if (weightKg <= 0 || durationMinutes <= 0) return 0;
    return met * weightKg * (durationMinutes / 60);
  }

  static double metForExercise(String name) {
    final lower = name.toLowerCase();
    const cardio = ['run', 'cardio', 'walk', 'cycle', 'bike', 'row', 'erg', 'sprint', 'jog'];
    const strength = [
      'press',
      'squat',
      'deadlift',
      'curl',
      'row',
      'pull',
      'bench',
      'ohp',
      'raise',
      'extension',
      'lunge',
    ];
    if (cardio.any(lower.contains)) return 8.0;
    if (strength.any(lower.contains)) return 5.0;
    return 4.0;
  }

  static double estimateSessionCalories({
    required List<String> exerciseNames,
    required double weightKg,
    required int durationMinutes,
  }) {
    if (exerciseNames.isEmpty) {
      return workoutCalories(met: 4.0, weightKg: weightKg, durationMinutes: durationMinutes.toDouble());
    }
    final avgMet = exerciseNames.map(metForExercise).reduce((a, b) => a + b) / exerciseNames.length;
    return workoutCalories(met: avgMet, weightKg: weightKg, durationMinutes: durationMinutes.toDouble());
  }
}
