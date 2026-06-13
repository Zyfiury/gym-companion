import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pending_celebrations.dart';
import '../providers/app_state.dart';
import '../core/navigation/app_router.dart';
import '../core/theme/app_colors_extension.dart';
import '../theme/app_theme.dart';
import '../utils/personal_record_helper.dart';
import '../widgets/feed_compose_sheet.dart';

class PrCelebrationModal extends StatefulWidget {
  final PendingPrCelebration celebration;

  const PrCelebrationModal({super.key, required this.celebration});

  static Future<void> show(BuildContext context, PendingPrCelebration celebration) {
    return AppRouter.pushModal(
      context,
      PrCelebrationModal(celebration: celebration),
    );
  }

  @override
  State<PrCelebrationModal> createState() => _PrCelebrationModalState();
}

class _PrCelebrationModalState extends State<PrCelebrationModal> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = widget.celebration;
    final valueText = PersonalRecordHelper.formatValue(c.value, c.unit);

    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_ctrl.value, colors)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: colors.sand, size: 48),
                  const SizedBox(height: 12),
                  Text('New PR!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.textPrimary)),
                  const SizedBox(height: 8),
                  Text('${c.exercise} - $valueText', style: TextStyle(fontSize: 16, color: t.textSecondary)),
                  if (c.previousBest != null)
                    Text('Previous best: ${c.previousBest!.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 12, color: t.textMuted)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: colors.primary),
                    onPressed: () async {
                      Navigator.pop(context);
                      context.read<AppState>().clearPendingPrCelebration();
                      await showFeedComposeSheet(
                        context,
                        initialPostType: 'pr',
                        initialActivityId: c.recordId,
                        initialContent: 'New PR 🏋️ ${c.exercise} - $valueText',
                      );
                    },
                    child: const Text('Share to Feed'),
                  ),
                ),
                  TextButton(
                    onPressed: () {
                      context.read<AppState>().clearPendingPrCelebration();
                      Navigator.pop(context);
                    },
                    child: const Text('Nice!'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final AppColorsExtension palette;
  _ConfettiPainter(this.t, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final confetti = [palette.mint, palette.sand, palette.primary, palette.dusk];
    for (var i = 0; i < 24; i++) {
      final paint = Paint()
        ..color = confetti[i % 4].withValues(alpha: 0.7);
      final x = (rnd.nextDouble() * size.width);
      final y = ((t + i * 0.07) % 1.0) * size.height;
      canvas.drawCircle(Offset(x, y), 3 + rnd.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
