import 'package:flutter/material.dart';

import '../services/barcode_lookup.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/barcode_confirm_sheet.dart';
import '../widgets/premium_ui.dart';

/// Manual barcode entry only - use [FoodLogActionsCard] on the Food tab instead.
@Deprecated('Use FoodLogActionsCard on the Food tab')
class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNotFound(String code) async {
    final t = context.appTheme;
    final nameCtrl = TextEditingController(text: 'Unknown item ($code)');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: sheetInsets(ctx, horizontal: 20, top: 20, extra: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product not found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 8),
            Text('Barcode $code is not in our database. Log manually with estimated macros.', style: TextStyle(fontSize: 13, color: t.textSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(hintText: 'Food name', hintStyle: TextStyle(color: t.textMuted)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.appColors.primary),
                onPressed: () async {
                  final product = {
                    'name': nameCtrl.text.trim().isEmpty ? 'Unknown item' : nameCtrl.text.trim(),
                    'brand': '',
                    'calories': 150.0,
                    'protein': 5.0,
                    'carbs': 20.0,
                    'fat': 5.0,
                    'allergens': <String>[],
                  };
                  Navigator.pop(ctx);
                  await BarcodeConfirmSheet.show(context, product);
                },
                child: const Text('Log manually'),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
  }

  Future<void> _lookupAndConfirm(String code) async {
    setState(() => _loading = true);
    final product = await BarcodeLookup.lookup(code);
    if (!mounted) return;

    if (product == null) {
      setState(() => _loading = false);
      await _showNotFound(code);
      return;
    }

    setState(() => _loading = false);
    await BarcodeConfirmSheet.show(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            identifier: 'barcode-input',
            child: TextField(
              controller: _codeCtrl,
              decoration: InputDecoration(hintText: 'Enter barcode manually', hintStyle: TextStyle(color: t.textMuted)),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            identifier: 'barcode-scan-btn',
            button: true,
            label: 'Look up and Log',
            enabled: !_loading,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading
                    ? null
                    : () => _lookupAndConfirm(_codeCtrl.text.isEmpty ? '5012345678901' : _codeCtrl.text),
                child: Text(_loading ? 'Looking up…' : 'Look up & Log'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
