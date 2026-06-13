import '../models/daily_context.dart';
import '../models/user_data.dart';
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
        'fiber': {
          'target': 30,
          'eaten': u.dailyMacrosLogged.fiber,
        },
        'sugar': {
          'target': 50,
          'eaten': u.dailyMacrosLogged.sugar,
        },
        'sodiumMg': {
          'target': 2300,
          'eaten': u.dailyMacrosLogged.sodiumMg,
        },
      },
      workoutToday: workoutToday,
      steps: u.steps.round(),
      stepCaloriesBurned: state.stepCaloriesBurned,
      water: u.water,
      streak: u.gamification['streak'] as int? ?? 0,
      recentPRs: state.recentPRs,
      activeGoals: state.activeGoals.map((g) => g.label).toList(),
      energyLevel: state.todayEnergyLevel,
      sleepHours: state.lastNightSleepHours,
      workoutAdjusted: state.workoutAdjustment,
      recentProgressions: state.recentProgressions.map((p) => p.message).toList(),
      weeklyVolume: state.weeklyVolume,
      trainingDay: state.isTrainingDay,
      foodLoggedToday: u.foodLog
          .map((e) => {
                'name': e['food'],
                'calories': e['calories'],
                'protein': e['protein'],
                'meal': e['meal_type'],
              })
          .toList(),
      plannedMeals: u.weeklyPlan.meals
          .map((m) => {
                'slot': m.mealType,
                'name': m.name,
                'calories': m.macros['calories'],
                'protein': m.macros['protein'],
              })
          .toList(),
    );
  }

  /// Natural-language snapshot for the coach model (easier to reason over than raw JSON).
  static String coachBrief(AppState state) {
    final u = state.user!;
    final ctx = fromAppState(state);
    final lines = <String>[];

    lines.add('TODAY ${ctx.date} (${ctx.trainingDay ? "training day" : "rest day"})');
    lines.add(
      'Calories: ${ctx.caloriesEaten} eaten / ${ctx.targetCalories} target — ${ctx.caloriesRemaining} left. '
      'Burned ~${ctx.activeCaloriesBurned.round()} kcal active, net ~${ctx.netCalories.round()} kcal.',
    );

    final pE = ctx.macros['protein']!['eaten']!.round();
    final pT = ctx.macros['protein']!['target']!.round();
    final cE = ctx.macros['carbs']!['eaten']!.round();
    final cT = ctx.macros['carbs']!['target']!.round();
    final fE = ctx.macros['fat']!['eaten']!.round();
    final fT = ctx.macros['fat']!['target']!.round();
    lines.add('Macros: protein ${pE}/${pT}g, carbs ${cE}/${cT}g, fat ${fE}/${fT}g.');
    lines.add(
      'Micros: fibre ${u.dailyMacrosLogged.fiber}g (target ~30g), sugar ${u.dailyMacrosLogged.sugar}g (limit ~50g), '
      'sodium ${u.dailyMacrosLogged.sodiumMg}mg.',
    );
    lines.add('Water ${(u.water / 1000).toStringAsFixed(1)}L, steps ${ctx.steps}, streak ${ctx.streak} days.');

    if (ctx.energyLevel > 0) {
      lines.add('Morning check-in: energy ${ctx.energyLevel}/4, sleep ${ctx.sleepHours}h.');
    }
    if (ctx.workoutAdjusted != 'none') {
      lines.add('Workout was adjusted today (${ctx.workoutAdjusted}).');
    }

    final w = ctx.workoutToday;
    if (w != null) {
      lines.add('Workout: ${w['name']} — status ${w['status']}.');
      if (w['exercisesLogged'] != null && (w['exercisesLogged'] as int) > 0) {
        lines.add('Logged ${w['exercisesLogged']} exercises in session.');
      }
    }

    if (u.foodLog.isEmpty) {
      lines.add('Food logged today: nothing yet.');
    } else {
      lines.add('Food logged today:');
      for (final e in u.foodLog.take(10)) {
        lines.add(
          '  · ${e['food']}: ${e['calories']} kcal, P${e['protein']}g '
          '(${e['meal_type'] ?? 'meal'})',
        );
      }
    }

    if (u.weeklyPlan.meals.isNotEmpty) {
      final mealLine = u.weeklyPlan.meals
          .map((m) => '${m.mealType}: ${m.name} (~${m.macros['calories'] ?? "?"} kcal)')
          .join('; ');
      lines.add('Planned meals: $mealLine.');
    }

    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final todayDay = days[DateTime.now().weekday % 7];
    WorkoutDay? planDay;
    for (final w in u.weeklyPlan.workouts) {
      if (w.day == todayDay) {
        planDay = w;
        break;
      }
    }
    if (planDay != null && ctx.workoutToday?['status'] != 'completed') {
      lines.add('Scheduled workout (${planDay.focus}): ${planDay.exercises.take(8).join(", ")}.');
    }

    if (ctx.recentPRs.isNotEmpty) {
      lines.add('Recent PRs: ${ctx.recentPRs.take(3).join(", ")}.');
    }
    if (ctx.activeGoals.isNotEmpty) {
      lines.add('Weekly goals: ${ctx.activeGoals.join(", ")}.');
    }
    if (ctx.recentProgressions.isNotEmpty) {
      lines.add('Progression notes: ${ctx.recentProgressions.take(2).join("; ")}.');
    }

    return lines.join('\n');
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
      'coach_brief': coachBrief(state),
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
