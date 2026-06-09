import 'package:flutter/material.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.bgBase,
    required this.bgDeep,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryDim,
    required this.primaryGlow,
    required this.onPrimary,
    required this.mint,
    required this.mintDim,
    required this.olive,
    required this.oliveDim,
    required this.sand,
    required this.sandDim,
    required this.dusk,
    required this.duskDim,
    required this.error,
    required this.errorDim,
    required this.macroProtein,
    required this.macroCarbs,
    required this.macroFat,
    required this.xpBarColors,
    required this.proBadgeColors,
    required this.cardShadow,
    required this.floatShadow,
    required this.primaryGlowShadow,
    required this.snackBarBg,
    required this.snackBarText,
    required this.switchTrackSelected,
    required this.switchTrackUnselected,
    required this.navIndicator,
  });

  final Color bgBase;
  final Color bgDeep;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color primaryDim;
  final Color primaryGlow;
  final Color onPrimary;
  final Color mint;
  final Color mintDim;
  final Color olive;
  final Color oliveDim;
  final Color sand;
  final Color sandDim;
  final Color dusk;
  final Color duskDim;
  final Color error;
  final Color errorDim;
  final Color macroProtein;
  final Color macroCarbs;
  final Color macroFat;
  final List<Color> xpBarColors;
  final List<Color> proBadgeColors;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> floatShadow;
  final List<BoxShadow> primaryGlowShadow;
  final Color snackBarBg;
  final Color snackBarText;
  final Color switchTrackSelected;
  final Color switchTrackUnselected;
  final Color navIndicator;

  LinearGradient get xpBarGradient => LinearGradient(
        colors: xpBarColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  LinearGradient get proBadgeGradient => LinearGradient(
        colors: proBadgeColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  List<BoxShadow> get subtleGlow => primaryGlowShadow;

  // Legacy aliases used across existing screens.
  Color get accent => dusk;
  Color get accentDim => dusk;
  Color get accentGlow => duskDim;
  Color get info => dusk;
  Color get warning => sand;
  Color get primaryTintBg => primaryGlow;
  Color get primaryTintBorder => primary.withValues(alpha: 0.28);
  Color get accentTintBg => duskDim;
  Color get accentTintBorder => dusk.withValues(alpha: 0.28);
  Color get infoTintBg => duskDim;
  Color get infoTintBorder => dusk.withValues(alpha: 0.28);

  /// Deep Water — dark teal wellness (unchanged dark mode).
  static const AppColorsExtension dark = AppColorsExtension(
    bgBase: Color(0xFF111C22),
    bgDeep: Color(0xFF0C1519),
    surface: Color(0xFF182830),
    surface2: Color(0xFF1F3340),
    surface3: Color(0xFF263D4D),
    border: Color(0xFF2E4A5C),
    borderStrong: Color(0xFF3D6175),
    textPrimary: Color(0xFFE8F0F4),
    textSecondary: Color(0xFF8BAABB),
    textMuted: Color(0xFF566F7D),
    primary: Color(0xFF7FB5A0),
    primaryDim: Color(0xFF6A9D8A),
    primaryGlow: Color(0x1F7FB5A0),
    onPrimary: Color(0xFF0C1519),
    mint: Color(0xFF96D7C6),
    mintDim: Color(0x337FB5A0),
    olive: Color(0xFFC49A5A),
    oliveDim: Color(0x26C49A5A),
    sand: Color(0xFFC49A5A),
    sandDim: Color(0x26C49A5A),
    dusk: Color(0xFF3D7A93),
    duskDim: Color(0x263D7A93),
    error: Color(0xFFC06B5E),
    errorDim: Color(0x26C06B5E),
    macroProtein: Color(0xFF7FB5A0),
    macroCarbs: Color(0xFFC49A5A),
    macroFat: Color(0xFF3D7A93),
    xpBarColors: [Color(0xFF3D7A93), Color(0xFF7FB5A0)],
    proBadgeColors: [Color(0xFF3D7A93), Color(0xFF7FB5A0)],
    cardShadow: [],
    floatShadow: [],
    primaryGlowShadow: [
      BoxShadow(
        color: Color(0x1F7FB5A0),
        blurRadius: 24,
        spreadRadius: -6,
      ),
    ],
    snackBarBg: Color(0xFF263D4D),
    snackBarText: Color(0xFFE8F0F4),
    switchTrackSelected: Color(0x667FB5A0),
    switchTrackUnselected: Color(0xFF263D4D),
    navIndicator: Color(0x337FB5A0),
  );

  /// Sea Mist — cool coastal premium wellness (light mode).
  static const AppColorsExtension light = AppColorsExtension(
    bgBase: Color(0xFFE8EEF0),
    bgDeep: Color(0xFFD8E2E6),
    surface: Color(0xFFF4F8F8),
    surface2: Color(0xFFDCE8EA),
    surface3: Color(0xFFC9D6DC),
    border: Color(0xFFC9D6DC),
    borderStrong: Color(0xFF9ABCC0),
    textPrimary: Color(0xFF1A2E30),
    textSecondary: Color(0xFF3A5A60),
    textMuted: Color(0xFF6A8A90),
    primary: Color(0xFF5AA7A7),
    primaryDim: Color(0xFF3A8888),
    primaryGlow: Color(0x1F5AA7A7),
    onPrimary: Color(0xFFF4F8F8),
    mint: Color(0xFF96D7C6),
    mintDim: Color(0x3396D7C6),
    olive: Color(0xFF8A9A30),
    oliveDim: Color(0x268A9A30),
    sand: Color(0xFFA89040),
    sandDim: Color(0x26A89040),
    dusk: Color(0xFF4A6A9A),
    duskDim: Color(0x264A6A9A),
    error: Color(0xFFA85848),
    errorDim: Color(0x1FA85848),
    macroProtein: Color(0xFF5AA7A7),
    macroCarbs: Color(0xFF8A9A30),
    macroFat: Color(0xFF4A6A9A),
    xpBarColors: [Color(0xFF5AA7A7), Color(0xFF96D7C6)],
    proBadgeColors: [Color(0xFF5AA7A7), Color(0xFF8A9A30)],
    cardShadow: [
      BoxShadow(
        color: Color(0x0F1A2E30),
        blurRadius: 16,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x081A2E30),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    floatShadow: [
      BoxShadow(
        color: Color(0x1A1A2E30),
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
    primaryGlowShadow: [
      BoxShadow(
        color: Color(0x2E5AA7A7),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ],
    snackBarBg: Color(0xFF1A2E30),
    snackBarText: Color(0xFFF4F8F8),
    switchTrackSelected: Color(0x595AA7A7),
    switchTrackUnselected: Color(0xFFC9D6DC),
    navIndicator: Color(0x335AA7A7),
  );

  @override
  AppColorsExtension copyWith({
    Color? bgBase,
    Color? bgDeep,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? primaryDim,
    Color? primaryGlow,
    Color? onPrimary,
    Color? mint,
    Color? mintDim,
    Color? olive,
    Color? oliveDim,
    Color? sand,
    Color? sandDim,
    Color? dusk,
    Color? duskDim,
    Color? error,
    Color? errorDim,
    Color? macroProtein,
    Color? macroCarbs,
    Color? macroFat,
    List<Color>? xpBarColors,
    List<Color>? proBadgeColors,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? floatShadow,
    List<BoxShadow>? primaryGlowShadow,
    Color? snackBarBg,
    Color? snackBarText,
    Color? switchTrackSelected,
    Color? switchTrackUnselected,
    Color? navIndicator,
  }) {
    return AppColorsExtension(
      bgBase: bgBase ?? this.bgBase,
      bgDeep: bgDeep ?? this.bgDeep,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryDim: primaryDim ?? this.primaryDim,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      onPrimary: onPrimary ?? this.onPrimary,
      mint: mint ?? this.mint,
      mintDim: mintDim ?? this.mintDim,
      olive: olive ?? this.olive,
      oliveDim: oliveDim ?? this.oliveDim,
      sand: sand ?? this.sand,
      sandDim: sandDim ?? this.sandDim,
      dusk: dusk ?? this.dusk,
      duskDim: duskDim ?? this.duskDim,
      error: error ?? this.error,
      errorDim: errorDim ?? this.errorDim,
      macroProtein: macroProtein ?? this.macroProtein,
      macroCarbs: macroCarbs ?? this.macroCarbs,
      macroFat: macroFat ?? this.macroFat,
      xpBarColors: xpBarColors ?? this.xpBarColors,
      proBadgeColors: proBadgeColors ?? this.proBadgeColors,
      cardShadow: cardShadow ?? this.cardShadow,
      floatShadow: floatShadow ?? this.floatShadow,
      primaryGlowShadow: primaryGlowShadow ?? this.primaryGlowShadow,
      snackBarBg: snackBarBg ?? this.snackBarBg,
      snackBarText: snackBarText ?? this.snackBarText,
      switchTrackSelected: switchTrackSelected ?? this.switchTrackSelected,
      switchTrackUnselected: switchTrackUnselected ?? this.switchTrackUnselected,
      navIndicator: navIndicator ?? this.navIndicator,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;

    return AppColorsExtension(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mintDim: Color.lerp(mintDim, other.mintDim, t)!,
      olive: Color.lerp(olive, other.olive, t)!,
      oliveDim: Color.lerp(oliveDim, other.oliveDim, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      sandDim: Color.lerp(sandDim, other.sandDim, t)!,
      dusk: Color.lerp(dusk, other.dusk, t)!,
      duskDim: Color.lerp(duskDim, other.duskDim, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorDim: Color.lerp(errorDim, other.errorDim, t)!,
      macroProtein: Color.lerp(macroProtein, other.macroProtein, t)!,
      macroCarbs: Color.lerp(macroCarbs, other.macroCarbs, t)!,
      macroFat: Color.lerp(macroFat, other.macroFat, t)!,
      xpBarColors: [
        Color.lerp(xpBarColors[0], other.xpBarColors[0], t)!,
        Color.lerp(xpBarColors[1], other.xpBarColors[1], t)!,
      ],
      proBadgeColors: [
        Color.lerp(proBadgeColors[0], other.proBadgeColors[0], t)!,
        Color.lerp(proBadgeColors[1], other.proBadgeColors[1], t)!,
      ],
      cardShadow: cardShadow,
      floatShadow: floatShadow,
      primaryGlowShadow: primaryGlowShadow,
      snackBarBg: Color.lerp(snackBarBg, other.snackBarBg, t)!,
      snackBarText: Color.lerp(snackBarText, other.snackBarText, t)!,
      switchTrackSelected: Color.lerp(switchTrackSelected, other.switchTrackSelected, t)!,
      switchTrackUnselected: Color.lerp(switchTrackUnselected, other.switchTrackUnselected, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
    );
  }
}
