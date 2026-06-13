import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

/// Last 7 days of calories eaten vs today's target.
class CalorieTrendCard extends StatelessWidget {
  const CalorieTrendCard({super.key});

  List<({String label, int calories, bool isToday})> _days(AppState state) {
    final byDate = <String, int>{};
    for (final log in state.dailyLogsHistory) {
      final date = log['date'] as String?;
      if (date != null) {
        byDate[date] = (log['calories_logged'] as num?)?.toInt() ?? 0;
      }
    }

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);

    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = d.toIso8601String().substring(0, 10);
      final isToday = key == today;
      return (
        label: weekdays[d.weekday - 1],
        calories: isToday
            ? (state.user?.dailyMacrosLogged.calories ?? 0)
            : (byDate[key] ?? 0),
        isToday: isToday,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final days = _days(state);
    final target = state.todayCalorieTarget;

    final loggedDays = days.where((d) => d.calories > 0).length;
    if (loggedDays == 0) return const SizedBox.shrink();

    final avg = days.map((d) => d.calories).reduce((a, b) => a + b) ~/ (loggedDays == 0 ? 1 : loggedDays);
    final maxCal = days.map((d) => d.calories).reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = (maxCal > target ? maxCal : target) * 1.25;

    Color barColor(int calories, bool isToday) {
      if (calories == 0) return t.elevated;
      if (target > 0 && calories > target * 1.1) return c.sand;
      return isToday ? c.primary : c.primary.withValues(alpha: 0.55);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Calories · last 7 days')),
              Text('avg $avg kcal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => t.elevated,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.round()} kcal',
                      TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[i].label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: days[i].isToday ? FontWeight.w700 : FontWeight.w400,
                              color: days[i].isToday ? c.primary : t.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: target > 0
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: target,
                          color: t.textMuted.withValues(alpha: 0.5),
                          strokeWidth: 1,
                          dashArray: [5, 4],
                        ),
                      ])
                    : null,
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].calories.toDouble(),
                          color: barColor(days[i].calories, days[i].isToday),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dashed line = your ${target.round()} kcal target · amber = over by 10%+',
            style: TextStyle(fontSize: 10.5, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
