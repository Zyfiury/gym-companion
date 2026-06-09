import '../models/user_data.dart';

class ProfileMapper {
  static UserData fromSupabase({
    required Map<String, dynamic> profile,
    Map<String, dynamic>? todayLog,
    List<Map<String, dynamic>>? weightHistory,
    List<Map<String, dynamic>>? personalRecords,
    Map<String, dynamic>? weekPlan,
  }) {
    final u = UserData.defaults();
    u.userId = profile['id'] as String? ?? '';
    u.profileComplete = profile['profile_complete'] as bool? ?? false;
    u.goal = profile['goal'] as String? ?? '';
    u.weight = (profile['weight_kg'] as num?)?.toDouble() ?? 70;
    u.height = (profile['height_cm'] as num?)?.toDouble() ?? 175;
    u.age = profile['age'] as int? ?? 30;
    u.tdee = profile['tdee'] as int? ?? 2200;
    u.weeklyBudget = (profile['weekly_budget'] as num?)?.toDouble() ?? 50;
    u.allergies = List<String>.from(profile['allergies'] as List? ?? []);
    u.dietType = profile['diet_type'] as String? ?? 'omnivore';
    u.mealVariety = profile['meal_variety'] as String? ?? 'rotate';
    u.bannedMeals = List<String>.from(profile['banned_meals'] as List? ?? []);
    u.favouriteMeals = (profile['favourite_meals'] as List?)
            ?.map((e) => e is String ? {'name': e} : Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    u.nutritionMode = profile['nutrition_mode'] as String? ?? 'cook_myself';
    u.dietaryRestrictions = profile['dietary_restrictions'] as String? ?? 'none';
    u.genderAtBirth = profile['gender_at_birth'] as String? ?? 'prefer_not_to_say';
    u.disabilities = List<String>.from(profile['disabilities'] as List? ?? []);
    u.pregnant = profile['pregnant'] as bool? ?? false;
    u.medications = List<String>.from(profile['medications'] as List? ?? []);
    u.tracksPeriod = profile['tracks_period'] as bool? ?? false;
    u.periodPhase = profile['period_phase'] as String?;
    u.gamification = {
      'xp': profile['xp'] ?? 0,
      'level': profile['level'] ?? 1,
      'streak': profile['streak'] ?? 0,
      'achievements': <String>[],
    };

    if (todayLog != null && todayLog.isNotEmpty) {
      u.dailyMacrosLogged = MacroLog(
        calories: todayLog['calories_logged'] as int? ?? 0,
        protein: (todayLog['protein_logged'] as num?)?.toInt() ?? 0,
        carbs: (todayLog['carbs_logged'] as num?)?.toInt() ?? 0,
        fat: (todayLog['fat_logged'] as num?)?.toInt() ?? 0,
      );
      u.foodLog = List<Map<String, dynamic>>.from(todayLog['food_log'] as List? ?? []);
    }

    if (weightHistory != null && weightHistory.isNotEmpty) {
      u.weightHistory = weightHistory
          .map((e) => {'date': e['date'], 'weight': (e['weight_kg'] as num).toDouble()})
          .toList();
    }

    if (personalRecords != null && personalRecords.isNotEmpty) {
      u.personalRecords = personalRecords
          .map((e) => {
                'exercise': e['exercise'] ?? e['exercise_name'] ?? e['lift'],
                'value': e['value'] ?? e['weight_kg'],
                'unit': e['unit'] ?? (e['weight_kg'] != null ? 'kg' : ''),
                'date': e['date'],
              })
          .toList();
    }

    if (weekPlan != null) {
      try {
        u.weeklyPlan = WeeklyPlan.fromJson(weekPlan);
      } catch (_) {}
    }

    u.weeklyPlan.macros['calories'] = u.tdee;
    return u;
  }

  static Map<String, dynamic> toProfileRow(UserData u) => {
        'goal': u.goal,
        'weight_kg': u.weight,
        'height_cm': u.height,
        'age': u.age,
        'tdee': u.tdee,
        'weekly_budget': u.weeklyBudget,
        'allergies': u.allergies,
        'diet_type': u.dietType,
        'meal_variety': u.mealVariety,
        'banned_meals': u.bannedMeals,
        'favourite_meals': u.favouriteMeals.map((m) => m['name']).toList(),
        'nutrition_mode': u.nutritionMode,
        'dietary_restrictions': u.dietaryRestrictions,
        'profile_complete': u.profileComplete,
        'xp': u.gamification['xp'] ?? 0,
        'level': u.gamification['level'] ?? 1,
        'streak': u.gamification['streak'] ?? 0,
        'gender_at_birth': u.genderAtBirth,
        'disabilities': u.disabilities,
        'pregnant': u.pregnant,
        'medications': u.medications,
        'tracks_period': u.tracksPeriod,
        'period_phase': u.periodPhase,
      };

  static Map<String, dynamic> toGroqContext(
    UserData u, {
    String? displayName,
    String contextPeriod = 'day',
    List<Map<String, dynamic>> dailyLogsHistory = const [],
  }) {
    final base = _baseContext(u, displayName);
    if (contextPeriod == 'week' && dailyLogsHistory.isNotEmpty) {
      final recent = dailyLogsHistory.take(7);
      var cal = 0, pro = 0;
      for (final l in recent) {
        cal += (l['calories_logged'] as num?)?.toInt() ?? 0;
        pro += (l['protein_logged'] as num?)?.toInt() ?? 0;
      }
      final n = recent.length.clamp(1, 7);
      base['calories_logged'] = (cal / n).round();
      base['protein_logged'] = (pro / n).round();
      base['context_note'] = '7-day average macros';
    } else if (contextPeriod == 'month' && dailyLogsHistory.isNotEmpty) {
      var cal = 0, pro = 0;
      for (final l in dailyLogsHistory) {
        cal += (l['calories_logged'] as num?)?.toInt() ?? 0;
        pro += (l['protein_logged'] as num?)?.toInt() ?? 0;
      }
      final n = dailyLogsHistory.length.clamp(1, 30);
      base['calories_logged'] = (cal / n).round();
      base['protein_logged'] = (pro / n).round();
      base['context_note'] = '30-day average macros';
      if (u.weightHistory.length >= 2) {
        final first = (u.weightHistory.first['weight'] as num).toDouble();
        final last = (u.weightHistory.last['weight'] as num).toDouble();
        base['weight_trend'] = '${(last - first).toStringAsFixed(1)} kg over ${u.weightHistory.length} entries';
      }
    } else {
      base['context_note'] = "Today's data only";
    }
    base['context_period'] = contextPeriod;
    return base;
  }

  static Map<String, dynamic> _baseContext(UserData u, String? displayName) => {
        'name': displayName ?? 'Athlete',
        'goal': u.goal,
        'weight_kg': u.weight,
        'height_cm': u.height,
        'age': u.age,
        'tdee': u.tdee,
        'weekly_budget': u.weeklyBudget,
        'allergies': u.allergies,
        'diet_type': u.dietType,
        'meal_variety': u.mealVariety,
        'calories_logged': u.dailyMacrosLogged.calories,
        'protein_logged': u.dailyMacrosLogged.protein,
        'carbs_logged': u.dailyMacrosLogged.carbs,
        'fat_logged': u.dailyMacrosLogged.fat,
        'xp': u.gamification['xp'] ?? 0,
        'level': u.gamification['level'] ?? 1,
        'banned_meals': u.bannedMeals,
        'favourite_meals': u.favouriteMeals.map((m) => m['name']).toList(),
        'gender_at_birth': u.genderAtBirth,
        'disabilities': u.disabilities,
        'pregnant': u.pregnant,
        'medications': u.medications,
        'tracks_period': u.tracksPeriod,
        'period_phase': u.periodPhase,
        'nutrition_mode': u.nutritionMode,
      };
}
