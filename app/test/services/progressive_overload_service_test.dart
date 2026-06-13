import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/progressive_overload_service.dart';

void main() {
  test('suggests +2.5kg when all reps hit', () {
    final current = SessionLog(
      date: '2026-06-11',
      sets: const [
        SetLog(reps: 10, weightKg: 80, targetReps: 10),
        SetLog(reps: 10, weightKg: 80, targetReps: 10),
      ],
    );
    final previous = SessionLog(
      date: '2026-06-10',
      sets: const [SetLog(reps: 10, weightKg: 80, targetReps: 10)],
    );
    final event = ProgressiveOverloadService.suggestNext(
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      previous: previous,
      current: current,
    );
    expect(event, isNotNull);
    expect(event!.suggestedWeightKg, 82.5);
  });

  test('keeps weight when reps missed', () {
    final previous = SessionLog(
      date: '2026-06-10',
      sets: const [SetLog(reps: 10, weightKg: 80, targetReps: 10)],
    );
    final current = SessionLog(
      date: '2026-06-11',
      sets: const [SetLog(reps: 6, weightKg: 80, targetReps: 10)],
    );
    final event = ProgressiveOverloadService.suggestNext(
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      previous: previous,
      current: current,
    );
    expect(event?.suggestedWeightKg, 80);
    expect(event?.message, contains('form'));
  });
}
