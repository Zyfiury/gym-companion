import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weekly_goal.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';

Future<void> showGoalPickerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _GoalPickerBody(),
  );
}

class _GoalPickerBody extends StatelessWidget {
  const _GoalPickerBody();

  static final _presets = [
    (GoalType.protein, 150.0, 5),
    (GoalType.calories, 2000.0, 5),
    (GoalType.workouts, 4.0, 4),
    (GoalType.water, 2.5, 5),
    (GoalType.steps, 8000.0, 5),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Padding(
      padding: sheetInsets(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a weekly goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text('Max 2 active goals at once', style: TextStyle(color: t.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ..._presets.map((p) {
            final (type, target, days) = p;
            final preview = WeeklyGoal(
              id: 'preview',
              type: type,
              targetValue: target,
              targetDays: days,
              weekStart: DateTime.now(),
            );
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(preview.label, style: TextStyle(color: t.textPrimary)),
              subtitle: Text('${days} days this week', style: TextStyle(color: t.textSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () async {
                await context.read<AppState>().setWeeklyGoal(type: type, targetValue: target, targetDays: days);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
