import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_session.dart';
import '../providers/app_state.dart';
import '../services/activity_calorie_service.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_parser.dart';
import '../utils/sheet_padding.dart';

Future<void> showWorkoutCompleteSheet(BuildContext context, List<String> exerciseStrings) async {
  final parsed = ExerciseParser.parseAll(exerciseStrings);
  final controllers = parsed
      .map(
        (e) => _ExerciseRowState(
          name: e.name,
          sets: TextEditingController(text: '${e.sets}'),
          reps: TextEditingController(text: '${e.reps}'),
          weight: TextEditingController(text: e.weightKg?.toStringAsFixed(0) ?? ''),
        ),
      )
      .toList();
  var duration = 45.0;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: sheetInsets(ctx),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Confirm workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
              const SizedBox(height: 12),
              ...controllers.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.name, style: TextStyle(fontWeight: FontWeight.w600, color: ctx.appTheme.textPrimary)),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: row.sets, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sets'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: row.reps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: row.weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kg'))),
                          ],
                        ),
                      ],
                    ),
                  )),
              Text('Duration: ${duration.round()} min', style: TextStyle(color: ctx.appTheme.textSecondary)),
              Slider(
                value: duration,
                min: 15,
                max: 120,
                divisions: 21,
                label: '${duration.round()} min',
                onChanged: (v) => setLocal(() => duration = v),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: () async {
                    final exercises = controllers.map((row) {
                      final met = ActivityCalorieService.metForExercise(row.name);
                      return LoggedExercise(
                        name: row.name,
                        sets: int.tryParse(row.sets.text) ?? 3,
                        reps: int.tryParse(row.reps.text) ?? 10,
                        weightKg: double.tryParse(row.weight.text),
                        met: met,
                      );
                    }).toList();
                    final msg = await ctx.read<AppState>().completeTodayWorkout(
                          exercises: exercises,
                          durationMinutes: duration.round(),
                        );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (msg != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    }
                  },
                  child: const Text('Mark as Complete'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ExerciseRowState {
  final String name;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController weight;

  _ExerciseRowState({required this.name, required this.sets, required this.reps, required this.weight});
}
