import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// A production-ready cinematic splash screen for Cinema Eats.
/// 
/// Optimized with a seamless overlapping transition between textual content
/// and the brand logo using scale, fade, and blur effects.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _word = "LOVE";
  static const String _tagline = "please taste me one time";
  static const String _logoAsset = 'assets/images/logo_transparent_refined.png';

  @override
  void initState() {
    super.initState();
    _initiateNavigation();
  }

  void _initiateNavigation() {
    // Total sequence duration adjusted for smooth overlap
    Future.delayed(6000.ms, () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // PHASE 1: Textual Content (LOVE + Tagline)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Typewriter "LOVE"
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _word.characters.indexed.map((item) {
                    final index = item.$1;
                    final char = item.$2;
                    return Text(
                      char,
                      style: GoogleFonts.montserrat(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 4,
                      ),
                    )
                        .animate(delay: (index * 200).ms)
                        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        );
                  }).toList(),
                )
                    .animate()
                    .scale(
                      delay: 1000.ms,
                      duration: 300.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(duration: 300.ms, end: const Offset(1, 1)),

                const SizedBox(height: 12),

                // Decorative Line
                Container(
                  height: 1.5,
                  width: 140,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.6),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                )
                    .animate(delay: 1400.ms)
                    .fadeIn(duration: 500.ms)
                    .scaleX(begin: 0, end: 1, curve: Curves.easeInOutExpo),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  _tagline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dancingScript(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                )
                    .animate(delay: 1600.ms)
                    .fadeIn(duration: 600.ms)
                    .moveY(begin: 10, end: 0, curve: Curves.easeOutCirc),
              ],
            )
                // SEAMLESS TRANSITION: Fade Out, Shrink, and Blur
                .animate(delay: 3800.ms)
                .fadeOut(duration: 800.ms, curve: Curves.easeInOut)
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(0.85, 0.85),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                )
                .blur(
                  begin: const Offset(0, 0),
                  end: const Offset(5, 5),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                ),

            // PHASE 2: Brand Logo (Overlapping appearance)
            Image.asset(
              _logoAsset,
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            )
                .animate(delay: 4000.ms) // Starts 200ms after text begins fading
                .fadeIn(duration: 1000.ms, curve: Curves.easeInOut)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  duration: 1000.ms,
                  curve: Curves.easeOutCubic,
                )
                .shimmer(
                  delay: 5200.ms,
                  duration: 1200.ms,
                  color: Colors.white12,
                ),
          ],
        ),
      ),
    );
  }
}
