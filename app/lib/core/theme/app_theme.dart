import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_extension.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(AppColorsExtension.dark);
  static ThemeData get light => _build(AppColorsExtension.light);

  static const _calmOverlay = WidgetStatePropertyAll<Color>(Color(0x0D000000));

  static ThemeData _build(AppColorsExtension c) {
    final isDark = identical(c, AppColorsExtension.dark);
    final textTheme = AppTypography.textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bgBase,
      canvasColor: c.bgBase,
      cardColor: c.surface,
      primaryColor: c.primary,
      dividerColor: c.border,
      splashFactory: InkRipple.splashFactory,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: c.primary,
        onPrimary: c.onPrimary,
        primaryContainer: c.primaryDim,
        onPrimaryContainer: c.textPrimary,
        secondary: c.olive,
        onSecondary: c.onPrimary,
        secondaryContainer: c.oliveDim,
        onSecondaryContainer: c.textPrimary,
        tertiary: c.dusk,
        onTertiary: c.onPrimary,
        error: c.error,
        onError: c.onPrimary,
        surface: c.surface,
        onSurface: c.textPrimary,
        onSurfaceVariant: c.textSecondary,
        outline: c.border,
        outlineVariant: c.borderStrong,
        shadow: c.textPrimary,
        scrim: c.textPrimary.withValues(alpha: 0.32),
        inverseSurface: c.textPrimary,
        onInverseSurface: c.surface,
        inversePrimary: c.mint,
        surfaceTint: c.primary,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgBase,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textSecondary, size: 22),
        actionsIconTheme: IconThemeData(color: c.textSecondary, size: 22),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: c.textPrimary.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          splashFactory: InkRipple.splashFactory,
          overlayColor: _calmOverlay,
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Color(0x00000000)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return c.surface3;
            return c.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return c.textMuted;
            return c.onPrimary;
          }),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          splashFactory: InkRipple.splashFactory,
          overlayColor: c.primaryGlow,
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          splashFactory: InkRipple.splashFactory,
          overlayColor: c.primaryGlow,
          foregroundColor: c.primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: c.textMuted,
        ),
        helperStyle: GoogleFonts.dmSans(fontSize: 11, color: c.textMuted),
        errorStyle: GoogleFonts.dmSans(fontSize: 11, color: c.error),
        floatingLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: c.primary,
        ),
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          borderSide: BorderSide(color: c.borderStrong, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          borderSide: BorderSide(color: c.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgDeep,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w300,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bgDeep,
        elevation: 0,
        height: 64,
        indicatorColor: c.navIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: c.primary,
            );
          }
          return GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            color: c.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: c.primary, size: 22);
          }
          return IconThemeData(color: c.textMuted, size: 22);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface2,
        selectedColor: c.mintDim,
        disabledColor: c.surface2,
        deleteIconColor: c.textMuted,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: c.textSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: c.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: c.border, width: 1),
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackBarBg,
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: c.snackBarText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
          side: BorderSide(color: c.border, width: 1),
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: c.textSecondary,
          height: 1.6,
        ),
      ),
      switchTheme: SwitchThemeData(
        splashRadius: 0,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.switchTrackSelected;
          return c.switchTrackUnselected;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.surface2,
        thumbColor: c.primary,
        overlayColor: c.primaryGlow,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surface2,
        circularTrackColor: c.surface2,
        linearMinHeight: 4,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.textMuted,
        indicatorColor: c.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.border,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w300,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      iconTheme: IconThemeData(color: c.textSecondary, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        tileColor: c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 0,
        splashColor: c.primaryGlow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

void applySystemChrome(ThemeMode mode, Brightness platformBrightness) {
  final isDark = resolveIsDark(mode, platformBrightness);
  final c = isDark ? AppColorsExtension.dark : AppColorsExtension.light;

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: c.bgDeep,
    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  ));
}

bool resolveIsDark(ThemeMode mode, Brightness platformBrightness) {
  return switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => platformBrightness == Brightness.dark,
  };
}
