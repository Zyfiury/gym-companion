import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../models/workout_status.dart';
import '../screens/workout_detail_screen.dart';
import '../providers/app_state.dart';
import '../services/health_safety_service.dart';
import '../services/workout_adaptation_service.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/skeletons.dart';
import '../core/widgets/tab_load_gate.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/premium_ui.dart';
import '../widgets/staggered_entry.dart';
import '../features/workout/workout_recovery_card.dart';
import '../features/workout/next_session_card.dart';
import '../features/workout/rest_timer_widget.dart';
import '../features/workout/exercise_video_sheet.dart';
import 'custom_workout_builder_screen.dart';
import '../widgets/page_transitions.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  static const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  String? expanded;

  @override
  void initState() {
    super.initState();
    expanded = days[DateTime.now().weekday % 7];
  }

  Future<void> _refresh() async {
    await context.read<AppState>().refreshHealthData();
  }

  Future<void> _playExerciseVideo(String exercise) => showExerciseVideoSheet(context, exercise);

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final user = state.user!;
    final workouts = user.weeklyPlan.workouts;
    final seatedPlan = WorkoutAdaptationService.needsSeatedPlan(user);
    final activeCustom = user.activeCustomWorkout;
    final c = context.appColors;
    final today = days[DateTime.now().weekday % 7];

    if (workouts.isEmpty) {
      return AmbientBackground(
        child: ListView(
          padding: tabListPadding(context),
          children: [
            AppEmptyState(
              icon: Icons.fitness_center_outlined,
              heading: 'No session planned',
              body: "Let's build your week",
              ctaLabel: 'Create workout',
              onCta: () => pushPremium(context, const CustomWorkoutListScreen()),
            ),
          ],
        ),
      );
    }

    final todayW = workouts.where((w) => w.day == today).firstOrNull ?? workouts.first;

    return TabLoadGate(
      skeleton: ListView(
        padding: tabListPadding(context),
        children: const [
          SkeletonWorkoutItem(),
          SkeletonWorkoutItem(),
          SkeletonWorkoutItem(),
          SkeletonWorkoutItem(),
        ],
      ),
      child: AmbientBackground(
      child: Stack(
      children: [
        RefreshIndicator(
        onRefresh: _refresh,
        color: c.primary,
        child: ListView(
          padding: tabListPadding(context),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            StaggeredEntry(
              index: 0,
              child: Semantics(
                identifier: 'workout-today-card',
                button: true,
                label: 'Today\'s workout: ${todayW.focus}',
                child: AppCard(
                  onTap: () => pushPremium(context, WorkoutDetailScreen(workout: todayW)),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [c.dusk, c.primary]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.bolt, color: c.onPrimary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Today', style: TextStyle(fontSize: 13, color: t.textSecondary)),
                                  if (activeCustom != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('Custom', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.primary)),
                                    ),
                                  ],
                                ],
                              ),
                              Text(todayW.focus, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.textPrimary)),
                            ],
                          ),
                        ),
                        if (context.watch<AppState>().todayWorkoutStatus != WorkoutStatus.planned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.mint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.watch<AppState>().todayWorkoutStatus.name,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.mint),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...todayW.exercises.map((e) => _ExerciseRow(label: e, user: user, onTap: () => _playExerciseVideo(e))),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 14),
            const StaggeredEntry(index: 1, child: NextSessionCard()),
            const SizedBox(height: 14),
            const StaggeredEntry(index: 2, child: WorkoutRecoveryCard()),
            if (seatedPlan) ...[
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 2,
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.accessible_forward_rounded, color: c.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your plan is adapted for seated/upper-body training.',
                          style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            StaggeredEntry(
              index: 3,
              child: const SectionLabel('WEEKLY SPLIT'),
            ),
            const SizedBox(height: 12),
            ...workouts.asMap().entries.map((entry) {
              final i = entry.key + 3;
              final w = entry.value;
              final open = expanded == w.day;
              final isToday = w.day == today;
              return StaggeredEntry(
                index: i,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: ValueKey('workout-day-${w.day}'),
                      initiallyExpanded: open,
                      onExpansionChanged: (v) => setState(() => expanded = v ? w.day : null),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isToday ? c.primary.withValues(alpha: 0.12) : t.elevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(w.day, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isToday ? c.primary : t.textMuted)),
                        ),
                      ),
                      title: Text(w.focus, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isToday ? c.primary : t.textPrimary)),
                      subtitle: Text('${w.exercises.length} exercises', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                      children: w.exercises
                          .map((e) => _ExerciseListTile(exercise: e, user: user, onTap: () => _playExerciseVideo(e)))
                          .toList(),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            StaggeredEntry(
              index: workouts.length + 4,
              child: Semantics(
                identifier: 'workout-custom-routines',
                button: true,
                child: AppCard(
                  key: const ValueKey('workout-custom-routines'),
                  onTap: () => pushPremium(context, const CustomWorkoutListScreen()),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.fitness_center, color: c.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My routines', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.textPrimary)),
                            Text('Create & edit custom workouts', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: t.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: RestTimerPill(),
        ),
      ],
    ),
    ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final String label;
  final UserData user;
  final VoidCallback onTap;

  const _ExerciseRow({required this.label, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final safety = HealthSafetyService.checkWorkoutSafe(label, user);
    if (!safety.isSafe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: c.sand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, color: t.textPrimary)),
                  Text('Adapted for your mobility', style: TextStyle(fontSize: 11, color: c.sand)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline, size: 18, color: c.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: t.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final String exercise;
  final UserData user;
  final VoidCallback onTap;

  const _ExerciseListTile({required this.exercise, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final safety = HealthSafetyService.checkWorkoutSafe(exercise, user);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        safety.isSafe ? Icons.fitness_center : Icons.info_outline,
        size: 16,
        color: safety.isSafe ? t.textMuted : c.sand,
      ),
      title: Text(exercise, style: TextStyle(fontSize: 14, color: t.textPrimary)),
      subtitle: safety.isSafe ? null : Text('Adapted for your mobility', style: TextStyle(fontSize: 11, color: c.sand)),
      trailing: safety.isSafe ? Icon(Icons.play_circle_outline, size: 20, color: c.primary) : null,
      onTap: safety.isSafe ? onTap : null,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
