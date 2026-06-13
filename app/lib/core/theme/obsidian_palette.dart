import 'package:flutter/material.dart';

import 'context_extensions.dart';

/// Theme-aware onboarding palette — light Sea Mist or dark Deep Water.
class ObsidianPalette {
  const ObsidianPalette({
    required this.base,
    required this.bgDeep,
    required this.heroAccent,
    required this.heroAccentDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.surfaceDark,
    required this.surfaceMuted,
    required this.track,
    required this.textOnAccent,
  });

  final Color base;
  final Color bgDeep;
  final Color heroAccent;
  final Color heroAccentDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color glassFill;
  final Color glassBorder;
  final Color surfaceDark;
  final Color surfaceMuted;
  final Color track;
  final Color textOnAccent;

  static const light = ObsidianPalette(
    base: Color(0xFFE8EEF0),
    bgDeep: Color(0xFFD8E2E6),
    heroAccent: Color(0xFF5AA7A7),
    heroAccentDark: Color(0xFF3A8888),
    textPrimary: Color(0xFF1A2E30),
    textSecondary: Color(0xFF3A5A60),
    textMuted: Color(0xFF6A8A90),
    glassFill: Color(0xFFF4F8F8),
    glassBorder: Color(0xFFC9D6DC),
    surfaceDark: Color(0xFFF4F8F8),
    surfaceMuted: Color(0xFFDCE8EA),
    track: Color(0xFFDCE8EA),
    textOnAccent: Color(0xFFF4F8F8),
  );

  factory ObsidianPalette.of(BuildContext context) {
    if (!context.isDarkTheme) return light;
    final c = context.appColors;
    return ObsidianPalette(
      base: c.bgBase,
      bgDeep: c.bgDeep,
      heroAccent: c.primary,
      heroAccentDark: c.primaryDim,
      textPrimary: c.textPrimary,
      textSecondary: c.textSecondary,
      textMuted: c.textMuted,
      glassFill: c.surface,
      glassBorder: c.border,
      surfaceDark: c.surface,
      surfaceMuted: c.surface2,
      track: c.surface2,
      textOnAccent: c.onPrimary,
    );
  }

  List<BoxShadow> glassShadow({Color? tint}) => [
        BoxShadow(
          color: (tint ?? heroAccent).withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  LinearGradient glassTopHighlight() => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [heroAccent.withValues(alpha: 0.08), heroAccent.withValues(alpha: 0)],
        stops: const [0.0, 0.35],
      );
}

extension ObsidianPaletteContext on BuildContext {
  ObsidianPalette get obsidian => ObsidianPalette.of(this);
}
