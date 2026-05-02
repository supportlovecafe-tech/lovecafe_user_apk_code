import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Swiggy/Premium Style)
  static const Color primary = Color(0xFFE11D48); // Deep Rose Red
  static const Color primaryLight = Color(0xFFFB7185);
  static const Color primaryDark = Color(0xFF9F1239);
  
  static const Color accent = Color(0xFFF59E0B);  // Amber
  static const Color secondary = Color(0xFF6366F1); // Indigo
  
  // Light Mode Colors
  static const Color bgLightStart = Color(0xFFFFFFFF);
  static const Color bgLightEnd = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color borderLight = Color(0xFFE2E8F0);
  
  // Dark Mode Colors
  static const Color bgDarkStart = Color(0xFF0F172A); // Slate 900
  static const Color bgDarkEnd = Color(0xFF020617);   // Slate 950
  static const Color surfaceDark = Color(0xFF1E293B);  // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color borderDark = Color(0xFF334155);
  
  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Helper Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Retro-compatibility (Internal aliases)
  static const Color bgStart = bgLightStart;
  static const Color bgEnd = bgLightEnd;
  static const Color surface = surfaceLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textSecondaryLight;
  static const Color primaryRed = primary;
  static const Color brandOrange = accent;
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color darkBackground = bgDarkStart;
  static const Color darkSurface = surfaceDark;
  static const Color accentTeal = Color(0xFF14B8A6);
}
