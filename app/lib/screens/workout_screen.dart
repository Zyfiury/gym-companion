import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_data.dart';
import '../providers/app_state.dart';
import '../services/health_safety_service.dart';
import '../services/workout_adaptation_service.dart';
import '../services/youtube_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_ui.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/staggered_entry.dart';
import 'barcode_screen.dart';
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
  bool _loadingVideo = false;

  @override
  void initState() {
    super.initState();
    expanded = days[DateTime.now().weekday % 7];
  }

  Future<void> _playExerciseVideo(String exercise) async {
    final user = context.read<AppState>().user!;
    final safety = HealthSafetyService.checkWorkoutSafe(exercise, user);
    if (!safety.isSafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safety.warning ?? 'Exercise adapted for your mobility')),
      );
      return;
    }

    setState(() => _loadingVideo = true);
    final query = HealthSafetyService.videoSearchQuery(exercise, user);
    final cacheKey = HealthSafetyService.videoCacheKey(exercise, user);
    final video = await YouTubeService.searchExercise(query, cacheKey: cacheKey);
    if (!mounted) return;
    setState(() => _loadingVideo = false);

    if (video == null) {
      final name = exercise.split(RegExp(r'\s+\d')).first.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(YouTubeService.hasKey ? 'No video found for $name' : 'Add YOUTUBE_API_KEY for exercise videos')),
      );
      return;
    }

    final t = context.appTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(video.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 14),
            if (video.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(video.thumbnail, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => launchUrl(Uri.parse('https://youtube.com/watch?v=${video.videoId}'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch on YouTube'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final user = state.user!;
    final workouts = user.weeklyPlan.workouts;
    final seatedPlan = WorkoutAdaptationService.needsSeatedPlan(user);
    final activeCustom = user.activeCustomWorkout;
    final today = days[DateTime.now().weekday % 7];
    final todayW = workouts.where((w) => w.day == today).firstOrNull ?? workouts.first;

    return AmbientBackground(
      child: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            StaggeredEntry(index: 0, child: BarcodeScreen(key: ValueKey('workout-barcode'))),
            if (seatedPlan) ...[
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 1,
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.accessible_forward_rounded, color: AppColors.accent, size: 22),
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
            const SizedBox(height: 14),
            StaggeredEntry(
              index: 1,
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
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.fitness_center, color: AppColors.accent, size: 20),
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
            const SizedBox(height: 20),
            StaggeredEntry(
              index: 2,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.bolt, color: Colors.white, size: 20),
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
                                        color: AppColors.accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Custom', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
                                    ),
                                  ],
                                ],
                              ),
                              Text(todayW.focus, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.textPrimary)),
                            ],
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
            const SizedBox(height: 28),
            StaggeredEntry(
              index: 2,
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
                          color: isToday ? AppColors.accent.withValues(alpha: 0.12) : t.elevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(w.day, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isToday ? AppColors.accent : t.textMuted)),
                        ),
                      ),
                      title: Text(w.focus, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isToday ? AppColors.accent : t.textPrimary)),
                      subtitle: Text('${w.exercises.length} exercises', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                      children: w.exercises
                          .map((e) => _ExerciseListTile(exercise: e, user: user, onTap: () => _playExerciseVideo(e)))
                          .toList(),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        if (_loadingVideo)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppCard(child: SizedBox(width: 280, child: MealCardSkeleton())),
            ),
          ),
      ],
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
    final safety = HealthSafetyService.checkWorkoutSafe(label, user);
    if (!safety.isSafe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.ember),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, color: t.textPrimary)),
                  Text('Adapted for your mobility', style: TextStyle(fontSize: 11, color: AppColors.ember)),
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
            Icon(Icons.play_circle_outline, size: 18, color: AppColors.accent),
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
    final safety = HealthSafetyService.checkWorkoutSafe(exercise, user);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        safety.isSafe ? Icons.fitness_center : Icons.info_outline,
        size: 16,
        color: safety.isSafe ? t.textMuted : AppColors.ember,
      ),
      title: Text(exercise, style: TextStyle(fontSize: 14, color: t.textPrimary)),
      subtitle: safety.isSafe ? null : Text('Adapted for your mobility', style: TextStyle(fontSize: 11, color: AppColors.ember)),
      trailing: safety.isSafe ? Icon(Icons.play_circle_outline, size: 20, color: AppColors.accent) : null,
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
