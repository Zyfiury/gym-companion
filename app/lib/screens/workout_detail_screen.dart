import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../models/workout_status.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_parser.dart';
import '../widgets/workout_complete_sheet.dart';
import '../widgets/workout_custom_sheet.dart';
import '../widgets/workout_skip_sheet.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutDay workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  Color _statusColor(WorkoutStatus status, AppThemeColors t) => switch (status) {
        WorkoutStatus.completed => AppColors.emerald,
        WorkoutStatus.skipped => t.textMuted,
        WorkoutStatus.modified => AppColors.ember,
        WorkoutStatus.planned => t.textSecondary,
      };

  String _statusLabel(WorkoutStatus status) => switch (status) {
        WorkoutStatus.completed => 'Completed',
        WorkoutStatus.skipped => 'Skipped',
        WorkoutStatus.modified => 'Modified',
        WorkoutStatus.planned => 'Planned',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final status = state.todayWorkoutStatus;

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: AppBar(
        title: Text(workout.focus),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status, t).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(color: _statusColor(status, t), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('${workout.day} · ${workout.exercises.length} exercises', style: TextStyle(color: t.textSecondary)),
          const SizedBox(height: 16),
          ...workout.exercises.map((raw) {
            final parsed = ExerciseParser.parse(raw);
            return Card(
              color: t.card,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(parsed.name, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('${parsed.sets} × ${parsed.reps}${parsed.weightKg != null ? ' @ ${parsed.weightKg}kg' : ''}'),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  identifier: 'workout-mark-complete',
                  button: true,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: status == WorkoutStatus.completed
                        ? null
                        : () => showWorkoutCompleteSheet(context, workout.exercises),
                    child: const Text('Mark as Complete'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => showWorkoutCustomSheet(context),
                      child: const Text('I did something else'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => showWorkoutSkipSheet(context),
                      child: const Text('Skip today'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
