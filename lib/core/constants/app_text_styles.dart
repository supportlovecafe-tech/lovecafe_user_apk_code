import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Heading Styles (Poppins for Premium Feel)
  static TextStyle headingHero = GoogleFonts.poppins(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Body Styles (Inter for readability)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Specialized Styles
  static TextStyle priceLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static TextStyle displayHero = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    height: 1,
  );
}
