import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_toast.dart';
import '../../models/user_data.dart';
import '../../models/workout_session.dart';
import '../../providers/app_state.dart';
import '../../services/progressive_overload_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/exercise_parser.dart';
import 'rest_timer_widget.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutDay workout;
  const WorkoutSessionScreen({super.key, required this.workout});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _SetRow {
  double weight;
  int reps;
  int targetReps;
  bool done;

  _SetRow({required this.weight, required this.reps, required this.targetReps, this.done = false});
}

class _ExerciseBlock {
  final ParsedExercise parsed;
  final List<_SetRow> sets;
  SessionLog? previous;

  _ExerciseBlock({required this.parsed, required this.sets, this.previous});
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late List<_ExerciseBlock> _blocks;
  int _exerciseIndex = 0;
  late DateTime _started;
  Timer? _elapsed;
  int _elapsedSec = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _elapsed = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSec = DateTime.now().difference(_started).inSeconds);
    });
    _blocks = widget.workout.exercises.map((raw) {
      final p = ExerciseParser.parse(raw);
      final state = context.read<AppState>();
      final target = state.user?.nextSessionTargets[p.name];
      final weight = target ?? p.weightKg ?? 0;
      return _ExerciseBlock(
        parsed: p,
        sets: List.generate(
          p.sets,
          (_) => _SetRow(weight: weight, reps: p.reps, targetReps: p.reps),
        ),
      );
    }).toList();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final state = context.read<AppState>();
    for (var i = 0; i < _blocks.length; i++) {
      final prev = await state.fetchLastExerciseSession(_blocks[i].parsed.name);
      if (prev != null && mounted) {
        setState(() => _blocks[i].previous = prev);
      }
    }
  }

  @override
  void dispose() {
    _elapsed?.cancel();
    super.dispose();
  }

  _ExerciseBlock get _current => _blocks[_exerciseIndex];

  String get _elapsedLabel {
    final m = _elapsedSec ~/ 60;
    final s = _elapsedSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _completeSet(int setIndex) {
    HapticFeedback.lightImpact();
    setState(() => _current.sets[setIndex].done = true);
    final rest = 90;
    context.read<RestTimerController>().start(seconds: rest, exerciseName: _current.parsed.name);
    final allDone = _current.sets.every((s) => s.done);
    if (allDone && _exerciseIndex < _blocks.length - 1) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _exerciseIndex++);
      });
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final state = context.read<AppState>();
    final detailed = <String, List<SetLog>>{};
    final exercises = <LoggedExercise>[];
    final previousByExercise = <String, SessionLog>{};

    for (final block in _blocks) {
      final completed = block.sets.where((s) => s.done).toList();
      if (completed.isEmpty) continue;
      final sets = completed
          .map((s) => SetLog(reps: s.reps, weightKg: s.weight, targetReps: s.targetReps))
          .toList();
      detailed[block.parsed.name] = sets;
      if (block.previous != null) previousByExercise[block.parsed.name] = block.previous!;
      final maxWeight = sets.map((s) => s.weightKg ?? 0).fold(0.0, (a, b) => a > b ? a : b);
      final avgReps = (sets.map((s) => s.reps).reduce((a, b) => a + b) / sets.length).round();
      exercises.add(LoggedExercise(
        name: block.parsed.name,
        sets: sets.length,
        reps: avgReps,
        weightKg: maxWeight > 0 ? maxWeight : null,
      ));
    }

    if (exercises.isEmpty) {
      if (mounted) AppToast.error(context, 'Log at least one set to finish');
      setState(() => _finishing = false);
      return;
    }

    final mins = (_elapsedSec / 60).ceil().clamp(1, 240);
    final msg = await state.completeTodayWorkout(
      exercises: exercises,
      durationMinutes: mins,
      workoutName: widget.workout.focus,
      detailedSets: detailed,
      previousSessions: previousByExercise,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (msg != null) AppToast.success(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final block = _current;
    final prev = block.previous;
    final prevLabel = prev != null && prev.sets.isNotEmpty
        ? 'Last: ${prev.sets.length}×${prev.sets.first.reps} @ ${prev.sets.map((s) => s.weightKg ?? 0).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}kg'
        : null;

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: AppBar(
        title: Text('Live session'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_elapsedLabel, style: TextStyle(fontWeight: FontWeight.w700, color: c.primary))),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              LinearProgressIndicator(
                value: (_exerciseIndex + 1) / _blocks.length,
                backgroundColor: t.progressTrack,
                color: c.primary,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text(
                'Exercise ${_exerciseIndex + 1} of ${_blocks.length}',
                style: TextStyle(fontSize: 12, color: t.textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(block.parsed.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.textPrimary)),
              if (prevLabel != null) ...[
                const SizedBox(height: 6),
                Text(prevLabel, style: TextStyle(fontSize: 12, color: c.mint, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 20),
              ...block.sets.asMap().entries.map((e) {
                final i = e.key;
                final set = e.value;
                return Card(
                  color: set.done ? c.mintDim : t.card,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set ${i + 1}', style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Weight', style: TextStyle(fontSize: 12, color: t.textMuted)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: set.done ? null : () => setState(() => set.weight = (set.weight - 2.5).clamp(0, 500)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${set.weight.toStringAsFixed(1)} kg', style: TextStyle(fontWeight: FontWeight.w700, color: t.textPrimary)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: set.done ? null : () => setState(() => set.weight += 2.5),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text('Reps', style: TextStyle(fontSize: 12, color: t.textMuted)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: set.done ? null : () => setState(() => set.reps = (set.reps - 1).clamp(1, 30)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${set.reps}', style: TextStyle(fontWeight: FontWeight.w700, color: t.textPrimary)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: set.done ? null : () => setState(() => set.reps = (set.reps + 1).clamp(1, 30)),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: set.done ? null : () => _completeSet(i),
                              icon: Icon(set.done ? Icons.check_circle : Icons.check_circle_outline, color: set.done ? c.mint : c.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_exerciseIndex < _blocks.length - 1)
                TextButton(
                  onPressed: () => setState(() => _exerciseIndex++),
                  child: const Text('Skip exercise'),
                ),
            ],
          ),
          const Positioned(left: 0, right: 0, bottom: 72, child: RestTimerPill()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _finishing ? null : _finish,
              child: Text(_finishing ? 'Saving…' : 'Finish workout'),
            ),
          ),
        ],
      ),
    );
  }
}
