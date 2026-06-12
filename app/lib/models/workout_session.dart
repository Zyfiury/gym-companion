import 'workout_status.dart';

class LoggedExercise {
  final String name;
  final int sets;
  final int reps;
  final double? weightKg;
  final double met;

  const LoggedExercise({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weightKg,
    this.met = 4.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        if (weightKg != null) 'weight_kg': weightKg,
        'met': met,
      };

  factory LoggedExercise.fromJson(Map<String, dynamic> j) => LoggedExercise(
        name: j['name'] as String? ?? '',
        sets: j['sets'] as int? ?? 3,
        reps: j['reps'] as int? ?? 10,
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        met: (j['met'] as num?)?.toDouble() ?? 4.0,
      );
}

class WorkoutSessionLog {
  final WorkoutStatus status;
  final String? workoutName;
  final String? skipReason;
  final String? customDescription;
  final String? completedAt;
  final List<LoggedExercise> exercises;
  final double caloriesBurned;
  final int durationMinutes;
  final String? sessionId;

  const WorkoutSessionLog({
    this.status = WorkoutStatus.planned,
    this.workoutName,
    this.skipReason,
    this.customDescription,
    this.completedAt,
    this.exercises = const [],
    this.caloriesBurned = 0,
    this.durationMinutes = 45,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'status': status.firestoreValue,
        if (workoutName != null) 'workout_name': workoutName,
        if (skipReason != null) 'skip_reason': skipReason,
        if (customDescription != null) 'custom_description': customDescription,
        if (completedAt != null) 'completed_at': completedAt,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'calories_burned': caloriesBurned,
        'duration_minutes': durationMinutes,
        if (sessionId != null) 'session_id': sessionId,
      };

  factory WorkoutSessionLog.fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return const WorkoutSessionLog();
    return WorkoutSessionLog(
      status: WorkoutStatus.fromString(j['status'] as String?),
      workoutName: j['workout_name'] as String?,
      skipReason: j['skip_reason'] as String?,
      customDescription: j['custom_description'] as String?,
      completedAt: j['completed_at'] as String?,
      exercises: (j['exercises'] as List?)
              ?.map((e) => LoggedExercise.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      caloriesBurned: (j['calories_burned'] as num?)?.toDouble() ?? 0,
      durationMinutes: j['duration_minutes'] as int? ?? 45,
      sessionId: j['session_id'] as String?,
    );
  }

  WorkoutSessionLog copyWith({String? sessionId}) => WorkoutSessionLog(
        status: status,
        workoutName: workoutName,
        skipReason: skipReason,
        customDescription: customDescription,
        completedAt: completedAt,
        exercises: exercises,
        caloriesBurned: caloriesBurned,
        durationMinutes: durationMinutes,
        sessionId: sessionId ?? this.sessionId,
      );
}
