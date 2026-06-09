import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Obsidian background: near-black base, accent orb, film grain.
class ObsidianShell extends StatelessWidget {
  final Widget child;

  const ObsidianShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: ObsidianTokens.base),
        Positioned(
          top: -ObsidianTokens.spacingXl * 2,
          right: -ObsidianTokens.spacingLg,
          child: Container(
            width: ObsidianTokens.spacingXl * 5,
            height: ObsidianTokens.spacingXl * 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ObsidianTokens.heroAccent.withValues(alpha: 0.12),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        const CustomPaint(painter: _FilmGrainPainter()),
        child,
      ],
    );
  }
}

class ObsidianGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ObsidianGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ObsidianTokens.spacingMd),
    this.radius = ObsidianTokens.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ObsidianTokens.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: ObsidianTokens.glassBorderDecoration(),
            boxShadow: ObsidianTokens.glassShadow(),
            gradient: ObsidianTokens.glassTopHighlight(),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class ObsidianStepHeader extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle;
  final int index;
  final String? semanticsId;

  const ObsidianStepHeader({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.index,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.toUpperCase(), style: ObsidianTypography.category()),
        SizedBox(height: ObsidianTokens.spacingSm),
        Text(title, style: ObsidianTypography.display(size: 26, weight: FontWeight.w800)),
        SizedBox(height: ObsidianTokens.spacingXs),
        Text(subtitle, style: ObsidianTypography.body(size: 14)),
      ],
    );
    return Stack(
      children: [
        header,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: ObsidianTokens.spacingXl,
            height: ObsidianTokens.spacingXl,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ObsidianTokens.heroAccent.withValues(alpha: 0.06),
              border: Border.all(color: ObsidianTokens.glassBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  const _FilmGrainPainter();

  static final _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: ObsidianTokens.grainOpacity);
    for (var i = 0; i < 2800; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
