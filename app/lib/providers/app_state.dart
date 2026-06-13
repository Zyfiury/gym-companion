import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/release_config.dart';
import '../constants/xp_rewards.dart';
import '../models/pending_celebrations.dart';
import '../models/today_activity_log.dart';
import '../models/user_data.dart';
import '../models/workout_session.dart';
import '../models/workout_status.dart';
import '../models/weekly_goal.dart';
import '../models/progression_event.dart';
import '../services/progressive_overload_service.dart';
import '../services/recovery_adjustment_service.dart';
import '../widgets/water_logger_sheet.dart';
import '../services/auth_service.dart' show AuthService, TestAccounts;
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/avatar_service.dart';
import '../services/backend_config.dart';
import '../services/chat_service.dart';
import '../services/coach_personality_service.dart';
import '../services/delivery_service.dart';
import '../services/firebase_service.dart';
import '../services/groq_chat_service.dart';
import '../services/meal_variety_service.dart';
import '../services/openclaw_service.dart';
import '../services/plan_agent_service.dart';
import '../services/daily_context_builder.dart';
import '../services/shopping_list_service.dart';
import '../services/storage_service.dart';
import '../services/store_service.dart';
import '../services/subscription_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/cheap_meal_plan_service.dart';
import '../services/user_md_sync_service.dart';
import '../services/vision_calorie_service.dart';
import '../services/health_service.dart';
import '../services/activity_calorie_service.dart';
import '../services/tdee_service.dart';
import '../utils/personal_record_helper.dart';
import '../utils/weight_history.dart';
import '../services/workout_adaptation_service.dart';
import '../services/achievement_service.dart';
import '../services/location_service.dart';
import '../services/fun_facts_service.dart';
import '../utils/macro_helpers.dart';
import '../utils/meal_type_helper.dart';
import '../services/notification_service.dart';

enum BackendMode { firebase, supabase, local }

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  final ChatService _rulesChat = ChatService();

  Map<String, String>? session;
  UserData? user;
  List<ChatMessage> chatMessages = [];
  List<Map<String, dynamic>> feedPosts = [];
  bool loading = true;
  bool chatTyping = false;
  bool isDark = true;
  int tabIndex = 0;
  BackendMode backend = BackendMode.local;
  StreamSubscription? _feedSubscription;
  bool shouldShowLocationPrompt = false;

  /// Cached Pro status - avoids RevenueCat flicker on every screen.
  bool isPro = false;
  bool isProResolved = false;
  int? pendingLevelUp;
  String? pendingXpToast;
  String? lastChatFailedMessage;
  FunFact? freshFunFact;
  final Map<String, SessionLog?> _exerciseHistoryCache = {};

  Future<void> refreshProStatus() async {
    isPro = await SubscriptionService.isPro();
    isProResolved = true;
    notifyListeners();
  }

  void clearPendingXpToast() {
    pendingXpToast = null;
  }

  void clearPendingLevelUp() {
    pendingLevelUp = null;
  }

  void clearFreshFunFact() {
    freshFunFact = null;
    notifyListeners();
  }

  void _maybeSetFreshFunFact(FunFact? fact) {
    if (fact != null) {
      freshFunFact = fact;
    }
  }

  static String exerciseId(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  Future<SessionLog?> fetchLastExerciseSession(String exerciseName) async {
    final id = exerciseId(exerciseName);
    if (_exerciseHistoryCache.containsKey(id)) return _exerciseHistoryCache[id];
    if (!useFirebase || userId == null) return null;
    final raw = await FirebaseService.getLastExerciseSession(userId!, id);
    if (raw == null) {
      _exerciseHistoryCache[id] = null;
      return null;
    }
    final setsRaw = raw['sets'] as List? ?? [];
    final sets = setsRaw.map((s) {
      final m = Map<String, dynamic>.from(s as Map);
      return SetLog(
        reps: (m['reps'] as num?)?.round() ?? 0,
        weightKg: (m['weight'] as num?)?.toDouble(),
        targetReps: (m['reps'] as num?)?.round() ?? 0,
      );
    }).toList();
    final session = SessionLog(date: raw['date'] as String? ?? '', sets: sets);
    _exerciseHistoryCache[id] = session;
    return session;
  }

  void _recordDailyActivity() {
    if (user == null) return;
    final g = Map<String, dynamic>.from(user!.gamification);
    final today = _todayKey();
    g['lastActiveDate'] = today;
    user!.gamification = g;
  }

  void evaluateStreakOnLaunch() {
    if (user == null) return;
    final g = Map<String, dynamic>.from(user!.gamification);
    final today = _todayKey();
    final last = g['lastActiveDate'] as String?;
    if (last == null || last == today) return;
    final lastDate = DateTime.tryParse(last);
    final todayDate = DateTime.parse(today);
    if (lastDate == null) return;
    final gap = todayDate.difference(lastDate).inDays;
    if (gap > 1) {
      final streak = g['streak'] as int? ?? 0;
      if (streak > 0) {
        final freezes = g['streakFreezes'] as int? ?? 0;
        if (freezes > 0 && gap == 2) {
          g['streakFreezes'] = freezes - 1;
        } else {
          g['streak'] = 0;
        }
      }
    }
    user!.gamification = g;
  }

  bool get useFirebase => backend == BackendMode.firebase;
  bool get useSupabase => backend == BackendMode.supabase;

  String? get userId => session?['userId'];
  String? get displayName => session?['displayName'];

  Future<void> init() async {
    try {
      await SyncService.startListening();

      if (BackendConfig.hasFirebase && FirebaseService.currentUser != null) {
        backend = BackendMode.firebase;
      } else if (BackendConfig.hasSupabase && SupabaseService.currentUser != null) {
        backend = BackendMode.supabase;
      } else if (ReleaseConfig.allowLocalAuth) {
        backend = BackendMode.local;
        await _auth.seedTestAccountsIfNeeded();
      }

      isDark = await _storage.isDarkTheme();
      coachContextPeriod = await _storage.getCoachContextPeriod();
      _coachOpenerDate = await _storage.getCoachOpenerDate();

      if (useFirebase) {
        final u = FirebaseService.currentUser!;
        session = {
          'userId': u.uid,
          'email': u.email ?? '',
          'displayName': u.displayName ?? u.email?.split('@').first ?? 'Athlete',
        };
        await SubscriptionService.linkUser(u.uid);
        await _loadUserData(u.uid);
      } else if (useSupabase) {
        final u = SupabaseService.currentUser!;
        session = {'userId': u.id, 'email': u.email ?? '', 'displayName': u.email?.split('@').first ?? 'Athlete'};
        await _loadUserData(u.id);
      } else {
        session = await _auth.getSession();
        if (session != null) await _loadUserData(session!['userId']!);
      }
    } catch (e, st) {
      debugPrint('AppState init failed: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
    if (useFirebase) {
      user = await FirebaseService.loadUserData(uid) ?? UserData.defaults()..userId = uid;
      feedPosts = await FirebaseService.getFeedPosts();
      _subscribeFeedRealtime();
      chatMessages = await FirebaseService.loadChat(uid);
    } else if (useSupabase) {
      user = await SupabaseService.loadUserData() ?? UserData.defaults()..userId = uid;
      feedPosts = await SupabaseService.getFeedPosts();
      _subscribeFeedRealtime();
      chatMessages = await _storage.loadChat(uid);
    } else {
      user = await _storage.loadUser(uid);
      if (uid == 'user_test_001') {
        user!
          ..allergies = ['dairy']
          ..mealVariety = 'rotate';
        user!.weeklyPlan = WeeklyPlan(
          macros: user!.weeklyPlan.macros,
          workouts: user!.weeklyPlan.workouts,
          meals: MealVarietyService.generateDailyPlan(user!),
          shoppingList: user!.weeklyPlan.shoppingList,
        );
        await _saveUser(uid);
      }
      feedPosts = await _storage.loadFeed();
      chatMessages = await _storage.loadChat(uid);
    }

    if (user != null) {
      WeightHistoryHelper.seedBaselineIfEmpty(user!.weightHistory, user!.weight);
      _syncDayCalorieTargets();
      evaluateStreakOnLaunch();
    }
    final rolledToNewDay = _resetDailyStateIfNeeded();
    if (rolledToNewDay.changed && userId != null) {
      await _saveUser(userId!);
    }
    _startDailyRolloverTimer();
    await refreshProStatus();
    if (useFirebase && userId != null) {
      dailyLogsHistory = await FirebaseService.fetchDailyLogsRange(userId!, 30);
      leaderboard = await FirebaseService.fetchLeaderboard();
      _hydrateTodayActivityFromHistory();
      await _refreshTodayFoodEntries();
      activeGoals = await FirebaseService.fetchWeeklyGoals(userId!);
      user!.weeklyGoals = List.from(activeGoals);
      await _loadTodayCheckin();
    } else {
      activeGoals = List.from(user!.weeklyGoals);
      _mergeLocalDailyLogs();
    }
    final nutritionFixed = _reconcileTodayNutritionFromEntries();
    if (nutritionFixed && userId != null) {
      await _saveUser(userId!);
    }
    _rebuildWeeklyVolumeFromLogs();
    await checkWeeklyGoals();
    await evaluateEndedWeeklyGoals();
    await refreshHealthData();
    await _migrateWorkoutPlanIfNeeded(uid);
    await _checkLocationPrompt();
    await _refreshNotificationReminders();
    } catch (e, st) {
      debugPrint('Load user data failed: $e\n$st');
    }
  }

  Future<void> _migrateWorkoutPlanIfNeeded(String uid) async {
    if (user == null || !WorkoutAdaptationService.planContainsBlockedExercises(user!)) return;
    final plan = WorkoutAdaptationService.buildWeeklyPlan(user!);
    user!.weeklyPlan = WeeklyPlan(
      macros: user!.weeklyPlan.macros,
      workouts: plan.workouts,
      meals: user!.weeklyPlan.meals,
      shoppingList: user!.weeklyPlan.shoppingList,
      deliveryOptions: user!.weeklyPlan.deliveryOptions,
    );
    await _saveUser(uid);
    notifyListeners();
  }

  Future<void> _refreshNotificationReminders() async {
    if (user == null) return;
    final pT = (user!.weeklyPlan.macros['protein'] ?? 140).round();
    final pE = user!.dailyMacrosLogged.protein;
    await NotificationService.refreshPersonalizedReminders(
      streak: user!.gamification['streak'] as int? ?? 0,
      goal: user!.goal.isEmpty ? 'maintain' : user!.goal,
      proteinShort: (pT - pE).clamp(0, 500),
    );
  }

  static const _locationPromptDismissedKey = 'location_prompt_dismissed';

  Future<void> _checkLocationPrompt() async {
    if (user == null || !user!.profileComplete) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_locationPromptDismissedKey) == true) return;
    if (await LocationService.hasPermission()) return;
    shouldShowLocationPrompt = true;
    notifyListeners();
  }

  Future<void> dismissLocationPrompt({bool granted = false}) async {
    shouldShowLocationPrompt = false;
    if (!granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPromptDismissedKey, true);
    }
    notifyListeners();
  }

  Future<DeliveryResult?> refreshDeliveryOptions({required bool dineIn}) async {
    if (user == null) return null;
    final result = await DeliveryService.suggestForMode(user!, dineIn: dineIn);
    if (result.options.isNotEmpty) {
      await patchUser((u) {
        u.weeklyPlan = WeeklyPlan(
          macros: u.weeklyPlan.macros,
          workouts: u.weeklyPlan.workouts,
          meals: u.weeklyPlan.meals,
          shoppingList: u.weeklyPlan.shoppingList,
          deliveryOptions: result.options.map((o) => o.toJson()).toList(),
        );
      });
    }
    return result;
  }

  Future<void> clearDeliveryOptions() async {
    if (user == null) return;
    if (user!.weeklyPlan.deliveryOptions?.isEmpty ?? true) return;
    await patchUser((u) {
      u.weeklyPlan = WeeklyPlan(
        macros: u.weeklyPlan.macros,
        workouts: u.weeklyPlan.workouts,
        meals: u.weeklyPlan.meals,
        shoppingList: u.weeklyPlan.shoppingList,
        deliveryOptions: const [],
      );
    });
  }

  static String deliveryFavKey(Map<String, dynamic> option) =>
      '${option['restaurant'] ?? ''}|${option['dish'] ?? ''}';

  bool isFavouriteDelivery(Map<String, dynamic> option) {
    final key = deliveryFavKey(option);
    return user?.favouriteDelivery.any((f) => deliveryFavKey(f) == key) ?? false;
  }

  Future<void> toggleFavouriteDelivery(Map<String, dynamic> option) async {
    if (user == null) return;
    final key = deliveryFavKey(option);
    await patchUser((u) {
      final favs = List<Map<String, dynamic>>.from(u.favouriteDelivery);
      final idx = favs.indexWhere((f) => deliveryFavKey(f) == key);
      if (idx >= 0) {
        favs.removeAt(idx);
      } else {
        favs.insert(0, {...option, 'savedAt': DateTime.now().toIso8601String()});
        if (favs.length > 20) favs.removeRange(20, favs.length);
      }
      u.favouriteDelivery = favs;
    });
  }

  bool healthConnected = false;
  String coachContextPeriod = 'day';
  List<Map<String, dynamic>> dailyLogsHistory = [];
  List<Map<String, dynamic>> leaderboard = [];
  TodayActivityLog todayActivity = TodayActivityLog();
  List<Map<String, dynamic>> todayFoodEntries = [];
  Timer? _healthRefreshTimer;
  Timer? _dailyRolloverTimer;
  int foodLogPulseTick = 0;
  PendingTdeeUpdate? pendingTdeeUpdate;
  PendingPrCelebration? pendingPrCelebration;
  PendingGoalCelebration? pendingGoalCelebration;
  List<WeeklyGoal> activeGoals = [];
  int todayEnergyLevel = 0;
  double lastNightSleepHours = 0;
  String workoutAdjustment = 'none';
  Map<String, double> weeklyVolume = {};
  String? _weeklyVolumeWeekKey;
  List<ProgressionEvent> recentProgressions = [];
  String? _morningCheckinDate;
  String? _coachOpenerDate;
  bool get morningCheckinDoneToday =>
      _morningCheckinDate == DateTime.now().toIso8601String().substring(0, 10);

  double get caloriesEaten => user?.dailyMacrosLogged.calories.toDouble() ?? 0;
  bool get splitCaloriesEnabled => user?.splitCaloriesEnabled ?? true;
  double get trainingDayCalories =>
      (user?.trainingDayCalories ?? user?.weeklyPlan.macros['calories'] ?? user?.tdee ?? 0).toDouble();
  double get restDayCalories =>
      (user?.restDayCalories ?? (trainingDayCalories - 200)).toDouble();
  bool get isTrainingDay {
    final w = todayWorkoutDay;
    if (w == null || w.focus.toLowerCase().contains('rest')) return false;
    return todayWorkoutStatus == WorkoutStatus.planned ||
        todayWorkoutStatus == WorkoutStatus.completed ||
        todayWorkoutStatus == WorkoutStatus.modified;
  }
  double get todayCalorieTarget => splitCaloriesEnabled && !isTrainingDay ? restDayCalories : trainingDayCalories;
  double get caloriesTarget => todayCalorieTarget;
  double get waterLitres => (user?.water ?? 0) / 1000;
  double get stepCaloriesBurned => todayActivity.stepCalories;
  double get workoutCaloriesBurned => todayActivity.workoutCalories;
  double get activeCaloriesBurned => todayActivity.activeCaloriesBurned;
  double get netCalories => caloriesEaten - activeCaloriesBurned;
  WorkoutStatus get todayWorkoutStatus => todayActivity.workoutStatus;
  String? get todayWorkoutName => todayActivity.workoutName;
  String? get todayWorkoutSessionId => todayActivity.todayWorkoutSessionId;
  List<String> get recentPRs => user == null
      ? const []
      : user!.personalRecords
          .take(5)
          .map(PersonalRecordHelper.formatRecentPr)
          .toList();

  void clearPendingTdeeUpdate() {
    pendingTdeeUpdate = null;
    notifyListeners();
  }

  void clearPendingPrCelebration() {
    pendingPrCelebration = null;
    notifyListeners();
  }

  void clearPendingGoalCelebration() {
    pendingGoalCelebration = null;
    notifyListeners();
  }

  WorkoutDay? get todayWorkoutDay {
    if (user == null) return null;
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = days[DateTime.now().weekday % 7];
    return user!.weeklyPlan.workouts.where((x) => x.day == today).firstOrNull ??
        user!.weeklyPlan.workouts.firstOrNull;
  }

  void _hydrateTodayActivityFromHistory() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final log = dailyLogsHistory.cast<Map<String, dynamic>?>().firstWhere(
          (l) => l?['date'] == today,
          orElse: () => null,
        );
    if (log != null) todayActivity.applyFromDailyLog(log);
    if (todayActivity.workoutName == null && todayWorkoutDay != null) {
      todayActivity.workoutName = todayWorkoutDay!.focus;
    }
  }

  Future<void> _refreshTodayFoodEntries() async {
    if (!useFirebase || userId == null) return;
    todayFoodEntries = await FirebaseService.fetchTodayFoodEntries(userId!);
  }

  /// Rebuild today's food log and macro/micro totals from dated entries only.
  bool _reconcileTodayNutritionFromEntries() {
    if (user == null) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    List<Map<String, dynamic>> entries;
    if (useFirebase && todayFoodEntries.isNotEmpty) {
      entries = todayFoodEntries.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (useFirebase && todayFoodEntries.isEmpty) {
      entries = [];
    } else {
      entries = user!.foodLog
          .where((e) => (e['date'] as String?) == today)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    for (final e in entries) {
      MacroHelpers.applyMicrosToEntry(e);
    }

    final nextTotals = MacroHelpers.sumFromEntries(entries);
    final changed = user!.foodLog.length != entries.length ||
        user!.dailyMacrosLogged.calories != nextTotals.calories ||
        user!.dailyMacrosLogged.protein != nextTotals.protein ||
        user!.dailyMacrosLogged.carbs != nextTotals.carbs ||
        user!.dailyMacrosLogged.fat != nextTotals.fat ||
        user!.dailyMacrosLogged.fiber != nextTotals.fiber ||
        user!.dailyMacrosLogged.sugar != nextTotals.sugar ||
        user!.dailyMacrosLogged.sodiumMg != nextTotals.sodiumMg ||
        user!.dailyLogDate != today;

    user!.foodLog = entries;
    user!.dailyMacrosLogged = nextTotals;
    user!.dailyLogDate = today;
    return changed;
  }

  String _weekStartKey() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day).toIso8601String().substring(0, 10);
  }

  bool _resetWeeklyStateIfNeeded() {
    if (user == null) return false;
    final weekKey = _weekStartKey();
    var changed = false;
    final g = Map<String, dynamic>.from(user!.gamification);
    final prevBudgetWeek = g['budgetWeekStart'] as String?;
    if (prevBudgetWeek == null) {
      g['budgetWeekStart'] = weekKey;
    } else if (prevBudgetWeek != weekKey) {
      g['budgetWeekStart'] = weekKey;
      user!.budgetSpent = 0;
      changed = true;
    }
    user!.gamification = g;

    if (_weeklyVolumeWeekKey != weekKey) {
      _weeklyVolumeWeekKey = weekKey;
      changed = true;
    }
    return changed;
  }

  Map<String, dynamic>? _activitySnapshotForArchive() {
    if (todayActivity.workoutStatus == WorkoutStatus.planned &&
        todayActivity.workoutCalories == 0 &&
        todayActivity.stepCalories == 0) {
      return null;
    }
    return todayActivity.toDailyLogFields();
  }

  void _mergeLocalDailyLogs() {
    if (user == null) return;
    dailyLogsHistory = List<Map<String, dynamic>>.from(user!.dailyLogArchive);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (user!.dailyLogDate == today &&
        (user!.dailyMacrosLogged.calories > 0 ||
            user!.foodLog.isNotEmpty ||
            user!.water > 0 ||
            todayActivity.workoutStatus != WorkoutStatus.planned)) {
      dailyLogsHistory.removeWhere((l) => l['date'] == today);
      dailyLogsHistory.add({
        'date': today,
        'calories_logged': user!.dailyMacrosLogged.calories,
        'protein_logged': user!.dailyMacrosLogged.protein,
        'carbs_logged': user!.dailyMacrosLogged.carbs,
        'fat_logged': user!.dailyMacrosLogged.fat,
        'fiber_logged': user!.dailyMacrosLogged.fiber,
        'sugar_logged': user!.dailyMacrosLogged.sugar,
        'sodium_mg_logged': user!.dailyMacrosLogged.sodiumMg,
        'water_ml': user!.water.round(),
        'steps': user!.steps.round(),
        ...todayActivity.toDailyLogFields(),
      });
    }
    dailyLogsHistory.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  String _muscleGroupKey(String name) {
    final n = name.toLowerCase();
    if (n.contains('squat') || n.contains('leg') || n.contains('rdl') || n.contains('deadlift')) {
      return 'Legs';
    }
    if (n.contains('row') || n.contains('pull') || n.contains('curl')) return 'Pull';
    if (n.contains('press') || n.contains('push') || n.contains('ohp')) return 'Push';
    return 'Other';
  }

  void _rebuildWeeklyVolumeFromLogs() {
    final weekKey = _weekStartKey();
    _weeklyVolumeWeekKey = weekKey;
    final volume = <String, double>{};
    final sources = <Map<String, dynamic>>[];
    sources.addAll(dailyLogsHistory);
    if (user != null) sources.addAll(user!.dailyLogArchive);

    for (final log in sources) {
      final date = log['date'] as String? ?? '';
      if (date.compareTo(weekKey) < 0) continue;
      final sessionMap = log['workout_session'] as Map<String, dynamic>?;
      if (sessionMap == null) continue;
      final session = WorkoutSessionLog.fromJson(sessionMap);
      for (final ex in session.exercises) {
        final vol = (ex.weightKg ?? 0) * ex.reps * ex.sets;
        if (vol <= 0) continue;
        final key = _muscleGroupKey(ex.name);
        volume[key] = (volume[key] ?? 0) + vol;
      }
    }
    weeklyVolume = volume;
  }

  Map<String, dynamic>? _dailyLogForDate(String date) {
    final fromHistory = dailyLogsHistory.cast<Map<String, dynamic>?>().firstWhere(
          (l) => l?['date'] == date,
          orElse: () => null,
        );
    if (fromHistory != null) return fromHistory;
    if (user == null) return null;
    return user!.dailyLogArchive.cast<Map<String, dynamic>?>().firstWhere(
          (l) => l?['date'] == date,
          orElse: () => null,
        );
  }

  ({bool changed, bool macrosRolled, bool weekRolled}) _resetDailyStateIfNeeded() {
    if (user == null) return (changed: false, macrosRolled: false, weekRolled: false);
    final todaysWorkout = todayWorkoutDay;
    final mealsReset = user!.resetMealsLoggedIfNewDay();
    final messagesReset = user!.resetFreeMessagesIfNewDay();
    final macrosReset = user!.resetDailyLogIfNewDay(
      activitySnapshot: _activitySnapshotForArchive(),
    );
    final weekReset = _resetWeeklyStateIfNeeded();

    if (macrosReset) {
      todayActivity = TodayActivityLog(workoutName: todaysWorkout?.focus);
      todayFoodEntries = [];
      todayEnergyLevel = 0;
      lastNightSleepHours = 0;
      workoutAdjustment = 'none';
      _morningCheckinDate = null;
      foodLogPulseTick++;
      pendingPrCelebration = null;
      pendingGoalCelebration = null;
      _recomputeStepCalories();
      if (!useFirebase) _mergeLocalDailyLogs();
    }
    if (weekReset) {
      _rebuildWeeklyVolumeFromLogs();
    }

    final changed = mealsReset || messagesReset || macrosReset || weekReset;
    return (changed: changed, macrosRolled: macrosReset, weekRolled: weekReset);
  }

  Future<void> ensureDailyStateFresh({bool notify = true}) async {
    if (user == null || userId == null) return;
    final rolled = _resetDailyStateIfNeeded();
    if (!rolled.changed) return;
    if (rolled.macrosRolled) {
      _reconcileTodayNutritionFromEntries();
      await checkWeeklyGoals();
    }
    if (useFirebase) {
      await _refreshTodayFoodEntries();
    }
    await _saveUser(userId!);
    if (notify) notifyListeners();
  }

  void _recomputeStepCalories() {
    if (user == null) return;
    final steps = user!.steps.round();
    todayActivity.stepCalories = ActivityCalorieService.stepsToCalories(steps, user!.weight);
  }

  void _startHealthRefreshTimer() {
    _healthRefreshTimer?.cancel();
    if (!healthConnected) return;
    _healthRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshHealthData();
    });
  }

  void _startDailyRolloverTimer() {
    _dailyRolloverTimer?.cancel();
    if (user == null) return;
    _dailyRolloverTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ensureDailyStateFresh();
    });
  }

  void disposeHealthTimer() {
    _healthRefreshTimer?.cancel();
  }

  Future<void> refreshHealthData({bool requestIfNeeded = false}) async {
    if (user == null) return;
    await ensureDailyStateFresh(notify: false);
    try {
      await HealthService.ensureConfigured();
      var granted = await HealthService.hasPermissions();
      if (!granted && requestIfNeeded) {
        granted = await HealthService.requestPermissions();
      }
      healthConnected = granted;
      if (granted) {
        final steps = await HealthService.getTodaySteps();
        final prevSteps = user!.steps.round();
        user!.steps = steps.toDouble();
        if (steps != prevSteps) {
          _recomputeStepCalories();
        }
        if (userId != null) await _saveUser(userId!);
        _startHealthRefreshTimer();
      } else {
        _healthRefreshTimer?.cancel();
      }
    } catch (_) {
      healthConnected = false;
    }
    notifyListeners();
  }

  /// Connect Health Connect / Apple Health. Returns a user-facing status message.
  Future<String> connectHealth() async {
    if (user == null) return 'Sign in first';

    try {
      final result = await HealthService.connect();
      healthConnected = result.success;

      if (result.success) {
        user!.steps = result.steps.toDouble();
        if (userId != null) await _saveUser(userId!);
        _startHealthRefreshTimer();
      } else {
        _healthRefreshTimer?.cancel();
      }

      notifyListeners();
      return result.message;
    } catch (e, st) {
      debugPrint('connectHealth failed: $e\n$st');
      healthConnected = false;
      notifyListeners();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'Could not connect to Apple Health. Check Health permissions in Settings.';
      }
      return 'Could not connect. Update Health Connect from the Play Store and try again.';
    }
  }

  Future<void> _saveUser(String uid) async {
    if (user == null) return;
    await _storage.saveUser(uid, user!);
    if (useFirebase) {
      await FirebaseService.saveUserData(user!, activityFields: todayActivity.toDailyLogFields());
    } else if (useSupabase) {
      await SupabaseService.saveUserData(user!);
    }
  }

  Future<void> _saveChat(String uid) async {
    await _storage.saveChat(uid, chatMessages);
    if (useFirebase) {
      await FirebaseService.saveChat(uid, chatMessages);
    }
  }

  void _subscribeFeedRealtime() {
    _feedSubscription?.cancel();
    if (useFirebase) {
      _feedSubscription = FirebaseService.feedStream().listen((posts) {
        feedPosts = posts;
        notifyListeners();
      });
    } else if (useSupabase) {
      _feedSubscription = SupabaseService.client
          .from('feed_posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(50)
          .listen((rows) {
        feedPosts = rows.map(SupabaseService.mapFeedPost).toList();
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _healthRefreshTimer?.cancel();
    _dailyRolloverTimer?.cancel();
    super.dispose();
  }

  bool _isLocalTestAccount(String email) =>
      email == TestAccounts.testEmail ||
      email == TestAccounts.demoEmail ||
      email == TestAccounts.alexEmail;

  Future<void> _completeFirebaseSession(dynamic firebaseUser) async {
    backend = BackendMode.firebase;
    session = {
      'userId': firebaseUser.uid as String,
      'email': firebaseUser.email as String? ?? '',
      'displayName': firebaseUser.displayName as String? ??
          (firebaseUser.email as String?)?.split('@').first ??
          'Athlete',
    };
    await SubscriptionService.linkUser(session!['userId']!);
    await _loadUserData(session!['userId']!);
    tabIndex = 0;
    AnalyticsService.login('firebase');
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (!BackendConfig.hasFirebase) {
      throw Exception('Google Sign-In requires Firebase. See GOOGLE_SIGNIN_SETUP.md');
    }
    final cred = await FirebaseService.signInWithGoogle();
    if (cred.user == null) throw Exception('Google sign-in failed');
    await _completeFirebaseSession(cred.user!);
  }

  Future<void> signInWithApple() async {
    if (!BackendConfig.hasFirebase) {
      throw Exception('Apple Sign-In requires Firebase. See GOOGLE_SIGNIN_SETUP.md');
    }
    final cred = await FirebaseService.signInWithApple();
    if (cred.user == null) throw Exception('Apple sign-in failed');
    await _completeFirebaseSession(cred.user!);
  }

  Future<void> resetPassword(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) throw Exception('Enter your email address');
    if (BackendConfig.hasFirebase) {
      await FirebaseService.sendPasswordResetEmail(normalized);
      return;
    }
    if (BackendConfig.hasSupabase) {
      await SupabaseService.client.auth.resetPasswordForEmail(normalized);
      return;
    }
    throw Exception('Password reset is not available');
  }

  Future<void> deleteAccount() async {
    if (userId == null) return;
    final uid = userId!;
    if (useFirebase) {
      await FirebaseService.deleteAccount(uid);
    } else {
      await _storage.clearUser(uid);
    }
    await logout();
  }

  Future<void> login(String email, String password) async {
    Object? lastError;

    if (ReleaseConfig.allowLocalAuth && _isLocalTestAccount(email)) {
      await _auth.seedTestAccountsIfNeeded();
      backend = BackendMode.local;
      final account = await _auth.login(email: email, password: password);
      await _auth.saveSession(account);
      session = {'userId': account.userId, 'email': account.email, 'displayName': account.displayName};
      await _loadUserData(account.userId);
      tabIndex = 0;
      AnalyticsService.login('local_test');
      notifyListeners();
      return;
    }

    if (BackendConfig.hasFirebase) {
      try {
        final cred = await FirebaseService.signIn(email, password);
        if (cred.user != null) {
          await _completeFirebaseSession(cred.user!);
          PlanAgentService.generateWeeklyPlanIfNeeded();
          return;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (!kReleaseMode && BackendConfig.hasSupabase) {
      try {
        final res = await SupabaseService.signIn(email, password);
        if (res.user != null) {
          backend = BackendMode.supabase;
          final profile = await SupabaseService.getProfile();
          session = {
            'userId': res.user!.id,
            'email': res.user!.email ?? email,
            'displayName': profile?['name'] ?? email.split('@').first,
          };
          await _loadUserData(res.user!.id);
          PlanAgentService.generateWeeklyPlanIfNeeded();
          tabIndex = 0;
          notifyListeners();
          return;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (ReleaseConfig.allowLocalAuth) {
      await _auth.seedTestAccountsIfNeeded();
      try {
        backend = BackendMode.local;
        final account = await _auth.login(email: email, password: password);
        await _auth.saveSession(account);
        session = {'userId': account.userId, 'email': account.email, 'displayName': account.displayName};
        await _loadUserData(account.userId);
        tabIndex = 0;
        notifyListeners();
        return;
      } catch (e) {
        lastError = e;
      }
    }

    final msg = lastError == null
        ? 'Invalid email or password'
        : lastError.toString().replaceFirst('Exception: ', '');
    throw Exception(msg);
  }

  Future<void> signUp(String email, String password, String displayName) async {
    if (BackendConfig.hasFirebase) {
      final cred = await FirebaseService.signUp(email, password, displayName);
      if (cred.user == null) throw Exception('Sign up failed');
      backend = BackendMode.firebase;
      session = {'userId': cred.user!.uid, 'email': email, 'displayName': displayName};
      user = UserData.defaults()..userId = cred.user!.uid..profileComplete = false;
      chatMessages = [ChatMessage(role: 'assistant', content: "Welcome! Let's set up your profile first.")];
      await _saveUser(cred.user!.uid);
      await _saveChat(cred.user!.uid);
    } else if (!kReleaseMode && BackendConfig.hasSupabase) {
      final res = await SupabaseService.signUp(email, password, displayName);
      if (res.user == null) throw Exception('Sign up failed');
      backend = BackendMode.supabase;
      session = {'userId': res.user!.id, 'email': email, 'displayName': displayName};
      user = UserData.defaults()..userId = res.user!.id..profileComplete = false;
      await SupabaseService.saveUserData(user!);
      chatMessages = [ChatMessage(role: 'assistant', content: "Welcome! Let's set up your profile first.")];
      await _saveChat(res.user!.id);
    } else if (ReleaseConfig.allowLocalAuth) {
      final account = await _auth.signUp(email: email, password: password, displayName: displayName);
      await _auth.saveSession(account);
      session = {'userId': account.userId, 'email': account.email, 'displayName': account.displayName};
      user = UserData.defaults()..userId = account.userId..profileComplete = false;
      await _storage.saveUser(account.userId, user!);
      chatMessages = [ChatMessage(role: 'assistant', content: "Welcome! Let's set up your profile first.")];
      await _saveChat(account.userId);
    } else {
      throw Exception('Sign up requires Firebase. Please try again later.');
    }
    tabIndex = 0;
    notifyListeners();
  }

  Future<void> logout() async {
    _feedSubscription?.cancel();
    _feedSubscription = null;
    _healthRefreshTimer?.cancel();
    _dailyRolloverTimer?.cancel();
    if (useFirebase) await FirebaseService.signOut();
    if (useSupabase) await SupabaseService.signOut();
    await _auth.clearSession();
    session = null;
    user = null;
    chatMessages = [];
    feedPosts = [];
    tabIndex = 0;
    backend = BackendMode.local;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String goal,
    required double weight,
    required double height,
    required int age,
    required int tdee,
    required double weeklyBudget,
    List<String> allergies = const [],
    String dietType = 'omnivore',
    String mealVariety = 'rotate',
    String genderAtBirth = 'prefer_not_to_say',
    List<String> disabilities = const [],
    bool pregnant = false,
    List<String> medications = const [],
    bool tracksPeriod = false,
    String? periodPhase,
    List<String> dietaryPreferences = const [],
    String nutritionMode = 'cook_myself',
  }) async {
    if (user == null || userId == null) return;
    user!
      ..goal = goal
      ..weight = weight
      ..height = height
      ..age = age
      ..tdee = tdee
      ..weeklyBudget = weeklyBudget
      ..allergies = allergies
      ..dietType = dietType
      ..mealVariety = mealVariety
      ..genderAtBirth = genderAtBirth
      ..disabilities = disabilities
      ..pregnant = pregnant
      ..medications = medications
      ..tracksPeriod = tracksPeriod
      ..periodPhase = periodPhase
      ..dietaryPreferences = dietaryPreferences
      ..nutritionMode = nutritionMode
      ..onboardingAnswers = {
        'age': age,
        'disabilities': disabilities,
        'allergies': allergies,
        'dietaryPreferences': dietaryPreferences,
        'goal': goal,
        'weeklyBudget': weeklyBudget,
        'nutritionMode': nutritionMode,
        'completedAt': DateTime.now().toIso8601String(),
      }
      ..profileComplete = true;
    WeightHistoryHelper.upsert(user!.weightHistory, weight);
    final meals = MealVarietyService.generateDailyPlan(user!);
    final workoutPlan = WorkoutAdaptationService.buildWeeklyPlan(user!);
    final macros = TdeeService.deriveMacros(calories: tdee, weightKg: weight);
    user!.weeklyPlan = WeeklyPlan(
      macros: macros,
      workouts: workoutPlan.workouts,
      meals: meals,
      shoppingList: user!.weeklyPlan.shoppingList,
    );
    await _saveUser(userId!);
    await UserMdSyncService.syncUser(user!, displayName: displayName);
    if (useFirebase || useSupabase) PlanAgentService.generateWeeklyPlanIfNeeded();
    tabIndex = 4;
    chatMessages = [];
    await _saveChat(userId!);
    notifyListeners();
  }

  Future<void> saveCustomWorkouts(List<CustomWorkout> workouts) async {
    if (user == null || userId == null) return;
    user!.customWorkouts = workouts;
    await _saveUser(userId!);
    await UserMdSyncService.syncUser(user!, displayName: displayName);
    notifyListeners();
  }

  Future<String> logVisionMeal(List<VisionFoodItem> items) async {
    if (user == null || userId == null) return '';
    await ensureDailyStateFresh(notify: false);
    var cal = 0, pro = 0, carbs = 0, fat = 0;
    for (final item in items.where((i) => !i.blocked)) {
      cal += item.calories;
      pro += item.protein;
      carbs += item.carbs;
      fat += item.fat;
      user!.foodLog.add({
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'food': item.name,
        'grams': item.grams,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fat': item.fat,
        'source': 'photo',
      });
    }
    user!.dailyMacrosLogged.calories += cal;
    user!.dailyMacrosLogged.protein += pro;
    user!.dailyMacrosLogged.carbs += carbs;
    user!.dailyMacrosLogged.fat += fat;
    await _saveUser(userId!);
    notifyListeners();
    return '✅ Logged ${items.where((i) => !i.blocked).map((i) => '${i.grams.round()}g ${i.name}').join(', ')} - $cal kcal, P ${pro}g';
  }

  Future<void> swapMeal(String mealType) async {
    if (user == null || userId == null) return;
    final newMeal = MealVarietyService.swapMeal(user!, mealType);
    final meals = List<Meal>.from(user!.weeklyPlan.meals);
    final idx = meals.indexWhere((m) => m.mealType == mealType);
    if (idx >= 0) {
      meals[idx] = newMeal;
    } else {
      meals.add(newMeal);
    }
    final store = StoreService.resolveStoreName(user!);
    user!.weeklyPlan = WeeklyPlan(
      macros: user!.weeklyPlan.macros,
      workouts: user!.weeklyPlan.workouts,
      meals: meals,
      shoppingList: ShoppingListService.buildFromMeals(meals, store: store),
    );
    MealVarietyService.recordMeal(user!, newMeal);
    await _saveUser(userId!);
    notifyListeners();
  }

  Future<void> shuffleMeals() async {
    if (user == null || userId == null) return;
    final meals = MealVarietyService.generateDailyPlan(user!);
    final store = StoreService.resolveStoreName(user!);
    user!.weeklyPlan = WeeklyPlan(
      macros: user!.weeklyPlan.macros,
      workouts: user!.weeklyPlan.workouts,
      meals: meals,
      shoppingList: ShoppingListService.buildFromMeals(meals, store: store),
    );
    await _saveUser(userId!);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    await _storage.setDarkTheme(isDark);
    notifyListeners();
  }

  void setTab(int i) {
    tabIndex = i;
    notifyListeners();
  }

  Future<void> updateUser(UserData data) async {
    if (userId == null) return;
    user = data;
    await _saveUser(userId!);
    notifyListeners();
  }

  Future<void> patchUser(void Function(UserData u) fn) async {
    if (user == null || userId == null) return;
    fn(user!);
    await _saveUser(userId!);
    notifyListeners();
  }

  Future<bool> updateAvatar(BuildContext context) async {
    if (user == null || userId == null) return false;
    final path = await AvatarService.pickAndSave(context, userId!);
    if (path == null) return false;
    final old = user!.avatarPath;
    await patchUser((u) => u.avatarPath = path);
    if (old != null && old != path) await AvatarService.deleteFile(old);
    return true;
  }

  Future<void> addLocalExchange(String userText, String reply) async {
    chatMessages.add(ChatMessage(role: 'user', content: userText));
    chatMessages.add(ChatMessage(role: 'assistant', content: reply));
    await _saveChat(userId!);
    notifyListeners();
  }

  static String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

  bool hasUserMessageToday() {
    final today = _todayKey();
    return chatMessages.any((m) => m.role == 'user' && m.ts.toIso8601String().substring(0, 10) == today);
  }

  /// Injects Mara's daily opener for returning users; empty-state uses the welcome card.
  Future<void> ensureCoachDailyOpener() async {
    if (user == null || userId == null) return;
    final today = _todayKey();
    if (_coachOpenerDate == today) return;
    _coachOpenerDate = today;
    await _storage.setCoachOpenerDate(today);

    if (hasUserMessageToday()) return;

    if (chatMessages.isEmpty) {
      notifyListeners();
      return;
    }

    final opener = CoachPersonalityService.dailyOpener(this);
    final alreadyHas = chatMessages.any(
      (m) => m.role == 'assistant' && m.ts.toIso8601String().substring(0, 10) == today && m.content == opener,
    );
    if (!alreadyHas) {
      chatMessages.add(ChatMessage(role: 'assistant', content: opener));
      await _saveChat(userId!);
    }
    notifyListeners();
  }

  Future<void> _consumeFreeChatMessageIfNeeded() async {
    if (isPro) return;
    await decrementFreeMessage();
  }

  Future<String> sendChat(String text) async {
    if (user == null || userId == null) return '';

    if (!isPro) {
      if (user!.freeMessagesRemaining <= 0) return 'FREE_LIMIT';
    }

    chatMessages.add(ChatMessage(role: 'user', content: text));
    chatTyping = true;
    lastChatFailedMessage = null;
    notifyListeners();

    try {
      return await _sendChatInternal(text);
    } catch (e) {
      debugPrint('sendChat error: $e');
      lastChatFailedMessage = text;
      chatMessages.add(ChatMessage(
        role: 'assistant',
        content: 'Something went wrong - tap Retry to send again.',
        actionChip: 'Retry',
      ));
      await _saveChat(userId!);
      return 'ERROR';
    } finally {
      chatTyping = false;
      notifyListeners();
    }
  }

  Future<String> retryLastChat() async {
    final msg = lastChatFailedMessage;
    if (msg == null || userId == null) return '';
    if (chatMessages.isNotEmpty && chatMessages.last.actionChip == 'Retry') {
      chatMessages.removeLast();
    }
    lastChatFailedMessage = null;
    chatTyping = true;
    notifyListeners();
    try {
      return await _sendChatInternal(msg);
    } finally {
      chatTyping = false;
      notifyListeners();
    }
  }

  Future<String> _sendChatInternal(String text) async {
    OpenClawService.sendChatCommand(message: text, user: user!, displayName: displayName);

    String reply;
    List<Map<String, dynamic>>? deliveryOptions;

    final planDuration = CheapMealPlanService.parseDuration(text);
    if (planDuration != null) {
      final plan = await CheapMealPlanService.generate(user!, planDuration);
      if (plan.meals.isEmpty) {
        reply = plan.reply.replaceAll('**', '');
        chatMessages.add(ChatMessage(role: 'assistant', content: reply));
        await _saveChat(userId!);
        chatTyping = false;
        await _consumeFreeChatMessageIfNeeded();
        notifyListeners();
        return reply;
      }
      if (plan.duration == PlanDuration.monthly && plan.monthlyPlan != null) {
        user!.monthlyPlan = plan.monthlyPlan;
        user!.weeklyPlan = WeeklyPlan(
          macros: user!.weeklyPlan.macros,
          workouts: user!.weeklyPlan.workouts,
          meals: plan.monthlyPlan!.meals.take(3).toList(),
          shoppingList: plan.shoppingList,
        );
      } else {
        user!.weeklyPlan = WeeklyPlan(
          macros: user!.weeklyPlan.macros,
          workouts: user!.weeklyPlan.workouts,
          meals: plan.meals,
          shoppingList: plan.shoppingList,
        );
      }
      reply = plan.reply.replaceAll('**', '');
      await _saveUser(userId!);
      await UserMdSyncService.syncUser(user!, displayName: displayName);
      chatMessages.add(ChatMessage(role: 'assistant', content: reply));
      await _saveChat(userId!);
      chatTyping = false;
      await _consumeFreeChatMessageIfNeeded();
      notifyListeners();
      return reply;
    }

    if (DeliveryService.isDeliveryQuery(text)) {
      final delivery = await DeliveryService.suggestNearby(text, user!);
      reply = delivery.reply.replaceAll('**', '');
      deliveryOptions = delivery.options.map((o) => o.toJson()).toList();
      if (deliveryOptions.isNotEmpty) {
        user!.weeklyPlan = WeeklyPlan(
          macros: user!.weeklyPlan.macros,
          workouts: user!.weeklyPlan.workouts,
          meals: user!.weeklyPlan.meals,
          shoppingList: user!.weeklyPlan.shoppingList,
          deliveryOptions: deliveryOptions,
        );
        await _saveUser(userId!);
      }
      chatMessages.add(ChatMessage(role: 'assistant', content: reply, deliveryOptions: deliveryOptions));
      await _saveChat(userId!);
      chatTyping = false;
      await _consumeFreeChatMessageIfNeeded();
      notifyListeners();
      return reply;
    }

    final ruleResult = _rulesChat.process(text, user!);
    final ruleHandled =
        ruleResult.updatedUser != null || ruleResult.foodLogIntent != null || ruleResult.reply.contains('Blocked');

    if (ruleResult.foodLogIntent != null) {
      final intent = ruleResult.foodLogIntent!;
      final chip = await logFood(
        name: intent.name,
        calories: intent.calories,
        protein: intent.protein,
        carbs: intent.carbs,
        fat: intent.fat,
        source: 'coach',
        servingG: intent.grams,
      );
      reply = ruleResult.reply;
      if (chip != null) reply = '$reply\n$chip';
    } else if (ruleHandled) {
      if (ruleResult.updatedUser != null) user = ruleResult.updatedUser;
      reply = ruleResult.reply;
    } else if (BackendConfig.hasGroq) {
      final history = chatMessages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final groq = await GroqChatService.chat(
        userMessage: text,
        userProfile: DailyContextBuilder.groqProfileFromAppState(this, displayName: displayName),
        history: history,
      );
      final chip = await _applyAiActions(groq.actions);
      if (!GroqChatService.isErrorOrEmpty(groq.displayText)) {
        reply = groq.displayText;
      } else {
        final fallback = _rulesChat.process(text, user!);
        reply = fallback.reply.startsWith("I'm Mara")
            ? groq.displayText.isNotEmpty ? groq.displayText : fallback.reply
            : fallback.reply;
      }
      chatMessages.add(ChatMessage(role: 'assistant', content: reply, actionChip: chip));
      await _saveChat(userId!);
      chatTyping = false;
      await _consumeFreeChatMessageIfNeeded();
      notifyListeners();
      return reply;
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      if (ruleResult.updatedUser != null) user = ruleResult.updatedUser;
      reply = ruleResult.reply;
    }

    if (user != null) {
      await _saveUser(userId!);
      if (ruleResult.updatedUser != null) {
        await UserMdSyncService.syncUser(user!, displayName: displayName);
      }
    }

    chatMessages.add(ChatMessage(role: 'assistant', content: reply));
    await _saveChat(userId!);
    chatTyping = false;
    await _consumeFreeChatMessageIfNeeded();
    notifyListeners();
    return reply;
  }

  Future<String?> _applyAiActions(List<AiAction> actions) async {
    if (user == null || actions.isEmpty) return null;
    String? chip;
    for (final a in actions) {
      switch (a.type) {
        case 'LOG_FOOD':
          chip = await logFood(
            name: a.data['name'] as String,
            calories: (a.data['calories'] as num).round(),
            protein: (a.data['protein'] as num).round(),
            carbs: (a.data['carbs'] as num).round(),
            fat: (a.data['fat'] as num).round(),
            source: 'coach',
          );
          break;
        case 'UPDATE_WEIGHT':
        case 'LOG_WEIGHT':
          final newWeight = (a.data['weight_kg'] as num).toDouble();
          if (newWeight >= 35 &&
              newWeight <= 300 &&
              !(user!.weight > 50 && newWeight < user!.weight * 0.5)) {
            chip = await logWeight(newWeight);
          }
          break;
        case 'LOG_PR':
          chip = await logPersonalRecord(
            exerciseName: a.data['exercise'] as String,
            value: (a.data['value'] as num).toDouble(),
            unit: a.data['unit'] as String? ?? 'kg',
          );
          break;
        case 'SWAP_MEAL':
          await swapMeal(a.data['meal_type'] as String? ?? 'Lunch');
          chip = '✓ Meal swapped';
          break;
        case 'COMPLETE_WORKOUT':
          tabIndex = 1;
          chip = '✓ Opening Workout - tap Start workout to log your sets';
          break;
        case 'UPDATE_GOAL':
          user!.goal = a.data['goal'] as String;
          break;
        case 'ADD_ALLERGY':
          final allergen = a.data['allergen'] as String;
          if (!user!.allergies.contains(allergen)) {
            user!.allergies = [...user!.allergies, allergen];
          }
          break;
        case 'ADD_XP':
          await awardXp(a.data['amount'] as int, 'Coach');
          chip = '✓ +${a.data['amount']} XP';
          break;
        case 'UPDATE_WORKOUT':
          final plan = WorkoutAdaptationService.buildWeeklyPlan(user!);
          user!.weeklyPlan = WeeklyPlan(
            macros: user!.weeklyPlan.macros,
            workouts: plan.workouts,
            meals: user!.weeklyPlan.meals,
            shoppingList: user!.weeklyPlan.shoppingList,
            deliveryOptions: user!.weeklyPlan.deliveryOptions,
          );
          break;
        case 'ADD_DISABILITY':
          final tag = a.data['tag'] as String;
          if (!user!.disabilities.contains(tag)) {
            user!.disabilities = [...user!.disabilities, tag];
          }
          final plan = WorkoutAdaptationService.buildWeeklyPlan(user!);
          user!.weeklyPlan = WeeklyPlan(
            macros: user!.weeklyPlan.macros,
            workouts: plan.workouts,
            meals: user!.weeklyPlan.meals,
            shoppingList: user!.weeklyPlan.shoppingList,
            deliveryOptions: user!.weeklyPlan.deliveryOptions,
          );
          break;
        case 'SET_PREGNANT':
          user!.pregnant = a.data['value'] as bool;
          final plan = WorkoutAdaptationService.buildWeeklyPlan(user!);
          user!.weeklyPlan = WeeklyPlan(
            macros: user!.weeklyPlan.macros,
            workouts: plan.workouts,
            meals: user!.weeklyPlan.meals,
            shoppingList: user!.weeklyPlan.shoppingList,
            deliveryOptions: user!.weeklyPlan.deliveryOptions,
          );
          break;
        case 'SET_PERIOD':
          user!.tracksPeriod = a.data['phase'] != null;
          user!.periodPhase = a.data['phase'] as String?;
          break;
        case 'SET_GOAL':
          final typeName = a.data['type'] as String;
          final goalType = GoalType.values.firstWhere(
            (t) => t.name == typeName,
            orElse: () => GoalType.protein,
          );
          await setWeeklyGoal(
            type: goalType,
            targetValue: (a.data['targetValue'] as num).toDouble(),
            targetDays: a.data['targetDays'] as int,
            createdBy: 'ai',
          );
          chip = '✓ Weekly goal set';
          break;
      }
    }
    if (userId != null) await _saveUser(userId!);
    return chip;
  }

  Future<void> refreshFeed() async {
    if (useFirebase) {
      feedPosts = await FirebaseService.getFeedPosts();
    } else if (useSupabase) {
      feedPosts = await SupabaseService.getFeedPosts();
    } else {
      feedPosts = await _storage.loadFeed();
    }
    notifyListeners();
  }

  Future<void> toggleFeedLike(String postId) async {
    final uid = userId!;
    if (useFirebase) {
      final post = feedPosts.firstWhere((p) => p['id'] == postId);
      final likes = List<String>.from(post['likes'] as List? ?? []);
      await FirebaseService.toggleLike(postId, uid, likes);
      return;
    }
    if (useSupabase) {
      final post = feedPosts.firstWhere((p) => p['id'] == postId);
      final likes = List<String>.from(post['likes'] as List? ?? []);
      await SupabaseService.toggleLike(postId, likes);
      await refreshFeed();
      return;
    }
    for (final p in feedPosts) {
      if (p['id'] == postId) {
        final likes = List<String>.from(p['likes'] as List? ?? []);
        if (likes.contains(uid)) {
          likes.remove(uid);
        } else {
          likes.add(uid);
        }
        p['likes'] = likes;
      }
    }
    await _storage.saveFeed(feedPosts);
    notifyListeners();
  }

  Future<void> addFeedPost(
    String content, {
    String type = 'workout',
    String? postType,
    Map<String, dynamic>? structuredContent,
    String? caption,
    String? activityId,
    String? activityCollection,
  }) async {
    if (userId == null) return;
    final resolvedType = postType ?? type;
    final isLinked = activityId != null &&
        activityId.isNotEmpty &&
        resolvedType != 'general' &&
        resolvedType != 'progress' &&
        resolvedType != 'motivation';
    if (useFirebase) {
      await FirebaseService.createPost(
        userId!,
        displayName ?? 'You',
        content,
        type: type,
        postType: resolvedType,
        structuredContent: structuredContent,
        caption: caption,
        activityId: activityId,
        activityCollection: activityCollection,
      );
    } else if (useSupabase) {
      await SupabaseService.createPost(content);
      await refreshFeed();
    } else {
      feedPosts.insert(0, {
        'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
        'authorId': userId,
        'authorName': displayName ?? 'You',
        if (user?.avatarPath != null) 'authorAvatarPath': user!.avatarPath,
        'content': content,
        'caption': caption,
        'postType': resolvedType,
        'structuredContent': structuredContent,
        if (activityId != null) 'activityId': activityId,
        if (activityCollection != null) 'activityCollection': activityCollection,
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'ts': DateTime.now().toIso8601String(),
        'type': type,
      });
      await _storage.saveFeed(feedPosts);
    }
    if (resolvedType == 'general' || resolvedType == 'motivation' || resolvedType == 'progress') {
      await awardXp(XpRewards.feedGeneral, 'Community post');
    } else if (isLinked) {
      await awardXp(
        resolvedType == 'pr' ? XpRewards.feedPrShare : XpRewards.feedLinked,
        'Linked community post',
      );
    }
    notifyListeners();
  }

  Future<void> setCoachContextPeriod(String period) async {
    coachContextPeriod = period;
    await _storage.setCoachContextPeriod(period);
    await refreshDailyLogsHistory();
    notifyListeners();
  }

  int get freeMessagesRemaining => user?.freeMessagesRemaining ?? 10;

  Future<void> awardXp(int amount, String reason) async {
    if (user == null) return;
    final g = Map<String, dynamic>.from(user!.gamification);
    final oldLevel = g['level'] as int? ?? 1;
    g['xp'] = (g['xp'] as int? ?? 0) + amount;
    g['level'] = ((g['xp'] as int) / 100).floor() + 1;
    final newLevel = g['level'] as int;
    if (newLevel > oldLevel) pendingLevelUp = newLevel;
    pendingXpToast = '+$amount XP · $reason';
    user!.gamification = g;
    AchievementService.afterActivity(user!, reason: reason);
    if (userId != null) {
      await _saveUser(userId!);
      if (useFirebase) {
        await FirebaseService.syncPublicProfile(userId!, g['xp'] as int, g['level'] as int);
        leaderboard = await FirebaseService.fetchLeaderboard();
      }
    }
    notifyListeners();
  }

  /// Spec alias - all food paths should call this or [logFood].
  Future<String?> addFoodEntry({
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String source = 'manual',
    double? servingG,
    String? photoUrl,
    int? fiber,
    int? sugar,
    int? sodiumMg,
  }) =>
      logFood(
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        source: source,
        servingG: servingG,
        photoUrl: photoUrl,
        fiber: fiber,
        sugar: sugar,
        sodiumMg: sodiumMg,
      );

  Future<String?> logFood({
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String source = 'manual',
    double? servingG,
    String? photoUrl,
    int? fiber,
    int? sugar,
    int? sodiumMg,
    String? mealType,
    bool? verified,
    String? barcode,
  }) async {
    if (user == null || userId == null) return null;
    await ensureDailyStateFresh(notify: false);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final micros = MacroHelpers.resolveMicros(
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      sodiumMg: sodiumMg,
    );
    final slot = mealType ?? MealTypeHelper.infer();
    final entry = <String, dynamic>{
      'date': today,
      'food': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': micros.fiber,
      'sugar': micros.sugar,
      'sodium_mg': micros.sodiumMg,
      'source': source,
      'meal_type': slot,
      'verified': verified ?? (source == 'barcode' || source == 'open_food_facts'),
      if (servingG != null) 'serving_g': servingG,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (barcode != null) 'barcode': barcode,
    };
    if (useFirebase) {
      final entryId = await FirebaseService.createFoodEntry(userId!, entry);
      entry['id'] = entryId;
      await _refreshTodayFoodEntries();
      _reconcileTodayNutritionFromEntries();
    } else {
      user!.foodLog.add(entry);
      _reconcileTodayNutritionFromEntries();
    }
    foodLogPulseTick++;
    HapticFeedback.lightImpact();
    _recordDailyActivity();
    _maybeSetFreshFunFact(FunFactsService.eventFact(user: user!, event: 'food_log'));
    await awardXp(XpRewards.logFood, 'Log food');
    await _saveUser(userId!);
    notifyListeners();
    return '✓ $name logged - ${user!.dailyMacrosLogged.calories} kcal today';
  }

  /// Removes a food entry logged today and reverts its macros/micros.
  /// Pass the exact map stored in [UserData.foodLog].
  Future<bool> deleteFoodEntry(Map<String, dynamic> entry) async {
    if (user == null || userId == null) return false;
    final idx = user!.foodLog.indexOf(entry);
    if (idx < 0) return false;
    user!.foodLog.removeAt(idx);
    if (useFirebase && entry['id'] is String) {
      try {
        await FirebaseService.deleteFoodEntry(userId!, entry['id'] as String);
      } catch (_) {}
      await _refreshTodayFoodEntries();
    }
    _reconcileTodayNutritionFromEntries();
    HapticFeedback.lightImpact();
    await _saveUser(userId!);
    notifyListeners();
    return true;
  }

  /// Undo helper for "just logged" toasts: removes the most recent entry.
  Future<void> undoLastFoodLog() async {
    if (user == null || user!.foodLog.isEmpty) return;
    await deleteFoodEntry(user!.foodLog.last);
  }

  Future<bool> updateFoodEntry(
    Map<String, dynamic> entry, {
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    int fiber = 0,
    int sugar = 0,
    int sodiumMg = 0,
    double? servingG,
    String? mealType,
  }) async {
    if (user == null || userId == null) return false;
    final idx = user!.foodLog.indexOf(entry);
    if (idx < 0) return false;

    final micros = MacroHelpers.resolveMicros(
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      sodiumMg: sodiumMg,
    );

    entry['calories'] = calories;
    entry['protein'] = protein;
    entry['carbs'] = carbs;
    entry['fat'] = fat;
    entry['fiber'] = micros.fiber;
    entry['sugar'] = micros.sugar;
    entry['sodium_mg'] = micros.sodiumMg;
    if (servingG != null) entry['serving_g'] = servingG;
    if (mealType != null) entry['meal_type'] = mealType;

    if (useFirebase && entry['id'] is String) {
      try {
        await FirebaseService.updateFoodEntry(userId!, entry['id'] as String, entry);
      } catch (_) {}
      await _refreshTodayFoodEntries();
    }
    _reconcileTodayNutritionFromEntries();
    await _saveUser(userId!);
    notifyListeners();
    return true;
  }

  Future<void> logWater(int ml) async {
    if (user == null || userId == null) return;
    await ensureDailyStateFresh(notify: false);
    user!.water += ml;
    notifyListeners();
    await _saveUser(userId!);
  }

  void showWaterSheet(BuildContext context) => showWaterLoggerSheet(context);

  void _syncDayCalorieTargets() {
    if (user == null) return;
    final training = user!.weeklyPlan.macros['calories'] ?? user!.tdee;
    final split = TdeeService.splitDayTargets(
      trainingDayCalories: training,
      baseMacros: user!.weeklyPlan.macros,
      goal: user!.goal.isEmpty ? 'maintain' : user!.goal,
    );
    user!.trainingDayCalories = split.training;
    user!.restDayCalories = split.rest;
  }

  Future<void> _recalculateTdeeIfNeeded({bool showBanner = true}) async {
    if (user == null) return;
    final oldTarget = user!.weeklyPlan.macros['calories'] ?? user!.tdee;
    final result = TdeeService.recalculateFromUser(user!);
    user!.tdee = result.plan.target;
    user!.weeklyPlan = WeeklyPlan(
      macros: result.macros,
      workouts: user!.weeklyPlan.workouts,
      meals: user!.weeklyPlan.meals,
      shoppingList: user!.weeklyPlan.shoppingList,
      deliveryOptions: user!.weeklyPlan.deliveryOptions,
    );
    _syncDayCalorieTargets();
    if (showBanner && (result.plan.target - oldTarget).abs() > 50) {
      pendingTdeeUpdate = PendingTdeeUpdate(oldTarget: oldTarget, newTarget: result.plan.target);
    }
  }

  Future<void> setTodayEnergyLevel(int level) async {
    await setMorningCheckin(energyLevel: level);
  }

  Future<void> setMorningCheckin({required int energyLevel, double? sleepHours}) async {
    if (user == null || userId == null) return;
    todayEnergyLevel = energyLevel.clamp(1, 4);
    if (sleepHours != null) lastNightSleepHours = sleepHours.clamp(0, 12);
    final today = _todayKey();
    _morningCheckinDate = today;
    notifyListeners();
    if (useFirebase) {
      await FirebaseService.saveDailyCheckin(userId!, today, {
        'energyLevel': todayEnergyLevel,
        'sleepHours': lastNightSleepHours,
      });
    }
  }

  Future<void> applyRecoveryAdjustment({required bool keepOriginal, bool lighter = true}) async {
    if (user == null || userId == null || todayWorkoutDay == null) return;
    if (keepOriginal) {
      workoutAdjustment = 'none';
      notifyListeners();
      return;
    }
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = days[DateTime.now().weekday % 7];
    final result = RecoveryAdjustmentService.apply(
      plan: user!.weeklyPlan,
      choice: lighter ? RecoveryChoice.lighter : RecoveryChoice.heavier,
      todayDay: today,
    );
    user!.weeklyPlan = WeeklyPlan(
      macros: user!.weeklyPlan.macros,
      workouts: result.adjustedWorkouts,
      meals: user!.weeklyPlan.meals,
      shoppingList: user!.weeklyPlan.shoppingList,
      deliveryOptions: user!.weeklyPlan.deliveryOptions,
    );
    todayActivity.workoutStatus = result.status;
    workoutAdjustment = result.adjustment;
    notifyListeners();
    await _saveUser(userId!);
  }

  Future<void> setWeeklyGoal({
    required GoalType type,
    required double targetValue,
    required int targetDays,
    String createdBy = 'user',
  }) async {
    if (userId == null) return;
    final active = activeGoals.where((g) => g.isActive).length;
    if (active >= 2) {
      activeGoals = activeGoals.map((g) => g.copyWith(isActive: false)).toList();
    }
    final goal = WeeklyGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      targetValue: targetValue,
      targetDays: targetDays,
      weekStart: WeeklyGoal.fromJson('x', {'weekStart': DateTime.now().toIso8601String()}).weekStart,
      createdBy: createdBy,
    );
    activeGoals = [...activeGoals.where((g) => g.isActive), goal];
    user!.weeklyGoals = List.from(activeGoals);
    notifyListeners();
    if (useFirebase) await FirebaseService.saveWeeklyGoal(userId!, goal);
    else await _saveUser(userId!);
  }

  Future<void> checkWeeklyGoals() async {
    if (user == null || activeGoals.isEmpty) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final gamification = Map<String, dynamic>.from(user!.gamification);
    if (gamification['weeklyGoalLastEvalDate'] == yesterday) return;

    final yLog = _dailyLogForDate(yesterday);
    var changed = false;
    activeGoals = activeGoals.map((g) {
      if (!g.isActive) return g;
      final met = _goalMetForDay(g, yLog, dayKey: yesterday);
      if (met && g.daysAchieved < g.targetDays) {
        changed = true;
        return g.copyWith(daysAchieved: g.daysAchieved + 1);
      }
      return g;
    }).toList();

    gamification['weeklyGoalLastEvalDate'] = yesterday;
    user!.gamification = gamification;
    user!.weeklyGoals = List.from(activeGoals);
    if (userId != null) await _saveUser(userId!);

    if (changed) {
      notifyListeners();
      if (useFirebase && userId != null) {
        for (final g in activeGoals.where((g) => g.isActive)) {
          await FirebaseService.saveWeeklyGoal(userId!, g);
        }
      }
    }
  }

  /// Sunday / week rollover - award XP and offer feed share when goals are met.
  Future<void> evaluateEndedWeeklyGoals() async {
    if (user == null || activeGoals.isEmpty) return;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    var changed = false;
    final next = <WeeklyGoal>[];

    for (final g in activeGoals) {
      if (!g.isActive) {
        next.add(g);
        continue;
      }
      final weekEnd = g.weekStart.add(const Duration(days: 7));
      if (today.isBefore(weekEnd)) {
        next.add(g);
        continue;
      }
      changed = true;
      if (g.daysAchieved >= g.targetDays) {
        await awardXp(XpRewards.weeklyGoalCrushed, 'Weekly goal crushed');
        pendingGoalCelebration = PendingGoalCelebration(
          goalLabel: g.label,
          daysAchieved: g.daysAchieved,
          targetDays: g.targetDays,
        );
      }
      final closed = g.copyWith(isActive: false);
      next.add(closed);
      if (useFirebase && userId != null) {
        await FirebaseService.saveWeeklyGoal(userId!, closed);
      }
    }

    if (changed) {
      activeGoals = next;
      user!.weeklyGoals = List.from(next);
      if (userId != null) await _saveUser(userId!);
      notifyListeners();
    }
  }

  bool _wasActiveOnDate(String date) {
    if (user == null) return false;
    final last = user!.gamification['lastActiveDate'] as String?;
    if (last == date) return true;
    final log = _dailyLogForDate(date);
    if (log == null) return false;
    return ((log['calories_logged'] as num?)?.toInt() ?? 0) > 0 ||
        log['workout_status'] == 'completed' ||
        log['workout_status'] == 'modified';
  }

  bool _weightMetOnDate(double target, String date) {
    if (user == null) return false;
    final entry = user!.weightHistory.cast<Map<String, dynamic>?>().firstWhere(
          (w) => w?['date'] == date,
          orElse: () => null,
        );
    if (entry != null) return (entry['weight'] as num).toDouble() <= target;
    return user!.weight <= target;
  }

  bool _goalMetForDay(WeeklyGoal g, Map<String, dynamic>? log, {required String dayKey}) {
    if (user == null) return false;
    return switch (g.type) {
      GoalType.protein =>
        log != null && ((log['protein_logged'] as num?)?.toInt() ?? 0) >= g.targetValue,
      GoalType.calories =>
        log != null && ((log['calories_logged'] as num?)?.toInt() ?? 0) <= g.targetValue,
      GoalType.workouts => log != null && log['workout_status'] == 'completed',
      GoalType.water =>
        log != null && ((log['water_ml'] as num?)?.toDouble() ?? 0) >= g.targetValue * 1000,
      GoalType.steps =>
        ((log != null ? (log['steps'] as num?)?.toDouble() : null) ?? user!.steps) >= g.targetValue,
      GoalType.streak => _wasActiveOnDate(dayKey) &&
          (user!.gamification['streak'] as int? ?? 0) >= g.targetValue,
      GoalType.weight => _weightMetOnDate(g.targetValue, dayKey),
    };
  }

  Future<void> _loadTodayCheckin() async {
    if (!useFirebase || userId == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await FirebaseService.fetchDailyCheckin(userId!, today);
    if (data != null) {
      todayEnergyLevel = data['energyLevel'] as int? ?? 0;
      lastNightSleepHours = (data['sleepHours'] as num?)?.toDouble() ?? 0;
      _morningCheckinDate = today;
    }
  }

  void startRestTimer({required int seconds, String? exerciseName}) {
    // Rest timer lives in RestTimerController - see main.dart provider.
  }

  Future<String?> logWeight(double kg, {DateTime? date}) async {
    if (user == null || userId == null) return null;
    final day = WeightHistoryHelper.dayKey(date ?? DateTime.now());
    final updated = WeightHistoryHelper.upsert(user!.weightHistory, kg, date: day);
    user!.weight = WeightHistoryHelper.latestWeight(user!.weightHistory);
    if (useFirebase) await FirebaseService.logWeight(userId!, kg, date: day);
    else if (useSupabase) await SupabaseService.logWeight(kg, date: day);
    if (WeightHistoryHelper.isToday(day)) {
      user!.weight = kg;
      await _recalculateTdeeIfNeeded();
    }
    HapticFeedback.lightImpact();
    await awardXp(XpRewards.logWeight, 'Log weight');
    await _saveUser(userId!);
    notifyListeners();
    final today = WeightHistoryHelper.isToday(day);
    final label = updated
        ? (today ? "Updated today's weight" : 'Updated weigh-in')
        : (today ? 'Weight logged' : 'Past weigh-in logged');
    return '✓ $label - ${kg.toStringAsFixed(1)} kg';
  }

  Future<String?> logPersonalRecord({
    required String exerciseName,
    required double value,
    required String unit,
    bool awardXpOnSave = true,
    bool checkForCelebration = false,
  }) async {
    if (user == null || userId == null) return null;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final isNew = PersonalRecordHelper.isNewBest(
      user!.personalRecords,
      exercise: exerciseName,
      value: value,
      unit: unit,
    );
    final previous = PersonalRecordHelper.previousBest(
      user!.personalRecords,
      exercise: exerciseName,
      unit: unit,
    );
    final record = PersonalRecordHelper.normalize({
      'exercise': exerciseName.trim(),
      'value': value,
      'unit': unit,
      'date': today,
    });
    String? recordId;
    if (useFirebase) {
      recordId = await FirebaseService.logPersonalRecord(
        userId!,
        exerciseName: exerciseName,
        value: value,
        unit: unit,
      );
      record['id'] = recordId;
    } else if (useSupabase) {
      await SupabaseService.logPersonalRecord(exerciseName: exerciseName, value: value, unit: unit, date: today);
    }
    user!.personalRecords.insert(0, record);
    user!.personalRecords = PersonalRecordHelper.merge(user!.personalRecords);
    if (awardXpOnSave) {
      await awardXp(isNew ? XpRewards.prDetected : XpRewards.logPrManual, isNew ? 'New PR' : 'Log PR');
    }
    if (isNew) HapticFeedback.heavyImpact();
    if (checkForCelebration && isNew) {
      pendingPrCelebration = PendingPrCelebration(
        exercise: exerciseName,
        value: value,
        unit: unit,
        recordId: recordId,
        previousBest: previous,
      );
    }
    await _saveUser(userId!);
    notifyListeners();
    return '✓ PR saved - ${record['exercise']} ${PersonalRecordHelper.formatValue(value, unit)}';
  }

  Future<String?> completeTodayWorkout({
    required List<LoggedExercise> exercises,
    required int durationMinutes,
    String? workoutName,
    Map<String, List<SetLog>>? detailedSets,
    Map<String, SessionLog>? previousSessions,
  }) async {
    if (user == null || userId == null) return null;
    final name = workoutName ?? todayWorkoutDay?.focus ?? 'Workout';
    final metValues = exercises.map((e) => e.met).toList();
    final avgMet = metValues.isEmpty
        ? 4.0
        : metValues.reduce((a, b) => a + b) / metValues.length;
    final burned = ActivityCalorieService.workoutCalories(
      met: avgMet,
      weightKg: user!.weight,
      durationMinutes: durationMinutes.toDouble(),
    );
    final completedAt = DateTime.now().toIso8601String().substring(11, 16);
    final session = WorkoutSessionLog(
      status: WorkoutStatus.completed,
      workoutName: name,
      completedAt: completedAt,
      exercises: exercises,
      caloriesBurned: burned,
      durationMinutes: durationMinutes,
    );
    String? sessionId;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (useFirebase) {
      sessionId = await FirebaseService.createWorkoutSession(userId!, {
        'date': today,
        ...session.toJson(),
      });
    }
    todayActivity
      ..workoutStatus = WorkoutStatus.completed
      ..workoutName = name
      ..workoutCalories = burned
      ..todayWorkoutSessionId = sessionId
      ..session = session.copyWith(sessionId: sessionId);

    for (final ex in exercises) {
      if (ex.weightKg != null && ex.weightKg! > 0) {
        final isNew = PersonalRecordHelper.isNewBest(
          user!.personalRecords,
          exercise: ex.name,
          value: ex.weightKg!,
          unit: 'kg',
        );
        if (isNew) {
          await logPersonalRecord(
            exerciseName: ex.name,
            value: ex.weightKg!,
            unit: 'kg',
            checkForCelebration: true,
          );
        }
      }
    }

    for (final ex in exercises) {
      final sets = detailedSets?[ex.name];
      final previous = previousSessions?[ex.name];
      final currentSets = sets ??
          List.generate(
            ex.sets,
            (_) => SetLog(reps: ex.reps, weightKg: ex.weightKg, targetReps: ex.reps),
          );
      final suggestion = ProgressiveOverloadService.suggestNext(
        exerciseId: ex.name.toLowerCase().replaceAll(' ', '_'),
        exerciseName: ex.name,
        previous: previous,
        current: SessionLog(date: today, sets: currentSets),
        prHit: PersonalRecordHelper.isNewBest(
          user!.personalRecords,
          exercise: ex.name,
          value: ex.weightKg ?? 0,
          unit: 'kg',
        ),
      );
      if (suggestion != null) {
        recentProgressions.insert(0, suggestion);
        user!.nextSessionTargets[ex.name] = suggestion.suggestedWeightKg;
      }
      final vol = currentSets.fold<double>(0, (s, set) => s + (set.weightKg ?? 0) * set.reps);
      if (vol > 0) {
        final key = ex.name.toLowerCase().contains('leg') || ex.name.toLowerCase().contains('squat')
            ? 'Legs'
            : ex.name.toLowerCase().contains('row') || ex.name.toLowerCase().contains('pull')
                ? 'Pull'
                : 'Push';
        weeklyVolume[key] = (weeklyVolume[key] ?? 0) + vol;
      }
      if (useFirebase && userId != null) {
        final exId = AppState.exerciseId(ex.name);
        final setPayload = currentSets.map((s) => {'reps': s.reps, 'weight': s.weightKg ?? 0}).toList();
        await FirebaseService.saveExerciseSession(userId!, exId, {
          'date': today,
          'sets': setPayload,
          'volume': vol,
        });
        _exerciseHistoryCache[exId] = SessionLog(date: today, sets: currentSets);
      }
    }
    recentProgressions = recentProgressions.take(10).toList();
    _rebuildWeeklyVolumeFromLogs();

    HapticFeedback.mediumImpact();
    _recordDailyActivity();
    _maybeSetFreshFunFact(FunFactsService.eventFact(user: user!, event: 'workout_complete'));
    await awardXp(XpRewards.workoutComplete, 'Workout complete');
    final g = Map<String, dynamic>.from(user!.gamification);
    g['streak'] = (g['streak'] as int? ?? 0) + 1;
    user!.gamification = g;
    await _saveUser(userId!);
    notifyListeners();
    return '✓ $name complete - ${burned.round()} kcal burned (+${XpRewards.workoutComplete} XP)';
  }

  Future<String?> logCustomWorkout({
    required String description,
    int durationMinutes = 45,
  }) async {
    if (user == null || userId == null) return null;
    final burned = ActivityCalorieService.workoutCalories(
      met: 4.0,
      weightKg: user!.weight,
      durationMinutes: durationMinutes.toDouble(),
    );
    final session = WorkoutSessionLog(
      status: WorkoutStatus.modified,
      workoutName: todayWorkoutDay?.focus,
      customDescription: description,
      completedAt: DateTime.now().toIso8601String().substring(11, 16),
      caloriesBurned: burned,
      durationMinutes: durationMinutes,
    );
    String? sessionId;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (useFirebase) {
      sessionId = await FirebaseService.createWorkoutSession(userId!, {
        'date': today,
        ...session.toJson(),
      });
    }
    todayActivity
      ..workoutStatus = WorkoutStatus.modified
      ..workoutName = todayWorkoutDay?.focus
      ..workoutCalories = burned
      ..todayWorkoutSessionId = sessionId
      ..session = session.copyWith(sessionId: sessionId);
    await awardXp(XpRewards.customWorkoutLogged, 'Custom workout');
    await _saveUser(userId!);
    notifyListeners();
    return '✓ Logged custom workout - ${burned.round()} kcal burned';
  }

  Future<String?> skipTodayWorkout({String? reason}) async {
    if (user == null || userId == null) return null;
    final session = WorkoutSessionLog(
      status: WorkoutStatus.skipped,
      workoutName: todayWorkoutDay?.focus,
      skipReason: reason,
    );
    String? sessionId;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (useFirebase) {
      sessionId = await FirebaseService.createWorkoutSession(userId!, {
        'date': today,
        ...session.toJson(),
      });
    }
    todayActivity
      ..workoutStatus = WorkoutStatus.skipped
      ..workoutName = todayWorkoutDay?.focus
      ..workoutCalories = 0
      ..todayWorkoutSessionId = sessionId
      ..session = session.copyWith(sessionId: sessionId);
    await _saveUser(userId!);
    notifyListeners();
    return '✓ Workout skipped for today';
  }

  Future<String?> logMealFromPlan(Meal meal) async {
    if (user == null || userId == null) return null;
    user!.resetMealsLoggedIfNewDay();
    if (user!.isMealLogged(meal.mealType)) return null;
    final chip = await logFood(
      name: meal.name,
      calories: meal.macros['calories'] ?? 0,
      protein: meal.macros['protein'] ?? 0,
      carbs: meal.macros['carbs'] ?? 0,
      fat: meal.macros['fat'] ?? 0,
      source: 'meal_plan',
    );
    user!.mealsLoggedToday = [...user!.mealsLoggedToday, meal.mealType];
    await _saveUser(userId!);
    notifyListeners();
    return chip;
  }

  Future<void> setActiveCustomWorkout(String? workoutId) async {
    if (user == null || userId == null) return;
    for (final w in user!.customWorkouts) {
      w.isActive = w.id == workoutId;
      if (w.id != workoutId) w.completedToday = [];
    }
    await saveCustomWorkouts(user!.customWorkouts);
  }

  Future<String?> completeWorkoutExercise(String workoutId, String exerciseName) async {
    if (user == null || userId == null) return null;
    final w = user!.customWorkouts.where((x) => x.id == workoutId).firstOrNull;
    if (w == null || w.completedToday.contains(exerciseName)) return null;
    w.completedToday = [...w.completedToday, exerciseName];
    if (useFirebase) {
      await FirebaseService.logCompletedExercise(userId!, workoutId: workoutId, exerciseName: exerciseName);
    }
    await awardXp(XpRewards.completeExercise, 'Complete exercise');
    if (w.completedToday.length >= w.exercises.length) {
      await awardXp(XpRewards.finishCustomWorkout, 'Complete workout');
      final g = Map<String, dynamic>.from(user!.gamification);
      g['streak'] = (g['streak'] as int? ?? 0) + 1;
      user!.gamification = g;
    }
    await _saveUser(userId!);
    notifyListeners();
    return '✓ $exerciseName complete';
  }

  Future<void> decrementFreeMessage() async {
    if (user == null) return;
    user!.resetFreeMessagesIfNewDay();
    final g = Map<String, dynamic>.from(user!.gamification);
    final remaining = (g['freeMessagesRemaining'] as int? ?? 10) - 1;
    g['freeMessagesRemaining'] = remaining.clamp(0, 10);
    g['freeMessagesDate'] = DateTime.now().toIso8601String().substring(0, 10);
    user!.gamification = g;
    if (userId != null) await _saveUser(userId!);
  }

  Future<void> refreshDailyLogsHistory() async {
    if (!useFirebase || userId == null) return;
    dailyLogsHistory = await FirebaseService.fetchDailyLogsRange(userId!, 30);
    _rebuildWeeklyVolumeFromLogs();
    notifyListeners();
  }

  Future<void> refreshLeaderboard() async {
    if (!useFirebase) return;
    leaderboard = await FirebaseService.fetchLeaderboard();
    notifyListeners();
  }

  MacroLog macrosForPeriod(String period) {
    if (user == null) return MacroLog();
    if (period == 'day') return user!.dailyMacrosLogged;
    final logs = dailyLogsHistory;
    if (logs.isEmpty) return user!.dailyMacrosLogged;
    var cal = 0, pro = 0, carbs = 0, fat = 0;
    for (final l in logs) {
      cal += (l['calories_logged'] as num?)?.toInt() ?? 0;
      pro += (l['protein_logged'] as num?)?.toInt() ?? 0;
      carbs += (l['carbs_logged'] as num?)?.toInt() ?? 0;
      fat += (l['fat_logged'] as num?)?.toInt() ?? 0;
    }
    final n = logs.length.clamp(1, 30);
    return MacroLog(calories: (cal / n).round(), protein: (pro / n).round(), carbs: (carbs / n).round(), fat: (fat / n).round());
  }
}
