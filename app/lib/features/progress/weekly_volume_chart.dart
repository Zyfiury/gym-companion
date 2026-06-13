import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class WeeklyVolumeChart extends StatelessWidget {
  const WeeklyVolumeChart({super.key});

  Map<String, double> _volumeData(AppState state) {
    if (state.weeklyVolume.isNotEmpty) return state.weeklyVolume;
    final fromProgressions = <String, double>{};
    for (final p in state.recentProgressions.take(5)) {
      final key = _muscleGroup(p.exerciseName);
      fromProgressions[key] = (fromProgressions[key] ?? 0) + p.suggestedWeightKg * 10;
    }
    return fromProgressions;
  }

  String _muscleGroup(String name) {
    final n = name.toLowerCase();
    if (n.contains('squat') || n.contains('leg') || n.contains('rdl') || n.contains('deadlift')) return 'Legs';
    if (n.contains('row') || n.contains('pull') || n.contains('curl')) return 'Pull';
    if (n.contains('press') || n.contains('push') || n.contains('ohp')) return 'Push';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final data = _volumeData(state);

    if (data.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Weekly volume'),
            const SizedBox(height: 12),
            Text(
              'Complete a workout to start tracking volume by muscle group.',
              style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.5),
            ),
          ],
        ),
      );
    }

    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Weekly volume'),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(entries[i].key, style: TextStyle(fontSize: 10, color: t.textMuted)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value,
                          color: c.primary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
