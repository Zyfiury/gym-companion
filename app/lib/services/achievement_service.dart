import '../models/user_data.dart';

class AchievementDef {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;

  const AchievementDef({required this.id, required this.title, required this.subtitle, required this.emoji});
}

class AchievementService {
  static const all = [
    AchievementDef(id: 'first_food', title: 'First bite', subtitle: 'Log your first meal', emoji: '🍽️'),
    AchievementDef(id: 'first_workout', title: 'Iron started', subtitle: 'Complete a workout', emoji: '💪'),
    AchievementDef(id: 'streak_3', title: 'On a roll', subtitle: '3-day streak', emoji: '🔥'),
    AchievementDef(id: 'streak_7', title: 'Week warrior', subtitle: '7-day streak', emoji: '⚡'),
    AchievementDef(id: 'streak_30', title: 'Unstoppable', subtitle: '30-day streak', emoji: '🏆'),
    AchievementDef(id: 'protein_day', title: 'Protein pro', subtitle: 'Hit protein target', emoji: '🥩'),
    AchievementDef(id: 'first_pr', title: 'New PR', subtitle: 'Log a personal record', emoji: '🎯'),
    AchievementDef(id: 'coach_10', title: 'Coach regular', subtitle: '10 coach chats', emoji: '💬'),
    AchievementDef(id: 'level_5', title: 'Level 5', subtitle: 'Reach level 5', emoji: '⭐'),
    AchievementDef(id: 'level_10', title: 'Level 10', subtitle: 'Reach level 10', emoji: '🌟'),
    AchievementDef(id: 'water_goal', title: 'Hydrated', subtitle: 'Hit water goal', emoji: '💧'),
    AchievementDef(id: 'barcode_scan', title: 'Scanner', subtitle: 'Log via barcode', emoji: '📷'),
  ];

  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static List<String> unlocked(UserData user) =>
      List<String>.from(user.gamification['achievements'] as List? ?? []);

  static bool has(UserData user, String id) => unlocked(user).contains(id);

  static String? unlock(UserData user, String id) {
    if (has(user, id)) return null;
    final list = unlocked(user)..add(id);
    user.gamification = {...user.gamification, 'achievements': list};
    return byId(id)?.title;
  }

  static void afterActivity(UserData user, {String? reason}) {
    final g = user.gamification;
    final streak = g['streak'] as int? ?? 0;
    final level = g['level'] as int? ?? 1;
    if (user.foodLog.isNotEmpty) unlock(user, 'first_food');
    if (user.water >= 2500) unlock(user, 'water_goal');
    if (streak >= 3) unlock(user, 'streak_3');
    if (streak >= 7) unlock(user, 'streak_7');
    if (streak >= 30) unlock(user, 'streak_30');
    if (level >= 5) unlock(user, 'level_5');
    if (level >= 10) unlock(user, 'level_10');
    if (user.personalRecords.isNotEmpty) unlock(user, 'first_pr');
    if (reason == 'Workout complete') unlock(user, 'first_workout');
    if (reason == 'Log food' && user.foodLog.any((e) => e['source'] == 'barcode')) {
      unlock(user, 'barcode_scan');
    }
    final proteinTarget = user.weeklyPlan.macros['protein'] ?? 0;
    if (proteinTarget > 0 && user.dailyMacrosLogged.protein >= proteinTarget) {
      unlock(user, 'protein_day');
    }
  }
}
