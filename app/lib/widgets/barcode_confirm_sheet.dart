import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/app_state.dart';
import '../services/allergy_guard.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';

class BarcodeConfirmSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  const BarcodeConfirmSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Map<String, dynamic> product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BarcodeConfirmSheet(product: product),
    );
  }

  @override
  State<BarcodeConfirmSheet> createState() => _BarcodeConfirmSheetState();
}

class _BarcodeConfirmSheetState extends State<BarcodeConfirmSheet> {
  double _grams = 100;
  Timer? _debounce;
  bool _logging = false;
  bool _acknowledgedAllergy = false;
  late GuardResult _guard;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user!;
    final prefs = UserAllergies.fromUser(user);
    final name = widget.product['name'] as String? ?? '';
    final allergens = List<String>.from(widget.product['allergens'] as List? ?? []);
    final ingredients = widget.product['ingredients'] as String? ?? '';
    final productGuard = AllergyGuard.checkProduct(name: name, allergenTags: allergens, prefs: prefs);
    final textGuard = ingredients.isNotEmpty
        ? AllergyGuard.checkText('$name $ingredients', prefs)
        : GuardResult.safe();
    if (productGuard.isSafe) {
      _guard = textGuard;
    } else if (textGuard.isSafe) {
      _guard = productGuard;
    } else {
      final conflicts = {...productGuard.conflicts, ...textGuard.conflicts}.toList();
      _guard = GuardResult.blocked(conflicts);
    }
  }

  Map<String, int> get _macros {
    final f = _grams / 100;
    return {
      'calories': ((widget.product['calories'] as num) * f).round(),
      'protein': ((widget.product['protein'] as num) * f).round(),
      'carbs': ((widget.product['carbs'] as num) * f).round(),
      'fat': ((widget.product['fat'] as num) * f).round(),
    };
  }

  bool get _canLog => _guard.isSafe || _acknowledgedAllergy;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final m = _macros;
    final imageUrl = widget.product['imageUrl'] as String?;

    return Padding(
      padding: sheetInsets(context, horizontal: 20, top: 20, extra: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_guard.isSafe)
            Semantics(
              identifier: 'barcode-allergy-warning',
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'Contains ${_guard.conflicts.join(', ')} — you marked this as an allergy',
                  style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: t.elevated,
                    highlightColor: t.card,
                    child: Container(height: 120, color: t.elevated),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: t.elevated,
                  child: const Icon(Icons.fastfood, size: 48, color: AppColors.accent),
                ),
              ),
            )
          else
            Container(
              height: 80,
              alignment: Alignment.center,
              child: const Icon(Icons.fastfood, size: 48, color: AppColors.accent),
            ),
          const SizedBox(height: 12),
          Text(widget.product['name'] as String? ?? 'Product', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: t.textPrimary)),
          if ((widget.product['brand'] as String?)?.isNotEmpty == true)
            Text(widget.product['brand'] as String, style: TextStyle(color: t.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _pill('${m['calories']} kcal', AppColors.orange),
              const SizedBox(width: 6),
              _pill('P ${m['protein']}g', AppColors.accent),
              const SizedBox(width: 6),
              _pill('C ${m['carbs']}g', AppColors.blue),
              const SizedBox(width: 6),
              _pill('F ${m['fat']}g', Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          Text('Serving size (g)', style: TextStyle(fontSize: 13, color: t.textSecondary)),
          Slider(
            value: _grams,
            min: 10,
            max: 500,
            divisions: 49,
            label: '${_grams.round()}g',
            activeColor: AppColors.accent,
            onChanged: (v) {
              setState(() => _grams = v);
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () => setState(() {}));
            },
          ),
          const SizedBox(height: 8),
          if (!_guard.isSafe && !_acknowledgedAllergy)
            Semantics(
              identifier: 'barcode-log-anyway',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => setState(() => _acknowledgedAllergy = true),
                  child: const Text('Log anyway'),
                ),
              ),
            ),
          Semantics(
            identifier: 'barcode-confirm-log',
            button: true,
            child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: !_canLog || _logging
                  ? null
                  : () async {
                      setState(() => _logging = true);
                      final chip = await context.read<AppState>().logFood(
                            name: widget.product['name'] as String,
                            calories: m['calories']!,
                            protein: m['protein']!,
                            carbs: m['carbs']!,
                            fat: m['fat']!,
                            source: 'barcode',
                            servingG: _grams,
                          );
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (chip != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chip)));
                      }
                    },
              child: _logging
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_guard.isSafe ? 'Log this food' : 'Confirm & log'),
            ),
          ),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
