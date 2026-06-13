import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../screens/barcode_scanner_page.dart';
import '../../widgets/page_transitions.dart';
import '../../services/barcode_lookup.dart';
import 'voice_food_pill.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import '../../widgets/barcode_confirm_sheet.dart';
import '../../widgets/premium_ui.dart';
import 'food_history_sheet.dart';
import 'food_search_sheet.dart';
import 'frequent_foods_row.dart';
import 'photo_log_sheet.dart';

/// Single food-logging hub: actions + manual barcode (one scanner entry via Scan).
class FoodLogActionsCard extends StatefulWidget {
  const FoodLogActionsCard({super.key});

  @override
  State<FoodLogActionsCard> createState() => _FoodLogActionsCardState();
}

class _FoodLogActionsCardState extends State<FoodLogActionsCard> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _manualBarcodeOpen = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNotFound(String code) async {
    final t = context.appTheme;
    final c = context.appColors;
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
            Text(
              'Barcode $code is not in our database. Log manually with estimated macros.',
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(hintText: 'Food name', hintStyle: TextStyle(color: t.textMuted)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: c.primary),
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
    final c = context.appColors;
    final allergies = context.watch<AppState>().user?.allergies ?? [];
    final allergyLabel = allergies.isEmpty
        ? 'No allergies set'
        : allergies.map((a) => a.replaceAll('_', ' ')).join(', ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log food', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 4),
          Text('Guarding: $allergyLabel', style: TextStyle(fontSize: 12, color: t.textSecondary)),
          const SizedBox(height: 12),
          const VoiceFoodPill(),
          const SizedBox(height: 14),
          const FrequentFoodsRow(),
          Row(
            children: [
              Expanded(child: _ActionTile(
                semanticsId: 'log-food-search',
                icon: Icons.search,
                label: 'Search',
                onTap: () => showFoodSearchSheet(context),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ActionTile(
                semanticsId: 'log-food-scan',
                icon: Icons.qr_code_scanner,
                label: 'Scan',
                onTap: () => pushPremium(context, const BarcodeScannerPage()),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ActionTile(
                semanticsId: 'log-food-photo',
                icon: Icons.photo_camera_outlined,
                label: 'Photo',
                onTap: () => showPhotoLogSheet(context),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ActionTile(
                semanticsId: 'log-food-history',
                icon: Icons.history,
                label: 'History',
                onTap: () => showFoodHistorySheet(context),
              )),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _manualBarcodeOpen = !_manualBarcodeOpen),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Enter barcode manually',
                    style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _manualBarcodeOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: t.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_manualBarcodeOpen) ...[
            const SizedBox(height: 8),
            Semantics(
              identifier: 'barcode-input',
              child: TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  hintText: 'Enter barcode manually',
                  hintStyle: TextStyle(color: t.textMuted),
                  isDense: true,
                ),
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
                  style: FilledButton.styleFrom(backgroundColor: c.primary),
                  onPressed: _loading
                      ? null
                      : () => _lookupAndConfirm(_codeCtrl.text.isEmpty ? '5012345678901' : _codeCtrl.text.trim()),
                  child: Text(_loading ? 'Looking up…' : 'Look up & Log'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String semanticsId;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.semanticsId,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = context.appTheme;

    return Semantics(
      identifier: semanticsId,
      button: true,
      label: label,
      child: Material(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, size: 22, color: c.primary),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
