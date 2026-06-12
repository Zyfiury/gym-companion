import '../models/daily_context.dart';
import '../providers/app_state.dart';

class DailyContextBuilder {
  static DailyContext fromAppState(AppState state) {
    final u = state.user!;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final target = state.caloriesTarget.round();
    final eaten = state.caloriesEaten.round();
    final burned = state.activeCaloriesBurned;
    final net = state.netCalories;
    final macros = u.weeklyPlan.macros;

    final session = state.todayActivity.session;
    final workoutToday = DailyContext.workoutTodayJson(
      name: state.todayWorkoutName ?? session.workoutName,
      status: state.todayWorkoutStatus,
      completedAt: session.completedAt,
      exercisesLogged: session.exercises.length,
      caloriesBurned: state.workoutCaloriesBurned,
    );

    return DailyContext(
      date: today,
      goal: u.goal.isEmpty ? 'maintain' : u.goal,
      targetCalories: target,
      caloriesEaten: eaten,
      caloriesRemaining: (target - eaten).clamp(0, 100000),
      activeCaloriesBurned: burned,
      netCalories: net,
      macros: {
        'protein': {
          'target': macros['protein'] ?? 140,
          'eaten': u.dailyMacrosLogged.protein,
        },
        'carbs': {
          'target': macros['carbs'] ?? 200,
          'eaten': u.dailyMacrosLogged.carbs,
        },
        'fat': {
          'target': macros['fat'] ?? 60,
          'eaten': u.dailyMacrosLogged.fat,
        },
      },
      workoutToday: workoutToday,
      steps: u.steps.round(),
      stepCaloriesBurned: state.stepCaloriesBurned,
      water: u.water,
      streak: u.gamification['streak'] as int? ?? 0,
      recentPRs: state.recentPRs,
    );
  }

  static Map<String, dynamic> groqProfileFromAppState(AppState state, {String? displayName}) {
    final u = state.user!;
    final ctx = fromAppState(state);
    return {
      'name': displayName ?? 'Athlete',
      'goal': u.goal,
      'weight_kg': u.weight,
      'height_cm': u.height,
      'age': u.age,
      'gender_at_birth': u.genderAtBirth,
      'tdee': u.tdee,
      'weekly_budget': u.weeklyBudget,
      'allergies': u.allergies,
      'disabilities': u.disabilities,
      'pregnant': u.pregnant,
      'medications': u.medications,
      'tracks_period': u.tracksPeriod,
      'period_phase': u.periodPhase,
      'nutrition_mode': u.nutritionMode,
      'diet_type': u.dietType,
      'meal_variety': u.mealVariety,
      'banned_meals': u.bannedMeals,
      'favourite_meals': u.favouriteMeals.map((m) => m['name']).toList(),
      'xp': u.gamification['xp'] ?? 0,
      'level': u.gamification['level'] ?? 1,
      'context_period': state.coachContextPeriod,
      'context_note': _contextNote(state),
      'daily_context': ctx.toJson(),
    };
  }

  static String _contextNote(AppState state) {
    switch (state.coachContextPeriod) {
      case 'week':
        return '7-day average macros where noted';
      case 'month':
        return '30-day average macros where noted';
      default:
        return "Today's live data in daily_context";
    }
  }
}
