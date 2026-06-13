import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../core/widgets/app_toast.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';

Future<void> showWorkoutCustomSheet(BuildContext context) async {
  final descCtrl = TextEditingController();
  var duration = 45.0;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: sheetInsets(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What did you do?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'e.g. 30 min football, yoga class...'),
            ),
            const SizedBox(height: 12),
            Text('Duration: ${duration.round()} min', style: TextStyle(color: ctx.appTheme.textSecondary)),
            Slider(
              value: duration,
              min: 10,
              max: 120,
              divisions: 22,
              onChanged: (v) => setLocal(() => duration = v),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.appColors.primary),
                onPressed: () async {
                  final msg = await ctx.read<AppState>().logCustomWorkout(
                        description: descCtrl.text.trim().isEmpty ? 'Custom activity' : descCtrl.text.trim(),
                        durationMinutes: duration.round(),
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (msg != null) {
                      AppToast.success(context, msg);
                    }
                  }
                },
                child: const Text('Log workout'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  descCtrl.dispose();
}
