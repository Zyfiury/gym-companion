import '../models/user_data.dart';
import 'health_safety_service.dart';

class WorkoutAdaptationService {
  static List<WorkoutDay> _basePlan() => [
        WorkoutDay(day: 'Mon', focus: 'Upper A', exercises: ['Bench Press 4×6-8', 'Barbell Row 4×8', 'OHP 3×10']),
        WorkoutDay(day: 'Tue', focus: 'Lower A', exercises: ['Squat 4×6-8', 'RDL 3×10', 'Leg Press 3×12']),
        WorkoutDay(day: 'Wed', focus: 'Rest', exercises: ['Walk 30 min', 'Mobility 15 min']),
        WorkoutDay(day: 'Thu', focus: 'Upper B', exercises: ['Incline DB 4×10', 'Cable Row 4×10', 'Lateral Raise 3×15']),
        WorkoutDay(day: 'Fri', focus: 'Lower B', exercises: ['Deadlift 4×5', 'Bulgarian Split Squat 3×10', 'Leg Curl 3×12']),
        WorkoutDay(day: 'Sat', focus: 'Active', exercises: ['Light cardio 20 min']),
        WorkoutDay(day: 'Sun', focus: 'Rest', exercises: ['Full rest or yoga']),
      ];

  static List<WorkoutDay> _wheelchairPlan() => [
        WorkoutDay(
          day: 'Mon',
          focus: 'Seated Upper A',
          exercises: ['Seated Cable Row 4×10', 'Seated Chest Press 4×8', 'Seated Shoulder Press 3×10', 'Band Pull-apart 3×15'],
        ),
        WorkoutDay(
          day: 'Tue',
          focus: 'Seated Upper B',
          exercises: ['Seated Bicep Curl 3×12', 'Tricep Pushdown 3×12', 'Seated Leg Extension 3×12', 'Core Brace Hold 3×30s'],
        ),
        WorkoutDay(day: 'Wed', focus: 'Active', exercises: ['Upper body ergometer 15 min', 'Seated mobility 15 min']),
        WorkoutDay(
          day: 'Thu',
          focus: 'Seated Upper A',
          exercises: ['Seated Cable Row 4×10', 'Seated Chest Press 4×8', 'Seated Shoulder Press 3×10', 'Band Pull-apart 3×15'],
        ),
        WorkoutDay(
          day: 'Fri',
          focus: 'Seated Upper B',
          exercises: ['Seated Bicep Curl 3×12', 'Tricep Pushdown 3×12', 'Seated Leg Extension 3×12', 'Core Brace Hold 3×30s'],
        ),
        WorkoutDay(day: 'Sat', focus: 'Active', exercises: ['Upper body ergometer 15 min', 'Seated mobility 15 min']),
        WorkoutDay(day: 'Sun', focus: 'Rest', exercises: ['Full rest or gentle stretch']),
      ];

  static bool needsSeatedPlan(UserData user) =>
      user.disabilities.contains('wheelchair') || user.disabilities.contains('mobility_limited');

  static bool planContainsBlockedExercises(UserData user) {
    if (!needsSeatedPlan(user)) return false;
    const blocked = ['bench press', 'leg press', 'rdl', 'deadlift', 'squat', 'bulgarian', 'leg curl', 'ohp'];
    for (final w in user.weeklyPlan.workouts) {
      for (final e in w.exercises) {
        final lower = e.toLowerCase();
        if (blocked.any(lower.contains)) return true;
      }
    }
    return false;
  }

  static final _substitutions = <String, Map<String, String>>{
    'knee_injury': {
      'Squat': 'Leg Press',
      'Bulgarian Split Squat': 'Step-ups (low box)',
      'Squat 4×6-8': 'Leg Press 4×10-12',
      'Bulgarian Split Squat 3×10': 'Step-ups 3×10 each leg',
    },
    'back_pain': {
      'Deadlift': 'Hip Hinge with DB',
      'Barbell Row': 'Chest-supported Row',
      'Deadlift 4×5': 'Hip Hinge with DB 3×10',
      'Barbell Row 4×8': 'Chest-supported Row 4×10',
      'RDL': 'Glute Bridge',
      'RDL 3×10': 'Glute Bridge 3×12',
    },
    'shoulder_injury': {
      'OHP': 'Landmine Press',
      'Bench Press': 'Floor Press',
      'OHP 3×10': 'Landmine Press 3×10',
      'Bench Press 4×6-8': 'Floor Press 4×8',
      'Incline DB': 'Neutral-grip Incline Press',
      'Incline DB 4×10': 'Neutral-grip Incline Press 4×10',
    },
    'wheelchair': {
      'Bench Press': 'Seated Chest Press',
      'Leg Press': 'Seated Cable Row',
      'RDL': 'Seated Cable Row',
      'Bulgarian Split Squat': 'Seated Leg Extension',
      'Leg Curl': 'Seated Leg Extension',
      'OHP': 'Seated Shoulder Press',
      'Incline DB': 'Seated Chest Press',
      'Squat': 'Seated Leg Extension',
      'Deadlift': 'Seated Cable Row',
      'Walk 30 min': 'Upper body ergometer 15 min',
      'Light cardio 20 min': 'Seated cardio 15 min',
    },
    'mobility_limited': {
      'Squat': 'Goblet Squat (supported)',
      'Deadlift': 'Trap Bar Deadlift (light)',
      'Bulgarian Split Squat': 'Wall Sit',
    },
  };

  static List<WorkoutDay> applyPrProgression(
    List<WorkoutDay> workouts,
    List<Map<String, dynamic>> personalRecords,
  ) {
    if (personalRecords.isEmpty) return workouts;
    return workouts.map((day) {
      final exercises = day.exercises.map((raw) {
        final parsedName = raw.split(RegExp(r'\s+\d')).first.trim().toLowerCase();
        for (final pr in personalRecords) {
          final prName = (pr['exercise'] ?? '').toString().toLowerCase();
          final unit = (pr['unit'] ?? 'kg').toString();
          if (unit != 'kg' && unit != 'lbs') continue;
          if (!parsedName.contains(prName) && !prName.contains(parsedName)) continue;
          final base = (pr['value'] as num?)?.toDouble() ?? 0;
          if (base <= 0) continue;
          final kg = unit == 'lbs' ? base * 0.453592 : base;
          final target = kg + 2.5;
          final targetText = target == target.roundToDouble() ? target.toInt() : target.toStringAsFixed(1);
          if (raw.contains('@')) {
            return raw.replaceAll(RegExp(r'@\s*[\d.]+\s*kg', caseSensitive: false), '@ ${targetText}kg');
          }
          return '$raw @ ${targetText}kg';
        }
        return raw;
      }).toList();
      return WorkoutDay(day: day.day, focus: day.focus, exercises: exercises);
    }).toList();
  }

  static AdaptedWorkoutPlan buildWeeklyPlan(UserData user) {
    if (needsSeatedPlan(user)) {
      return AdaptedWorkoutPlan(
        workouts: _wheelchairPlan(),
        adaptations: [
          'Seated upper-body plan for ${user.disabilities.contains('wheelchair') ? 'wheelchair user' : 'limited mobility'}',
        ],
      );
    }

    final adaptations = <String>[];
    final tags = <String>[...user.disabilities];
    if (user.pregnant) tags.add('pregnant');

    var workouts = _basePlan().map((w) {
      var exercises = List<String>.from(w.exercises);
      var focus = w.focus;

      for (final tag in tags) {
        if (tag == 'wheelchair' || tag == 'mobility_limited') continue;
        final subs = _substitutions[tag];
        if (subs == null && tag == 'pregnant') {
          exercises = exercises.map((e) {
            if (e.toLowerCase().contains('deadlift')) {
              adaptations.add('Replaced deadlift with hip hinge (pregnancy-safe)');
              return 'Hip Hinge with DB 3×10';
            }
            if (e.toLowerCase().contains('squat') && !e.toLowerCase().contains('leg press')) {
              adaptations.add('Replaced squat with leg press (pregnancy-safe)');
              return 'Leg Press 4×10';
            }
            return e;
          }).toList();
          continue;
        }
        if (subs == null) continue;

        exercises = exercises.map((e) {
          for (final entry in subs.entries) {
            if (e.contains(entry.key)) {
              final label = HealthSafetyService.disabilityLabels[tag] ?? tag;
              adaptations.add('${entry.key} → ${entry.value} ($label)');
              return entry.value.contains('×') ? entry.value : e.replaceFirst(entry.key, entry.value);
            }
          }
          return e;
        }).toList();
      }

      return WorkoutDay(day: w.day, focus: focus, exercises: exercises);
    }).toList();

    if (adaptations.isEmpty) {
      adaptations.add('Standard upper/lower split applied to your profile.');
    }

    workouts = applyPrProgression(workouts, user.personalRecords);

    return AdaptedWorkoutPlan(workouts: workouts, adaptations: adaptations.toSet().toList());
  }

  static String formatReply(AdaptedWorkoutPlan plan) {
    final summary = plan.workouts
        .where((w) => w.focus != 'Rest')
        .map((w) => '${w.day} - ${w.focus}')
        .join('\n');
    final adapt = plan.adaptations.take(3).map((a) => '• $a').join('\n');
    return '✅ Updated your workout plan. Check the Workout tab.\n$summary\n\nAdaptations:\n$adapt';
  }
}

class AdaptedWorkoutPlan {
  final List<WorkoutDay> workouts;
  final List<String> adaptations;

  AdaptedWorkoutPlan({required this.workouts, required this.adaptations});
}
