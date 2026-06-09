import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_data.dart';
import 'profile_mapper.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // AUTH
  static Future<AuthResponse> signUp(String email, String password, String name) async {
    final res = await client.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await client.from('profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'name': name,
        'profile_complete': false,
      });
    }
    return res;
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async => client.auth.signOut();

  static Stream<AuthState> get authStream => client.auth.onAuthStateChange;

  // PROFILE
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await client.from('profiles').select().eq('id', user.id).single();
    } catch (_) {
      return null;
    }
  }

  static Future<void> upsertProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('profiles').upsert({'id': user.id, ...data});
  }

  static Future<UserData?> loadUserData() async {
    final profile = await getProfile();
    if (profile == null) return null;
    final todayLog = await getTodayLog();
    final weightHistory = await getWeightHistory();
    final prs = await getPersonalRecords();
    final weekPlan = await getCurrentWeekPlan();
    return ProfileMapper.fromSupabase(
      profile: profile,
      todayLog: todayLog,
      weightHistory: weightHistory,
      personalRecords: prs,
      weekPlan: weekPlan,
    );
  }

  static Future<void> saveUserData(UserData data) async {
    final user = currentUser;
    if (user == null) return;
    await upsertProfile(ProfileMapper.toProfileRow(data));
    await updateTodayLog({
      'calories_logged': data.dailyMacrosLogged.calories,
      'protein_logged': data.dailyMacrosLogged.protein.toDouble(),
      'carbs_logged': data.dailyMacrosLogged.carbs.toDouble(),
      'fat_logged': data.dailyMacrosLogged.fat.toDouble(),
      'food_log': data.foodLog,
    });
    await saveWeeklyPlan(data.weeklyPlan.toJson());
  }

  // DAILY LOG
  static Future<Map<String, dynamic>> getTodayLog() async {
    final user = currentUser;
    if (user == null) return {};
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      return await client.from('daily_logs').select().eq('user_id', user.id).eq('date', today).single();
    } catch (_) {
      final newLog = {
        'user_id': user.id,
        'date': today,
        'calories_logged': 0,
        'protein_logged': 0,
        'carbs_logged': 0,
        'fat_logged': 0,
        'food_log': <Map<String, dynamic>>[],
        'meals': <String, dynamic>{},
      };
      await client.from('daily_logs').insert(newLog);
      return newLog;
    }
  }

  static Future<void> updateTodayLog(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await client.from('daily_logs').upsert({'user_id': user.id, 'date': today, ...data});
  }

  // WEIGHT
  static Future<List<Map<String, dynamic>>> getWeightHistory() async {
    final user = currentUser;
    if (user == null) return [];
    final res = await client.from('weight_history').select().eq('user_id', user.id).order('date', ascending: true).limit(30);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> logWeight(double weightKg, {String? date}) async {
    final user = currentUser;
    if (user == null) return;
    final day = date ?? DateTime.now().toIso8601String().substring(0, 10);
    await client.from('weight_history').upsert({'user_id': user.id, 'date': day, 'weight_kg': weightKg});
    final history = await getWeightHistory();
    final latest = history.isEmpty
        ? weightKg
        : (history.last['weight_kg'] as num?)?.toDouble() ?? weightKg;
    await upsertProfile({'weight_kg': latest});
  }

  // PRs
  static Future<List<Map<String, dynamic>>> getPersonalRecords() async {
    final user = currentUser;
    if (user == null) return [];
    final res = await client.from('personal_records').select().eq('user_id', user.id).order('date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> addPersonalRecord(String exercise, double weightKg, int reps) async {
    await logPersonalRecord(exerciseName: exercise, value: weightKg, unit: 'kg');
  }

  static Future<void> logPersonalRecord({
    required String exerciseName,
    required double value,
    required String unit,
    String? date,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final day = date ?? DateTime.now().toIso8601String().substring(0, 10);
    await client.from('personal_records').insert({
      'user_id': user.id,
      'exercise': exerciseName,
      'value': value,
      'unit': unit,
      'date': day,
    });
  }

  // FEED
  static Future<List<Map<String, dynamic>>> getFeedPosts() async {
    final res = await client.from('feed_posts').select().order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(res).map(mapFeedPost).toList();
  }

  static Map<String, dynamic> mapFeedPost(Map<String, dynamic> p) => {
        'id': p['id'],
        'authorId': p['user_id'],
        'authorName': p['author_name'] ?? 'Athlete',
        'content': p['content'],
        'likes': List<String>.from((p['liked_by'] as List?)?.map((e) => e.toString()) ?? []),
        'comments': <Map<String, dynamic>>[],
        'ts': p['created_at'],
        'type': 'workout',
      };

  static Future<void> createPost(String content) async {
    final user = currentUser;
    if (user == null) return;
    final profile = await getProfile();
    await client.from('feed_posts').insert({
      'user_id': user.id,
      'author_name': profile?['name'] ?? 'Athlete',
      'content': content,
    });
  }

  static Future<void> toggleLike(String postId, List<String> currentLikedBy) async {
    final user = currentUser;
    if (user == null) return;
    final isLiked = currentLikedBy.contains(user.id);
    final newLikedBy = isLiked ? currentLikedBy.where((id) => id != user.id).toList() : [...currentLikedBy, user.id];
    await client.from('feed_posts').update({
      'likes': newLikedBy.length,
      'liked_by': newLikedBy,
    }).eq('id', postId);
  }

  // WEEKLY PLAN
  static Future<Map<String, dynamic>?> getCurrentWeekPlan() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final res = await client.from('weekly_plans').select().eq('user_id', user.id).eq('week_start', _monday()).single();
      return res['plan'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveWeeklyPlan(Map<String, dynamic> plan) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('weekly_plans').upsert({
      'user_id': user.id,
      'week_start': _monday(),
      'plan': plan,
    });
  }

  static Future<void> addXP(int amount) async {
    final profile = await getProfile();
    if (profile == null) return;
    final currentXP = (profile['xp'] as int? ?? 0) + amount;
    final level = (currentXP / 100).floor() + 1;
    await upsertProfile({'xp': currentXP, 'level': level});
  }

  static String _monday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.toIso8601String().substring(0, 10);
  }
}
