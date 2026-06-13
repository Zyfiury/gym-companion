import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/coach_personality_service.dart';
import '../../services/recovery_adjustment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class CoachMorningCheckin extends StatefulWidget {
  final ValueChanged<String>? onSorenessMessage;

  const CoachMorningCheckin({super.key, this.onSorenessMessage});

  @override
  State<CoachMorningCheckin> createState() => _CoachMorningCheckinState();
}

class _CoachMorningCheckinState extends State<CoachMorningCheckin> {
  double? _sleepHours;

  double _sleepValue(AppState state) {
    if (_sleepHours != null) return _sleepHours!;
    if (state.lastNightSleepHours > 0) return state.lastNightSleepHours;
    return 7;
  }

  Future<void> _save(AppState state, int energy, {String? sorenessMessage}) async {
    await state.setMorningCheckin(energyLevel: energy, sleepHours: _sleepValue(state));
    if (sorenessMessage != null && mounted) {
      widget.onSorenessMessage?.call(sorenessMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!RecoveryAdjustmentService.isMorningCheckinWindow()) return const SizedBox.shrink();
    if (state.morningCheckinDoneToday) return const SizedBox.shrink();

    final t = context.appTheme;
    final c = context.appColors;
    final name = CoachPersonalityService.coachName;
    final sleep = _sleepValue(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick check-in with $name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Helps me tailor today\'s workout and meals.',
              style: TextStyle(fontSize: 12, color: t.textSecondary),
            ),
            const SizedBox(height: 12),
            Text('Energy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                _EnergyChip(label: '😴', level: 1, color: c.textMuted, onPick: (l) => _save(state, l)),
                const SizedBox(width: 6),
                _EnergyChip(label: '😐', level: 2, color: c.textSecondary, onPick: (l) => _save(state, l)),
                const SizedBox(width: 6),
                _EnergyChip(label: '💪', level: 3, color: c.primary, onPick: (l) => _save(state, l)),
                const SizedBox(width: 6),
                _EnergyChip(label: '🔥', level: 4, color: c.olive, onPick: (l) => _save(state, l)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Sleep last night: ${sleep.round()}h', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted)),
            Slider(
              value: sleep,
              min: 4,
              max: 10,
              divisions: 12,
              onChanged: (v) => setState(() => _sleepHours = v),
            ),
            Text('Anything sore?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SorenessChip(
                  label: 'Knees',
                  onTap: () => _save(state, state.todayEnergyLevel > 0 ? state.todayEnergyLevel : 3, sorenessMessage: 'My knees are sore today - can we adjust my workout?'),
                ),
                _SorenessChip(
                  label: 'Back',
                  onTap: () => _save(state, state.todayEnergyLevel > 0 ? state.todayEnergyLevel : 3, sorenessMessage: 'My back feels tight today.'),
                ),
                _SorenessChip(
                  label: 'Shoulders',
                  onTap: () => _save(state, state.todayEnergyLevel > 0 ? state.todayEnergyLevel : 3, sorenessMessage: 'My shoulders are sore - lighter upper body please.'),
                ),
                _SorenessChip(
                  label: 'All good',
                  onTap: () => _save(state, 4, sorenessMessage: 'Feeling good today - full send!'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  final String label;
  final int level;
  final Color color;
  final ValueChanged<int> onPick;

  const _EnergyChip({required this.label, required this.level, required this.color, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        identifier: 'coach-energy-$level',
        button: true,
        child: OutlinedButton(
          onPressed: () => onPick(level),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(label, style: TextStyle(fontSize: 16, color: color)),
        ),
      ),
    );
  }
}

class _SorenessChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SorenessChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: t.textPrimary)),
      backgroundColor: t.elevated,
      side: BorderSide(color: t.borderSubtle),
      onPressed: onTap,
    );
  }
}
