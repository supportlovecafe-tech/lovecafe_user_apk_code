import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLightEnd,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        error: AppColors.error,
        outline: AppColors.borderLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLightStart,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero.copyWith(color: AppColors.textPrimaryLight),
        displayMedium: AppTextStyles.headingHero.copyWith(color: AppColors.textPrimaryLight),
        displaySmall: AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimaryLight),
        headlineLarge: AppTextStyles.headingHero.copyWith(color: AppColors.textPrimaryLight),
        headlineMedium: AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimaryLight),
        titleLarge: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimaryLight),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
        labelLarge: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimaryLight),
        labelSmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDarkEnd,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        background: AppColors.bgDarkEnd,
        error: AppColors.error,
        outline: AppColors.borderDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDarkStart,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero.copyWith(color: AppColors.textPrimaryDark),
        displayMedium: AppTextStyles.headingHero.copyWith(color: AppColors.textPrimaryDark),
        displaySmall: AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimaryDark),
        headlineLarge: AppTextStyles.headingHero.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimaryDark),
        titleLarge: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimaryDark),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
        labelLarge: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimaryDark),
        labelSmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
    );
  }
}
