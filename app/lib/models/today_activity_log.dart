import 'workout_session.dart';
import 'workout_status.dart';

/// Today's activity snapshot - synced to daily_logs/{date} in Firestore.
class TodayActivityLog {
  double stepCalories;
  double workoutCalories;
  WorkoutStatus workoutStatus;
  String? workoutName;
  WorkoutSessionLog session;
  String? todayWorkoutSessionId;

  TodayActivityLog({
    this.stepCalories = 0,
    this.workoutCalories = 0,
    this.workoutStatus = WorkoutStatus.planned,
    this.workoutName,
    WorkoutSessionLog? session,
    this.todayWorkoutSessionId,
  }) : session = session ?? const WorkoutSessionLog();

  double get activeCaloriesBurned => stepCalories + workoutCalories;

  void applyFromDailyLog(Map<String, dynamic> log) {
    stepCalories = (log['step_calories'] as num?)?.toDouble() ?? 0;
    workoutCalories = (log['workout_calories'] as num?)?.toDouble() ?? 0;
    workoutStatus = WorkoutStatus.fromString(log['workout_status'] as String?);
    workoutName = log['workout_name'] as String?;
    todayWorkoutSessionId = log['workout_session_id'] as String?;
    final sessionMap = log['workout_session'] as Map<String, dynamic>?;
    if (sessionMap != null) {
      session = WorkoutSessionLog.fromJson(sessionMap);
    }
  }

  Map<String, dynamic> toDailyLogFields() => {
        'step_calories': stepCalories,
        'workout_calories': workoutCalories,
        'active_calories_burned': activeCaloriesBurned,
        'workout_status': workoutStatus.firestoreValue,
        if (workoutName != null) 'workout_name': workoutName,
        if (todayWorkoutSessionId != null) 'workout_session_id': todayWorkoutSessionId,
        'workout_session': session.toJson(),
      };
}
