import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';

Future<void> showWeightLogSheet(BuildContext context) {
  final ctrl = TextEditingController(
    text: context.read<AppState>().user?.weight.toStringAsFixed(1) ?? '',
  );

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: sheetInsets(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ctx.appTheme.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null || v <= 0) return;
                HapticFeedback.lightImpact();
                await ctx.read<AppState>().logWeight(v);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save changes'),
            ),
          ),
        ],
      ),
    ),
  );
}
