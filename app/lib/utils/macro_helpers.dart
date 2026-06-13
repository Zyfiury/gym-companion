import '../models/user_data.dart';

/// Shared macro/micro helpers for food logging and daily totals.
class MacroHelpers {
  /// Estimate fibre and sugar when APIs omit them (same heuristics as photo AI).
  static ({int fiber, int sugar, int sodiumMg}) resolveMicros({
    required int carbs,
    int? fiber,
    int? sugar,
    int? sodiumMg,
  }) {
    final f = fiber ?? 0;
    final s = sugar ?? 0;
    final na = sodiumMg ?? 0;
    return (
      fiber: f > 0 ? f : (carbs > 0 ? (carbs * 0.12).round() : 0),
      sugar: s > 0 ? s : (carbs > 0 ? (carbs * 0.25).round() : 0),
      sodiumMg: na,
    );
  }

  static void applyMicrosToEntry(Map<String, dynamic> entry) {
    final carbs = (entry['carbs'] as num?)?.toInt() ?? 0;
    final micros = resolveMicros(
      carbs: carbs,
      fiber: (entry['fiber'] as num?)?.toInt(),
      sugar: (entry['sugar'] as num?)?.toInt(),
      sodiumMg: (entry['sodium_mg'] as num?)?.toInt(),
    );
    entry['fiber'] = micros.fiber;
    entry['sugar'] = micros.sugar;
    entry['sodium_mg'] = micros.sodiumMg;
  }

  static MacroLog sumFromEntries(List<Map<String, dynamic>> entries, {String? onlyDate}) {
    final totals = MacroLog();
    for (final raw in entries) {
      final e = Map<String, dynamic>.from(raw);
      if (onlyDate != null && (e['date'] as String?) != onlyDate) continue;
      applyMicrosToEntry(e);
      totals.calories += (e['calories'] as num?)?.toInt() ?? 0;
      totals.protein += (e['protein'] as num?)?.toInt() ?? 0;
      totals.carbs += (e['carbs'] as num?)?.toInt() ?? 0;
      totals.fat += (e['fat'] as num?)?.toInt() ?? 0;
      totals.fiber += (e['fiber'] as num?)?.toInt() ?? 0;
      totals.sugar += (e['sugar'] as num?)?.toInt() ?? 0;
      totals.sodiumMg += (e['sodium_mg'] as num?)?.toInt() ?? 0;
    }
    return totals;
  }
}
