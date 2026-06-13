import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/fun_facts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

/// Compact summary of the last 7 days - workouts, calories, protein.
class WeeklyRecapCard extends StatefulWidget {
  const WeeklyRecapCard({super.key});

  @override
  State<WeeklyRecapCard> createState() => _WeeklyRecapCardState();
}

class _WeeklyRecapCardState extends State<WeeklyRecapCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final u = state.user!;
    final proteinTarget = u.weeklyPlan.macros['protein'] ?? 140;

    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    var workoutDays = 0;
    var proteinDays = 0;
    var loggedDays = 0;
    var totalCal = 0;

    for (var i = 1; i <= 7; i++) {
      final key = now.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      final log = state.dailyLogsHistory.cast<Map<String, dynamic>?>().firstWhere(
            (l) => l?['date'] == key,
            orElse: () => null,
          );
      if (log == null) continue;
      loggedDays++;
      final cal = (log['calories_logged'] as num?)?.toInt() ?? 0;
      final pro = (log['protein_logged'] as num?)?.toInt() ?? 0;
      totalCal += cal;
      if (pro >= proteinTarget) proteinDays++;
      if (log['workout_status'] == 'completed') workoutDays++;
    }

    if (loggedDays == 0 && u.dailyMacrosLogged.calories == 0) {
      return const SizedBox.shrink();
    }

    final todayProHit = u.dailyMacrosLogged.protein >= proteinTarget;
    final avgCal = loggedDays > 0 ? totalCal ~/ loggedDays : u.dailyMacrosLogged.calories;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.insights_outlined, size: 20, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your week', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary)),
                        Text(
                          '$workoutDays workouts · avg $avgCal kcal · protein $proteinDays/7 days',
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
          if (_open) ...[
            Divider(height: 1, color: t.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  _RecapRow(label: 'Workouts logged', value: '$workoutDays / 7 days', icon: Icons.fitness_center),
                  const SizedBox(height: 10),
                  _RecapRow(label: 'Protein target hit', value: '$proteinDays / 7 days', icon: Icons.egg_outlined),
                  const SizedBox(height: 10),
                  _RecapRow(label: 'Avg calories', value: '$avgCal kcal/day', icon: Icons.local_fire_department_outlined),
                  const SizedBox(height: 10),
                  _RecapRow(
                    label: 'Today',
                    value: todayProHit
                        ? '${u.dailyMacrosLogged.calories} kcal · protein ✓'
                        : '${u.dailyMacrosLogged.calories} kcal · P ${u.dailyMacrosLogged.protein}/${proteinTarget}g',
                    icon: Icons.today_outlined,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('THIS WEEK IN FACTS', style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: t.textMuted)),
                  ),
                  const SizedBox(height: 10),
                  ...FunFactsService.weeklyFacts(user: u, dailyLogsHistory: state.dailyLogsHistory).map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(f.text, style: TextStyle(fontSize: 12.5, height: 1.4, color: t.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RecapRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: c.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: t.textSecondary))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary)),
      ],
    );
  }
}
