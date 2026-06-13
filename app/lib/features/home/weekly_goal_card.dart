import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.activeGoals.where((g) => g.isActive).toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    final goal = goals.first;
    final t = context.appTheme;
    final c = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("This week's goal", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: t.textMuted)),
          const SizedBox(height: 8),
          Text('${goal.label} · ${goal.progressLabel}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.textPrimary)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: c.surface2,
              color: c.olive,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.read<AppState>().setTab(3),
            child: Text('Manage in Progress', style: TextStyle(color: c.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
