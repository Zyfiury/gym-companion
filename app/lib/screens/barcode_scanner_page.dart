import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/food_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/barcode_confirm_sheet.dart';
import '../widgets/inline_loading.dart';

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
        padding: sheetInsets(ctx, horizontal: 20, top: 20, extra: 20),
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
    setState(() => _processing = false);
    await BarcodeConfirmSheet.show(context, product);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final cameraBg = c.bgDeep;
    return Scaffold(
      backgroundColor: cameraBg,
      appBar: AppBar(
        title: const Text('Scan food'),
        backgroundColor: cameraBg,
        foregroundColor: c.onPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_processing) const Center(child: InlineLoading(width: 36, height: 36)),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point camera at barcode',
                style: TextStyle(color: c.onPrimary, fontSize: 16, fontWeight: FontWeight.w500),
              ),
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
