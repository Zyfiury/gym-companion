import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_data.dart';
import '../models/weekly_goal.dart';
import '../utils/personal_record_helper.dart';
import '../utils/weight_history.dart';

/// Firebase Auth + Cloud Firestore - primary backend for production mobile.
class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  /// Web client ID from `google-services.json` - required for Firebase Google Sign-In id tokens.
  static const _googleWebClientId =
      '928816456435-bktcdi6j6b9bbc3lpkjck25mck1ddl8m.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleWebClientId,
  );

  static const _firestoreTimeout = Duration(seconds: 10);

  /// Firestore writes must never block auth - API may be disabled or rules pending.
  static Future<void> _firestoreOp(String label, Future<void> Function() op) async {
    try {
      await op().timeout(_firestoreTimeout);
    } catch (e) {
      debugPrint('Firestore $label failed (app continues locally): $e');
    }
  }

  static User? get currentUser {
    try {
      if (Firebase.apps.isEmpty) return null;
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static Future<void> enableOfflineSync() async {
    try {
      db.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      debugPrint('Firestore offline persistence: $e');
    }
  }

  // ─── AUTH ───────────────────────────────────────────────────────────────────

  static Future<UserCredential> signUp(String email, String password, String name) async {
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);
    final uid = cred.user!.uid;
    await _firestoreOp('signUp create user', () => db.collection('users').doc(uid).set({
          'email': email,
          'name': name,
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'gamification': {'xp': 0, 'level': 1, 'streak': 0, 'achievements': <String>[]},
        }));
    return cred;
  }

  static Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> sendPasswordResetEmail(String email) {
    return auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'cancelled', message: 'Sign in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await auth.signInWithCredential(credential);
    await _ensureUserDocument(cred.user!);
    return cred;
  }

  static Future<UserCredential> signInWithApple() async {
    if (!Platform.isIOS) {
      throw FirebaseAuthException(code: 'unsupported', message: 'Apple Sign-In is iOS only');
    }
    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCred.identityToken,
      accessToken: appleCred.authorizationCode,
    );
    final cred = await auth.signInWithCredential(oauth);
    final name = [
      appleCred.givenName,
      appleCred.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    if (name.isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(name);
    }
    await _ensureUserDocument(cred.user!, displayName: name.isNotEmpty ? name : null);
    return cred;
  }

  static Future<void> _ensureUserDocument(User user, {String? displayName}) async {
    final ref = db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;
    final name = displayName ?? user.displayName ?? user.email?.split('@').first ?? 'Athlete';
    await _firestoreOp('ensureUserDocument', () => ref.set({
          'email': user.email ?? '',
          'name': name,
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'gamification': {'xp': 0, 'level': 1, 'streak': 0, 'achievements': <String>[]},
        }));
  }

  static Future<void> deleteAccount(String uid) async {
    final batch = db.batch();
    final userRef = db.collection('users').doc(uid);
    final subcollections = ['daily_logs', 'weight_history', 'weekly_plans', 'meta', 'personal_records', 'completed_exercises', 'food_entries', 'workout_sessions'];
    for (final sub in subcollections) {
      final snap = await userRef.collection(sub).get();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(userRef);
    await batch.commit();
    final current = auth.currentUser;
    if (current != null && current.uid == uid) {
      try {
        await current.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('Please sign out, sign in again, then delete your account');
        }
        rethrow;
      }
    }
    await _googleSignIn.signOut();
    await auth.signOut();
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await auth.signOut();
  }

  // ─── USER DATA ──────────────────────────────────────────────────────────────

  static Future<UserData?> loadUserData(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logDoc = await db.collection('users').doc(uid).collection('daily_logs').doc(today).get();
    if (logDoc.exists) {
      final log = logDoc.data()!;
      data['dailyMacrosLogged'] = {
        'calories': log['calories_logged'] ?? 0,
        'protein': log['protein_logged'] ?? 0,
        'carbs': log['carbs_logged'] ?? 0,
        'fat': log['fat_logged'] ?? 0,
        'fiber': log['fiber_logged'] ?? 0,
        'sugar': log['sugar_logged'] ?? 0,
        'sodiumMg': log['sodium_mg_logged'] ?? 0,
      };
      data['foodLog'] = log['food_log'] ?? [];
      // The daily fields above are confirmed fresh for today.
      data['dailyLogDate'] = today;
      data['todayActivityLog'] = {
        'step_calories': log['step_calories'],
        'workout_calories': log['workout_calories'],
        'workout_status': log['workout_status'],
        'workout_name': log['workout_name'],
        'workout_session_id': log['workout_session_id'],
        'workout_session': log['workout_session'],
      };
      final qs = data['quickStats'] as Map<String, dynamic>? ?? {};
      qs['water'] = log['water_ml'] ?? qs['water'] ?? 0;
      data['quickStats'] = qs;
    }
    final embeddedHistory =
        (data['weightHistory'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final weightSnap = await db.collection('users').doc(uid).collection('weight_history').orderBy('date').get();
    final subHistory = weightSnap.docs.map((d) {
      final w = d.data();
      return {'date': w['date'], 'weight': (w['weight'] as num).toDouble()};
    }).toList();
    data['weightHistory'] = WeightHistoryHelper.merge([...embeddedHistory, ...subHistory]);
    final embeddedPrs =
        (data['personalRecords'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final prSnap = await db.collection('users').doc(uid).collection('personal_records').orderBy('recorded_at', descending: true).limit(50).get();
    final subPrs = prSnap.docs.map((d) {
      final p = d.data();
      return {
        'id': d.id,
        'exercise': p['exercise_name'],
        'value': p['value'],
        'unit': p['unit'],
        'date': (p['recorded_at'] as Timestamp?)?.toDate().toIso8601String().substring(0, 10) ?? p['date'],
      };
    }).toList();
    data['personalRecords'] = PersonalRecordHelper.merge([...embeddedPrs, ...subPrs]);
    data['userId'] = uid;
    return UserData.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> saveUserData(UserData data, {Map<String, dynamic>? activityFields}) async {
    final uid = data.userId;
    if (uid.isEmpty) return;
    final json = data.toJson()..remove('userId');
    await _firestoreOp('saveUserData', () async {
      await db.collection('users').doc(uid).set(json, SetOptions(merge: true));
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final dailyPayload = <String, dynamic>{
        'date': today,
        'water_ml': data.water.round(),
        'steps': data.steps.round(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (activityFields != null) ...activityFields,
      };
      // Only write macro totals when UserData is stamped for today (avoids stale rollover writes).
      if (data.dailyLogDate == today) {
        dailyPayload.addAll({
          'calories_logged': data.dailyMacrosLogged.calories,
          'protein_logged': data.dailyMacrosLogged.protein,
          'carbs_logged': data.dailyMacrosLogged.carbs,
          'fat_logged': data.dailyMacrosLogged.fat,
          'fiber_logged': data.dailyMacrosLogged.fiber,
          'sugar_logged': data.dailyMacrosLogged.sugar,
          'sodium_mg_logged': data.dailyMacrosLogged.sodiumMg,
          'food_log': data.foodLog,
        });
      }
      await db.collection('users').doc(uid).collection('daily_logs').doc(today).set(
            dailyPayload,
            SetOptions(merge: true),
          );
      await syncPublicProfile(uid, data.gamification['xp'] as int? ?? 0, data.gamification['level'] as int? ?? 1);
    });
  }

  static Future<String> createFoodEntry(String uid, Map<String, dynamic> entry) async {
    final ref = await db.collection('users').doc(uid).collection('food_entries').add({
      ...entry,
      'recorded_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> deleteFoodEntry(String uid, String entryId) async {
    await db.collection('users').doc(uid).collection('food_entries').doc(entryId).delete();
  }

  static Future<void> updateFoodEntry(String uid, String entryId, Map<String, dynamic> entry) async {
    await db.collection('users').doc(uid).collection('food_entries').doc(entryId).set(entry, SetOptions(merge: true));
  }

  static Future<String> createWorkoutSession(String uid, Map<String, dynamic> session) async {
    final ref = await db.collection('users').doc(uid).collection('workout_sessions').add({
      ...session,
      'recorded_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<List<Map<String, dynamic>>> fetchTodayFoodEntries(String uid) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final snap = await db
        .collection('users')
        .doc(uid)
        .collection('food_entries')
        .where('date', isEqualTo: today)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Future<Map<String, dynamic>?> fetchTodayWorkoutSession(String uid) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final snap = await db
        .collection('users')
        .doc(uid)
        .collection('workout_sessions')
        .where('date', isEqualTo: today)
        .orderBy('recorded_at', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  static Future<void> syncPublicProfile(String uid, int xp, int level) async {
    try {
      final userDoc = await db.collection('users').doc(uid).get().timeout(_firestoreTimeout);
      final name = userDoc.data()?['name'] as String? ?? 'Athlete';
      await db.collection('public_profiles').doc(uid).set({
        'displayName': name,
        'xp': xp,
        'level': level,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_firestoreTimeout);
    } catch (e) {
      debugPrint('Firestore syncPublicProfile failed: $e');
    }
  }

  static Future<void> logWeight(String uid, double weightKg, {String? date}) async {
    final day = date ?? WeightHistoryHelper.dayKey(DateTime.now());
    await db.collection('users').doc(uid).collection('weight_history').doc(day).set({
      'date': day,
      'weight': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final userDoc = await db.collection('users').doc(uid).get();
    final embedded =
        (userDoc.data()?['weightHistory'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final weightSnap = await db.collection('users').doc(uid).collection('weight_history').orderBy('date').get();
    final subHistory = weightSnap.docs.map((d) {
      final w = d.data();
      return {'date': w['date'], 'weight': (w['weight'] as num).toDouble()};
    }).toList();
    final latest = WeightHistoryHelper.latestWeight(WeightHistoryHelper.merge([...embedded, ...subHistory]));
    await db.collection('users').doc(uid).update({'weight': latest});
  }

  static Future<String> logPersonalRecord(String uid, {
    required String exerciseName,
    required double value,
    required String unit,
  }) async {
    final ref = await db.collection('users').doc(uid).collection('personal_records').add({
      'exercise_name': exerciseName,
      'value': value,
      'unit': unit,
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'recorded_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> logCompletedExercise(String uid, {
    required String workoutId,
    required String exerciseName,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.collection('users').doc(uid).collection('completed_exercises').add({
      'workout_id': workoutId,
      'exercise_name': exerciseName,
      'date': today,
      'completed_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchDailyLogsRange(String uid, int days) async {
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final startStr = start.toIso8601String().substring(0, 10);
    final snap = await db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .where('date', isGreaterThanOrEqualTo: startStr)
        .get();
    return snap.docs.map((d) => {'date': d.id, ...d.data()}).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 10}) async {
    try {
      final snap = await db.collection('public_profiles').orderBy('xp', descending: true).limit(limit).get();
      return snap.docs.map((d) => {
        'userId': d.id,
        'displayName': d.data()['displayName'] ?? 'Athlete',
        'xp': d.data()['xp'] ?? 0,
        'level': d.data()['level'] ?? 1,
      }).toList();
    } catch (e) {
      debugPrint('Leaderboard fetch failed: $e');
      return [];
    }
  }

  // ─── CHAT HISTORY ─────────────────────────────────────────────────────────────

  static Future<List<ChatMessage>> loadChat(String uid) async {
    final doc = await db.collection('users').doc(uid).collection('meta').doc('chat').get();
    if (!doc.exists) return [];
    final list = doc.data()?['messages'] as List? ?? [];
    return list
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveChat(String uid, List<ChatMessage> messages) async {
    final trimmed = messages.length > 100 ? messages.sublist(messages.length - 100) : messages;
    await _firestoreOp('saveChat', () => db.collection('users').doc(uid).collection('meta').doc('chat').set({
          'messages': trimmed.map((m) => m.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }));
  }

  // ─── FEED ─────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFeedPosts() async {
    final snap = await db.collection('feed_posts').orderBy('createdAt', descending: true).limit(50).get();
    return snap.docs.map(mapFeedPost).toList();
  }

  static Map<String, dynamic> mapFeedPost(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final p = doc.data();
    return {
      'id': doc.id,
      'authorId': p['authorId'],
      'authorName': p['authorName'] ?? 'Athlete',
      'content': p['content'],
      'caption': p['caption'],
      'postType': p['postType'] ?? p['type'] ?? 'motivation',
      'structuredContent': p['structuredContent'],
      'likes': List<String>.from((p['likes'] as List?)?.map((e) => e.toString()) ?? []),
      'comments': List<Map<String, dynamic>>.from(p['comments'] as List? ?? []),
      'ts': (p['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'type': p['type'] ?? 'workout',
    };
  }

  static Stream<List<Map<String, dynamic>>> feedStream() {
    return db
        .collection('feed_posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(mapFeedPost).toList());
  }

  static Future<void> createPost(
    String uid,
    String authorName,
    String content, {
    String type = 'workout',
    String? postType,
    Map<String, dynamic>? structuredContent,
    String? caption,
    String? activityId,
    String? activityCollection,
  }) async {
    await db.collection('feed_posts').add({
      'authorId': uid,
      'authorName': authorName,
      'content': content,
      'caption': caption,
      'postType': postType ?? type,
      'structuredContent': structuredContent,
      if (activityId != null) 'activityId': activityId,
      if (activityCollection != null) 'activityCollection': activityCollection,
      'likes': <String>[],
      'comments': <Map<String, dynamic>>[],
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> toggleLike(String postId, String uid, List<String> currentLikes) async {
    final likes = List<String>.from(currentLikes);
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
    await db.collection('feed_posts').doc(postId).update({'likes': likes});
  }

  // ─── WEEKLY PLAN ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCurrentWeekPlan(String uid) async {
    final monday = _monday();
    final doc = await db.collection('users').doc(uid).collection('weekly_plans').doc(monday).get();
    return doc.data()?['plan'] as Map<String, dynamic>?;
  }

  static Future<void> saveWeeklyPlan(String uid, Map<String, dynamic> plan) async {
    await db.collection('users').doc(uid).collection('weekly_plans').doc(_monday()).set({
      'week_start': _monday(),
      'plan': plan,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String _monday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.toIso8601String().substring(0, 10);
  }

  static String encodeUser(UserData u) => u.encode();
  static UserData decodeUser(String s) => UserData.decode(s);

  // ─── WEEKLY GOALS ───────────────────────────────────────────────────────────

  static Future<List<WeeklyGoal>> fetchWeeklyGoals(String uid) async {
    try {
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('weeklyGoals')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(_firestoreTimeout);
      return snap.docs.map((d) => WeeklyGoal.fromJson(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('fetchWeeklyGoals failed: $e');
      return [];
    }
  }

  static Future<void> saveWeeklyGoal(String uid, WeeklyGoal goal) async {
    await _firestoreOp('saveWeeklyGoal', () => db.collection('users').doc(uid).collection('weeklyGoals').doc(goal.id).set({
          ...goal.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        }));
  }

  // ─── DAILY CHECK-INS ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchDailyCheckin(String uid, String date) async {
    try {
      final doc = await db.collection('users').doc(uid).collection('dailyCheckins').doc(date).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDailyCheckin(String uid, String date, Map<String, dynamic> data) async {
    await _firestoreOp('saveDailyCheckin', () => db.collection('users').doc(uid).collection('dailyCheckins').doc(date).set({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)));
  }

  // ─── EXERCISE HISTORY ───────────────────────────────────────────────────────

  static Future<void> saveExerciseSession(
    String uid,
    String exerciseId,
    Map<String, dynamic> session,
  ) async {
    await _firestoreOp(
      'saveExerciseSession',
      () => db
          .collection('users')
          .doc(uid)
          .collection('exerciseHistory')
          .doc(exerciseId)
          .collection('sessions')
          .add({
        ...session,
        'recorded_at': FieldValue.serverTimestamp(),
      }),
    );
  }

  static Future<Map<String, dynamic>?> getLastExerciseSession(String uid, String exerciseId) async {
    try {
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('exerciseHistory')
          .doc(exerciseId)
          .collection('sessions')
          .orderBy('recorded_at', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    } catch (_) {
      return null;
    }
  }
}
