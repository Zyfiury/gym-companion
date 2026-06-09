import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/allergy_guard.dart';
import '../services/food_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_confirm_sheet.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final _controller = MobileScannerController();
  bool _processing = false;

  Future<void> _showNotFound(String code) async {
    final t = context.appTheme;
    final nameCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product not found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 8),
            Text('Barcode $code is not in our database.', style: TextStyle(fontSize: 13, color: t.textSecondary)),
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
                  if (mounted) Navigator.pop(context, true);
                },
                child: const Text('Log manually'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _controller.start();
              },
              child: const Text('Scan again'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    setState(() => _processing = true);
    _controller.stop();
    final product = await FoodApiService.lookupBarcode(code);
    if (!mounted) return;
    if (product == null) {
      setState(() => _processing = false);
      await _showNotFound(code);
      return;
    }
    final user = context.read<AppState>().user!;
    final guard = AllergyGuard.checkProduct(
      name: product['name'] as String,
      allergenTags: List<String>.from(product['allergens'] as List? ?? []),
      prefs: UserAllergies.fromUser(user),
    );
    if (!guard.isSafe) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blocked: ${guard.message}')));
      _controller.start();
      return;
    }
    setState(() => _processing = false);
    await BarcodeConfirmSheet.show(context, product);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan Food'), backgroundColor: Colors.black),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_processing) const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text('Point camera at barcode', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
