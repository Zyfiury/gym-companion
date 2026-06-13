import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/premium_ui.dart';
import '../widgets/page_transitions.dart';

class CustomWorkoutBuilderScreen extends StatefulWidget {
  final CustomWorkout? existing;

  const CustomWorkoutBuilderScreen({super.key, this.existing});

  @override
  State<CustomWorkoutBuilderScreen> createState() => _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState extends State<CustomWorkoutBuilderScreen> {
  late final TextEditingController _nameCtrl;
  late List<CustomExercise> _exercises;
  final Map<int, TextEditingController> _exerciseCtrls = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _exercises = List.from(widget.existing?.exercises ?? [CustomExercise(name: 'Exercise 1')]);
    for (var i = 0; i < _exercises.length; i++) {
      _exerciseCtrls[i] = TextEditingController(text: _exercises[i].name);
    }
  }

  TextEditingController _ctrlFor(int index) {
    return _exerciseCtrls.putIfAbsent(index, () => TextEditingController(text: _exercises[index].name));
  }

  void _disposeCtrl(int index) {
    _exerciseCtrls.remove(index)?.dispose();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _exerciseCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _exercises.isEmpty) return;
    final state = context.read<AppState>();
    final list = List<CustomWorkout>.from(state.user?.customWorkouts ?? []);
    final id = widget.existing?.id ?? 'cw_${DateTime.now().millisecondsSinceEpoch}';
    final workout = CustomWorkout(id: id, name: name, exercises: _exercises);
    final idx = list.indexWhere((w) => w.id == id);
    if (idx >= 0) {
      list[idx] = workout;
    } else {
      list.add(workout);
    }
    await state.saveCustomWorkouts(list);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: AppBar(
        backgroundColor: t.scaffold,
        title: Text(widget.existing == null ? 'New routine' : 'Edit routine', style: TextStyle(color: t.textPrimary)),
        iconTheme: IconThemeData(color: t.textPrimary),
        actions: [
          Semantics(
            identifier: 'custom-workout-save',
            button: true,
            child: TextButton(onPressed: _save, child: Text('Save', style: TextStyle(color: context.appColors.primary, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(context.screenPadding),
        children: [
          Semantics(
            identifier: 'custom-workout-name',
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Routine name'),
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel('Exercises'),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _exercises.removeAt(oldIndex);
                _exercises.insert(newIndex, item);
                final oldCtrl = _exerciseCtrls.remove(oldIndex);
                final rebuilt = <int, TextEditingController>{};
                for (var i = 0; i < _exercises.length; i++) {
                  rebuilt[i] = _exerciseCtrls[i] ?? (i == newIndex && oldCtrl != null ? oldCtrl : TextEditingController(text: _exercises[i].name));
                }
                _exerciseCtrls
                  ..clear()
                  ..addAll(rebuilt);
              });
            },
            itemBuilder: (_, i) {
              final e = _exercises[i];
              return Card(
                key: ValueKey('ex_$i'),
                margin: const EdgeInsets.only(bottom: 10),
                color: t.card,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: 'Exercise'),
                        controller: _ctrlFor(i),
                        onChanged: (v) => e.name = v,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _numField('Sets', e.sets, (v) => e.sets = v)),
                          const SizedBox(width: 8),
                          Expanded(child: _numField('Reps', e.reps, (v) => e.reps = v)),
                          const SizedBox(width: 8),
                          Expanded(child: _numField('Rest (s)', e.restSeconds, (v) => e.restSeconds = v)),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: _exercises.length > 1
                              ? () => setState(() {
                                    _disposeCtrl(i);
                                    _exercises.removeAt(i);
                                  })
                              : null,
                          icon: Icon(Icons.delete_outline, color: t.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Semantics(
            identifier: 'custom-workout-add-exercise',
            button: true,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                final idx = _exercises.length;
                _exercises.add(CustomExercise(name: 'Exercise ${idx + 1}'));
                _exerciseCtrls[idx] = TextEditingController(text: _exercises[idx].name);
              }),
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, int value, void Function(int) onChanged) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: '$value'),
      onChanged: (v) => onChanged(int.tryParse(v) ?? value),
    );
  }
}

class CustomWorkoutListScreen extends StatelessWidget {
  const CustomWorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final workouts = state.user?.customWorkouts ?? [];

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: AppBar(
        backgroundColor: t.scaffold,
        title: Text('My routines', style: TextStyle(color: t.textPrimary)),
        iconTheme: IconThemeData(color: t.textPrimary),
      ),
      floatingActionButton: Semantics(
        identifier: 'custom-workout-create',
        button: true,
        child: FloatingActionButton(
          backgroundColor: c.primary,
          onPressed: () => pushPremium(context, const CustomWorkoutBuilderScreen()),
          child: const Icon(Icons.add),
        ),
      ),
      body: workouts.isEmpty
          ? Center(
              child: EmptyStateCard(
                icon: Icons.fitness_center,
                headline: 'Build your first routine',
                subtext: 'Create a custom workout and use it as today\'s session',
                buttonLabel: 'New routine',
                onAction: () => pushPremium(context, const CustomWorkoutBuilderScreen()),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(context.screenPadding),
              itemCount: workouts.length,
              itemBuilder: (_, i) {
                final w = workouts[i];
                return Semantics(
                  identifier: 'custom-workout-item',
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => pushPremium(context, CustomWorkoutBuilderScreen(existing: w)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.name, style: TextStyle(fontWeight: FontWeight.w700, color: t.textPrimary)),
                                  Text('${w.exercises.length} exercises', style: TextStyle(color: t.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final list = List<CustomWorkout>.from(workouts)..removeAt(i);
                                await state.saveCustomWorkouts(list);
                              },
                              icon: Icon(Icons.delete_outline, color: t.textMuted),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text('Use as today\'s session', style: TextStyle(fontSize: 13, color: t.textSecondary))),
                            Switch(
                              value: w.isActive,
                              onChanged: (v) => state.setActiveCustomWorkout(v ? w.id : null),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
