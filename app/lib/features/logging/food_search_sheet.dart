import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/nutrition_source_badge.dart';
import '../../core/widgets/skeletons.dart';
import '../../screens/barcode_scanner_page.dart';
import '../../services/food_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import '../../widgets/barcode_confirm_sheet.dart';
import '../../widgets/page_transitions.dart';

Future<void> showFoodSearchSheet(BuildContext context) {
  return AppRouter.pushModal(
    context,
    Scaffold(
      backgroundColor: context.appColors.bgBase,
      appBar: AppBar(
        backgroundColor: context.appColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appColors.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Search food', style: TextStyle(color: context.appColors.textPrimary)),
      ),
      body: const _FoodSearchSheet(),
    ),
  );
}

class _FoodSearchSheet extends StatefulWidget {
  const _FoodSearchSheet();

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final _queryCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _loading = true);
    final hits = await FoodApiService.searchFood(q);
    if (!mounted || q != _queryCtrl.text.trim()) return;
    setState(() {
      _results = hits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Padding(
      padding: sheetInsets(context, horizontal: 20, top: 12, extra: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryCtrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'e.g. chicken breast',
              hintStyle: TextStyle(color: t.textMuted),
              suffixIcon: IconButton(
                icon: _loading ? const SkeletonBox(width: 18, height: 18, radius: 9) : const Icon(Icons.search),
                onPressed: _loading ? null : _search,
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 24),
            const SkeletonText(width: double.infinity, height: 14),
            const SizedBox(height: 10),
            const SkeletonText(width: 200, height: 14),
            const SizedBox(height: 10),
            const SkeletonText(width: 160, height: 14),
          ] else if (_queryCtrl.text.trim().length >= 2 && _results.isEmpty) ...[
            const AppEmptyState(
              icon: Icons.search_off_outlined,
              heading: 'Nothing found',
              body: 'Try a different search term or scan the barcode',
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: context.appColors.primary),
                onPressed: () {
                  Navigator.pop(context);
                  pushPremium(context, const BarcodeScannerPage());
                },
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan barcode instead'),
              ),
            ),
          ]
          else if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: t.borderSubtle),
                itemBuilder: (ctx, i) {
                  final item = _results[i];
                  final name = item['name'] as String? ?? 'Unknown';
                  final brand = item['brand'] as String? ?? '';
                  final cal = (item['calories'] as num?)?.round() ?? 0;
                  final verified = item['verified'] == true;
                  final imageUrl = item['imageUrl'] as String?;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, width: 44, height: 44, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: context.appColors.primary)),
                          )
                        : Icon(Icons.fastfood_outlined, color: context.appColors.primary),
                    title: Row(
                      children: [
                        Expanded(child: Text(name, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w500))),
                        NutritionSourceBadge(verified: verified, compact: true),
                      ],
                    ),
                    subtitle: brand.isNotEmpty ? Text(brand, style: TextStyle(color: t.textSecondary, fontSize: 12)) : null,
                    trailing: Text('$cal kcal/100g', style: TextStyle(color: t.textMuted, fontSize: 12)),
                    onTap: () async {
                      Navigator.pop(context);
                      await BarcodeConfirmSheet.show(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
