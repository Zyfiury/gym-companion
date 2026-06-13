import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../widgets/premium_ui.dart';
import '../goals/goal_picker_sheet.dart';

class WeeklyGoalsSection extends StatelessWidget {
  const WeeklyGoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final goals = state.activeGoals.where((g) => g.isActive).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel("This week's goals")),
              TextButton(
                onPressed: () => showGoalPickerSheet(context),
                child: Text('Change goal', style: TextStyle(color: c.primary, fontSize: 13)),
              ),
            ],
          ),
          if (goals.isEmpty)
            AppEmptyState(
              icon: Icons.flag_outlined,
              heading: 'No goals set this week',
              body: 'Set a small target to stay on track',
              ctaLabel: 'Set a goal',
              onCta: () => showGoalPickerSheet(context),
            )
          else ...[
            const SizedBox(height: 8),
            ...goals.map((g) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.label, style: TextStyle(fontWeight: FontWeight.w500, color: t.textPrimary)),
                    Text(g.progressLabel, style: TextStyle(fontSize: 12, color: t.textSecondary)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: g.progress,
                        minHeight: 6,
                        backgroundColor: c.surface2,
                        color: c.olive,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
