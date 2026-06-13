import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_toast.dart';
import '../../core/widgets/nutrition_source_badge.dart';
import '../../providers/app_state.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/app_theme.dart';
import '../../utils/meal_type_helper.dart';
import '../../utils/sheet_padding.dart';
import 'food_entry_edit_sheet.dart';

/// Compact, collapsible list of everything logged today with swipe-to-delete.
class TodayFoodLogCard extends StatefulWidget {
  const TodayFoodLogCard({super.key});

  @override
  State<TodayFoodLogCard> createState() => _TodayFoodLogCardState();
}

class _TodayFoodLogCardState extends State<TodayFoodLogCard> {
  bool _open = false;

  IconData _sourceIcon(String? source) {
    return switch (source) {
      'barcode' => Icons.qr_code_scanner,
      'photo' => Icons.photo_camera_outlined,
      'voice' => Icons.mic_none,
      'delivery' => Icons.delivery_dining_outlined,
      'eat_out' => Icons.storefront_outlined,
      'meal_plan' => Icons.restaurant_menu,
      'history' => Icons.history,
      _ => Icons.restaurant,
    };
  }

  Future<void> _delete(Map<String, dynamic> entry) async {
    final state = context.read<AppState>();
    final name = entry['food'] as String? ?? 'Food';
    final ok = await state.deleteFoodEntry(entry);
    if (ok && mounted) {
      AppToast.success(context, '$name removed');
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByMeal(List<Map<String, dynamic>> entries) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      final slot = e['meal_type'] as String? ?? 'Other';
      grouped.putIfAbsent(slot, () => []).add(e);
    }
    final order = [...MealTypeHelper.slots, 'Other'];
    return Map.fromEntries(order.where(grouped.containsKey).map((k) => MapEntry(k, grouped[k]!)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final entries = state.user?.foodLog ?? [];
    if (entries.isEmpty) return const SizedBox.shrink();

    final totalKcal = entries.fold<int>(0, (sum, e) => sum + ((e['calories'] as num?)?.toInt() ?? 0));
    final grouped = _groupByMeal(entries);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Semantics(
            identifier: 'today-log-toggle',
            button: true,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 20, color: c.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's log",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            '${entries.length} ${entries.length == 1 ? 'item' : 'items'} · $totalKcal kcal · tap to edit',
                            style: TextStyle(fontSize: 11.5, color: t.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down, color: t.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: t.borderSubtle),
            ...grouped.entries.expand((group) {
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(group.key.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: t.textMuted)),
                ),
                ...group.value.reversed.map((e) {
                  final cal = (e['calories'] as num?)?.round() ?? 0;
                  final p = (e['protein'] as num?)?.round() ?? 0;
                  final verified = e['verified'] == true;
                  return Dismissible(
                    key: ValueKey('${e['id'] ?? e['food']}-${e.hashCode}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: c.error.withValues(alpha: 0.85),
                      child: Icon(Icons.delete_outline, color: c.onPrimary, size: 20),
                    ),
                    onDismissed: (_) => _delete(e),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onTap: () => showFoodEntryEditSheet(context, e),
                      leading: Icon(_sourceIcon(e['source'] as String?), size: 18, color: t.textMuted),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e['food'] as String? ?? 'Food',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: t.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          NutritionSourceBadge(verified: verified, compact: true),
                        ],
                      ),
                      trailing: Text(
                        '$cal kcal · P ${p}g',
                        style: TextStyle(fontSize: 11.5, color: t.textSecondary),
                      ),
                    ),
                  );
                }),
              ];
            }),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
