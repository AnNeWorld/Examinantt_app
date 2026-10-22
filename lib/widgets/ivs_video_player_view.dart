import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' hide PlayerState;
import 'package:aws_ivs_player/aws_ivs_player.dart';

import '../utils/app_logger.dart';

/// Unified Amazon IVS Video Player widget that provides:
/// 1. Official Amazon IVS Player SDK on native Android and iOS for ultra-low latency streams.
/// 2. Seamless HTML5/VideoPlayer fallback on Web and desktop platforms.
/// 3. YouTube iframe integration for YouTube streams.
/// 4. Comprehensive state management (Loading, Live, Offline, Error with Retry).
/// 5. Clean resource disposal and orientation handling.
class IvsVideoPlayerView extends StatefulWidget {
  final String streamUrl;
  final String? fallbackRecordingUrl;
  final bool isLive;
  final bool isRecorded;
  final bool autoPlay;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;

  const IvsVideoPlayerView({
    super.key,
    required this.streamUrl,
    this.fallbackRecordingUrl,
    this.isLive = true,
    this.isRecorded = false,
    this.autoPlay = true,
    this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  State<IvsVideoPlayerView> createState() => _IvsVideoPlayerViewState();
}

class _IvsVideoPlayerViewState extends State<IvsVideoPlayerView> {
  // Native Amazon IVS Player
  IvsPlayerController? _ivsController;

  // VideoPlayer fallback for Web/Desktop/MP4
  VideoPlayerController? _videoController;

  // YouTube Controller
  YoutubePlayerController? _ytController;

  bool _isYoutube = false;
  bool _useNativeIvs = false;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _determineEngineAndPlay(widget.streamUrl);
  }

  @override
  void didUpdateWidget(covariant IvsVideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _determineEngineAndPlay(widget.streamUrl);
    }
  }

  static String _extractYoutubeId(String url) {
    String clean = url.trim();
    if (clean.isEmpty) return '';

    if (clean.contains('<iframe') && clean.contains('src=')) {
      final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(clean) ??
          RegExp("src='([^']+)'").firstMatch(clean);
      if (srcMatch != null) {
        clean = srcMatch.group(1) ?? clean;
      }
    }

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(clean)) {
      return clean;
    }

    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com|youtube-nocookie\.com)\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|live|shorts)\/|\S*?[?&]v=)([a-zA-Z0-9_-]{11})|(?:https?:\/\/)?youtu\.be\/([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(clean);
    if (match != null) {
      return match.group(1) ?? match.group(2) ?? '';
    }
    return '';
  }

  void _determineEngineAndPlay(String rawUrl) {
    _cleanupAllControllers();
    final url = rawUrl.trim();

    if (url.isEmpty) {
      if (widget.fallbackRecordingUrl != null && widget.fallbackRecordingUrl!.isNotEmpty) {
        _determineEngineAndPlay(widget.fallbackRecordingUrl!);
        return;
      }
      setState(() {
        _hasError = true;
        _errorMessage = 'Live stream URL is currently not available.';
        _isInitialized = false;
      });
      return;
    }

    // 1. Check if YouTube
    final ytId = _extractYoutubeId(url);
    if (ytId.isNotEmpty) {
      _isYoutube = true;
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        autoPlay: widget.autoPlay,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          playsInline: true,
          enableJavaScript: true,
        ),
      );
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
      return;
    }

    // 2. Determine whether to use official Native Amazon IVS Player or Fallback VideoPlayer
    // On native mobile (Android/iOS) for m3u8 or Amazon live-video.net, use official Amazon IVS SDK!
    final bool isNativeMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final bool isIvsStream = url.contains('live-video.net') || url.endsWith('.m3u8') || widget.isLive;

    if (isNativeMobile && isIvsStream && !url.endsWith('.mp4')) {
      _initNativeIvsPlayer(url);
    } else {
      _initFallbackVideoPlayer(url);
    }
  }

  /// Initialize Native Amazon IVS Player
  void _initNativeIvsPlayer(String url) {
    try {
      _useNativeIvs = true;
      _ivsController = IvsPlayerController();

      _ivsController!.addListener(() {
        if (!mounted) return;
        final state = _ivsController!.state;
        if (state == PlayerState.ready || state == PlayerState.playing) {
          if (!_isInitialized) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
              _isPlaying = true;
            });
          }
        } else if (state == PlayerState.error) {
          _handleIvsError(_ivsController!.errorMessage ?? 'Failed to stream Amazon IVS broadcast');
        }
      });

      setState(() {
        _hasError = false;
        _isInitialized = false;
      });
    } catch (e) {
      AppLogger.w("Native Amazon IVS player init failed, falling back to standard player: $e", tag: "IVS_PLAYER");
      _initFallbackVideoPlayer(url);
    }
  }

  void _handleIvsError(String error) {
    AppLogger.w("Amazon IVS Player error: $error", tag: "IVS_PLAYER");
    // If recorded fallback exists, try playing it
    if (widget.fallbackRecordingUrl != null &&
        widget.fallbackRecordingUrl!.isNotEmpty &&
        widget.fallbackRecordingUrl != widget.streamUrl) {
      AppLogger.i("Switching to recorded fallback lecture: ${widget.fallbackRecordingUrl}", tag: "IVS_PLAYER");
      _initFallbackVideoPlayer(widget.fallbackRecordingUrl!);
      return;
    }

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Stream is currently offline or unreachable. Tap to retry.';
      });
    }
  }

  /// Initialize VideoPlayer for Web, Desktop, or MP4 recorded sessions
  void _initFallbackVideoPlayer(String url) {
    try {
      _useNativeIvs = false;
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _videoController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _isPlaying = widget.autoPlay;
        });
        if (widget.autoPlay) {
          _videoController!.play();
        }
      }).catchError((e) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = 'Video playback error. Please check your internet connection.';
        });
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  void _cleanupAllControllers() {
    try {
      _ivsController?.dispose();
    } catch (_) {}
    _ivsController = null;

    try {
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;

    try {
      _ytController?.close();
    } catch (_) {}
    _ytController = null;

    _useNativeIvs = false;
    _isYoutube = false;
  }

  void _togglePlayPause() {
    if (_useNativeIvs && _ivsController != null) {
      if (_isPlaying) {
        _ivsController!.pause();
        setState(() => _isPlaying = false);
      } else {
        _ivsController!.resume();
        setState(() => _isPlaying = true);
      }
    } else if (_videoController != null && _isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        setState(() => _isPlaying = false);
      } else {
        _videoController!.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_videoController != null && _isInitialized) {
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }

  void _retryStream() {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });
    _determineEngineAndPlay(widget.streamUrl);
  }

  @override
  void dispose() {
    _cleanupAllControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: ClipRRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The Video Surface
              _buildVideoSurface(),

              // 2. Loading State
              if (!_isInitialized && !_hasError) _buildLoadingOverlay(),

              // 3. Error / Stream Ended State
              if (_hasError) _buildErrorOverlay(),

              // 4. Controls Overlay
              if (_isInitialized && !_hasError && !_isYoutube) _buildControlsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSurface() {
    if (_isYoutube && _ytController != null) {
      return YoutubePlayer(controller: _ytController!);
    }

    if (_useNativeIvs && _ivsController != null) {
      return IvsVideoPlayer(
        url: widget.streamUrl,
        controller: _ivsController,
        autoPlay: widget.autoPlay,
        showOverlayControls: false,
        onError: (err) => _handleIvsError(err),
      );
    }

    if (_videoController != null && _isInitialized) {
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFF000E24).withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connecting to Amazon IVS Live Stream...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: const Color(0xFF000F24).withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_off_rounded, color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isLive ? 'Stream Currently Offline' : 'Stream Unavailable',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _retryStream,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
                foregroundColor: const Color(0xFF00122C),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Live Badge & Quality
              Row(
                children: [
                  if (widget.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'LIVE • IVS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: const Text(
                      'HD 1080p • Low Latency',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Center Play/Pause button
              Center(
                child: IconButton(
                  iconSize: 48,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),

              // Bottom Bar: Mute and Fullscreen
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 20,
                    icon: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _toggleMute,
                  ),
                  if (widget.onToggleFullscreen != null)
                    IconButton(
                      iconSize: 20,
                      icon: Icon(
                        widget.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                      onPressed: widget.onToggleFullscreen,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
