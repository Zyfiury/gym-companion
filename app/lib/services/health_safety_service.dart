import '../models/user_data.dart';

class SafetyCheck {
  final bool isSafe;
  final String? warning;

  const SafetyCheck({required this.isSafe, this.warning});
}

class HealthSafetyService {
  static const disabilityOptions = [
    'knee_injury',
    'back_pain',
    'shoulder_injury',
    'wheelchair',
    'mobility_limited',
  ];

  static const disabilityLabels = {
    'knee_injury': 'knee injury',
    'back_pain': 'back pain',
    'shoulder_injury': 'shoulder injury',
    'wheelchair': 'wheelchair user',
    'mobility_limited': 'limited mobility',
  };

  /// Map natural language to disability tags.
  static String? parseDisabilityTag(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'bad knee|knee (injury|pain|problem)').hasMatch(lower)) return 'knee_injury';
    if (RegExp(r'back (pain|injury|problem)').hasMatch(lower)) return 'back_pain';
    if (RegExp(r'shoulder (pain|injury|problem)').hasMatch(lower)) return 'shoulder_injury';
    if (lower.contains('wheelchair')) return 'wheelchair';
    if (RegExp(r'limited mobility|mobility issue').hasMatch(lower)) return 'mobility_limited';
    return null;
  }

  static SafetyCheck checkWorkoutSafe(String exercise, UserData user) {
    final lower = exercise.toLowerCase();
    if (user.pregnant) {
      if (lower.contains('deadlift') || lower.contains('heavy squat')) {
        return const SafetyCheck(isSafe: false, warning: 'Avoid heavy lifts during pregnancy - use supported alternatives.');
      }
    }
    if (user.disabilities.contains('wheelchair') || user.disabilities.contains('mobility_limited')) {
      const blocked = ['bench press', 'leg press', 'squat', 'deadlift', 'rdl', 'bulgarian', 'leg curl', 'ohp', 'barbell row', 'walk 30'];
      if (blocked.any(lower.contains)) {
        return const SafetyCheck(isSafe: false, warning: 'Adapted for your mobility - seated alternatives in your plan.');
      }
    }
    for (final d in user.disabilities) {
      if (d == 'knee_injury' && (lower.contains('squat') || lower.contains('lunge'))) {
        return SafetyCheck(isSafe: false, warning: 'High knee stress - substituted in your plan.');
      }
      if (d == 'back_pain' && lower.contains('deadlift')) {
        return SafetyCheck(isSafe: false, warning: 'Spinal loading avoided due to back pain.');
      }
      if (d == 'shoulder_injury' && (lower.contains('ohp') || lower.contains('overhead'))) {
        return SafetyCheck(isSafe: false, warning: 'Overhead pressing avoided due to shoulder injury.');
      }
    }
    return const SafetyCheck(isSafe: true);
  }

  static SafetyCheck checkMealSafe({required String name, required List<String> ingredients, required UserData user}) {
    final combined = '$name ${ingredients.join(' ')}'.toLowerCase();
    for (final med in user.medications) {
      final m = med.toLowerCase();
      if (m.contains('statin') && combined.contains('grapefruit')) {
        return const SafetyCheck(isSafe: false, warning: 'Grapefruit can interact with statins - check with your doctor.');
      }
    }
    return const SafetyCheck(isSafe: true);
  }

  static String? periodNutritionHint(UserData user) {
    if (!user.tracksPeriod) return null;
    if (user.periodPhase == 'menstrual') {
      return 'Iron and magnesium rich - good for energy during your period.';
    }
    if (user.periodPhase == 'luteal') {
      return 'Complex carbs and protein help manage pre-period cravings.';
    }
    return null;
  }

  static List<String> videoModifiers(UserData user) {
    final mods = <String>[];
    if (user.disabilities.contains('wheelchair') || user.disabilities.contains('mobility_limited')) {
      mods.add('wheelchair accessible seated');
    }
    if (user.pregnant) mods.add('pregnancy safe');
    return mods;
  }

  static String _parseExerciseName(String exercise) =>
      exercise.split(RegExp(r'\s+\d')).first.trim();

  static bool _needsSeatedVideos(UserData user) =>
      user.disabilities.contains('wheelchair') || user.disabilities.contains('mobility_limited');

  /// Full YouTube search query tailored to user mobility.
  static String videoSearchQuery(String exercise, UserData user) {
    final name = _parseExerciseName(exercise);
    final lower = name.toLowerCase();

    if (_needsSeatedVideos(user)) {
      const replacements = {
        'bench press': 'seated chest press machine wheelchair accessible',
        'leg press': 'seated cable row wheelchair accessible',
        'squat': 'seated leg extension wheelchair accessible',
        'deadlift': 'seated cable row wheelchair accessible',
        'rdl': 'seated cable row wheelchair accessible',
        'bulgarian': 'seated leg extension wheelchair accessible',
        'leg curl': 'seated leg extension wheelchair accessible',
        'ohp': 'seated shoulder press wheelchair accessible',
        'barbell row': 'seated cable row wheelchair accessible',
        'incline db': 'seated chest press wheelchair accessible',
      };
      for (final entry in replacements.entries) {
        if (lower.contains(entry.key)) return '${entry.value} form tutorial';
      }
      if (lower.contains('seated')) return '$name wheelchair accessible form tutorial';
      return 'seated $name wheelchair accessible form tutorial';
    }

    final mods = videoModifiers(user);
    if (mods.isEmpty) return '$name form tutorial';
    return '${mods.join(' ')} $name form tutorial';
  }

  static String videoCacheKey(String exercise, UserData user) {
    final name = _parseExerciseName(exercise);
    final mobility = _needsSeatedVideos(user) ? 'seated' : 'standard';
    return '${name}_$mobility';
  }
}
