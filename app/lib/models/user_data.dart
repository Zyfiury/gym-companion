import 'dart:convert';

import '../services/shopping_list_service.dart';
import '../services/store_service.dart';

class MacroLog {
  int calories;
  int protein;
  int carbs;
  int fat;

  MacroLog({this.calories = 0, this.protein = 0, this.carbs = 0, this.fat = 0});

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory MacroLog.fromJson(Map<String, dynamic> j) => MacroLog(
        calories: j['calories'] as int? ?? 0,
        protein: j['protein'] as int? ?? 0,
        carbs: j['carbs'] as int? ?? 0,
        fat: j['fat'] as int? ?? 0,
      );
}

class WorkoutDay {
  final String day;
  final String focus;
  final List<String> exercises;

  WorkoutDay({required this.day, required this.focus, required this.exercises});

  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
        day: j['day'] as String,
        focus: j['focus'] as String,
        exercises: (j['exercises'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() =>
      {'day': day, 'focus': focus, 'exercises': exercises};
}

class Meal {
  final String mealType;
  final String name;
  final String description;
  final Map<String, int> macros;
  final String? youtubeVideoId;
  final List<String> steps;
  final List<String> ingredients;

  Meal({
    required this.mealType,
    required this.name,
    required this.description,
    required this.macros,
    this.youtubeVideoId,
    this.steps = const [],
    this.ingredients = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        mealType: j['mealType'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        macros: Map<String, int>.from(
          (j['macros'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        ),
        youtubeVideoId: j['youtubeVideoId'] as String?,
        steps: (j['steps'] as List?)?.cast<String>() ?? [],
        ingredients: (j['ingredients'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'mealType': mealType,
        'name': name,
        'description': description,
        'macros': macros,
        'youtubeVideoId': youtubeVideoId,
        'steps': steps,
        'ingredients': ingredients,
      };
}

class CustomExercise {
  String name;
  int sets;
  int reps;
  int restSeconds;

  CustomExercise({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds = 60,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
      };

  factory CustomExercise.fromJson(Map<String, dynamic> j) => CustomExercise(
        name: j['name'] as String? ?? '',
        sets: j['sets'] as int? ?? 3,
        reps: j['reps'] as int? ?? 10,
        restSeconds: j['restSeconds'] as int? ?? 60,
      );
}

class CustomWorkout {
  String id;
  String name;
  List<CustomExercise> exercises;
  bool isActive;
  List<String> completedToday;

  CustomWorkout({
    required this.id,
    required this.name,
    this.exercises = const [],
    this.isActive = false,
    this.completedToday = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'isActive': isActive,
        'completedToday': completedToday,
      };

  factory CustomWorkout.fromJson(Map<String, dynamic> j) => CustomWorkout(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        exercises: (j['exercises'] as List?)
                ?.map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: j['isActive'] as bool? ?? false,
        completedToday: (j['completedToday'] as List?)?.cast<String>() ?? [],
      );
}

class MonthlyPlan {
  List<Meal> meals;
  Map<String, dynamic>? shoppingList;
  String? supermarket;
  String startDate;

  MonthlyPlan({
    this.meals = const [],
    this.shoppingList,
    this.supermarket,
    String? startDate,
  }) : startDate = startDate ?? DateTime.now().toIso8601String().substring(0, 10);

  Map<String, dynamic> toJson() => {
        'meals': meals.map((m) => m.toJson()).toList(),
        if (shoppingList != null) 'shoppingList': shoppingList,
        if (supermarket != null) 'supermarket': supermarket,
        'startDate': startDate,
      };

  factory MonthlyPlan.fromJson(Map<String, dynamic> j) => MonthlyPlan(
        meals: (j['meals'] as List?)?.map((e) => Meal.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        shoppingList: j['shoppingList'] as Map<String, dynamic>?,
        supermarket: j['supermarket'] as String?,
        startDate: j['startDate'] as String?,
      );
}

class WeeklyPlan {
  Map<String, int> macros;
  List<WorkoutDay> workouts;
  List<Meal> meals;
  Map<String, dynamic>? shoppingList;
  List<Map<String, dynamic>>? deliveryOptions;

  WeeklyPlan({
    required this.macros,
    required this.workouts,
    required this.meals,
    this.shoppingList,
    this.deliveryOptions,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> j) => WeeklyPlan(
        macros: Map<String, int>.from(
          (j['macros'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        ),
        workouts: (j['workouts'] as List)
            .map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        meals: (j['meals'] as List?)
                ?.map((e) => Meal.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        shoppingList: j['shoppingList'] as Map<String, dynamic>?,
        deliveryOptions: (j['deliveryOptions'] as List?)?.cast<Map<String, dynamic>>(),
      );

  Map<String, dynamic> toJson() => {
        'macros': macros,
        'workouts': workouts.map((w) => w.toJson()).toList(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'shoppingList': shoppingList,
        if (deliveryOptions != null) 'deliveryOptions': deliveryOptions,
      };
}

class UserData {
  String userId;
  bool profileComplete;
  String? avatarPath;
  String goal;
  double weight;
  double height;
  int age;
  int tdee;
  double weeklyBudget;
  String nutritionMode;
  String dietaryRestrictions;
  List<String> allergies;
  List<String> excludedIngredients;
  String dietType;
  String mealVariety;
  List<String> bannedMeals;
  List<Map<String, dynamic>> recentMeals;
  List<Map<String, dynamic>> favouriteMeals;
  WeeklyPlan weeklyPlan;
  MacroLog dailyMacrosLogged;
  double budgetSpent;
  List<Map<String, dynamic>> weightHistory;
  List<Map<String, dynamic>> personalRecords;
  List<Map<String, dynamic>> foodLog;
  Map<String, dynamic> gamification;
  double steps;
  double water;
  String genderAtBirth;
  List<String> disabilities;
  bool pregnant;
  List<String> medications;
  bool tracksPeriod;
  String? periodPhase;
  List<String> dietaryPreferences;
  Map<String, dynamic> onboardingAnswers;
  List<CustomWorkout> customWorkouts;
  MonthlyPlan? monthlyPlan;
  List<String> mealsLoggedToday;
  String mealsLoggedDate;

  UserData({
    this.userId = '',
    this.profileComplete = false,
    this.avatarPath,
    this.goal = '',
    this.weight = 70,
    this.height = 175,
    this.age = 30,
    this.tdee = 2200,
    this.weeklyBudget = 50,
    this.nutritionMode = 'cook_myself',
    this.dietaryRestrictions = 'none',
    this.allergies = const [],
    this.excludedIngredients = const [],
    this.dietType = 'omnivore',
    this.mealVariety = 'rotate',
    this.bannedMeals = const [],
    this.recentMeals = const [],
    this.favouriteMeals = const [],
    required this.weeklyPlan,
    MacroLog? dailyMacrosLogged,
    this.budgetSpent = 0,
    List<Map<String, dynamic>>? weightHistory,
    this.personalRecords = const [],
    this.foodLog = const [],
    Map<String, dynamic>? gamification,
    this.steps = 0,
    this.water = 0,
    this.genderAtBirth = 'prefer_not_to_say',
    this.disabilities = const [],
    this.pregnant = false,
    this.medications = const [],
    this.tracksPeriod = false,
    this.periodPhase,
    this.dietaryPreferences = const [],
    Map<String, dynamic>? onboardingAnswers,
    List<CustomWorkout>? customWorkouts,
    this.monthlyPlan,
    List<String>? mealsLoggedToday,
    String? mealsLoggedDate,
  })  : onboardingAnswers = onboardingAnswers ?? {},
        customWorkouts = customWorkouts ?? [],
        mealsLoggedToday = mealsLoggedToday ?? [],
        mealsLoggedDate = mealsLoggedDate ?? '',
        dailyMacrosLogged = dailyMacrosLogged ?? MacroLog(),
        gamification = gamification ??
            {'xp': 0, 'level': 1, 'streak': 0, 'achievements': <String>[], 'freeMessagesRemaining': 10},
        weightHistory = weightHistory ?? [];

  factory UserData.defaults() {
    final meals = [
      Meal(
        mealType: 'Breakfast',
        name: 'Greek Yogurt Bowl',
        description: 'High protein start',
        macros: {'calories': 420, 'protein': 35, 'carbs': 45, 'fat': 10},
        ingredients: ['greek yogurt', 'berries', 'oats'],
        youtubeVideoId: 'dQw4w9WgXcQ',
        steps: ['Add yogurt to a bowl', 'Top with berries and oats'],
      ),
      Meal(
        mealType: 'Lunch',
        name: 'Chicken Rice Bowl',
        description: 'Balanced midday meal',
        macros: {'calories': 650, 'protein': 45, 'carbs': 70, 'fat': 18},
        ingredients: ['chicken breast', 'rice', 'broccoli'],
        youtubeVideoId: 'dQw4w9WgXcQ',
        steps: ['Grill chicken breast', 'Cook rice', 'Steam broccoli and serve together'],
      ),
      Meal(
        mealType: 'Dinner',
        name: 'Salmon & Quinoa',
        description: 'Omega-3 dinner',
        macros: {'calories': 520, 'protein': 42, 'carbs': 40, 'fat': 18},
        ingredients: ['salmon', 'quinoa', 'asparagus'],
        youtubeVideoId: 'dQw4w9WgXcQ',
        steps: ['Pan-sear salmon', 'Cook quinoa', 'Roast asparagus and plate up'],
      ),
    ];
    final shoppingList = ShoppingListService.buildFromMeals(meals, store: StoreService.defaultLabel);
    return UserData(
      weeklyPlan: WeeklyPlan(
        macros: {'calories': 2200, 'protein': 140, 'carbs': 220, 'fat': 65},
        workouts: [
          WorkoutDay(day: 'Mon', focus: 'Push', exercises: ['Bench Press 4×8', 'OHP 3×10', 'Tricep Pushdown 3×12']),
          WorkoutDay(day: 'Tue', focus: 'Pull', exercises: ['Deadlift 4×5', 'Rows 4×10', 'Face Pulls 3×15']),
          WorkoutDay(day: 'Wed', focus: 'Legs', exercises: ['Squat 4×8', 'RDL 3×10', 'Leg Curl 3×12']),
          WorkoutDay(day: 'Thu', focus: 'Push', exercises: ['Incline DB 4×10', 'Lateral Raise 3×15']),
          WorkoutDay(day: 'Fri', focus: 'Pull', exercises: ['Pull-ups 4×AMRAP', 'Curls 3×12']),
          WorkoutDay(day: 'Sat', focus: 'Legs', exercises: ['Leg Press 4×12', 'Calf Raise 4×15']),
          WorkoutDay(day: 'Sun', focus: 'Rest', exercises: ['Walk 30 min', 'Stretch 15 min']),
        ],
        meals: meals,
        shoppingList: shoppingList,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'profileComplete': profileComplete,
        if (avatarPath != null) 'avatarPath': avatarPath,
        'goal': goal,
        'weight': weight,
        'height': height,
        'age': age,
        'tdee': tdee,
        'weeklyBudget': weeklyBudget,
        'nutritionMode': nutritionMode,
        'dietaryRestrictions': dietaryRestrictions,
        'allergies': allergies,
        'excludedIngredients': excludedIngredients,
        'dietType': dietType,
        'mealVariety': mealVariety,
        'bannedMeals': bannedMeals,
        'recentMeals': recentMeals,
        'favouriteMeals': favouriteMeals,
        'weeklyPlan': weeklyPlan.toJson(),
        'dailyMacrosLogged': dailyMacrosLogged.toJson(),
        'budgetSpent': budgetSpent,
        'weightHistory': weightHistory,
        'personalRecords': personalRecords,
        'foodLog': foodLog,
        'gamification': gamification,
        'quickStats': {'steps': steps, 'water': water},
        'genderAtBirth': genderAtBirth,
        'disabilities': disabilities,
        'pregnant': pregnant,
        'medications': medications,
        'tracksPeriod': tracksPeriod,
        if (periodPhase != null) 'periodPhase': periodPhase,
        'dietaryPreferences': dietaryPreferences,
        'onboardingAnswers': onboardingAnswers,
        'customWorkouts': customWorkouts.map((w) => w.toJson()).toList(),
        if (monthlyPlan != null) 'monthlyPlan': monthlyPlan!.toJson(),
        'mealsLoggedToday': mealsLoggedToday,
        'mealsLoggedDate': mealsLoggedDate,
      };

  factory UserData.fromJson(Map<String, dynamic> j) {
    final qs = j['quickStats'] as Map<String, dynamic>?;
    return UserData(
      userId: j['userId'] as String? ?? '',
      profileComplete: j['profileComplete'] as bool? ?? false,
      avatarPath: j['avatarPath'] as String?,
      goal: j['goal'] as String? ?? '',
      weight: (j['weight'] as num?)?.toDouble() ?? 70,
      height: (j['height'] as num?)?.toDouble() ?? 175,
      age: j['age'] as int? ?? 30,
      tdee: j['tdee'] as int? ?? 2200,
      weeklyBudget: (j['weeklyBudget'] as num?)?.toDouble() ?? 50,
      nutritionMode: j['nutritionMode'] as String? ?? 'cook_myself',
      dietaryRestrictions: j['dietaryRestrictions'] as String? ?? 'none',
      allergies: (j['allergies'] as List?)?.cast<String>() ?? [],
      excludedIngredients: (j['excludedIngredients'] as List?)?.cast<String>() ?? [],
      dietType: j['dietType'] as String? ?? 'omnivore',
      mealVariety: j['mealVariety'] as String? ?? 'rotate',
      bannedMeals: (j['bannedMeals'] as List?)?.cast<String>() ?? [],
      recentMeals: (j['recentMeals'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      favouriteMeals:
          (j['favouriteMeals'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      weeklyPlan: WeeklyPlan.fromJson(j['weeklyPlan'] as Map<String, dynamic>),
      dailyMacrosLogged: MacroLog.fromJson(
        j['dailyMacrosLogged'] as Map<String, dynamic>? ?? {},
      ),
      budgetSpent: (j['budgetSpent'] as num?)?.toDouble() ?? 0,
      weightHistory:
          (j['weightHistory'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      personalRecords:
          (j['personalRecords'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      foodLog: (j['foodLog'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      gamification: (j['gamification'] as Map<String, dynamic>?) ?? {'xp': 0, 'level': 1, 'streak': 0},
      steps: (qs?['steps'] as num?)?.toDouble() ?? 0,
      water: (qs?['water'] as num?)?.toDouble() ?? 0,
      genderAtBirth: j['genderAtBirth'] as String? ?? 'prefer_not_to_say',
      disabilities: (j['disabilities'] as List?)?.cast<String>() ?? [],
      pregnant: j['pregnant'] as bool? ?? false,
      medications: (j['medications'] as List?)?.cast<String>() ?? [],
      tracksPeriod: j['tracksPeriod'] as bool? ?? false,
      periodPhase: j['periodPhase'] as String?,
      dietaryPreferences: (j['dietaryPreferences'] as List?)?.cast<String>() ?? [],
      onboardingAnswers: (j['onboardingAnswers'] as Map<String, dynamic>?) ?? {},
      customWorkouts: (j['customWorkouts'] as List?)
              ?.map((e) => CustomWorkout.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyPlan: j['monthlyPlan'] != null
          ? MonthlyPlan.fromJson(j['monthlyPlan'] as Map<String, dynamic>)
          : null,
      mealsLoggedToday: (j['mealsLoggedToday'] as List?)?.cast<String>() ?? [],
      mealsLoggedDate: j['mealsLoggedDate'] as String? ?? '',
    );
  }

  int get freeMessagesRemaining => gamification['freeMessagesRemaining'] as int? ?? 10;

  void resetMealsLoggedIfNewDay() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (mealsLoggedDate != today) {
      mealsLoggedToday = [];
      mealsLoggedDate = today;
    }
  }

  bool isMealLogged(String mealType) {
    resetMealsLoggedIfNewDay();
    return mealsLoggedToday.contains(mealType);
  }

  CustomWorkout? get activeCustomWorkout {
    for (final w in customWorkouts) {
      if (w.isActive) return w;
    }
    return null;
  }

  String encode() => jsonEncode(toJson());

  static UserData decode(String s) =>
      UserData.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime ts;
  final List<Map<String, dynamic>>? deliveryOptions;
  final String? actionChip;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? ts,
    this.deliveryOptions,
    this.actionChip,
  }) : ts = ts ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'ts': ts.toIso8601String(),
        if (deliveryOptions != null) 'deliveryOptions': deliveryOptions,
        if (actionChip != null) 'actionChip': actionChip,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role'] as String,
        content: j['content'] as String,
        ts: DateTime.tryParse(j['ts'] as String? ?? '') ?? DateTime.now(),
        deliveryOptions: (j['deliveryOptions'] as List?)?.cast<Map<String, dynamic>>(),
        actionChip: j['actionChip'] as String?,
      );
}
