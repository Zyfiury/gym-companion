import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../screens/workout_detail_screen.dart';
import '../../widgets/page_transitions.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import 'photo_log_sheet.dart';
import 'weight_log_sheet.dart';

Future<void> showUnifiedLogSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _UnifiedLogBody(),
  );
}

class _UnifiedLogBody extends StatelessWidget {
  const _UnifiedLogBody();

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;

    return Padding(
      padding: sheetInsets(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Text('Log something', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 8),
          _LogRow(
            semanticsId: 'log-food',
            icon: Icons.restaurant_outlined,
            title: 'Log food',
            subtitle: 'Search, scan or speak',
            onTap: () {
              Navigator.pop(context);
              context.read<AppState>().setTab(2);
            },
          ),
          _LogRow(
            semanticsId: 'log-photo',
            icon: Icons.photo_camera_outlined,
            title: 'Photo log',
            subtitle: 'Point camera at your meal',
            onTap: () {
              Navigator.pop(context);
              showPhotoLogSheet(context);
            },
          ),
          _LogRow(
            semanticsId: 'log-workout',
            icon: Icons.fitness_center_outlined,
            title: 'Log workout',
            subtitle: "Record today's session",
            onTap: () {
              Navigator.pop(context);
              final workout = context.read<AppState>().todayWorkoutDay;
              if (workout != null) {
                pushPremium(context, WorkoutDetailScreen(workout: workout));
              }
            },
          ),
          _LogRow(
            semanticsId: 'log-weight',
            icon: Icons.monitor_weight_outlined,
            title: 'Log weight',
            subtitle: 'Track your progress',
            onTap: () {
              Navigator.pop(context);
              showWeightLogSheet(context);
            },
          ),
          _LogRow(
            semanticsId: 'log-water',
            icon: Icons.water_drop_outlined,
            title: 'Log water',
            subtitle: "Add to today's intake",
            onTap: () {
              Navigator.pop(context);
              context.read<AppState>().showWaterSheet(context);
            },
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final String semanticsId;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LogRow({
    required this.semanticsId,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;

    return Semantics(
      identifier: semanticsId,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Icon(icon, size: 24, color: c.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: t.textPrimary)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: t.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
