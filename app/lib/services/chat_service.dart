import '../models/user_data.dart';
import 'allergy_guard.dart';
import 'health_safety_service.dart';
import 'meal_variety_service.dart';
import 'tdee_service.dart';
import 'workout_adaptation_service.dart';

class FoodLogIntent {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double? grams;

  const FoodLogIntent({
    required this.name,
    required this.calories,
    required this.protein,
    this.carbs = 0,
    this.fat = 0,
    this.grams,
  });
}

class ChatResult {
  final String reply;
  final UserData? updatedUser;
  final FoodLogIntent? foodLogIntent;

  ChatResult({required this.reply, this.updatedUser, this.foodLogIntent});
}

class ChatService {
  static const _dayMap = {
    'monday': 'Mon', 'mon': 'Mon',
    'tuesday': 'Tue', 'tue': 'Tue',
    'wednesday': 'Wed', 'wed': 'Wed',
    'thursday': 'Thu', 'thu': 'Thu',
    'friday': 'Fri', 'fri': 'Fri',
    'saturday': 'Sat', 'sat': 'Sat',
    'sunday': 'Sun', 'sun': 'Sun',
  };

  int _calcTdee(UserData u, {String? goal}) {
    final g = goal ?? u.goal;
    final plan = TdeeService.plan(
      weightKg: u.weight,
      heightCm: u.height,
      age: u.age,
      goal: g.isEmpty ? 'maintain' : g,
      genderAtBirth: u.genderAtBirth,
    );
    return plan.target;
  }

  UserData _clone(UserData u) => UserData.fromJson(u.toJson());

  int? _weeksUntilDeadline(String lower) {
    const months = {
      'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
      'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6, 'july': 7, 'jul': 7,
      'august': 8, 'aug': 8, 'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10, 'november': 11, 'nov': 11, 'december': 12, 'dec': 12,
    };
    final m = RegExp(r'by\s+(\w+)', caseSensitive: false).firstMatch(lower);
    if (m == null) return null;
    final month = months[m.group(1)!.toLowerCase()];
    if (month == null) return null;
    final now = DateTime.now();
    var year = now.year;
    if (month <= now.month) year++;
    final deadline = DateTime(year, month + 1, 0);
    final days = deadline.difference(now).inDays;
    if (days <= 0) return null;
    return (days / 7).ceil();
  }

  UserData _applyWorkoutPlan(UserData u, AdaptedWorkoutPlan plan) {
    return _clone(u)
      ..weeklyPlan = WeeklyPlan(
        macros: u.weeklyPlan.macros,
        workouts: plan.workouts,
        meals: u.weeklyPlan.meals,
        shoppingList: u.weeklyPlan.shoppingList,
        deliveryOptions: u.weeklyPlan.deliveryOptions,
      );
  }

  ChatResult process(String text, UserData user) {
    final lower = text.toLowerCase();
    var u = user;
    final changes = <String>[];

    final allergyRe = RegExp(r"(?:allergic to|allergy to|i'm allergic to|add allergy)\s+([a-z_\s]+)", caseSensitive: false);
    final allergyMatch = allergyRe.firstMatch(lower);
    if (allergyMatch != null) {
      final raw = allergyMatch.group(1)!.trim().replaceAll(' ', '_');
      final match = AllergyGuard.allAllergenOptions.where((a) => a.contains(raw) || raw.contains(a.replaceAll('_', ' '))).firstOrNull ?? raw;
      u = _clone(u);
      if (!u.allergies.contains(match)) {
        u.allergies = [...u.allergies, match];
        return ChatResult(reply: '✅ Added $match to your allergies. I\'ll block unsafe foods and meals.', updatedUser: u);
      }
      return ChatResult(reply: 'You already have $match listed as an allergy.');
    }

    final customWorkoutRe = RegExp(r'show\s+my\s+custom\s+workout\s+(.+)', caseSensitive: false);
    final customMatch = customWorkoutRe.firstMatch(lower);
    if (customMatch != null) {
      final name = customMatch.group(1)!.trim();
      final w = u.customWorkouts.where((x) => x.name.toLowerCase().contains(name)).firstOrNull;
      if (w != null) {
        return ChatResult(
          reply: '${w.name}:\n${w.exercises.map((e) => '• ${e.name} — ${e.sets}×${e.reps}, rest ${e.restSeconds}s').join('\n')}',
        );
      }
      return ChatResult(reply: 'No custom workout matching "$name". Create one in the Workout tab.');
    }

    if (lower.contains('swap') && (lower.contains('lunch') || lower.contains('breakfast') || lower.contains('dinner') || lower.contains('meal'))) {
      final mealType = lower.contains('breakfast') ? 'Breakfast' : lower.contains('dinner') ? 'Dinner' : 'Lunch';
      final newMeal = MealVarietyService.swapMeal(u, mealType);
      final meals = List<Meal>.from(u.weeklyPlan.meals);
      final idx = meals.indexWhere((m) => m.mealType == mealType);
      if (idx >= 0) {
        meals[idx] = newMeal;
      } else {
        meals.add(newMeal);
      }
      u = _clone(u)
        ..weeklyPlan = WeeklyPlan(
          macros: u.weeklyPlan.macros,
          workouts: u.weeklyPlan.workouts,
          meals: meals,
          shoppingList: u.weeklyPlan.shoppingList,
        );
      MealVarietyService.recordMeal(u, newMeal);
      return ChatResult(
        reply: '✅ Swapped your $mealType to ${newMeal.name} — ${newMeal.description}. Check the Food tab.',
        updatedUser: u,
      );
    }

    if (lower.contains('something different') || lower.contains('shuffle meals') || lower.contains('new meal plan')) {
      final meals = MealVarietyService.generateDailyPlan(u);
      u = _clone(u)
        ..weeklyPlan = WeeklyPlan(
          macros: u.weeklyPlan.macros,
          workouts: u.weeklyPlan.workouts,
          meals: meals,
          shoppingList: u.weeklyPlan.shoppingList,
        );
      return ChatResult(
        reply: '✅ Fresh meal plan:\n${meals.map((m) => '• ${m.mealType}: ${m.name}').join('\n')}',
        updatedUser: u,
      );
    }

    final banRe = RegExp(r'ban\s+(.+)', caseSensitive: false);
    final banMatch = banRe.firstMatch(lower);
    if (banMatch != null) {
      final name = banMatch.group(1)!.trim();
      u = _clone(u)..bannedMeals = [...u.bannedMeals, name];
      return ChatResult(reply: '✅ Banned "$name" from future meal suggestions.', updatedUser: u);
    }

    // "lose 10kg" is a goal — not "my weight is 10kg"
    final lossGoalRe = RegExp(
      r'(?:want\s+to\s+|wanna\s+|trying\s+to\s+|need\s+to\s+)?(?:lose|drop|shed)\s+(\d+(?:\.\d+)?)\s*k?g',
      caseSensitive: false,
    );
    final lossMatch = lossGoalRe.firstMatch(lower);
    if (lossMatch != null) {
      final lossKg = double.parse(lossMatch.group(1)!);
      var currentWeight = user.weight;

      final statedWeightRe = RegExp(
        r'(?:i\s+)?weigh(?:t)?\s+(\d+(?:\.\d+)?)\s*k?g',
        caseSensitive: false,
      );
      final statedMatch = statedWeightRe.firstMatch(lower);
      if (statedMatch != null) {
        currentWeight = double.parse(statedMatch.group(1)!);
      }

      final targetWeight = currentWeight - lossKg;
      u = _clone(user);
      if (statedMatch != null) u.weight = currentWeight;
      u.goal = 'cut';
      final tdee = _calcTdee(u);
      u = _clone(u)
        ..tdee = tdee
        ..weeklyPlan = WeeklyPlan(
          macros: {...u.weeklyPlan.macros, 'calories': tdee},
          workouts: u.weeklyPlan.workouts,
          meals: u.weeklyPlan.meals,
          shoppingList: u.weeklyPlan.shoppingList,
        );

      final weeksNeeded = (lossKg / 0.75).ceil();
      final deadlineWeeks = _weeksUntilDeadline(lower);
      String feasibility;
      if (deadlineWeeks != null) {
        feasibility = deadlineWeeks >= weeksNeeded
            ? 'Losing ${lossKg.toStringAsFixed(0)}kg in $deadlineWeeks weeks is realistic with a steady cut.'
            : 'Losing ${lossKg.toStringAsFixed(0)}kg in $deadlineWeeks weeks is ambitious — aim for ~${(deadlineWeeks * 0.75).toStringAsFixed(0)}kg in that window, or extend the deadline.';
      } else {
        feasibility = 'Aim for ~0.5–1kg per week — about $weeksNeeded weeks for ${lossKg.toStringAsFixed(0)}kg.';
      }

      final weightNote = statedMatch != null ? '✅ Logged your weight as ${currentWeight.toStringAsFixed(0)}kg.\n' : '';
      return ChatResult(
        reply: '${weightNote}✅ Set your goal to cutting — target ~${targetWeight.toStringAsFixed(0)}kg (${lossKg.toStringAsFixed(0)}kg to lose). Daily calories: $tdee kcal.\n$feasibility Want me to generate a cutting workout plan?',
        updatedUser: u,
      );
    }

    final isLossPhrase = RegExp(r'(?:lose|drop|shed|lost|losing)\s+\d', caseSensitive: false).hasMatch(lower);
    if (!isLossPhrase) {
      final weightRe = RegExp(
        r'(?:set\s+(?:my\s+)?weight\s+to|(?:my\s+)?weight\s+(?:is|to|=)|(?:i\s+)?weigh(?:t)?)\s*(\d+(?:\.\d+)?)\s*k?g?',
        caseSensitive: false,
      );
      final weightMatch = weightRe.firstMatch(lower);
      if (weightMatch != null) {
        final w = double.parse(weightMatch.group(1)!);
        if (w >= 35 && w <= 300) {
          u = _clone(u)..weight = w;
          changes.add('weight to ${u.weight}kg');
        }
      }
    }

    final goalRe = RegExp(r'goal\s*(?:to|is|=)?\s*(cut|bulk|maintain)|(cutting|bulking)', caseSensitive: false);
    final goalMatch = goalRe.firstMatch(lower) ?? RegExp(r'(?:change|set).*(cut|bulk|maintain)').firstMatch(lower);
    if (goalMatch != null) {
      var g = goalMatch.group(1) ?? goalMatch.group(2) ?? '';
      if (g == 'cutting') g = 'cut';
      if (g == 'bulking') g = 'bulk';
      if (['cut', 'bulk', 'maintain'].contains(g)) {
        u = _clone(u)..goal = g;
        changes.add("goal to '$g'");
      }
    }

    if (changes.isNotEmpty) {
      final tdee = _calcTdee(u);
      u = _clone(u)
        ..tdee = tdee
        ..weeklyPlan = WeeklyPlan(
          macros: {...u.weeklyPlan.macros, 'calories': tdee},
          workouts: u.weeklyPlan.workouts,
          meals: u.weeklyPlan.meals,
          shoppingList: u.weeklyPlan.shoppingList,
        );
      var reply = '✅ Updated your ${changes.join(' and ')}. Your daily calorie target is now $tdee kcal.';
      if (u.goal == 'cut') reply += ' Want me to generate a cutting workout plan?';
      if (u.goal == 'bulk') reply += ' Want me to generate a bulking workout plan?';
      return ChatResult(reply: reply, updatedUser: u);
    }

    final logFood = RegExp(r'log\s+(\d+(?:\.\d+)?)\s*g?\s+(.+)', caseSensitive: false).firstMatch(text);
    if (logFood != null) {
      final grams = double.parse(logFood.group(1)!);
      final food = logFood.group(2)!.trim();
      final guard = AllergyGuard.checkText(food, UserAllergies.fromUser(u));
      if (!guard.isSafe) {
        return ChatResult(reply: '⚠️ Blocked: $food — ${guard.message}');
      }
      final cal = (grams * 1.65).round();
      final protein = (grams * 0.31).round();
      final carbs = (grams * 0.08).round();
      final fat = (grams * 0.05).round();
      return ChatResult(
        reply: '✅ Logged ${grams}g $food — $cal kcal, P ${protein}g',
        foodLogIntent: FoodLogIntent(
          name: food,
          calories: cal,
          protein: protein,
          carbs: carbs,
          fat: fat,
          grams: grams,
        ),
      );
    }

    if (lower.contains('calories') && (lower.contains('eaten') || lower.contains('today') || lower.contains('how many'))) {
      final logged = u.dailyMacrosLogged.calories;
      final target = u.weeklyPlan.macros['calories'] ?? u.tdee;
      final pct = target > 0 ? ((logged / target) * 100).round() : 0;
      return ChatResult(
        reply: "You've logged $logged kcal today out of your $target kcal target ($pct%).",
      );
    }

    if (lower.contains('allerg') || lower.contains('allergy')) {
      final list = u.allergies.isEmpty ? 'none set' : u.allergies.map((a) => a.replaceAll('_', ' ')).join(', ');
      return ChatResult(reply: 'Your allergies: $list. Say "I\'m allergic to dairy" to add one.');
    }

    if ((lower.contains('today') || lower.contains("today's")) && (lower.contains('workout') || lower.contains('training'))) {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final today = days[DateTime.now().weekday % 7];
      final w = u.weeklyPlan.workouts.where((x) => x.day == today).firstOrNull;
      if (w != null) {
        return ChatResult(
          reply: '$today — ${w.focus}\n${w.exercises.map((e) => '• $e').join('\n')}',
        );
      }
    }

    for (final entry in _dayMap.entries) {
      if (lower.contains(entry.key) && (lower.contains('workout') || lower.contains('training'))) {
        final w = u.weeklyPlan.workouts.where((x) => x.day == entry.value).firstOrNull;
        if (w != null) {
          return ChatResult(
            reply: '${entry.value} — ${w.focus}\n${w.exercises.map((e) => '• $e').join('\n')}',
          );
        }
      }
    }

    final disabilityRe = RegExp(r"(?:i have|add disability|bad knee|knee injury|back pain|shoulder injury|wheelchair|limited mobility)", caseSensitive: false);
    if (disabilityRe.hasMatch(lower)) {
      final tag = HealthSafetyService.parseDisabilityTag(lower);
      if (tag != null) {
        u = _clone(u);
        if (!u.disabilities.contains(tag)) {
          u.disabilities = [...u.disabilities, tag];
        }
        final plan = WorkoutAdaptationService.buildWeeklyPlan(u);
        u = _applyWorkoutPlan(u, plan);
        return ChatResult(
          reply: '✅ Added ${HealthSafetyService.disabilityLabels[tag] ?? tag} to your profile and adapted your workout.\n${WorkoutAdaptationService.formatReply(plan)}',
          updatedUser: u,
        );
      }
    }

    if (RegExp(r'(change|update|modify|adapt|new)\s+(?:my\s+)?workout', caseSensitive: false).hasMatch(lower) ||
        (lower.contains('workout') && (lower.contains('change') || lower.contains('adapt') || lower.contains('modify')))) {
      final plan = WorkoutAdaptationService.buildWeeklyPlan(u);
      u = _applyWorkoutPlan(u, plan);
      return ChatResult(reply: WorkoutAdaptationService.formatReply(plan), updatedUser: u);
    }

    if (lower.contains('high') && lower.contains('protein') || lower.contains('meal plan') || lower.contains('generate') && lower.contains('meal')) {
      final protein = (u.weight * 2).round();
      final meals = MealVarietyService.generateDailyPlan(u);
      u = _clone(u)
        ..weeklyPlan = WeeklyPlan(
          macros: {'calories': u.tdee, 'protein': protein, 'carbs': 200, 'fat': 65},
          workouts: u.weeklyPlan.workouts,
          meals: meals,
          shoppingList: u.weeklyPlan.shoppingList,
        );
      return ChatResult(
        reply: "Here's your allergy-safe high-protein plan (~${protein}g protein):\n${meals.map((m) => '• ${m.mealType}: ${m.name}').join('\n')}",
        updatedUser: u,
      );
    }

    if (lower.contains('generate') || lower.contains('yes') && lower.contains('plan') || lower.contains('workout plan') || lower.contains('upper')) {
      final plan = WorkoutAdaptationService.buildWeeklyPlan(u);
      u = _applyWorkoutPlan(u, plan);
      return ChatResult(reply: WorkoutAdaptationService.formatReply(plan), updatedUser: u);
    }

    if (RegExp(r'^(hi|hello|hey)').hasMatch(lower)) {
      return ChatResult(
        reply: "Hey! I'm your AI coach. Try:\n• Set my weight to 72kg\n• Swap my lunch\n• I'm allergic to shellfish\n• Log 200g chicken breast",
      );
    }

    return ChatResult(
      reply: 'I can update your profile, show workouts, track calories, swap meals, or manage allergies. Try: "Swap my lunch" or "I\'m allergic to dairy"',
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
