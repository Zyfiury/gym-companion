import 'package:flutter/material.dart';

import 'app_colors_extension.dart';
import 'app_spacing.dart';

/// Semantic theme colors for widgets - maps to [AppColorsExtension].
class AppThemeColors {
  const AppThemeColors(this._c);

  final AppColorsExtension _c;

  factory AppThemeColors.of(BuildContext context) =>
      AppThemeColors(context.appColors);

  Color get scaffold => _c.bgBase;
  Color get card => _c.surface;
  Color get elevated => _c.surface2;
  Color get textPrimary => _c.textPrimary;
  Color get textSecondary => _c.textSecondary;
  Color get textMuted => _c.textMuted;
  Color get borderSubtle => _c.border;
  Color get border => _c.border;
  Color get navBar => _c.bgDeep;
  Color get navInactive => _c.textMuted;
  Color get progressTrack => _c.surface2;
  Color get chipBg => _c.surface2;
  Color get iconMuted => _c.textSecondary;
  Color get shadow => _c.textPrimary.withValues(alpha: 0.08);
  List<BoxShadow> get cardShadow =>
      _c.cardShadow.isEmpty ? _c.subtleGlow : _c.cardShadow;
  List<BoxShadow> get floatShadow => _c.floatShadow;
  Color get proBannerBg => _c.primaryTintBg;
  Color get proBannerBorder => _c.primaryTintBorder;
  Color get coachBubble => _c.surface;
  Color get inputFill => _c.surface2;
  Color get ambientTop => _c.primaryGlow;
  Color get ambientBottom => _c.duskDim;
}

extension AppThemeContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColorsExtension.dark
          : AppColorsExtension.light);

  AppThemeColors get appTheme => AppThemeColors.of(this);

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  double get screenPadding {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 360) return AppSpacing.lg;
    if (w > 600) return AppSpacing.xxxl - 4;
    return AppSpacing.xl;
  }
}

/// Legacy spacing aliases used by existing screens.
class AppSpacingLegacy {
  AppSpacingLegacy._();

  static const sm = AppSpacing.sm;
  static const md = AppSpacing.lg;
  static const lg = AppSpacing.xxl;

  static double screenPadding(BuildContext context) => context.screenPadding;
}
