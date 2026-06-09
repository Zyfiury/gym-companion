import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/release_config.dart';
import '../models/user_data.dart';
import '../services/auth_service.dart' show AuthService, TestAccounts;
import '../services/analytics_service.dart';
import '../services/backend_config.dart';
import '../services/chat_service.dart';
import '../services/delivery_service.dart';
import '../services/firebase_service.dart';
import '../services/groq_chat_service.dart';
import '../services/meal_variety_service.dart';
import '../services/openclaw_service.dart';
import '../services/plan_agent_service.dart';
import '../services/profile_mapper.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/cheap_meal_plan_service.dart';
import '../services/user_md_sync_service.dart';
import '../services/vision_calorie_service.dart';
import '../services/health_service.dart';
import '../services/tdee_service.dart';
import '../utils/personal_record_helper.dart';
import '../utils/weight_history.dart';
import '../services/workout_adaptation_service.dart';
import '../services/location_service.dart';

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
    }
    user?.resetMealsLoggedIfNewDay();
    if (useFirebase && userId != null) {
      dailyLogsHistory = await FirebaseService.fetchDailyLogsRange(userId!, 30);
      leaderboard = await FirebaseService.fetchLeaderboard();
    }
    await refreshHealthData();
    await _migrateWorkoutPlanIfNeeded(uid);
    await _checkLocationPrompt();
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

  bool healthConnected = false;
  String coachContextPeriod = 'day';
  List<Map<String, dynamic>> dailyLogsHistory = [];
  List<Map<String, dynamic>> leaderboard = [];

  Future<void> refreshHealthData({bool requestIfNeeded = false}) async {
    if (user == null) return;
    try {
      var granted = await HealthService.hasPermissions();
      if (!granted && requestIfNeeded) {
        granted = await HealthService.requestPermissions();
      }
      healthConnected = granted;
      if (granted) {
        final steps = await HealthService.getTodaySteps();
        user!.steps = steps.toDouble();
        if (userId != null) await _saveUser(userId!);
      }
    } catch (_) {
      healthConnected = false;
    }
    notifyListeners();
  }

  Future<void> _saveUser(String uid) async {
    await _storage.saveUser(uid, user!);
    if (useFirebase) {
      await FirebaseService.saveUserData(user!);
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
      });
    }
    user!.dailyMacrosLogged.calories += cal;
    user!.dailyMacrosLogged.protein += pro;
    user!.dailyMacrosLogged.carbs += carbs;
    user!.dailyMacrosLogged.fat += fat;
    await _saveUser(userId!);
    notifyListeners();
    return '✅ Logged ${items.where((i) => !i.blocked).map((i) => '${i.grams.round()}g ${i.name}').join(', ')} — $cal kcal, P ${pro}g';
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
    user!.weeklyPlan = WeeklyPlan(
      macros: user!.weeklyPlan.macros,
      workouts: user!.weeklyPlan.workouts,
      meals: meals,
      shoppingList: user!.weeklyPlan.shoppingList,
    );
    MealVarietyService.recordMeal(user!, newMeal);
    await _saveUser(userId!);
    notifyListeners();
  }

  Future<void> shuffleMeals() async {
    if (user == null || userId == null) return;
    final meals = MealVarietyService.generateDailyPlan(user!);
    user!.weeklyPlan = WeeklyPlan(
      macros: user!.weeklyPlan.macros,
      workouts: user!.weeklyPlan.workouts,
      meals: meals,
      shoppingList: user!.weeklyPlan.shoppingList,
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

  Future<void> addLocalExchange(String userText, String reply) async {
    chatMessages.add(ChatMessage(role: 'user', content: userText));
    chatMessages.add(ChatMessage(role: 'assistant', content: reply));
    await _saveChat(userId!);
    notifyListeners();
  }

  Future<String> sendChat(String text) async {
    if (user == null || userId == null) return '';

    if (!await SubscriptionService.isPro()) {
      if (user!.freeMessagesRemaining <= 0) return 'FREE_LIMIT';
    }

    chatMessages.add(ChatMessage(role: 'user', content: text));
    chatTyping = true;
    notifyListeners();

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
        SubscriptionService.recordChatMessage();
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
      SubscriptionService.recordChatMessage();
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
      SubscriptionService.recordChatMessage();
      notifyListeners();
      return reply;
    }

    final ruleResult = _rulesChat.process(text, user!);
    final ruleHandled = ruleResult.updatedUser != null || ruleResult.reply.contains('Blocked');

    if (ruleHandled) {
      if (ruleResult.updatedUser != null) user = ruleResult.updatedUser;
      reply = ruleResult.reply;
    } else if (BackendConfig.hasGroq) {
      final history = chatMessages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final groq = await GroqChatService.chat(
        userMessage: text,
        userProfile: ProfileMapper.toGroqContext(
          user!,
          displayName: displayName,
          contextPeriod: coachContextPeriod,
          dailyLogsHistory: dailyLogsHistory,
        ),
        history: history,
      );
      final chip = await _applyAiActions(groq.actions);
      reply = groq.displayText.isNotEmpty ? groq.displayText : ruleResult.reply;
      chatMessages.add(ChatMessage(role: 'assistant', content: reply, actionChip: chip));
      await _saveChat(userId!);
      chatTyping = false;
      await decrementFreeMessage();
      SubscriptionService.recordChatMessage();
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
    await decrementFreeMessage();
    SubscriptionService.recordChatMessage();
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
          chip = await logWeight((a.data['weight_kg'] as num).toDouble());
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
          await awardXp(20, 'Complete workout');
          final g = Map<String, dynamic>.from(user!.gamification);
          g['streak'] = (g['streak'] as int? ?? 0) + 1;
          user!.gamification = g;
          chip = '✓ Workout complete — +20 XP';
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
  }) async {
    if (userId == null) return;
    if (useFirebase) {
      await FirebaseService.createPost(
        userId!,
        displayName ?? 'You',
        content,
        type: type,
        postType: postType,
        structuredContent: structuredContent,
        caption: caption,
      );
    } else if (useSupabase) {
      await SupabaseService.createPost(content);
      await refreshFeed();
    } else {
      feedPosts.insert(0, {
        'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
        'authorId': userId,
        'authorName': displayName ?? 'You',
        'content': content,
        'caption': caption,
        'postType': postType ?? type,
        'structuredContent': structuredContent,
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'ts': DateTime.now().toIso8601String(),
        'type': type,
      });
      await _storage.saveFeed(feedPosts);
    }
    await awardXp(10, 'Community post');
    notifyListeners();
  }

  Future<void> setCoachContextPeriod(String period) async {
    coachContextPeriod = period;
    await _storage.setCoachContextPeriod(period);
    notifyListeners();
  }

  int get freeMessagesRemaining => user?.freeMessagesRemaining ?? 10;

  Future<void> awardXp(int amount, String reason) async {
    if (user == null) return;
    final g = Map<String, dynamic>.from(user!.gamification);
    g['xp'] = (g['xp'] as int? ?? 0) + amount;
    g['level'] = ((g['xp'] as int) / 100).floor() + 1;
    user!.gamification = g;
    if (userId != null) {
      await _saveUser(userId!);
      if (useFirebase) {
        await FirebaseService.syncPublicProfile(userId!, g['xp'] as int, g['level'] as int);
        leaderboard = await FirebaseService.fetchLeaderboard();
      }
    }
    notifyListeners();
  }

  Future<String?> logFood({
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String source = 'manual',
    double? servingG,
  }) async {
    if (user == null || userId == null) return null;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    user!.dailyMacrosLogged.calories += calories;
    user!.dailyMacrosLogged.protein += protein;
    user!.dailyMacrosLogged.carbs += carbs;
    user!.dailyMacrosLogged.fat += fat;
    user!.foodLog.add({
      'date': today,
      'food': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'source': source,
      if (servingG != null) 'serving_g': servingG,
    });
    await awardXp(5, 'Log food');
    await _saveUser(userId!);
    notifyListeners();
    return '✓ $name logged — ${user!.dailyMacrosLogged.calories} kcal today';
  }

  Future<void> logWater(int ml) async {
    if (user == null || userId == null) return;
    user!.water = ml.toDouble();
    await _saveUser(userId!);
    notifyListeners();
  }

  Future<String?> logWeight(double kg, {DateTime? date}) async {
    if (user == null || userId == null) return null;
    final day = WeightHistoryHelper.dayKey(date ?? DateTime.now());
    final updated = WeightHistoryHelper.upsert(user!.weightHistory, kg, date: day);
    user!.weight = WeightHistoryHelper.latestWeight(user!.weightHistory);
    if (useFirebase) await FirebaseService.logWeight(userId!, kg, date: day);
    else if (useSupabase) await SupabaseService.logWeight(kg, date: day);
    await awardXp(5, 'Log weight');
    await _saveUser(userId!);
    notifyListeners();
    final today = WeightHistoryHelper.isToday(day);
    final label = updated
        ? (today ? "Updated today's weight" : 'Updated weigh-in')
        : (today ? 'Weight logged' : 'Past weigh-in logged');
    return '✓ $label — ${kg.toStringAsFixed(1)} kg';
  }

  Future<String?> logPersonalRecord({
    required String exerciseName,
    required double value,
    required String unit,
  }) async {
    if (user == null || userId == null) return null;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final record = PersonalRecordHelper.normalize({
      'exercise': exerciseName.trim(),
      'value': value,
      'unit': unit,
      'date': today,
    });
    user!.personalRecords.insert(0, record);
    user!.personalRecords = PersonalRecordHelper.merge(user!.personalRecords);
    if (useFirebase) {
      await FirebaseService.logPersonalRecord(userId!, exerciseName: exerciseName, value: value, unit: unit);
    } else if (useSupabase) {
      await SupabaseService.logPersonalRecord(exerciseName: exerciseName, value: value, unit: unit, date: today);
    }
    await awardXp(15, 'Log PR');
    await _saveUser(userId!);
    notifyListeners();
    return '✓ PR saved — ${record['exercise']} ${PersonalRecordHelper.formatValue(value, unit)}';
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
    await awardXp(5, 'Complete exercise');
    if (w.completedToday.length >= w.exercises.length) {
      await awardXp(15, 'Complete workout');
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
    final g = Map<String, dynamic>.from(user!.gamification);
    final remaining = (g['freeMessagesRemaining'] as int? ?? 10) - 1;
    g['freeMessagesRemaining'] = remaining.clamp(0, 10);
    user!.gamification = g;
    if (userId != null) await _saveUser(userId!);
  }

  Future<void> refreshDailyLogsHistory() async {
    if (!useFirebase || userId == null) return;
    dailyLogsHistory = await FirebaseService.fetchDailyLogsRange(userId!, 30);
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
