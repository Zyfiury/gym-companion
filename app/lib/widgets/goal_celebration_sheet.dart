import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/pending_celebrations.dart';
import '../providers/app_state.dart';
import '../core/navigation/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import 'feed_compose_sheet.dart';

class GoalCelebrationSheet extends StatelessWidget {
  final PendingGoalCelebration celebration;

  const GoalCelebrationSheet({super.key, required this.celebration});

  static Future<void> show(BuildContext context, PendingGoalCelebration celebration) {
    return AppRouter.pushModal(
      context,
      Scaffold(
        backgroundColor: context.appColors.bgBase,
        body: SafeArea(child: GoalCelebrationSheet(celebration: celebration)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;

    return Padding(
      padding: sheetInsets(context, horizontal: 24, top: 24, extra: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 48, color: c.olive),
          const SizedBox(height: 16),
          Text('Goal crushed 🎯', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text(
            '${celebration.goalLabel} - ${celebration.daysAchieved} of ${celebration.targetDays} days',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.pop(context);
                showFeedComposeSheet(
                  context,
                  initialPostType: 'progress',
                  initialContent: 'Goal crushed this week: ${celebration.goalLabel} 🎯',
                );
                context.read<AppState>().clearPendingGoalCelebration();
              },
              child: const Text('Share to feed'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppState>().clearPendingGoalCelebration();
            },
            child: const Text('Nice - keep going'),
          ),
        ],
      ),
    );
  }
}
