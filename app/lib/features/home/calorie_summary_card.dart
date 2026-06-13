import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class CalorieSummaryCard extends StatefulWidget {
  const CalorieSummaryCard({super.key});

  @override
  State<CalorieSummaryCard> createState() => _CalorieSummaryCardState();
}

class _CalorieSummaryCardState extends State<CalorieSummaryCard> {
  static final _fmt = NumberFormat('#,###');
  int _lastNet = 0;
  bool _microsOpen = false;

  // Sensible daily reference values: fiber target 30g (NHS),
  // free-sugar limit ~50g, sodium limit 2300mg.
  static const _fiberTarget = 30;
  static const _sugarLimit = 50;
  static const _sodiumLimitMg = 2300;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final u = state.user!;
    final logged = state.caloriesEaten.round();
    final target = state.todayCalorieTarget.round();
    final burned = state.activeCaloriesBurned.round();
    final net = state.netCalories.round();
    final netBegin = _lastNet;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastNet != net) setState(() => _lastNet = net);
    });
    final pct = target > 0 ? logged / target : 0.0;
    final isTraining = state.isTrainingDay;
    final remaining = target - logged > 0 ? target - logged : 0;
    final proteinTarget = u.weeklyPlan.macros['protein'] ?? 140;
    final carbsTarget = state.isTrainingDay
        ? (u.weeklyPlan.macros['carbs'] ?? 200) + 30
        : ((u.weeklyPlan.macros['carbs'] ?? 200) - 30).clamp(50, 400);

    return AppCard(
      child: Column(
        children: [
          if (state.splitCaloriesEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isTraining ? c.primaryGlow : c.surface2,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: c.border),
              ),
              child: Text(
                isTraining ? 'Training day' : 'Rest day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isTraining ? c.primary : t.textMuted,
                ),
              ),
            ),
          Row(
            children: [
              MacroRing(
                progress: pct,
                value: _fmt.format(logged),
                label: 'kcal eaten',
                sublabel: '/ ${_fmt.format(target)}',
                color: c.macroCarbs,
                size: 110,
                pulseTrigger: state.foodLogPulseTick,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: t.textMuted)),
                    const SizedBox(height: 4),
                    Text('${_fmt.format(burned)} kcal burned', style: TextStyle(fontSize: 13, color: t.textSecondary)),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: netBegin, end: net),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        'Net: ${_fmt.format(v)} kcal',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    MacroBar(label: 'Protein', current: u.dailyMacrosLogged.protein, target: proteinTarget, color: c.macroProtein),
                    const SizedBox(height: 10),
                    MacroBar(label: 'Carbs', current: u.dailyMacrosLogged.carbs, target: carbsTarget, color: c.macroCarbs),
                    const SizedBox(height: 10),
                    MacroBar(label: 'Fat', current: u.dailyMacrosLogged.fat, target: u.weeklyPlan.macros['fat'] ?? 60, color: c.macroFat),
                    const SizedBox(height: 8),
                    Text(
                      remaining > 0 ? '${_fmt.format(remaining)} kcal left to eat' : 'Target reached',
                      style: TextStyle(fontSize: 12, color: remaining > 0 ? t.textSecondary : c.mint, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            identifier: 'micros-toggle',
            button: true,
            child: InkWell(
              onTap: () => setState(() => _microsOpen = !_microsOpen),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _microsOpen
                          ? 'Hide micronutrients'
                          : 'Micros · Fibre ${u.dailyMacrosLogged.fiber}g · Sugar ${u.dailyMacrosLogged.sugar}g',
                      style: TextStyle(fontSize: 11.5, color: t.textMuted, fontWeight: FontWeight.w500),
                    ),
                    Icon(
                      _microsOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: t.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_microsOpen) ...[
            const SizedBox(height: 8),
            MacroBar(label: 'Fibre', current: u.dailyMacrosLogged.fiber, target: _fiberTarget, color: c.mint),
            const SizedBox(height: 10),
            MacroBar(label: 'Sugar', current: u.dailyMacrosLogged.sugar, target: _sugarLimit, color: c.sand),
            const SizedBox(height: 10),
            MacroBar(label: 'Sodium mg', current: u.dailyMacrosLogged.sodiumMg, target: _sodiumLimitMg, color: c.macroFat),
            const SizedBox(height: 4),
            Text(
              'Fibre: aim to reach 30g · Sugar & sodium: stay under the bar',
              style: TextStyle(fontSize: 10.5, color: t.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
