import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
      surface: AppColors.surfaceLight,
    );

    return _base(
      colorScheme: colorScheme,
      scaffold: AppColors.surfaceLight,
      card: AppColors.cardLight,
      ink: AppColors.inkLight,
      muted: AppColors.mutedLight,
      hairline: AppColors.hairlineLight,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedDark,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
    );

    return _base(
      colorScheme: colorScheme,
      scaffold: AppColors.surfaceDark,
      card: AppColors.cardDark,
      ink: AppColors.inkDark,
      muted: AppColors.mutedDark,
      hairline: AppColors.hairlineDark,
    );
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color card,
    required Color ink,
    required Color muted,
    required Color hairline,
  }) {
    // Notion-like clarity: Plus Jakarta for display, DM Sans for UI.
    final base = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final display = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );

    final textTheme = base.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
      displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45, color: muted),
      bodySmall: base.bodySmall?.copyWith(height: 1.4, color: muted),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: ink,
        titleTextStyle: display.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          side: BorderSide(color: hairline.withValues(alpha: 0.7)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          borderSide: BorderSide(color: hairline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: muted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        elevation: 0,
        height: 68,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.1,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.radiusSm + 2),
          ),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.radiusSm + 2),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radiusSm),
        ),
        side: BorderSide(color: hairline),
        backgroundColor: card,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
