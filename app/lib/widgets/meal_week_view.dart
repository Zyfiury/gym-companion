import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

class MealWeekView extends StatelessWidget {
  final List<Meal> meals;
  const MealWeekView({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final days = <String, List<Meal>>{};
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var i = 0; i < meals.length && i < 21; i++) {
      final day = dayNames[i ~/ 3];
      days.putIfAbsent(day, () => []).add(meals[i]);
    }

    return Column(
      children: days.entries.map((entry) {
        final kcal = entry.value.fold<int>(0, (s, m) => s + (m.macros['calories'] ?? 0));
        final protein = entry.value.fold<int>(0, (s, m) => s + (m.macros['protein'] ?? 0));
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
          subtitle: Text('$kcal kcal · ${protein}g protein', style: TextStyle(fontSize: 12, color: t.textSecondary)),
          children: entry.value
              .map((m) => ListTile(
                    dense: true,
                    title: Text('${m.mealType}: ${m.name}', style: TextStyle(color: t.textPrimary)),
                    trailing: Text('${m.macros['calories']} kcal', style: TextStyle(color: context.appColors.primary, fontSize: 12)),
                  ))
              .toList(),
        );
      }).toList(),
    );
  }
}
