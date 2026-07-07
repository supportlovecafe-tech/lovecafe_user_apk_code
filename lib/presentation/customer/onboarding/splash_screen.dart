import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
      await _controller.initialize();
      _controller.setLooping(false);
      
      _controller.addListener(_videoListener);
      
      setState(() {
        _isVideoInitialized = true;
      });
      
      if (kIsWeb) {
        await _controller.setVolume(0.0); // Web requires mute for autoplay
      }
      
      await _controller.play();
    } catch (e) {
      print("Error initializing video: $e");
      setState(() {
        _hasError = true;
      });
      // Fallback: wait a bit and navigate
      Future.delayed(const Duration(seconds: 2), _navigateNext);
    }
  }

  void _videoListener() {
    if (_controller.value.isInitialized && !_hasNavigated) {
      // Allow a tiny buffer (e.g. 50ms) to ensure it reaches the very end
      if (_controller.value.position >= _controller.value.duration && _controller.value.duration != Duration.zero) {
        _navigateNext();
      }
    }
  }

  void _navigateNext() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    if (mounted) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.AUTHENTICATED || authState.status == AuthStatus.GUEST) {
        context.go('/home');
      } else {
        context.go('/welcome');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_hasNavigated) {
        _controller.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isVideoInitialized) {
      _controller.removeListener(_videoListener);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep authProvider warm to ensure session is fully restored during video playback
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _isVideoInitialized && !_hasError
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : Center(
                child: _hasError 
                  ? Image.asset(
                      'assets/images/logo_transparent_refined.png',
                      width: 260,
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
              ),
      ),
    );
  }
}
