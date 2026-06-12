import '../models/user_data.dart';

class PersonalRecordHelper {
  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    final exercise = (raw['exercise'] ?? raw['lift'] ?? raw['exercise_name'] ?? '').toString().trim();
    dynamic value = raw['value'];
    if (value is String) {
      final match = RegExp(r'^([\d.]+)').firstMatch(value);
      value = match != null ? double.tryParse(match.group(1)!) : null;
    }
    var unit = (raw['unit'] ?? '').toString();
    if (unit.isEmpty && value is String && value.contains('×')) {
      unit = 'kg';
    }
    if (unit.isEmpty && raw['weight_kg'] != null) {
      value = raw['weight_kg'];
      unit = 'kg';
    }
    final date = (raw['date'] ?? '').toString();
    return {
      if (raw['id'] != null) 'id': raw['id'],
      'exercise': exercise,
      'value': value is num ? value.toDouble() : value,
      'unit': unit,
      'date': date.length >= 10 ? date.substring(0, 10) : date,
    };
  }

  static List<Map<String, dynamic>> merge(List<Map<String, dynamic>> entries) {
    final normalized = entries.map(normalize).where((e) => (e['exercise'] as String).isNotEmpty).toList();
    normalized.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return normalized;
  }

  static String formatValue(dynamic value, String unit) {
    if (value == null) return '—';
    final v = (value as num).toDouble();
    final text = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    return unit.isEmpty ? text : '$text $unit';
  }

  static String _normalizeExerciseName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  static double _toKg(double value, String unit) {
    if (unit == 'lbs' || unit == 'lb') return value * 0.453592;
    return value;
  }

  static double? previousBest(
    List<Map<String, dynamic>> records, {
    required String exercise,
    required String unit,
  }) {
    final target = _normalizeExerciseName(exercise);
    double? best;
    for (final r in records) {
      final name = _normalizeExerciseName((r['exercise'] ?? '').toString());
      if (name != target) continue;
      final rUnit = (r['unit'] ?? 'kg').toString();
      if (unit == 'reps' || rUnit == 'reps') {
        if (unit != 'reps') continue;
        final v = (r['value'] as num?)?.toDouble();
        if (v != null && (best == null || v > best)) best = v;
      } else {
        if (rUnit == 'reps') continue;
        final v = _toKg((r['value'] as num?)?.toDouble() ?? 0, rUnit);
        if (best == null || v > best) best = v;
      }
    }
    return best;
  }

  static bool isNewBest(
    List<Map<String, dynamic>> records, {
    required String exercise,
    required double value,
    required String unit,
  }) {
    final prev = previousBest(records, exercise: exercise, unit: unit);
    if (prev == null) return value > 0;
    if (unit == 'reps') return value > prev;
    return _toKg(value, unit) > prev + 0.01;
  }

  static String formatRecentPr(Map<String, dynamic> record) {
    final exercise = record['exercise'] ?? '';
    final value = record['value'];
    final unit = (record['unit'] ?? 'kg').toString();
    if (unit == 'kg' || unit == 'lbs') {
      final kg = _toKg((value as num?)?.toDouble() ?? 0, unit);
      final text = kg == kg.roundToDouble() ? kg.toInt() : kg.toStringAsFixed(1);
      return '$exercise ${text}kg';
    }
    return '$exercise ${formatValue(value, unit)}';
  }

  static List<String> exerciseSuggestions(UserData user) {
    final names = <String>{
      'Bench Press',
      'Squat',
      'Deadlift',
      'Pull-ups',
      'Overhead Press',
      'Row',
    };
    for (final day in user.weeklyPlan.workouts) {
      for (final ex in day.exercises) {
        final name = ex.split(RegExp(r'\s+\d')).first.trim();
        if (name.isNotEmpty) names.add(name);
      }
    }
    for (final workout in user.customWorkouts) {
      for (final ex in workout.exercises) {
        if (ex.name.trim().isNotEmpty) names.add(ex.name.trim());
      }
    }
    for (final pr in user.personalRecords) {
      final name = (pr['exercise'] ?? pr['lift'] ?? '').toString().trim();
      if (name.isNotEmpty) names.add(name);
    }
    final list = names.toList()..sort();
    return list;
  }
}
