import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Make sure the user places their video here
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');
    
    try {
      await _videoController.initialize();
      _videoController.setLooping(false);
      _videoController.play();
      
      // Wait for the video to finish playing
      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration && !_hasNavigated) {
          _navigateNext();
        }
      });
      
      // Fallback in case video fails to finish for some reason
      Future.delayed(_videoController.value.duration + const Duration(seconds: 1), () {
        if (!_hasNavigated) _navigateNext();
      });
      
      setState(() {});
    } catch (e) {
      // Fallback if video is missing or fails to load
      debugPrint('Error loading splash video: $e');
      Future.delayed(const Duration(seconds: 2), () {
        if (!_hasNavigated) _navigateNext();
      });
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
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep authProvider warm to ensure session is fully restored
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Usually black for video splash
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              )
            : const CircularProgressIndicator(), // Fallback while loading
      ),
    );
  }
}
