import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'empty_state_card.dart';

class WeightLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final VoidCallback? onLogWeight;

  const WeightLineChart({super.key, required this.history, this.onLogWeight});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    if (history.isEmpty) {
      return EmptyStateCard(
        icon: Icons.monitor_weight_outlined,
        headline: 'No weight logged yet',
        subtext: 'Track your progress by logging your weight regularly.',
        buttonLabel: "Log today's weight",
        onAction: onLogWeight,
      );
    }

    final sorted = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    final weights = sorted.map((e) => (e['weight'] as num).toDouble()).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final pad = (maxW - minW).abs() < 0.5 ? 2.0 : 1.0;
    final latest = weights.last;
    final first = weights.first;
    final delta = latest - first;

    final spots = weights.length == 1
        ? [FlSpot(0, weights[0]), FlSpot(1, weights[0])]
        : List.generate(weights.length, (i) => FlSpot(i.toDouble(), weights[i]));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${latest.toStringAsFixed(1)} kg',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
            const SizedBox(width: 8),
            if (weights.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (delta <= 0 ? AppColors.emerald : AppColors.orange).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: delta <= 0 ? AppColors.emerald : AppColors.orange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          weights.length == 1
              ? 'First weigh-in — log again on another day to see your trend'
              : '${weights.length} weigh-ins · ${first.toStringAsFixed(1)} → ${latest.toStringAsFixed(1)} kg',
          style: TextStyle(fontSize: 12, color: t.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: weights.length == 1 ? 1 : (weights.length - 1).toDouble(),
              minY: minW - pad,
              maxY: maxW + pad,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: pad >= 2 ? 1 : 0.5,
                getDrawingHorizontalLine: (_) => FlLine(color: t.borderSubtle, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: pad >= 2 ? 1 : 0.5,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
                      style: TextStyle(fontSize: 10, color: t.textMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: weights.length > 1,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      if (weights.length == 1) return const SizedBox.shrink();
                      final i = v.round();
                      if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                      final d = DateTime.tryParse(sorted[i]['date'] as String? ?? '');
                      if (d == null) return const SizedBox.shrink();
                      return Text(DateFormat('dd/MM').format(d), style: TextStyle(fontSize: 9, color: t.textMuted));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: weights.length > 2,
                  color: AppColors.accent,
                  barWidth: 2.5,
                  dotData: FlDotData(show: weights.length > 1),
                  belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
