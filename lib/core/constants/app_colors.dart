import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Neon Cinematic Style)
  static const Color primary = Color(0xFFFF4D9D); // Neon Pink
  static const Color primaryLight = Color(0xFFFF7EB3);
  static const Color primaryDark = Color(0xFFC82672);
  
  static const Color accent = Color(0xFF00D4FF);  // Electric Blue
  static const Color secondary = Color(0xFF7B61FF); // Purple Glow
  
  // Light Mode Colors (Forced to Dark for Premium Cinema Feel)
  static const Color bgLightStart = Color(0xFF0A0A0F);
  static const Color bgLightEnd = Color(0xFF0A0A0F);
  static const Color surfaceLight = Color(0xFF14141E);
  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFFB0B0B0);
  static const Color borderLight = Color(0xFF2A2A3A);
  
  // Dark Mode Colors
  static const Color bgDarkStart = Color(0xFF0A0A0F); // Dark Cinematic
  static const Color bgDarkEnd = Color(0xFF050508);   // Deeper Dark
  static const Color surfaceDark = Color(0xFF14141E);  // Glass Base
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // White
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Light Grey
  static const Color borderDark = Color(0xFF2A2A3A);
  
  // Semantic
  static const Color success = Color(0xFF00FF9D); // Neon Green
  static const Color warning = Color(0xFFFFB800); // Neon Yellow
  static const Color error = Color(0xFFFF3366);   // Bright Red
  static const Color info = Color(0xFF00D4FF);    // Electric Blue

  // Helper Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Retro-compatibility (Internal aliases)
  static const Color bgStart = bgDarkStart;
  static const Color bgEnd = bgDarkEnd;
  static const Color surface = surfaceDark;
  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textMuted = textSecondaryDark;
  static const Color primaryRed = primary;
  static const Color brandOrange = accent;
  static const Color surfaceContainer = Color(0xFF14141E);
  static const Color surfaceContainerHigh = Color(0xFF2A2A3A);
  static const Color darkBackground = bgDarkStart;
  static const Color darkSurface = surfaceDark;
  static const Color accentTeal = Color(0xFF00D4FF);
}

