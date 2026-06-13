import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/recovery_adjustment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

/// Shown on Workout tab after morning energy check-in - offers lighter/heavier session.
class WorkoutRecoveryCard extends StatelessWidget {
  const WorkoutRecoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.todayEnergyLevel <= 0 || state.workoutAdjustment != 'none') {
      return const SizedBox.shrink();
    }

    final lighter = RecoveryAdjustmentService.shouldOfferLighter(
      energyLevel: state.todayEnergyLevel,
      sleepHours: state.lastNightSleepHours,
    );
    final heavier = RecoveryAdjustmentService.shouldOfferHeavier(energyLevel: state.todayEnergyLevel);
    if (!lighter && !heavier) return const SizedBox.shrink();

    final t = context.appTheme;
    final c = context.appColors;
    final message = lighter
        ? "You're feeling low today. Want a lighter session?"
        : "You're feeling strong today - want to push harder?";

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.applyRecoveryAdjustment(keepOriginal: true),
                  child: const Text('Keep original plan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => state.applyRecoveryAdjustment(
                    keepOriginal: false,
                    lighter: lighter,
                  ),
                  child: Text(lighter ? 'Switch to recovery' : 'Increase intensity'),
                ),
              ),
            ],
          ),
          if (state.workoutAdjustment != 'none')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Plan adjusted for today', style: TextStyle(color: c.primary, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
