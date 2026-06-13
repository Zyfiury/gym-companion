import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class NextSessionCard extends StatelessWidget {
  const NextSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final progressions = state.recentProgressions;
    if (progressions.isEmpty) return const SizedBox.shrink();

    final latest = progressions.first;
    final t = context.appTheme;
    final c = context.appColors;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.oliveDim,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text('Suggested ↑', style: TextStyle(color: c.olive, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(latest.exerciseName, style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
                Text(
                  '${latest.suggestedWeightKg} kg - ${latest.message}',
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
