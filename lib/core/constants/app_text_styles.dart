import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Love Cafe — Typography System
/// Poppins for headings/prices (personality & weight)
/// Inter for body/labels (readability & precision)
class AppTextStyles {
  // ═══════════════════════════════════════════
  // DISPLAY — Hero headlines (home banner, splash)
  // ═══════════════════════════════════════════

  static TextStyle get displayHero => GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  // ═══════════════════════════════════════════
  // HEADINGS — Section and screen titles
  // ═══════════════════════════════════════════

  static TextStyle get headingHero => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingSmall => GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ═══════════════════════════════════════════
  // TITLES — Card titles, item names
  // ═══════════════════════════════════════════

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ═══════════════════════════════════════════
  // BODY — Descriptions and content
  // ═══════════════════════════════════════════

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.6,
        letterSpacing: -0.2,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: -0.1,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ═══════════════════════════════════════════
  // LABELS — Chips, badges, tags, nav
  // ═══════════════════════════════════════════

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.textDisabled,
      );

  // ═══════════════════════════════════════════
  // PRICE — Food prices, totals
  // ═══════════════════════════════════════════

  static TextStyle get priceLarge => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      );

  static TextStyle get priceMedium => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get priceSmall => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get priceStrikethrough => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.lineThrough,
        color: AppColors.textDisabled,
      );

  // ═══════════════════════════════════════════
  // BUTTON — CTA labels
  // ═══════════════════════════════════════════

  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.white,
      );

  static TextStyle get buttonMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.white,
      );

  // Backward compat
  static TextStyle get buttonText => buttonLarge;
}
