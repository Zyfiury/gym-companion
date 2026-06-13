import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export '../core/theme/app_colors.dart';
export '../core/theme/app_colors_extension.dart';
export '../core/theme/app_spacing.dart';
export '../core/theme/app_theme.dart'
    show AppTheme, applySystemChrome, resolveIsDark;
export '../core/theme/app_typography.dart';
export '../core/theme/context_extensions.dart';
export '../core/theme/obsidian_palette.dart';
export '../core/theme/theme_provider.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart' as core;

ThemeData buildLightTheme() => core.AppTheme.light;
ThemeData buildDarkTheme() => core.AppTheme.dark;

// ─── Obsidian Premium (onboarding) - Sea Mist palette ───────────────────────

class ObsidianTokens {
  ObsidianTokens._();

  static const base = Color(0xFFE8EEF0);
  static const heroAccent = Color(0xFF5AA7A7);
  static const heroAccentDark = Color(0xFF3A8888);
  static const textPrimary = Color(0xFF1A2E30);
  static const textSecondary = Color(0xFF3A5A60);
  static const textMuted = Color(0xFF6A8A90);
  static const textOnAccent = Color(0xFFF4F8F8);
  static const glassFill = Color(0xFFF4F8F8);
  static const glassBorder = Color(0xFFC9D6DC);
  static const glassHighlight = Color(0x0A5AA7A7);
  static const surfaceDark = Color(0xFFF4F8F8);
  static const surfaceMuted = Color(0xFFDCE8EA);
  static const track = Color(0xFFDCE8EA);
  static const grainOpacity = 0.02;

  static const radiusSm = AppRadius.sm;
  static const radiusMd = AppRadius.card;
  static const radiusLg = AppRadius.lg;
  static const radiusPill = AppRadius.pill;

  static const spacingXs = 6.0;
  static const spacingSm = 10.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  static const progressHeight = 3.0;
  static const navButtonHeight = 56.0;
  static const cardHeightDiet = 72.0;
  static const cardHeightNutrition = 100.0;
  static const chipHeight = 40.0;
  static const sliderThumb = 24.0;
  static const sliderThumbActive = 32.0;
  static const accentStripe = 3.0;
  static const watermarkOpacity = 0.08;
  static const tdeeSize = 64.0;
  static const heroStatSize = 56.0;

  static const staggerMs = 200;
  static const exitMs = 150;
  static const springMs = 300;

  static List<BoxShadow> glassShadow({Color? tint}) => [
        BoxShadow(
          color: (tint ?? heroAccent).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x140C1519),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static Border glassBorderDecoration() => Border.all(color: glassBorder, width: 1);

  static LinearGradient glassTopHighlight() => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x18E8F0F4), Color(0x00E8F0F4)],
        stops: [0.0, 0.35],
      );
}

class ObsidianTypography {
  ObsidianTypography._();

  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w400,
    Color color = ObsidianTokens.textPrimary,
    double letterSpacing = -0.03,
  }) =>
      GoogleFonts.gloock(
        fontSize: size,
        color: color,
        letterSpacing: size * letterSpacing,
        height: 1.1,
      );

  static TextStyle displayLarge({Color color = ObsidianTokens.textPrimary}) =>
      display(size: 34, color: color);

  static TextStyle category({Color color = ObsidianTokens.textMuted}) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 2.4,
      );

  static TextStyle mono({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = ObsidianTokens.heroAccent,
  }) =>
      GoogleFonts.dmMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle monoHero({Color color = ObsidianTokens.heroAccent}) =>
      mono(size: ObsidianTokens.tdeeSize, weight: FontWeight.w500, color: color);

  static TextStyle body({
    double size = 15,
    Color color = ObsidianTokens.textSecondary,
    FontWeight weight = FontWeight.w300,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.7,
      );

  static TextStyle label({
    double size = 13,
    Color color = ObsidianTokens.textMuted,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.6,
      );

  static TextStyle button({Color color = ObsidianTokens.textOnAccent}) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );
}
