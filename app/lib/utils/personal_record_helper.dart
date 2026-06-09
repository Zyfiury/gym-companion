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
