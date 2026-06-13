import '../models/progression_event.dart';

class SetLog {
  final int reps;
  final double? weightKg;
  final int targetReps;

  const SetLog({required this.reps, this.weightKg, required this.targetReps});
}

class SessionLog {
  final String date;
  final List<SetLog> sets;

  const SessionLog({required this.date, required this.sets});
}

class ProgressiveOverloadService {
  static const double incrementKg = 2.5;

  /// Compare current session vs previous - returns suggestion for next session.
  static ProgressionEvent? suggestNext({
    required String exerciseId,
    required String exerciseName,
    required SessionLog? previous,
    required SessionLog current,
    bool prHit = false,
  }) {
    if (current.sets.isEmpty) return null;

    final workingWeight = _maxWeight(current.sets);
    if (workingWeight <= 0) return null;

    if (prHit) {
      return ProgressionEvent(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        suggestedWeightKg: _roundToPlate(workingWeight + incrementKg),
        message: 'New working weight - try +${incrementKg}kg next session',
        date: DateTime.now(),
      );
    }

    if (previous == null || previous.sets.isEmpty) {
      return ProgressionEvent(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        suggestedWeightKg: workingWeight,
        message: 'Baseline logged - repeat to confirm before increasing',
        date: DateTime.now(),
      );
    }

    final allHit = current.sets.every((s) => s.reps >= s.targetReps);
    final anyMissed = current.sets.any((s) => s.reps < s.targetReps);

    if (allHit) {
      return ProgressionEvent(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        suggestedWeightKg: _roundToPlate(workingWeight + incrementKg),
        message: 'All sets hit - suggest +${incrementKg}kg next session',
        date: DateTime.now(),
      );
    }

    if (anyMissed) {
      return ProgressionEvent(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        suggestedWeightKg: workingWeight,
        message: 'Focus on form - keep same weight next session',
        date: DateTime.now(),
      );
    }

    return null;
  }

  static double totalVolume(List<SetLog> sets) =>
      sets.fold(0.0, (sum, s) => sum + (s.weightKg ?? 0) * s.reps);

  static Map<String, double> weeklyVolumeByMuscle(
    Map<String, List<SessionLog>> sessionsByExercise,
    Map<String, String> exerciseMuscleTags,
  ) {
    final volume = <String, double>{};
    for (final entry in sessionsByExercise.entries) {
      final muscle = exerciseMuscleTags[entry.key] ?? 'other';
      final weekVol = entry.value.fold(0.0, (s, session) => s + totalVolume(session.sets));
      volume[muscle] = (volume[muscle] ?? 0) + weekVol;
    }
    return volume;
  }

  static double _maxWeight(List<SetLog> sets) =>
      sets.map((s) => s.weightKg ?? 0).fold(0.0, (a, b) => a > b ? a : b);

  static double _roundToPlate(double kg) => (kg / incrementKg).round() * incrementKg;
}
