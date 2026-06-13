import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/obsidian_palette.dart';
import '../../theme/app_theme.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const OnboardingProgressBar({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final o = context.obsidian;
    final progress = (step + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${step + 1} of $total',
          style: ObsidianTypography.label(size: 12, color: o.textMuted),
        ),
        SizedBox(height: ObsidianTokens.spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(ObsidianTokens.radiusPill),
          child: SizedBox(
            height: ObsidianTokens.progressHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: o.track),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: _ShimmerFill(progress: progress, palette: o),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerFill extends StatelessWidget {
  final double progress;
  final ObsidianPalette palette;

  const _ShimmerFill({required this.progress, required this.palette});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.heroAccent),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.heroAccent.withValues(alpha: 0.0),
                palette.textOnAccent.withValues(alpha: 0.35),
                palette.heroAccent.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: const Duration(milliseconds: 2200),
              color: palette.textOnAccent.withValues(alpha: 0.25),
            ),
      ),
    );
  }
}
