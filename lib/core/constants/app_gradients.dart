import 'package:flutter/material.dart';

/// Cinema Eats — Gradient Token Library
/// All gradients used across the app defined in one place for consistency.
class AppGradients {
  // ═══════════════════════════════════════════
  // BUTTON GRADIENTS
  // ═══════════════════════════════════════════

  /// Primary CTA gradient: Hot Pink → Dark Pink → Deep Violet
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF4FA3),
      Color(0xFFD63384),
      Color(0xFFB026FF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Secondary button — subtle dark with pink tint
  static const LinearGradient secondaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF202028), Color(0xFF18181F)],
  );

  // ═══════════════════════════════════════════
  // BACKGROUND GRADIENTS
  // ═══════════════════════════════════════════

  /// Full app background gradient (top → bottom)
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF09090B), Color(0xFF0E0E12), Color(0xFF14141A)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Subtle card inner gradient
  static const LinearGradient cardInner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF202028), Color(0xFF18181F)],
  );

  // ═══════════════════════════════════════════
  // OVERLAY GRADIENTS
  // ═══════════════════════════════════════════

  /// Hero image overlay — left side fade to black (for text readability)
  static const LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Colors.transparent, Color(0xE609090B)],
    stops: [0.0, 0.75],
  );

  /// Food card bottom overlay — for text on image
  static const LinearGradient cardImageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC09090B)],
    stops: [0.3, 1.0],
  );

  /// Pink glow overlay (for selected cards, active elements)
  static const LinearGradient pinkGlowOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x22FF4FA3), Colors.transparent],
  );

  // ═══════════════════════════════════════════
  // FEATURE GRADIENTS
  // ═══════════════════════════════════════════

  /// CinePoints VIP gradient — Purple to Pink
  static const LinearGradient cinePoints = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFB026FF), Color(0xFFFF4FA3)],
    stops: [0.0, 0.6, 1.0],
  );

  /// CinePoints card shimmer highlight
  static const LinearGradient cinePointsShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFF8B5CF6)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gold VIP gradient
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFC857), Color(0xFFFFAA00)],
  );

  /// Pink neon glow (radial — for selected items)
  static RadialGradient pinkNeonGlow = RadialGradient(
    colors: [
      Color(0x44FF4FA3),
      Color(0x11FF4FA3),
      Colors.transparent,
    ],
    stops: const [0.0, 0.5, 1.0],
    radius: 1.0,
  );
}
