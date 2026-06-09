import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_data.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/profile/profile_glass_card.dart';
import '../../widgets/profile/profile_hero_header.dart';
import '../../widgets/staggered_entry.dart';

class ProfileYouTab extends StatelessWidget {
  final UserData user;
  final String displayName;
  final VoidCallback onEdit;

  const ProfileYouTab({
    super.key,
    required this.user,
    required this.displayName,
    required this.onEdit,
  });

  String _goalLabel(String goal) => switch (goal) {
        'cut' => 'Cut',
        'bulk' => 'Bulk',
        _ => 'Maintain',
      };

  String _nutritionLabel(String mode) => switch (mode) {
        'home_delivery' => 'Home delivery',
        'eat_out' => 'Eat out',
        _ => 'Cook myself',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final g = user.gamification;
    final xp = g['xp'] as int? ?? 0;
    final level = g['level'] as int? ?? 1;
    final streak = g['streak'] as int? ?? 0;
    final xpInLevel = xp % 100;
    final xpProgress = xpInLevel / 100.0;
    final budgetPct = user.weeklyBudget > 0 ? (user.budgetSpent / user.weeklyBudget).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              StaggeredEntry(
                index: 0,
                child: ProfileHeroHeader(
                  displayName: displayName,
                  goalLabel: _goalLabel(user.goal),
                  statsLine: '${user.weight.round()} kg · ${user.tdee} kcal',
                  profileComplete: user.profileComplete,
                  onEdit: onEdit,
                ),
              ),
              if (!user.profileComplete) ...[
                const SizedBox(height: 12),
                StaggeredEntry(
                  index: 1,
                  child: ProfileGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.ember, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete your profile so we can personalize workouts and meals.',
                            style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              StaggeredEntry(
                index: 2,
                child: ProfileGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel('Progress'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StatPill(icon: Icons.military_tech_outlined, value: '$level', label: 'Level'),
                          StatPill(icon: Icons.bolt_rounded, value: '$xp', label: 'XP'),
                          StatPill(icon: Icons.local_fire_department_outlined, value: '$streak', label: 'Streak'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TO NEXT LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: t.textMuted)),
                          Text('$xpInLevel / 100 XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedProgressBar(value: xpProgress, color: AppColors.volt, trackColor: t.progressTrack, height: 6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 3,
                child: ProfileGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel('Food budget'),
                      const SizedBox(height: 12),
                      Text(
                        '£${user.budgetSpent.toStringAsFixed(2)} / £${user.weeklyBudget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: t.textPrimary,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedProgressBar(value: budgetPct, color: AppColors.ember, trackColor: t.progressTrack, height: 6),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [5, 10, 15].map((n) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: n == 15 ? 0 : 8),
                              child: PressableScale(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<AppState>().patchUser((u) => u.budgetSpent += n.toDouble());
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: t.elevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.volt.withValues(alpha: 0.35)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+£$n',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.volt),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 4,
                child: ProfileGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel('Your plan'),
                      const SizedBox(height: 12),
                      _SummaryRow(label: 'Goal', value: _goalLabel(user.goal)),
                      _SummaryRow(label: 'Weight', value: '${user.weight.round()} kg'),
                      _SummaryRow(label: 'Height', value: '${user.height.round()} cm'),
                      _SummaryRow(label: 'Age', value: '${user.age}'),
                      _SummaryRow(label: 'TDEE', value: '${user.tdee} kcal'),
                      _SummaryRow(label: 'Weekly budget', value: '£${user.weeklyBudget.toStringAsFixed(0)}'),
                      _SummaryRow(label: 'Nutrition', value: _nutritionLabel(user.nutritionMode)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: t.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary)),
        ],
      ),
    );
  }
}
