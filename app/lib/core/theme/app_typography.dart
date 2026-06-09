import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_extension.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(AppColorsExtension colors) {
    return TextTheme(
      displayLarge: GoogleFonts.gloock(
        fontSize: 52,
        letterSpacing: -1.0,
        color: colors.textPrimary,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.gloock(
        fontSize: 38,
        letterSpacing: -0.5,
        color: colors.textPrimary,
        height: 1.08,
      ),
      displaySmall: GoogleFonts.gloock(
        fontSize: 28,
        letterSpacing: -0.3,
        color: colors.textPrimary,
        height: 1.1,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: colors.textPrimary,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: colors.textPrimary,
        height: 1.7,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: colors.textPrimary,
        height: 1.6,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: colors.textPrimary,
        height: 1.3,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        color: colors.textSecondary,
        height: 1.3,
      ),
      labelSmall: GoogleFonts.dmMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        color: colors.textMuted,
        height: 1.2,
      ),
    );
  }
}
