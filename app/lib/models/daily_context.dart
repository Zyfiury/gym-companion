import 'workout_status.dart';

class DailyContext {
  final String date;
  final String goal;
  final int targetCalories;
  final int caloriesEaten;
  final int caloriesRemaining;
  final double activeCaloriesBurned;
  final double netCalories;
  final Map<String, Map<String, num>> macros;
  final Map<String, dynamic>? workoutToday;
  final int steps;
  final double stepCaloriesBurned;
  final double water;
  final int streak;
  final List<String> recentPRs;
  final List<String> activeGoals;
  final int energyLevel;
  final double sleepHours;
  final String workoutAdjusted;
  final List<String> recentProgressions;
  final Map<String, double> weeklyVolume;
  final bool trainingDay;
  final List<Map<String, dynamic>> foodLoggedToday;
  final List<Map<String, dynamic>> plannedMeals;

  const DailyContext({
    required this.date,
    required this.goal,
    required this.targetCalories,
    required this.caloriesEaten,
    required this.caloriesRemaining,
    required this.activeCaloriesBurned,
    required this.netCalories,
    required this.macros,
    this.workoutToday,
    required this.steps,
    required this.stepCaloriesBurned,
    required this.water,
    required this.streak,
    required this.recentPRs,
    this.activeGoals = const [],
    this.energyLevel = 0,
    this.sleepHours = 0,
    this.workoutAdjusted = 'none',
    this.recentProgressions = const [],
    this.weeklyVolume = const {},
    this.trainingDay = true,
    this.foodLoggedToday = const [],
    this.plannedMeals = const [],
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'goal': goal,
        'targetCalories': targetCalories,
        'caloriesEaten': caloriesEaten,
        'caloriesRemaining': caloriesRemaining,
        'activeCaloriesBurned': activeCaloriesBurned.round(),
        'netCalories': netCalories.round(),
        'macros': macros,
        if (workoutToday != null) 'workoutToday': workoutToday,
        'steps': steps,
        'stepCaloriesBurned': stepCaloriesBurned.round(),
        'water': water,
        'streak': streak,
        'recentPRs': recentPRs,
        'activeGoals': activeGoals,
        'energyLevel': energyLevel,
        'sleepHours': sleepHours,
        'workoutAdjusted': workoutAdjusted,
        'recentProgressions': recentProgressions,
        'weeklyVolume': weeklyVolume,
        'trainingDay': trainingDay,
        if (foodLoggedToday.isNotEmpty) 'foodLoggedToday': foodLoggedToday,
        if (plannedMeals.isNotEmpty) 'plannedMeals': plannedMeals,
      };

  static Map<String, dynamic>? workoutTodayJson({
    required String? name,
    required WorkoutStatus status,
    required String? completedAt,
    required int exercisesLogged,
    required double caloriesBurned,
  }) {
    if (name == null && status == WorkoutStatus.planned) return null;
    return {
      'name': name ?? 'Rest',
      'status': status.firestoreValue,
      if (completedAt != null) 'completedAt': completedAt,
      'exercisesLogged': exercisesLogged,
      'caloriesBurned': caloriesBurned.round(),
    };
  }
}
