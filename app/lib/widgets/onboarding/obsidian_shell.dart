import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/obsidian_palette.dart';
import '../../theme/app_theme.dart';

/// Obsidian background: themed base, accent orb, film grain.
class ObsidianShell extends StatelessWidget {
  final Widget child;

  const ObsidianShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final o = context.obsidian;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: o.base),
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
                  color: o.heroAccent.withValues(alpha: 0.14),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        CustomPaint(painter: _FilmGrainPainter(color: o.textPrimary)),
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
    final o = context.obsidian;
  final isDark = context.isDarkTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isDark ? 12 : 16, sigmaY: isDark ? 12 : 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: o.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: o.glassBorder, width: 1),
            boxShadow: o.glassShadow(),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: o.glassTopHighlight(),
            ),
            child: Padding(padding: padding, child: child),
          ),
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
    final o = context.obsidian;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.toUpperCase(), style: ObsidianTypography.category(color: o.textMuted)),
        SizedBox(height: ObsidianTokens.spacingSm),
        Text(title, style: ObsidianTypography.display(size: 26, weight: FontWeight.w800, color: o.textPrimary)),
        SizedBox(height: ObsidianTokens.spacingXs),
        Text(subtitle, style: ObsidianTypography.body(size: 14, color: o.textSecondary)),
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
              color: o.heroAccent.withValues(alpha: 0.06),
              border: Border.all(color: o.glassBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  final Color color;
  const _FilmGrainPainter({required this.color});

  static final _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: ObsidianTokens.grainOpacity);
    for (var i = 0; i < 2800; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) => oldDelegate.color != color;
}
