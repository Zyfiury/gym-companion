/// Weight log helpers - one entry per calendar day, merged by date.
class WeightHistoryHelper {
  static String dayKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().substring(0, 10);
  }

  static bool isToday(String day) => day == dayKey(DateTime.now());

  static double latestWeight(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0;
    return (merge(history).last['weight'] as num).toDouble();
  }

  static List<Map<String, dynamic>> merge(List<Map<String, dynamic>> entries) {
    final byDate = <String, double>{};
    for (final e in entries) {
      final date = e['date'] as String?;
      final weight = e['weight'];
      if (date == null || weight == null) continue;
      byDate[date] = (weight as num).toDouble();
    }
    return byDate.entries
        .map((e) => {'date': e.key, 'weight': e.value})
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Upsert today's weigh-in (or [date]) and keep history sorted.
  static bool upsert(List<Map<String, dynamic>> history, double kg, {String? date}) {
    final day = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final existing = history.indexWhere((e) => e['date'] == day);
    final entry = {'date': day, 'weight': kg};
    if (existing >= 0) {
      history[existing] = entry;
    } else {
      history.add(entry);
    }
    history.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return existing >= 0;
  }

  /// First weigh-in from profile weight when history was never seeded.
  static void seedBaselineIfEmpty(List<Map<String, dynamic>> history, double profileWeight) {
    if (history.isNotEmpty || profileWeight <= 0) return;
    history.add({'date': dayKey(DateTime.now()), 'weight': profileWeight});
  }
}
