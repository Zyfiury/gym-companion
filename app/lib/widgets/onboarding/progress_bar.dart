import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const OnboardingProgressBar({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${step + 1} of $total',
          style: ObsidianTypography.label(size: 12),
        ),
        SizedBox(height: ObsidianTokens.spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(ObsidianTokens.radiusPill),
          child: SizedBox(
            height: ObsidianTokens.progressHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: ObsidianTokens.track),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: _ShimmerFill(progress: progress),
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

  const _ShimmerFill({required this.progress});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: ObsidianTokens.heroAccent),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ObsidianTokens.heroAccent.withValues(alpha: 0.0),
                ObsidianTokens.textOnAccent.withValues(alpha: 0.35),
                ObsidianTokens.heroAccent.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: const Duration(milliseconds: 2200), color: ObsidianTokens.textOnAccent.withValues(alpha: 0.25)),
      ),
    );
  }
}
