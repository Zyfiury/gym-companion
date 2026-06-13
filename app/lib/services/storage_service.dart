import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import 'meal_variety_service.dart';

class StorageService {
  static const _themeKey = 'gymapp_theme';
  static const _coachPeriodKey = 'coachContextPeriod';
  static const _coachOpenerDateKey = 'coachOpenerDate';

  String _userKey(String userId) => 'gymapp_user_$userId';
  String _chatKey(String userId) => 'gymapp_chat_$userId';
  String _feedKey() => 'gymapp_global_feed';

  Future<UserData> loadUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey(userId));
    if (raw == null) return _defaultForUser(userId);
    try {
      var data = UserData.decode(raw);
      if (userId == 'user_test_001' && data.allergies.isEmpty) {
        data.allergies = ['dairy'];
        data.mealVariety = 'rotate';
        data.weeklyPlan = WeeklyPlan(
          macros: data.weeklyPlan.macros,
          workouts: data.weeklyPlan.workouts,
          meals: MealVarietyService.generateDailyPlan(data),
          shoppingList: data.weeklyPlan.shoppingList,
        );
        await saveUser(userId, data);
      }
      return data;
    } catch (_) {
      return _defaultForUser(userId);
    }
  }

  UserData _defaultForUser(String userId) {
    final u = UserData.defaults();
    u.userId = userId;
    if (userId == 'user_test_001') {
      u.profileComplete = true;
      u.goal = 'cut';
      u.weight = 72;
      u.tdee = 2100;
      u.allergies = ['dairy'];
      u.mealVariety = 'rotate';
      u.gamification = {'xp': 125, 'level': 2, 'streak': 5, 'achievements': ['first_barcode']};
      u.foodLog = [
        {'date': DateTime.now().toIso8601String().substring(0, 10), 'food': 'Chicken breast', 'calories': 330, 'protein': 62},
      ];
      u.dailyMacrosLogged = MacroLog(calories: 330, protein: 62, carbs: 0, fat: 7);
      u.weeklyPlan = WeeklyPlan(
        macros: {'calories': 2100, 'protein': 140, 'carbs': 200, 'fat': 60},
        workouts: u.weeklyPlan.workouts,
        meals: MealVarietyService.generateDailyPlan(u),
        shoppingList: u.weeklyPlan.shoppingList,
      );
    } else if (userId == 'user_alex_003') {
      u.profileComplete = true;
      u.goal = 'bulk';
      u.weight = 80;
      u.tdee = 2800;
      u.gamification = {'xp': 320, 'level': 3, 'streak': 12, 'achievements': ['workout_10', 'first_pr']};
    } else if (userId == 'user_demo_002') {
      u.profileComplete = false;
    }
    return u;
  }

  Future<void> saveUser(String userId, UserData data) async {
    final prefs = await SharedPreferences.getInstance();
    data.userId = userId;
    await prefs.setString(_userKey(userId), data.encode());
  }

  Future<void> clearUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey(userId));
    await prefs.remove(_chatKey(userId));
  }

  Future<List<ChatMessage>> loadChat(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatKey(userId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveChat(String userId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = messages.length > 100 ? messages.sublist(messages.length - 100) : messages;
    await prefs.setString(_chatKey(userId), jsonEncode(trimmed.map((m) => m.toJson()).toList()));
  }

  Future<List<Map<String, dynamic>>> loadFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedKey());
    if (raw == null) return _defaultFeed();
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveFeed(List<Map<String, dynamic>> posts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedKey(), jsonEncode(posts));
  }

  List<Map<String, dynamic>> _defaultFeed() => [];

  Future<bool> isDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true;
  }

  Future<void> setDarkTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, dark);
  }

  Future<String> getCoachContextPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_coachPeriodKey) ?? 'day';
  }

  Future<void> setCoachContextPeriod(String period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coachPeriodKey, period);
  }

  Future<String?> getCoachOpenerDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_coachOpenerDateKey);
  }

  Future<void> setCoachOpenerDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coachOpenerDateKey, date);
  }
}
