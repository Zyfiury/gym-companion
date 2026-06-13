import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_toast.dart';
import '../../core/widgets/nutrition_source_badge.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/meal_type_helper.dart';
import '../../utils/sheet_padding.dart';

Future<void> showFoodEntryEditSheet(BuildContext context, Map<String, dynamic> entry) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _FoodEntryEditSheet(entry: entry),
  );
}

class _FoodEntryEditSheet extends StatefulWidget {
  final Map<String, dynamic> entry;
  const _FoodEntryEditSheet({required this.entry});

  @override
  State<_FoodEntryEditSheet> createState() => _FoodEntryEditSheetState();
}

class _FoodEntryEditSheetState extends State<_FoodEntryEditSheet> {
  late double _grams;
  late String _mealType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _grams = (widget.entry['serving_g'] as num?)?.toDouble() ?? 100;
    _mealType = widget.entry['meal_type'] as String? ?? MealTypeHelper.infer();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final verified = widget.entry['verified'] == true;
    final origG = (widget.entry['serving_g'] as num?)?.toDouble() ?? 100;
    final factor = _grams / origG;
    final macros = {
      'calories': ((widget.entry['calories'] as num?) ?? 0) * factor,
      'protein': ((widget.entry['protein'] as num?) ?? 0) * factor,
      'carbs': ((widget.entry['carbs'] as num?) ?? 0) * factor,
      'fat': ((widget.entry['fat'] as num?) ?? 0) * factor,
      'fiber': ((widget.entry['fiber'] as num?) ?? 0) * factor,
      'sugar': ((widget.entry['sugar'] as num?) ?? 0) * factor,
      'sodiumMg': ((widget.entry['sodium_mg'] as num?) ?? 0) * factor,
    };

    return Padding(
      padding: sheetInsets(context, horizontal: 20, top: 20, extra: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.entry['food'] as String? ?? 'Food',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: t.textPrimary),
                ),
              ),
              NutritionSourceBadge(verified: verified, compact: true),
            ],
          ),
          const SizedBox(height: 16),
          Text('Meal', style: TextStyle(fontSize: 12, color: t.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MealTypeHelper.slots.map((slot) {
              return ChoiceChip(
                label: Text(slot),
                selected: _mealType == slot,
                onSelected: (_) => setState(() => _mealType = slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Serving (${_grams.round()}g)', style: TextStyle(fontSize: 12, color: t.textSecondary)),
          Slider(
            value: _grams.clamp(10, 500),
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: c.primary,
            onChanged: (v) => setState(() => _grams = v),
          ),
          Row(
            children: [
              _chip(context, '${macros['calories']!.round()} kcal', c.sand),
              const SizedBox(width: 6),
              _chip(context, 'P ${macros['protein']!.round()}g', c.macroProtein),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final ok = await context.read<AppState>().updateFoodEntry(
                            widget.entry,
                            calories: macros['calories']!.round(),
                            protein: macros['protein']!.round(),
                            carbs: macros['carbs']!.round(),
                            fat: macros['fat']!.round(),
                            fiber: macros['fiber']!.round(),
                            sugar: macros['sugar']!.round(),
                            sodiumMg: macros['sodiumMg']!.round(),
                            servingG: _grams,
                            mealType: _mealType,
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (ok) AppToast.success(context, 'Entry updated');
                    },
              child: Text(_saving ? 'Saving…' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
