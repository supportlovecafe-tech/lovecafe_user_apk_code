import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Show the splash screen for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted || _hasNavigated) return;
    
    // Fade out the splash screen
    await _animationController.forward();
    
    _navigateNext();
  }

  void _navigateNext() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    if (mounted) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.AUTHENTICATED || authState.status == AuthStatus.GUEST) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep authProvider warm to ensure session is fully restored
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Image.asset(
            'assets/logo_transparent.png',
            width: 260,
            height: 260,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
