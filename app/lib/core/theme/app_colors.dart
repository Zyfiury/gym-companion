import 'package:flutter/material.dart';

import 'app_colors_extension.dart';

/// Legacy color access - prefer [AppColorsExtension] via `context.appColors`.
class AppColors {
  AppColors._();

  static AppColorsExtension of(BuildContext context) {
    return Theme.of(context).extension<AppColorsExtension>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColorsExtension.dark
            : AppColorsExtension.light);
  }

  static const AppColorsExtension dark = AppColorsExtension.dark;
  static const AppColorsExtension light = AppColorsExtension.light;

  // ─── Legacy aliases (dark palette defaults for const contexts) ───────────

  static const Color volt = Color(0xFF7FB5A0);
  static const Color voltDark = Color(0xFF6A9D8A);
  static const Color ember = Color(0xFFC49A5A);
  static const Color hydro = Color(0xFF3D7A93);
  static const Color slate900 = Color(0xFF111C22);
  static const Color slate800 = Color(0xFF182830);
  static const Color slate600 = Color(0xFF2E4A5C);
  static const Color slate400 = Color(0xFF566F7D);
  static const Color offWhite = Color(0xFFE8F0F4);
  static const Color lightBg = Color(0xFFE8EEF0);
  static const Color lightCard = Color(0xFFF4F8F8);
  static const Color lightElevated = Color(0xFFDCE8EA);
  static const Color lightMuted = Color(0xFFC9D6DC);
  static const Color textDark = Color(0xFF1A2E30);
  static const Color textMutedLight = Color(0xFF6A8A90);
  static const Color textSubtleLight = Color(0xFF6A8A90);

  static const Color accent = Color(0xFF3D7A93);
  static const Color accentLight = Color(0xFF7FB5A0);
  static const Color orange = Color(0xFFC49A5A);
  static const Color emerald = Color(0xFF96D7C6);
  static const Color blue = Color(0xFF3D7A93);
  static const Color violet = Color(0xFF7FB5A0);
  static const Color surface = Color(0xFF111C22);
  static const Color surfaceCard = Color(0xFF182830);
  static const Color surfaceElevated = Color(0xFF1F3340);
  static const Color darkElevated = Color(0xFF1F3340);

  static const LinearGradient gradient = LinearGradient(
    colors: [Color(0xFF3D7A93), Color(0xFF7FB5A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFF7FB5A0), Color(0xFFC49A5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color macroTrack = Color(0xFF1F3340);
  static Color voltTintBg = const Color(0x1F7FB5A0);
  static Color voltTintBorder = const Color(0xFF7FB5A0).withValues(alpha: 0.28);
  static Color emberTintBg = const Color(0x26C49A5A);
  static Color emberTintBorder = const Color(0xFFC49A5A).withValues(alpha: 0.28);
  static Color hydroTintBg = const Color(0x263D7A93);
  static Color hydroTintBorder = const Color(0xFF3D7A93).withValues(alpha: 0.28);
  static Color userBubbleBg = const Color(0x1F7FB5A0);
}
