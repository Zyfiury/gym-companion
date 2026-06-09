import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<void> showHealthConnectSheet(
  BuildContext context, {
  required bool connected,
  required int steps,
  required VoidCallback onConnect,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connect health app', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            connected
                ? (steps > 0 ? '$steps steps today — keep moving!' : '0 steps today — keep moving!')
                : 'Sync your step count automatically from Apple Health or Google Fit.',
            style: TextStyle(color: ctx.appTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (!connected)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () {
                  Navigator.pop(ctx);
                  onConnect();
                },
                child: const Text('Connect now'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ),
        ],
      ),
    ),
  );
}
