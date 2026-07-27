import 'package:flutter/material.dart';

/// Love Cafe — Shadow Token Library
/// Consistent depth/glow system across the entire app.
class AppShadows {
  // ═══════════════════════════════════════════
  // STRUCTURAL SHADOWS
  // ═══════════════════════════════════════════

  /// Standard card shadow — deep, premium feel
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// Elevated modal/bottom sheet shadow
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 50,
          spreadRadius: 0,
          offset: const Offset(0, 16),
        ),
      ];

  /// Floating bottom nav shadow
  static List<BoxShadow> get floatingNav => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 40,
          offset: const Offset(0, -8),
        ),
        BoxShadow(
          color: const Color(0xFFFF4FA3).withValues(alpha: 0.05),
          blurRadius: 25,
          offset: const Offset(0, -5),
        ),
      ];

  // ═══════════════════════════════════════════
  // NEON GLOW SHADOWS
  // ═══════════════════════════════════════════

  /// Hot pink glow — active buttons, selected cards
  static List<BoxShadow> get pinkGlow => [
        BoxShadow(
          color: const Color(0xFFFF4FA3).withValues(alpha: 0.4),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFFFF4FA3).withValues(alpha: 0.15),
          blurRadius: 48,
          spreadRadius: 4,
        ),
      ];

  /// Soft pink glow — subtle active states, not too strong
  static List<BoxShadow> get pinkGlowSoft => [
        BoxShadow(
          color: const Color(0xFFFF4FA3).withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Purple glow — CinePoints, secondary accents
  static List<BoxShadow> get purpleGlow => [
        BoxShadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
          blurRadius: 32,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          blurRadius: 60,
          spreadRadius: 8,
        ),
      ];

  /// Gold glow — VIP rewards highlights
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: const Color(0xFFFFC857).withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  // ═══════════════════════════════════════════
  // BUTTON SHADOWS
  // ═══════════════════════════════════════════

  /// Primary gradient button glow
  static List<BoxShadow> get buttonPrimary => [
        BoxShadow(
          color: const Color(0xFFFF4FA3).withValues(alpha: 0.45),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// Small icon button glow
  static List<BoxShadow> get iconGlow => [
        BoxShadow(
          color: const Color(0xFFFF4FA3).withValues(alpha: 0.35),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
}
