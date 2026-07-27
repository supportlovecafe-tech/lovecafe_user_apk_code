import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Love Cafe — Centralized Design System
/// Single source of truth for all Material ThemeData.
/// Both light and dark return the same luxury dark theme
/// because Love Cafe is OLED-first by design.
class AppTheme {
  // ─────────────────────────────────────────
  // COLOR SCHEME
  // ─────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF3D1A2E),
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF2D1B6B),
    onSecondaryContainer: AppColors.secondary,
    tertiary: AppColors.gold,
    onTertiary: Colors.black,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.cardBorder,
    shadow: Colors.black,
    scrim: Color(0xCC000000),
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.primaryDark,
    surfaceTint: AppColors.primary,
  );

  // ─────────────────────────────────────────
  // TEXT THEME
  // ─────────────────────────────────────────
  static TextTheme get _textTheme => TextTheme(
        displayLarge: AppTextStyles.displayHero,
        displayMedium: AppTextStyles.displayLarge,
        displaySmall: AppTextStyles.headingHero,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        headlineSmall: AppTextStyles.headingSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );

  // ─────────────────────────────────────────
  // COMPONENT THEMES
  // ─────────────────────────────────────────

  static AppBarTheme get _appBarTheme => AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
        titleTextStyle: AppTextStyles.headingSmall,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor:
              WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
          minimumSize:
              WidgetStateProperty.all(const Size(double.infinity, 56)),
          maximumSize: WidgetStateProperty.all(const Size(double.infinity, 64)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStateProperty.all(AppTextStyles.buttonLarge),
          elevation: WidgetStateProperty.all(0),
          animationDuration: const Duration(milliseconds: 150),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(AppTextStyles.labelLarge),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.borderStrong, width: 1),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(AppTextStyles.buttonMedium),
          animationDuration: const Duration(milliseconds: 150),
        ),
      );

  static CardThemeData get _cardTheme => CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      );

  static InputDecorationTheme get _inputTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
        labelStyle: AppTextStyles.labelMedium,
        prefixIconColor: AppColors.textDisabled,
        suffixIconColor: AppColors.textDisabled,
      );

  static BottomNavigationBarThemeData get _bottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );

  static TabBarThemeData get _tabBarTheme => TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      );

  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      );

  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.labelMedium,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );

  static DividerThemeData get _dividerTheme => const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      );

  static BottomSheetThemeData get _bottomSheetTheme => BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: AppColors.borderStrong,
        dragHandleSize: const Size(40, 4),
        elevation: 0,
        modalElevation: 0,
      );

  static DialogThemeData get _dialogTheme => DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTextStyles.headingSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      );

  // ─────────────────────────────────────────
  // ASSEMBLED THEME
  // ─────────────────────────────────────────
  static ThemeData get _theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: _colorScheme,
        textTheme: _textTheme,
        appBarTheme: _appBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        textButtonTheme: _textButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        cardTheme: _cardTheme,
        inputDecorationTheme: _inputTheme,
        bottomNavigationBarTheme: _bottomNavTheme,
        tabBarTheme: _tabBarTheme,
        snackBarTheme: _snackBarTheme,
        chipTheme: _chipTheme,
        dividerTheme: _dividerTheme,
        bottomSheetTheme: _bottomSheetTheme,
        dialogTheme: _dialogTheme,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        focusColor: AppColors.primary.withValues(alpha: 0.12),
      );

  /// Love Cafe forces dark (OLED-first)
  static ThemeData get darkTheme => _theme;
  static ThemeData get lightTheme => _theme;
}
