import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.background,
              colorScheme.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(colorScheme),
                      const SizedBox(height: 40),
                      _buildBranding(theme, colorScheme),
                      const SizedBox(height: 60),
                      _buildLoader(colorScheme),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 60),
    );
  }

  Widget _buildBranding(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'CinemaEats',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'GOURMET DINING • PREMIER CINEMA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onBackground.withOpacity(0.5),
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader(ColorScheme colorScheme) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          LinearProgressIndicator(
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Preparing your experience...',
            style: TextStyle(
              color: colorScheme.onBackground.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

