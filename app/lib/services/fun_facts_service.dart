import '../models/user_data.dart';

class FunFact {
  final String emoji;
  final String text;
  final String category;

  const FunFact({required this.emoji, required this.text, required this.category});
}

/// Personal, data-driven fun facts - not random trivia.
class FunFactsService {
  static FunFact? dailyFact({
    required UserData user,
    List<Map<String, dynamic>> dailyLogsHistory = const [],
    String? displayName,
  }) {
    final pool = _buildPool(user, dailyLogsHistory, displayName: displayName);
    if (pool.isEmpty) return null;
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final seed = (day + (user.userId ?? '')).hashCode.abs();
    return pool[seed % pool.length];
  }

  static List<FunFact> weeklyFacts({
    required UserData user,
    List<Map<String, dynamic>> dailyLogsHistory = const [],
  }) {
    final pool = _buildPool(user, dailyLogsHistory, weekly: true);
    if (pool.length <= 3) return pool;
    final week = _weekKey();
    final seed = (week + (user.userId ?? '')).hashCode.abs();
    final picked = <FunFact>[];
    for (var i = 0; i < 3; i++) {
      picked.add(pool[(seed + i * 7) % pool.length]);
    }
    return picked;
  }

  static FunFact? eventFact({
    required UserData user,
    required String event,
    List<Map<String, dynamic>> dailyLogsHistory = const [],
  }) {
    return switch (event) {
      'workout_complete' => _workoutCompleteFact(user),
      'food_log' => _foodLogFact(user),
      'streak' => _streakFact(user),
      _ => null,
    };
  }

  static String _weekKey() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.toIso8601String().substring(0, 10);
  }

  static List<FunFact> _buildPool(
    UserData user,
    List<Map<String, dynamic>> history, {
    String? displayName,
    bool weekly = false,
  }) {
    final facts = <FunFact>[];
    final name = displayName?.split(' ').first;
    final g = user.gamification;
    final xp = g['xp'] as int? ?? 0;
    final level = g['level'] as int? ?? 1;
    final streak = g['streak'] as int? ?? 0;
    final xpToNext = 100 - (xp % 100);
    final proteinTarget = user.weeklyPlan.macros['protein'] ?? 140;
    final goal = user.goal;

    if (streak >= 3) {
      facts.add(FunFact(
        emoji: '🔥',
        text: '$streak-day streak${name != null ? ', $name' : ''} - that\'s the habit that builds everything else.',
        category: 'streak',
      ));
    }

    if (xpToNext <= 25) {
      facts.add(FunFact(
        emoji: '⚡',
        text: 'Only $xpToNext XP until Level ${level + 1}. You\'re closer than it feels.',
        category: 'xp',
      ));
    }

    final topFood = _topFood(user.foodLog);
    if (topFood != null) {
      facts.add(FunFact(
        emoji: '🍽️',
        text: '${topFood.name} is your signature - logged ${topFood.count}× recently.',
        category: 'food',
      ));
    }

    if (user.foodLog.length >= 10) {
      facts.add(FunFact(
        emoji: '📊',
        text: '${user.foodLog.length} meals logged. Most people quit before double digits.',
        category: 'milestone',
      ));
    }

    if (user.dailyMacrosLogged.protein >= proteinTarget && proteinTarget > 0) {
      facts.add(FunFact(
        emoji: '🥩',
        text: 'Protein target hit today (${user.dailyMacrosLogged.protein}g). ${goal == 'cut' ? 'Cutting with muscle in mind.' : 'Fuel for the work.'}',
        category: 'food',
      ));
    }

    if (user.water >= 2000) {
      facts.add(FunFact(
        emoji: '💧',
        text: '${(user.water / 1000).toStringAsFixed(1)}L water today - hydration is a silent PR.',
        category: 'habit',
      ));
    }

    if (user.personalRecords.isNotEmpty) {
      facts.add(FunFact(
        emoji: '🎯',
        text: '${user.personalRecords.length} personal record${user.personalRecords.length == 1 ? '' : 's'} on the board. Numbers don\'t lie.',
        category: 'workout',
      ));
    }

    final peakDay = _peakWorkoutDay(history);
    if (peakDay != null) {
      facts.add(FunFact(
        emoji: '📅',
        text: '$peakDay is your most consistent workout day - your body knows the rhythm.',
        category: 'workout',
      ));
    }

    if (weekly) {
      final weekStats = _weekStats(user, history, proteinTarget);
      if (weekStats.workoutDays >= 2) {
        facts.add(FunFact(
          emoji: '💪',
          text: '${weekStats.workoutDays} workouts this week - ${weekStats.workoutDays >= 4 ? 'elite consistency' : 'solid momentum'}.',
          category: 'workout',
        ));
      }
      if (weekStats.proteinDays >= 3) {
        facts.add(FunFact(
          emoji: '🥚',
          text: 'Protein target hit ${weekStats.proteinDays}/7 days. That\'s how ${goal == 'bulk' ? 'muscle gets built' : 'cuts stay muscle-sparing'}.',
          category: 'food',
        ));
      }
      if (weekStats.totalProtein > 0) {
        facts.add(FunFact(
          emoji: '🐔',
          text: '${weekStats.totalProtein}g protein logged this week - roughly ${(weekStats.totalProtein / 31).round()} chicken breasts worth.',
          category: 'food',
        ));
      }
    }

    final mealSlot = _peakMealSlot(user.foodLog);
    if (mealSlot != null) {
      facts.add(FunFact(
        emoji: '⏰',
        text: 'You log most food at $mealSlot - ${mealSlot == 'Snacks' ? 'night owl energy' : 'creature of habit'}.',
        category: 'habit',
      ));
    }

    if (facts.isEmpty) {
      facts.add(FunFact(
        emoji: '✨',
        text: name != null
            ? 'Every log makes Mara smarter about you, $name. Keep going.'
            : 'Every log teaches your coach something new about you.',
        category: 'coach',
      ));
    }

    return facts;
  }

  static FunFact? _workoutCompleteFact(UserData user) {
    final streak = user.gamification['streak'] as int? ?? 0;
    if (streak >= 7) {
      return FunFact(
        emoji: '🏆',
        text: 'Workout done - $streak days in a row. That\'s not luck, that\'s you.',
        category: 'workout',
      );
    }
    return FunFact(
      emoji: '💪',
      text: 'Session complete. Your future self just sent a thank-you note.',
      category: 'workout',
    );
  }

  static FunFact? _foodLogFact(UserData user) {
    final count = user.foodLog.length;
    if (count == 1) {
      return FunFact(
        emoji: '🍽️',
        text: 'First meal logged today. Awareness is step one - nice work.',
        category: 'food',
      );
    }
    if (count == 5) {
      return FunFact(
        emoji: '📝',
        text: '5 items logged today. Detailed loggers see results faster - fact.',
        category: 'food',
      );
    }
    final top = _topFood(user.foodLog);
    if (top != null && top.count >= 3) {
      return FunFact(
        emoji: '🔁',
        text: '${top.name} again? Consistency beats variety when it works.',
        category: 'food',
      );
    }
    return null;
  }

  static FunFact? _streakFact(UserData user) {
    final streak = user.gamification['streak'] as int? ?? 0;
    if (streak < 3) return null;
    return FunFact(
      emoji: '🔥',
      text: '$streak-day streak. You\'re in the top tier of people who actually show up.',
      category: 'streak',
    );
  }

  static ({String name, int count})? _topFood(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return null;
    final counts = <String, int>{};
    for (final e in logs) {
      final name = (e['food'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final short = name.length > 40 ? '${name.substring(0, 37)}…' : name;
      counts[short] = (counts[short] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (top.value < 2) return null;
    return (name: top.key, count: top.value);
  }

  static String? _peakWorkoutDay(List<Map<String, dynamic>> history) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final counts = List.filled(7, 0);
    for (final log in history) {
      if (log['workout_status'] != 'completed') continue;
      final date = DateTime.tryParse(log['date'] as String? ?? '');
      if (date == null) continue;
      counts[date.weekday - 1]++;
    }
    final max = counts.reduce((a, b) => a > b ? a : b);
    if (max < 2) return null;
    return days[counts.indexOf(max)];
  }

  static String? _peakMealSlot(List<Map<String, dynamic>> logs) {
    if (logs.length < 3) return null;
    final counts = <String, int>{};
    for (final e in logs) {
      final slot = e['meal_type'] as String?;
      if (slot == null) continue;
      counts[slot] = (counts[slot] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (top.value < 2) return null;
    return top.key;
  }

  static ({int workoutDays, int proteinDays, int totalProtein}) _weekStats(
    UserData user,
    List<Map<String, dynamic>> history,
    int proteinTarget,
  ) {
    final now = DateTime.now();
    var workoutDays = 0;
    var proteinDays = 0;
    var totalProtein = 0;
    for (var i = 0; i < 7; i++) {
      final key = now.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      final log = history.cast<Map<String, dynamic>?>().firstWhere(
            (l) => l?['date'] == key,
            orElse: () => null,
          );
      if (log == null) continue;
      final pro = (log['protein_logged'] as num?)?.toInt() ?? 0;
      totalProtein += pro;
      if (pro >= proteinTarget) proteinDays++;
      if (log['workout_status'] == 'completed') workoutDays++;
    }
    return (workoutDays: workoutDays, proteinDays: proteinDays, totalProtein: totalProtein);
  }
}
