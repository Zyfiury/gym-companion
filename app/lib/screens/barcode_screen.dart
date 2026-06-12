import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/food_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/barcode_confirm_sheet.dart';
import '../widgets/premium_ui.dart';
import 'barcode_scanner_page.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _codeCtrl = TextEditingController();
  String? lastMsg;
  bool blocked = false;
  bool _loading = false;

  static const demoFoods = {
    '5012345678901': (name: 'Chicken Breast 100g', cal: 165, p: 31, c: 0, f: 4, allergens: <String>[]),
    '5000112588103': (name: 'Greek Yogurt 500g', cal: 120, p: 10, c: 8, f: 5, allergens: ['milk', 'dairy', 'yogurt']),
    '5000119000000': (name: 'Protein Bar', cal: 220, p: 20, c: 25, f: 8, allergens: ['milk', 'soy']),
  };

  Future<Map<String, dynamic>?> _lookup(String code) async {
    if (demoFoods.containsKey(code)) {
      final demo = demoFoods[code]!;
      return {
        'name': demo.name,
        'brand': '',
        'calories': demo.cal.toDouble(),
        'protein': demo.p.toDouble(),
        'carbs': demo.c.toDouble(),
        'fat': demo.f.toDouble(),
        'allergens': demo.allergens,
      };
    }
    return FoodApiService.lookupBarcode(code);
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
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
                  if (mounted) setState(() => lastMsg = null);
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
    setState(() {
      _loading = true;
      lastMsg = null;
      blocked = false;
    });

    final product = await _lookup(code);
    if (!mounted) return;

    if (product == null) {
      setState(() => _loading = false);
      await _showNotFound(code);
      return;
    }

    setState(() => _loading = false);
    await BarcodeConfirmSheet.show(context, product);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final u = context.watch<AppState>().user!;
    final logged = u.dailyMacrosLogged.calories;
    final target = u.weeklyPlan.macros['calories'] ?? u.tdee;
    final allergyLabel = u.allergies.isEmpty ? 'No allergies set' : u.allergies.map((a) => a.replaceAll('_', ' ')).join(', ');

    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log food', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
                      Text('Guarding: $allergyLabel', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MacroBar(label: 'Calories today', current: logged, target: target, color: AppColors.accent),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.volt, side: BorderSide(color: t.borderSubtle)),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
                  setState(() {});
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Open camera scanner'),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              identifier: 'barcode-input',
              child: TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(hintText: 'Or enter barcode manually', hintStyle: TextStyle(color: t.textMuted)),
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
            if (lastMsg != null) ...[
              const SizedBox(height: 12),
              Semantics(
                identifier: 'barcode-result',
                label: lastMsg,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blocked ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: blocked ? Colors.redAccent.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Text(lastMsg!, style: TextStyle(fontSize: 13, color: t.textPrimary)),
                ),
              ),
            ],
          ],
        ),
    );
  }
}
