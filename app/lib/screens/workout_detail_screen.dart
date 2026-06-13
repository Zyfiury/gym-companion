import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/workout/plate_calculator_sheet.dart';
import '../features/workout/rest_timer_widget.dart';
import '../features/workout/exercise_video_sheet.dart';
import '../features/workout/workout_session_screen.dart';
import '../models/user_data.dart';
import '../models/workout_status.dart';
import '../providers/app_state.dart';
import '../core/widgets/app_toast.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_parser.dart';
import '../widgets/workout_complete_sheet.dart';
import '../widgets/workout_custom_sheet.dart';
import '../widgets/workout_skip_sheet.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutDay workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  Color _statusColor(WorkoutStatus status, AppColorsExtension c) => switch (status) {
        WorkoutStatus.completed => c.mint,
        WorkoutStatus.skipped => c.textMuted,
        WorkoutStatus.modified => c.sand,
        WorkoutStatus.planned => c.textSecondary,
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
    final c = context.appColors;
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
              color: _statusColor(status, c).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(color: _statusColor(status, c), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('${workout.day} · ${workout.exercises.length} exercises', style: TextStyle(color: t.textSecondary)),
              const SizedBox(height: 16),
              ...workout.exercises.map((raw) {
                final parsed = ExerciseParser.parse(raw);
                final target = state.user?.nextSessionTargets[parsed.name];
                return Card(
                  color: t.card,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(parsed.name, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${parsed.sets} × ${parsed.reps}${target != null ? ' · target ${target.toStringAsFixed(1)}kg' : parsed.weightKg != null ? ' @ ${parsed.weightKg}kg' : ''}',
                    ),
                    onTap: () => showExerciseVideoSheet(context, raw),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (parsed.weightKg != null)
                          IconButton(
                            tooltip: 'Plate calculator',
                            icon: Icon(Icons.fitness_center, size: 20, color: t.textMuted),
                            onPressed: () => showPlateCalculatorSheet(context, initialWeightKg: parsed.weightKg),
                          ),
                        IconButton(
                          tooltip: 'Start 90s rest',
                          icon: Icon(Icons.timer_outlined, size: 20, color: c.primary),
                          onPressed: () {
                            context.read<RestTimerController>().start(seconds: 90, exerciseName: parsed.name);
                            AppToast.success(context, 'Rest timer started - 90s');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(child: RestTimerPill()),
          ),
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
                  identifier: 'workout-start-session',
                  button: true,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: c.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: status == WorkoutStatus.completed
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WorkoutSessionScreen(workout: workout)),
                            ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start workout'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  identifier: 'workout-mark-complete',
                  button: true,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: c.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: status == WorkoutStatus.completed
                        ? null
                        : () => showWorkoutCompleteSheet(context, workout.exercises),
                    child: const Text('Quick complete'),
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
