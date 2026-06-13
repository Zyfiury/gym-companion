import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_router.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_toast.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

/// Food history: everything you ate, day by day (today, yesterday, last 30 days).
Future<void> showFoodHistorySheet(BuildContext context) {
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
        title: Text('Food history', style: TextStyle(color: context.appColors.textPrimary)),
      ),
      body: const _FoodHistoryView(),
    ),
  );
}

class _DayLog {
  final String date;
  final List<Map<String, dynamic>> entries;
  final int calories, protein, carbs, fat;

  _DayLog({
    required this.date,
    required this.entries,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class _FoodHistoryView extends StatelessWidget {
  const _FoodHistoryView();

  List<_DayLog> _buildDays(AppState state) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final days = <_DayLog>[];

    final u = state.user;
    if (u != null && u.foodLog.isNotEmpty) {
      days.add(_DayLog(
        date: today,
        entries: u.foodLog.reversed.toList(),
        calories: u.dailyMacrosLogged.calories,
        protein: u.dailyMacrosLogged.protein,
        carbs: u.dailyMacrosLogged.carbs,
        fat: u.dailyMacrosLogged.fat,
      ));
    }

    final history = List<Map<String, dynamic>>.from(state.dailyLogsHistory)
      ..sort((a, b) => (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''));
    for (final log in history) {
      final date = log['date'] as String? ?? '';
      if (date.isEmpty || date == today) continue;
      final foods = (log['food_log'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      if (foods.isEmpty) continue;
      days.add(_DayLog(
        date: date,
        entries: foods.reversed.toList(),
        calories: (log['calories_logged'] as num?)?.toInt() ?? 0,
        protein: (log['protein_logged'] as num?)?.toInt() ?? 0,
        carbs: (log['carbs_logged'] as num?)?.toInt() ?? 0,
        fat: (log['fat_logged'] as num?)?.toInt() ?? 0,
      ));
    }
    return days;
  }

  static String _dayLabel(String date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  Future<void> _logAgain(BuildContext context, Map<String, dynamic> entry) async {
    final name = entry['food'] as String? ?? 'Food';
    final state = context.read<AppState>();
    final chip = await state.logFood(
          name: name,
          calories: (entry['calories'] as num?)?.toInt() ?? 0,
          protein: (entry['protein'] as num?)?.toInt() ?? 0,
          carbs: (entry['carbs'] as num?)?.toInt() ?? 0,
          fat: (entry['fat'] as num?)?.toInt() ?? 0,
          fiber: (entry['fiber'] as num?)?.toInt(),
          sugar: (entry['sugar'] as num?)?.toInt(),
          sodiumMg: (entry['sodium_mg'] as num?)?.toInt(),
          source: 'history',
        );
    if (chip != null && context.mounted) {
      AppToast.success(context, chip, actionLabel: 'Undo', onAction: () => state.undoLastFoodLog());
    }
  }

  Future<void> _deleteToday(BuildContext context, Map<String, dynamic> entry) async {
    final state = context.read<AppState>();
    final name = entry['food'] as String? ?? 'Food';
    final ok = await state.deleteFoodEntry(entry);
    if (ok && context.mounted) {
      AppToast.success(context, '$name removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final days = _buildDays(state);

    if (days.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.history,
          heading: 'No food logged yet',
          body: 'Anything you log shows up here, day by day',
        ),
      );
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final isToday = day.date == today;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        _dayLabel(day.date),
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        '${day.calories} kcal · P ${day.protein}g · C ${day.carbs}g · F ${day.fat}g',
                        style: TextStyle(fontSize: 11.5, color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: t.borderSubtle),
                ...day.entries.map((e) {
                  final cal = (e['calories'] as num?)?.round() ?? 0;
                  final p = (e['protein'] as num?)?.round() ?? 0;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.only(left: 16, right: 8),
                    title: Text(
                      e['food'] as String? ?? 'Food',
                      style: TextStyle(fontSize: 13.5, color: t.textPrimary, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$cal kcal · P ${p}g${e['source'] != null ? ' · ${(e['source'] as String).replaceAll('_', ' ')}' : ''}',
                      style: TextStyle(fontSize: 11, color: t.textMuted),
                    ),
                    trailing: isToday
                        ? IconButton(
                            tooltip: 'Remove from today',
                            icon: Icon(Icons.delete_outline, size: 18, color: t.textMuted),
                            onPressed: () => _deleteToday(context, e),
                          )
                        : IconButton(
                            tooltip: 'Log again today',
                            icon: Icon(Icons.replay, size: 18, color: c.primary),
                            onPressed: () => _logAgain(context, e),
                          ),
                  );
                }),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}
