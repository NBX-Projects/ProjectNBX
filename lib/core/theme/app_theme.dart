import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';

export 'package:projectnbx/core/theme/app_radius.dart';

class AppTheme {
  // ==========================================
  // 🌑 DARK THEME (Pastel Tech Aesthetic)
  // ==========================================
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );
    final headingFont = GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      primaryColor: AppColors.darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSage,
        tertiary: AppColors.darkLavender,
        surface: AppColors.darkSurface,
        error: AppColors.darkDanger,
        onPrimary: AppColors.darkCanvas, // Dark text on peach button
        onSecondary: AppColors.darkCanvas,
        onSurface: AppColors.darkTextPrimary,
        onError: AppColors.darkCanvas,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: headingFont.copyWith(fontSize: 32, letterSpacing: -0.5),
        headlineMedium: headingFont.copyWith(fontSize: 24, letterSpacing: -0.3),
        titleLarge: headingFont.copyWith(fontSize: 20, letterSpacing: -0.2),
        titleMedium: headingFont.copyWith(fontSize: 16),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.darkTextPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          color: AppColors.darkTextMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInput,
        hintStyle: GoogleFonts.inter(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(
            color: AppColors.darkPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.darkDanger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkCanvas,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // Ergonomic Pill
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      switchTheme: const SwitchThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      checkboxTheme: const CheckboxThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      radioTheme: const RadioThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(false),
        interactive: true,
        radius: const Radius.circular(9999),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return 8.0;
          }
          return 6.0;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return AppColors.darkPrimary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.darkPrimary.withValues(alpha: 0.85);
          }
          return AppColors.darkTextMuted.withValues(alpha: 0.4);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.darkSurface.withValues(alpha: 0.35);
          }
          return Colors.transparent;
        }),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
        crossAxisMargin: 2.0,
        mainAxisMargin: 4.0,
        minThumbLength: 36.0,
      ),
    );
  }

  // ==========================================
  // ☀️ LIGHT THEME (Forest Slate Aesthetic)
  // ==========================================
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );
    final headingFont = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      primaryColor: AppColors.lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSkyBlue,
        tertiary: AppColors.lightLavender,
        surface: AppColors.lightSurface,
        error: AppColors.lightDanger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: headingFont.copyWith(fontSize: 32, letterSpacing: -0.5),
        headlineMedium: headingFont.copyWith(fontSize: 24, letterSpacing: -0.3),
        titleLarge: headingFont.copyWith(fontSize: 20, letterSpacing: -0.2),
        titleMedium: headingFont.copyWith(fontSize: 16),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.lightTextPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          color: AppColors.lightTextMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: GoogleFonts.inter(
          color: AppColors.lightTextMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(
            color: AppColors.lightPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.lightDanger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // Ergonomic Pill
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      switchTheme: const SwitchThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      checkboxTheme: const CheckboxThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      radioTheme: const RadioThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(false),
        interactive: true,
        radius: const Radius.circular(9999),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return 8.0;
          }
          return 6.0;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return AppColors.lightPrimary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.lightPrimary.withValues(alpha: 0.85);
          }
          return AppColors.lightTextMuted.withValues(alpha: 0.4);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.lightSurfaceElevated.withValues(alpha: 0.5);
          }
          return Colors.transparent;
        }),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
        crossAxisMargin: 2.0,
        mainAxisMargin: 4.0,
        minThumbLength: 36.0,
      ),
    );
  }
}
