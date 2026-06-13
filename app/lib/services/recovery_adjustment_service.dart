import '../models/user_data.dart';
import '../models/workout_status.dart';

enum RecoveryChoice { keep, lighter, heavier }

class RecoveryAdjustmentResult {
  final List<WorkoutDay> adjustedWorkouts;
  final WorkoutStatus status;
  final String adjustment; // none | lighter | heavier
  final String message;

  const RecoveryAdjustmentResult({
    required this.adjustedWorkouts,
    required this.status,
    required this.adjustment,
    required this.message,
  });
}

class RecoveryAdjustmentService {
  static bool shouldOfferLighter({required int energyLevel, required double sleepHours}) =>
      energyLevel == 1 || (energyLevel == 2 && sleepHours < 6);

  static bool shouldOfferHeavier({required int energyLevel}) => energyLevel == 4;

  static bool isMorningCheckinWindow() {
    final h = DateTime.now().hour;
    return h >= 6 && h < 11;
  }

  static RecoveryAdjustmentResult apply({
    required WeeklyPlan plan,
    required RecoveryChoice choice,
    required String todayDay,
  }) {
    if (choice == RecoveryChoice.keep) {
      return RecoveryAdjustmentResult(
        adjustedWorkouts: plan.workouts,
        status: WorkoutStatus.planned,
        adjustment: 'none',
        message: 'Keeping your original plan',
      );
    }

    final workouts = plan.workouts.map((w) {
      if (w.day != todayDay) return w;
      final exercises = w.exercises.map((raw) {
        if (choice == RecoveryChoice.lighter) return _lighterExercise(raw);
        return _heavierExercise(raw);
      }).toList();
      if (choice == RecoveryChoice.lighter && exercises.isNotEmpty) {
        exercises.removeLast();
      }
      return WorkoutDay(day: w.day, focus: w.focus, exercises: exercises);
    }).toList();

    return RecoveryAdjustmentResult(
      adjustedWorkouts: workouts,
      status: WorkoutStatus.modified,
      adjustment: choice == RecoveryChoice.lighter ? 'lighter' : 'heavier',
      message: choice == RecoveryChoice.lighter
          ? 'Recovery session - lighter weights and fewer sets'
          : 'Intensity bump - +5% weight today only',
    );
  }

  static String _lighterExercise(String raw) {
    final match = RegExp(r'(.+?)\s+(\d+)×(\d+(?:-\d+)?)(?:\s*@\s*(\d+(?:\.\d+)?)\s*kg)?').firstMatch(raw);
    if (match == null) return raw;
    final name = match.group(1)!;
    final sets = (int.tryParse(match.group(2)!) ?? 3) - 1;
    final reps = match.group(3)!;
    final weight = double.tryParse(match.group(4) ?? '');
    if (weight != null) {
      final lighter = (weight * 0.8 / 2.5).round() * 2.5;
      return '$name ${sets.clamp(1, 99)}×$reps @ ${lighter}kg';
    }
    return '$name ${sets.clamp(1, 99)}×$reps';
  }

  static String _heavierExercise(String raw) {
    final match = RegExp(r'(.+?)\s+(\d+)×(\d+(?:-\d+)?)(?:\s*@\s*(\d+(?:\.\d+)?)\s*kg)?').firstMatch(raw);
    if (match == null) return raw;
    final name = match.group(1)!;
    final sets = match.group(2)!;
    final reps = match.group(3)!;
    final weight = double.tryParse(match.group(4) ?? '');
    if (weight != null) {
      final heavier = (weight * 1.05 / 2.5).round() * 2.5;
      return '$name $sets×$reps @ ${heavier}kg';
    }
    return raw;
  }
}
