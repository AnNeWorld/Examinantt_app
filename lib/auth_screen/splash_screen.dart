import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../main.dart'; // To navigate to AuthWrapper
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _isNavigating = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Immersive mode for seamless full-screen video display
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset('assets/logo_video.mp4');
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      controller.setLooping(false);
      await controller.setVolume(1.0); // Full audio if video has sound
      await controller.play();

      setState(() {});
      FlutterNativeSplash.remove();

      // Listen to exact video completion
      controller.addListener(_videoListener);

      // Dynamic safety timer: allows the entire video to play completely
      final videoDuration = controller.value.duration;
      final safetyWait = videoDuration > Duration.zero
          ? videoDuration + const Duration(milliseconds: 300)
          : const Duration(seconds: 6);

      Future.delayed(safetyWait, () {
        if (mounted && !_isNavigating) {
          _navigateToNext();
        }
      });
    } catch (e) {
      debugPrint('[SplashScreen] Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        FlutterNativeSplash.remove();
        // Fallback timer if video cannot play
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_isNavigating) {
            _navigateToNext();
          }
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;

    if (!value.isInitialized) return;

    // When the video finishes playing all the way to the end
    if (value.position >= value.duration && value.duration > Duration.zero) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (_isNavigating) return;
    _isNavigating = true;

    // Restore standard status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    try {
      _controller?.removeListener(_videoListener);
    } catch (e) {
      debugPrint('[SplashScreen] Error removing listener: $e');
    }

    if (!mounted) return;

    // Smooth fade transition to next screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    } catch (_) {}

    try {
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF00122C),
      body: GestureDetector(
        onTap: _navigateToNext, // Tap anywhere to skip
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF00122C),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isInitialized && !_hasError)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (_hasError)
                _buildFallbackView()
              else
                const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                    ),
                  ),
                ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Examinantt',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
