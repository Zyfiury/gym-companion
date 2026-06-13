import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_toast.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class _FrequentFood {
  final String name;
  final int count;
  final Map<String, dynamic> entry;

  _FrequentFood(this.name, this.count, this.entry);
}

/// One-tap chips for the foods you log most often (last 30 days).
class FrequentFoodsRow extends StatelessWidget {
  const FrequentFoodsRow({super.key});

  static List<_FrequentFood> _compute(AppState state) {
    final counts = <String, int>{};
    final samples = <String, Map<String, dynamic>>{};

    void tally(Iterable<Map<String, dynamic>> entries) {
      for (final e in entries) {
        final name = e['food'] as String?;
        if (name == null || name.isEmpty) continue;
        counts[name] = (counts[name] ?? 0) + 1;
        samples[name] = e;
      }
    }

    for (final log in state.dailyLogsHistory) {
      final foods = (log['food_log'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map));
      if (foods != null) tally(foods);
    }
    tally(state.user?.foodLog ?? []);

    final frequent = counts.entries
        .where((e) => e.value >= 2)
        .map((e) => _FrequentFood(e.key, e.value, samples[e.key]!))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return frequent.take(6).toList();
  }

  Future<void> _quickLog(BuildContext context, _FrequentFood food) async {
    final state = context.read<AppState>();
    final e = food.entry;
    final chip = await state.logFood(
      name: food.name,
      calories: (e['calories'] as num?)?.toInt() ?? 0,
      protein: (e['protein'] as num?)?.toInt() ?? 0,
      carbs: (e['carbs'] as num?)?.toInt() ?? 0,
      fat: (e['fat'] as num?)?.toInt() ?? 0,
      fiber: (e['fiber'] as num?)?.toInt(),
      sugar: (e['sugar'] as num?)?.toInt(),
      sodiumMg: (e['sodium_mg'] as num?)?.toInt(),
      source: 'quick_log',
    );
    if (chip != null && context.mounted) {
      AppToast.success(context, chip, actionLabel: 'Undo', onAction: () => state.undoLastFoodLog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final frequent = _compute(state);
    if (frequent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK LOG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: t.textMuted)),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: frequent.length,
            separatorBuilder: (_, i) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final f = frequent[i];
              final cal = (f.entry['calories'] as num?)?.round() ?? 0;
              return Material(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  onTap: () => _quickLog(context, f),
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: c.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: c.primary),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            '${f.name} · $cal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}
