import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MealMonthChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyLogs;
  final void Function(String date)? onDayTap;

  const MealMonthChart({super.key, required this.dailyLogs, this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    if (dailyLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Log meals to see your monthly trend', style: TextStyle(color: t.textSecondary), textAlign: TextAlign.center),
      );
    }

    final sorted = List<Map<String, dynamic>>.from(dailyLogs)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    final bars = List.generate(sorted.length, (i) {
      final cal = (sorted[i]['calories_logged'] as num?)?.toInt() ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: cal.toDouble(), color: context.appColors.sand, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
      );
    });

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: bars.map((b) => b.barRods.first.toY).fold<double>(0, (a, b) => a > b ? a : b) + 200,
          barGroups: bars,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: t.borderSubtle)),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: t.textMuted)))),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              if (event.isInterestedForInteractions && response?.spot != null && onDayTap != null) {
                final i = response!.spot!.touchedBarGroupIndex;
                if (i >= 0 && i < sorted.length) onDayTap!(sorted[i]['date'] as String);
              }
            },
          ),
        ),
      ),
    );
  }
}
