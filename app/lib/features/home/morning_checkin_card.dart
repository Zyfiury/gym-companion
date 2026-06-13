import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/recovery_adjustment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class MorningCheckinCard extends StatelessWidget {
  const MorningCheckinCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!RecoveryAdjustmentService.isMorningCheckinWindow()) return const SizedBox.shrink();
    if (state.morningCheckinDoneToday) return const SizedBox.shrink();

    final t = context.appTheme;
    final c = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _EnergyChip(label: '😴 Drained', level: 1, color: c.textMuted),
              const SizedBox(width: 8),
              _EnergyChip(label: '😐 Okay', level: 2, color: c.textSecondary),
              const SizedBox(width: 8),
              _EnergyChip(label: '💪 Good', level: 3, color: c.primary),
              const SizedBox(width: 8),
              _EnergyChip(label: '🔥 Great', level: 4, color: c.olive),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  final String label;
  final int level;
  final Color color;

  const _EnergyChip({required this.label, required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        identifier: 'energy-level-$level',
        button: true,
        child: OutlinedButton(
          onPressed: () => context.read<AppState>().setTodayEnergyLevel(level),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(label, style: TextStyle(fontSize: 10, color: color), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

