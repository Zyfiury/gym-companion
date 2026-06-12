import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';

Future<void> showWaterLoggerSheet(BuildContext context) {
  final ctrl = TextEditingController();
  final state = context.read<AppState>();
  final currentMl = state.user?.water.round() ?? 0;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return Padding(
        padding: sheetInsets(ctx),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log water', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
              if (currentMl > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Today: ${(currentMl / 1000).toStringAsFixed(1)}L', style: TextStyle(color: AppColors.accent)),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: ctx.appTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Amount (ml)', hintText: 'e.g. 500'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                  onPressed: () async {
                    final ml = int.tryParse(ctrl.text.trim());
                    if (ml != null && ml > 0) {
                      await ctx.read<AppState>().logWater(ml);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Log water'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
