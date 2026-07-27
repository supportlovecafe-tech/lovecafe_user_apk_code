import 'package:flutter/material.dart';

/// Love Cafe — Luxury Dark Color System
/// Palette: OLED Black + Hot Pink + Purple + VIP Gold
class AppColors {
  // ═══════════════════════════════════════════
  // BACKGROUNDS
  // ═══════════════════════════════════════════
  static const Color bg = Color(0xFF09090B);           // Primary background (OLED black)
  static const Color bgSecondary = Color(0xFF111114);  // Secondary / section bg
  static const Color surface = Color(0xFF18181F);      // Card surface
  static const Color surfaceElevated = Color(0xFF202028); // Elevated cards / modals

  // ═══════════════════════════════════════════
  // BRAND COLORS
  // ═══════════════════════════════════════════
  static const Color primary = Color(0xFFFF4FA3);      // Hot Pink — primary CTA
  static const Color primaryDark = Color(0xFFD63384);  // Dark Pink — gradient mid
  static const Color primaryDeep = Color(0xFFB026FF);  // Deep Violet — gradient end
  static const Color secondary = Color(0xFF8B5CF6);    // Purple — secondary accent
  static const Color accent = Color(0xFF8B5CF6);
  static const Color gold = Color(0xFFFFC857);         // VIP Gold — rewards
  static const Color vipGold = Color(0xFFFFC857);

  // ═══════════════════════════════════════════
  // TEXT
  // ═══════════════════════════════════════════
  static const Color textPrimary = Color(0xFFF7F7F8);   // Headlines & values
  static const Color textSecondary = Color(0xFFA1A1AA); // Descriptions & labels
  static const Color textDisabled = Color(0xFF71717A);  // Placeholders & muted

  // ═══════════════════════════════════════════
  // SEMANTIC
  // ═══════════════════════════════════════════
  static const Color success = Color(0xFF22C55E);  // Delivered / positive
  static const Color warning = Color(0xFFFACC15);  // Preparing / caution
  static const Color error = Color(0xFFEF4444);    // Error / cancelled
  static const Color info = Color(0xFF8B5CF6);     // Info — use purple

  // ═══════════════════════════════════════════
  // BORDERS & DIVIDERS
  // ═══════════════════════════════════════════
  /// Subtle card border: rgba(255,255,255,0.05)
  static const Color cardBorder = Color(0x0DFFFFFF);
  
  /// Sleek glass border for premium overlays: rgba(255,255,255,0.1)
  static const Color glassBorder = Color(0x1AFFFFFF);

  /// Stronger border for inputs and sections
  static const Color borderStrong = Color(0xFF2A2A35);
  /// Divider between list items
  static const Color divider = Color(0xFF1E1E26);

  // ═══════════════════════════════════════════
  // UTILITY
  // ═══════════════════════════════════════════
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ═══════════════════════════════════════════
  // BACKWARD COMPATIBILITY ALIASES
  // (used throughout existing screens — do not remove)
  // ═══════════════════════════════════════════
  static const Color bgStart = bg;
  static const Color bgEnd = bgSecondary;
  static const Color bgDarkStart = bg;
  static const Color bgDarkEnd = bgSecondary;
  static const Color bgLightStart = bg;
  static const Color bgLightEnd = bgSecondary;
  static const Color surfaceDark = surface;
  static const Color surfaceLight = surface;
  static const Color surfaceContainer = surface;
  static const Color surfaceContainerHigh = surfaceElevated;
  static const Color darkBackground = bg;
  static const Color darkSurface = surface;
  static const Color textMuted = textSecondary;
  static const Color textPrimaryLight = textPrimary;
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textSecondaryDark = textSecondary;
  static const Color borderLight = borderStrong;
  static const Color borderDark = borderStrong;
  static const Color border = borderStrong;
  static const Color primaryLight = primary;
  static const Color primaryRed = primary;
  static const Color brandOrange = Color(0xFFFF8C42);
  static const Color accentTeal = secondary;
}
