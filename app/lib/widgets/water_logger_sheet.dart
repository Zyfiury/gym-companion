import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';

Future<void> showWaterLoggerSheet(BuildContext context) {
  final ctrl = TextEditingController();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      final state = ctx.watch<AppState>();
      final currentMl = state.user?.water.round() ?? 0;
      final c = ctx.appColors;
      final t = ctx.appTheme;

      Future<void> add(int ml) async {
        HapticFeedback.lightImpact();
        await ctx.read<AppState>().logWater(ml);
        if (ctx.mounted) Navigator.pop(ctx);
      }

      return Padding(
        padding: sheetInsets(ctx),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log water', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
              if (currentMl > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Today: ${(currentMl / 1000).toStringAsFixed(1)}L', style: TextStyle(color: c.primary)),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickBtn(label: '+250ml', onTap: () => add(250)),
                  _QuickBtn(label: '+500ml', onTap: () => add(500)),
                  _QuickBtn(label: '+750ml', onTap: () => add(750)),
                  _QuickBtn(label: '+1L', onTap: () => add(1000)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: t.textPrimary),
                decoration: const InputDecoration(labelText: 'Custom amount (ml)', hintText: 'e.g. 500'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ml = int.tryParse(ctrl.text.trim());
                    if (ml != null && ml > 0) await add(ml);
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

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
