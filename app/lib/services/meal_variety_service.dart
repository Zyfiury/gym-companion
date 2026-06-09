import '../models/user_data.dart';
import 'allergy_guard.dart';
import 'health_safety_service.dart';
import 'youtube_service.dart';

class MealVarietyService {
  static final _pool = <String, List<_MealTemplate>>{
    'Breakfast': [
      _MealTemplate('Greek Yogurt Bowl', 'High protein start', ['greek yogurt', 'berries', 'oats'], {'calories': 420, 'protein': 35, 'carbs': 45, 'fat': 10}),
      _MealTemplate('Protein Oats', 'Warm filling breakfast', ['oats', 'whey protein', 'banana'], {'calories': 450, 'protein': 40, 'carbs': 50, 'fat': 12}),
      _MealTemplate('Egg White Scramble', 'Lean morning protein', ['egg whites', 'spinach', 'tomato'], {'calories': 280, 'protein': 32, 'carbs': 8, 'fat': 10}),
      _MealTemplate('Tofu Breakfast Bowl', 'Plant-based start', ['tofu', 'quinoa', 'avocado'], {'calories': 380, 'protein': 28, 'carbs': 35, 'fat': 14}),
      _MealTemplate('Smoked Salmon Bagel', 'Omega-3 breakfast', ['smoked salmon', 'bagel', 'cream cheese'], {'calories': 480, 'protein': 30, 'carbs': 42, 'fat': 18}),
    ],
    'Lunch': [
      _MealTemplate('Chicken Rice Bowl', 'Balanced midday meal', ['chicken breast', 'brown rice', 'broccoli'], {'calories': 650, 'protein': 45, 'carbs': 70, 'fat': 18}),
      _MealTemplate('Turkey Wrap', 'Quick lean lunch', ['turkey', 'whole wheat wrap', 'lettuce'], {'calories': 520, 'protein': 42, 'carbs': 48, 'fat': 14}),
      _MealTemplate('Tuna Salad', 'Light high-protein', ['tuna', 'mixed greens', 'olive oil'], {'calories': 400, 'protein': 38, 'carbs': 12, 'fat': 20}),
      _MealTemplate('Lentil Buddha Bowl', 'Vegan protein bowl', ['lentils', 'sweet potato', 'kale'], {'calories': 490, 'protein': 28, 'carbs': 65, 'fat': 12}),
      _MealTemplate('Beef Stir Fry', 'Iron-rich lunch', ['lean beef', 'peppers', 'rice noodles'], {'calories': 580, 'protein': 40, 'carbs': 55, 'fat': 16}),
    ],
    'Dinner': [
      _MealTemplate('Salmon & Quinoa', 'Omega-3 dinner', ['salmon', 'quinoa', 'asparagus'], {'calories': 520, 'protein': 42, 'carbs': 40, 'fat': 18}),
      _MealTemplate('Grilled Chicken & Veg', 'Simple clean dinner', ['chicken thigh', 'zucchini', 'rice'], {'calories': 550, 'protein': 48, 'carbs': 45, 'fat': 15}),
      _MealTemplate('Cod with Roasted Potatoes', 'Light white fish', ['cod', 'potato', 'green beans'], {'calories': 460, 'protein': 40, 'carbs': 42, 'fat': 10}),
      _MealTemplate('Chickpea Curry', 'Plant protein dinner', ['chickpeas', 'coconut milk', 'rice'], {'calories': 510, 'protein': 22, 'carbs': 68, 'fat': 16}),
      _MealTemplate('Pork Tenderloin & Salad', 'Lean pork dinner', ['pork tenderloin', 'mixed salad', 'balsamic'], {'calories': 480, 'protein': 44, 'carbs': 20, 'fat': 22}),
    ],
  };

  static Meal pickMeal(String mealType, UserData user, {String? excludeName}) {
    final prefs = UserAllergies.fromUser(user);
    final templates = _pool[mealType] ?? _pool['Lunch']!;
    final recent = user.recentMeals.map((m) => (m['name'] as String).toLowerCase()).toSet();
    final banned = user.bannedMeals.map((b) => b.toLowerCase()).toSet();

    final scored = <(_MealTemplate, int)>[];
    for (final t in templates) {
      if (excludeName != null && t.name.toLowerCase() == excludeName.toLowerCase()) continue;
      if (banned.contains(t.name.toLowerCase())) continue;
      final guard = AllergyGuard.checkMeal(name: t.name, description: t.description, ingredients: t.ingredients, prefs: prefs);
      if (!guard.isSafe) continue;

      var score = 0;
      if (recent.contains(t.name.toLowerCase())) score -= 50;
      if (!recent.contains(t.name.toLowerCase())) score += 25;
      if (user.favouriteMeals.any((f) => (f['name'] as String?)?.toLowerCase() == t.name.toLowerCase())) score += 30;
      scored.add((t, score));
    }

    if (scored.isEmpty) {
      final fallback = templates.first;
      return _toMeal(fallback, mealType, user);
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return _toMeal(scored.first.$1, mealType, user);
  }

  static List<Meal> generateDailyPlan(UserData user) {
    return [
      pickMeal('Breakfast', user),
      pickMeal('Lunch', user),
      pickMeal('Dinner', user),
    ];
  }

  static Meal swapMeal(UserData user, String mealType) {
    final current = user.weeklyPlan.meals.where((m) => m.mealType == mealType).firstOrNull;
    return pickMeal(mealType, user, excludeName: current?.name);
  }

  static void recordMeal(UserData user, Meal meal) {
    final recent = List<Map<String, dynamic>>.from(user.recentMeals);
    recent.add({
      'name': meal.name,
      'mealType': meal.mealType,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
    user.recentMeals = recent.length > 30 ? recent.sublist(recent.length - 30) : recent;
  }

  static Meal _toMeal(_MealTemplate t, String mealType, UserData user) {
    var desc = t.description;
    final hint = HealthSafetyService.periodNutritionHint(user);
    if (hint != null) desc = '$desc — $hint';
    return Meal(
      mealType: mealType,
      name: t.name,
      description: desc,
      macros: t.macros,
      ingredients: t.ingredients,
      steps: _cookingSteps(t),
    );
  }

  static List<String> _cookingSteps(_MealTemplate t) => [
        'Gather: ${t.ingredients.take(3).join(', ')}',
        'Prep and season ingredients',
        'Cook ${t.name} until done',
        'Plate up — 1 serving (~${t.macros['calories']} kcal)',
      ];

  static Future<Meal> enrichWithVideo(Meal meal) async {
    if (meal.youtubeVideoId != null) return meal;
    try {
      if (!YouTubeService.hasKey) return meal;
    } catch (_) {
      return meal;
    }
    final video = await YouTubeService.getRecipeVideo(meal.name);
    if (video == null) return meal;
    return Meal(
      mealType: meal.mealType,
      name: meal.name,
      description: meal.description,
      macros: meal.macros,
      youtubeVideoId: video.videoId,
      steps: meal.steps,
      ingredients: meal.ingredients,
    );
  }

  static int nutritionScore(Map<String, int> macros) {
    final p = macros['protein'] ?? 0;
    final c = macros['calories'] ?? 0;
    if (c == 0) return 50;
    final ratio = p / (c / 100);
    return (50 + ratio * 8).round().clamp(40, 99);
  }
}

class _MealTemplate {
  final String name;
  final String description;
  final List<String> ingredients;
  final Map<String, int> macros;

  _MealTemplate(this.name, this.description, this.ingredients, this.macros);
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
