import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../models/workout_status.dart';
import '../providers/app_state.dart';
import '../screens/workout_detail_screen.dart';
import '../core/widgets/app_toast.dart';
import '../core/widgets/skeletons.dart';
import '../core/widgets/tab_load_gate.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/tdee_update_banner.dart';
import '../widgets/health_connect_sheet.dart';
import '../widgets/premium_ui.dart';
import '../widgets/pro_badge.dart';
import '../widgets/staggered_entry.dart';
import '../widgets/user_avatar.dart';
import '../widgets/page_transitions.dart';
import '../widgets/water_logger_sheet.dart';
import '../features/home/morning_checkin_card.dart';
import '../features/home/calorie_summary_card.dart';
import '../features/home/weekly_goal_card.dart';
import '../features/home/weekly_recap_card.dart';
import '../features/home/fun_fact_card.dart';
import '../core/widgets/animated_xp_bar.dart';
import 'paywall_screen.dart';
import 'profile/profile_screen.dart';
import '../services/subscription_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshHealthData();
    });
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    await Future.wait([
      state.refreshHealthData(),
      state.refreshDailyLogsHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final u = state.user!;
    final target = state.caloriesTarget.round();
    final g = u.gamification;

    return TabLoadGate(
      skeleton: ListView(
        padding: tabListPadding(context),
        children: const [
          SkeletonCard(),
          SizedBox(height: 14),
          SkeletonCard(),
          SizedBox(height: 14),
          SkeletonCard(),
        ],
      ),
      child: AmbientBackground(
      child: RefreshIndicator(
      onRefresh: _refresh,
      color: context.appColors.primary,
      child: ListView(
        padding: tabListPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          StaggeredEntry(
            index: 0,
            child: Semantics(
              identifier: 'home-profile-card',
              button: true,
              label: 'Open your profile',
              explicitChildNodes: true,
              child: InkWell(
                onTap: () => pushPremium(context, const ProfileScreen()),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      UserAvatar(
                        imagePath: u.avatarPath,
                        name: state.displayName ?? 'Athlete',
                        radius: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              identifier: 'home-greeting',
                              child: Text(
                                'Good ${_timeOfDay()}, ${state.displayName ?? 'Athlete'}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: t.textPrimary, letterSpacing: -0.4, height: 1.2),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Semantics(
                              identifier: 'app-subtitle',
                              label: '${state.displayName ?? ""} $target kcal target',
                              child: Text(
                                '${_goalLabel(u.goal)} · $target kcal · View profile',
                                style: TextStyle(color: t.textSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: t.textMuted, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const StaggeredEntry(index: 0, child: TdeeUpdateBanner()),
          const StaggeredEntry(index: 0, child: MorningCheckinCard()),
          const SizedBox(height: 4),
          StaggeredEntry(index: 1, child: CalorieSummaryCard()),
          const SizedBox(height: 14),
          StaggeredEntry(index: 2, child: WeeklyGoalCard()),
          const SizedBox(height: 14),
          StaggeredEntry(index: 2, child: WeeklyRecapCard()),
          const SizedBox(height: 14),
          const StaggeredEntry(index: 2, child: FunFactCard()),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 3,
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  StatPill(
                    icon: Icons.directions_walk,
                    value: state.healthConnected ? '${u.steps.toInt()}' : '-',
                    label: state.healthConnected && state.stepCaloriesBurned > 0
                        ? '${state.stepCaloriesBurned.round()} kcal'
                        : 'Steps',
                    onTap: () => showHealthConnectSheet(
                      context,
                      connected: state.healthConnected,
                      steps: u.steps.toInt(),
                    ),
                  ),
                  StatPill(
                    icon: Icons.water_drop_outlined,
                    value: u.water > 0 ? '${(u.water / 1000).toStringAsFixed(1)}L' : '-',
                    label: 'Water',
                    onTap: () => showWaterLoggerSheet(context),
                  ),
                  StatPill(
                    icon: Icons.local_fire_department_outlined,
                    value: '${g['streak'] ?? 0}d',
                    label: 'Streak',
                    onTap: () => pushPremium(context, const ProfileScreen()),
                  ),
                  StatPill(
                    icon: Icons.bolt_outlined,
                    value: '${g['xp'] ?? 0}',
                    label: 'XP',
                    onTap: () => pushPremium(context, const ProfileScreen()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredEntry(
            index: 3,
            child: AnimatedXpBar(
              xp: g['xp'] as int? ?? 0,
              level: g['level'] as int? ?? 1,
            ),
          ),
          const SizedBox(height: 24),
          StaggeredEntry(index: 4, child: const WorkoutPreview()),
          const SizedBox(height: 14),
          StaggeredEntry(index: 5, child: _MealPreview()),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 6,
            child: _CoachTeaser(onTap: () => state.setTab(4)),
          ),
          const SizedBox(height: 14),
          StaggeredEntry(index: 7, child: _ProStrip()),
        ],
      ),
      ),
    ),
    );
  }

  static String _timeOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  static String _goalLabel(String goal) => switch (goal) {
        'cut' => 'Cutting · stay disciplined',
        'bulk' => 'Bulking · fuel the gains',
        'maintain' => 'Maintaining · consistency wins',
        _ => 'Your plan is ready',
      };
}

class _CoachTeaser extends StatelessWidget {
  final VoidCallback onTap;
  const _CoachTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.primaryTintBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.primaryTintBorder),
        ),
        child: Row(
          children: [
            const CoachAvatar(size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Coach', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: t.textPrimary)),
                  Text('Ask about workouts, meals, or delivery', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: c.primary),
          ],
        ),
      ),
    );
  }
}

class _MealPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final meals = context.watch<AppState>().user!.weeklyPlan.meals;
    if (meals.isEmpty) return const SizedBox.shrink();

    final hour = DateTime.now().hour;
    final mealType = hour < 11 ? 'Breakfast' : hour < 15 ? 'Lunch' : 'Dinner';
    final meal = meals.where((m) => m.mealType == mealType).firstOrNull ?? meals.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Next meal'),
        const SizedBox(height: 10),
        AppCard(
          onTap: () => context.read<AppState>().setTab(2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.restaurant, color: c.mint, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.mealType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted, letterSpacing: 0.3)),
                    Text(meal.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: t.textPrimary)),
                    Text('${meal.macros['calories']} kcal · ${meal.macros['protein']}g protein', style: TextStyle(fontSize: 12, color: t.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.textMuted, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return FutureBuilder<bool>(
      future: SubscriptionService.isPro(),
      builder: (context, snap) {
        if (snap.data == true) return const SizedBox.shrink();
        return PressableScale(
          onTap: () => pushModal(context, const PaywallScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: t.proBannerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.proBannerBorder),
            ),
            child: Row(
              children: [
                const ProBadge(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Unlock Pro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.textPrimary)),
                ),
                Icon(Icons.arrow_forward, size: 18, color: t.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WorkoutPreview extends StatelessWidget {
  const WorkoutPreview({super.key});

  static const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static void _openDetail(BuildContext context, WorkoutDay w) {
    pushPremium(context, WorkoutDetailScreen(workout: w));
  }

  static Color _statusColor(WorkoutStatus status, AppColorsExtension c) => switch (status) {
        WorkoutStatus.completed => c.mint,
        WorkoutStatus.skipped => c.textMuted,
        WorkoutStatus.modified => c.sand,
        WorkoutStatus.planned => c.textSecondary,
      };

  static String _statusLabel(WorkoutStatus status) => switch (status) {
        WorkoutStatus.completed => 'Completed',
        WorkoutStatus.skipped => 'Skipped',
        WorkoutStatus.modified => 'Modified',
        WorkoutStatus.planned => 'Planned',
      };

  static Widget _statusChip(WorkoutStatus status, AppColorsExtension c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status, c).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status, c)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final u = state.user!;
    final custom = u.activeCustomWorkout;

    if (custom != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel("Today's session"),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => state.setTab(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.dusk, c.primary]), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.fitness_center, color: c.onPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(custom.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
                          Text('Custom · ${custom.exercises.length} exercises', style: TextStyle(color: t.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: t.textMuted, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                ...custom.exercises.asMap().entries.map((e) {
                  final done = custom.completedToday.contains(e.value.name);
                  return StaggeredEntry(
                    index: e.key,
                    baseDelayMs: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PressableScale(
                        onTap: done
                            ? null
                            : () async {
                                await state.completeWorkoutExercise(custom.id, e.value.name);
                                if (context.mounted) {
                                  AppToast.success(context, 'Exercise logged ✓');
                                }
                              },
                        child: Row(
                          children: [
                            Icon(
                              done ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 22,
                              color: done ? c.mint : t.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value.name, style: TextStyle(fontSize: 14, color: t.textPrimary))),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    }

    final today = days[DateTime.now().weekday % 7];
    final w = u.weeklyPlan.workouts.where((x) => x.day == today).firstOrNull ?? u.weeklyPlan.workouts.first;
    final status = state.todayWorkoutStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Today's session"),
        const SizedBox(height: 10),
        AppCard(
          onTap: () => _openDetail(context, w),
          child: Semantics(
            identifier: 'workout-today-card',
            button: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.dusk, c.primary]), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.local_fire_department, color: c.onPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.focus, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
                          Text('$today · ${w.exercises.length} exercises', style: TextStyle(color: t.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    _statusChip(status, c),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: t.textMuted, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                ...w.exercises.take(3).toList().asMap().entries.map((e) => StaggeredEntry(
                      index: e.key,
                      baseDelayMs: 50,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.primary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value, style: TextStyle(fontSize: 14, color: t.textPrimary))),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
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
