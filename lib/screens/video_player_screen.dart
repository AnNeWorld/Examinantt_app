import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String instructor;
  final bool isLive;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.instructor = 'Examinantt Educator',
    this.isLive = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _ytController;
  VideoPlayerController? _nativeController;
  bool _isNativeVideo = false;
  bool _isNativeInitialized = false;
  String _activeVideoId = '';

  static String extractVideoId(String url) {
    String clean = url.trim();
    if (clean.isEmpty) return '';

    // If an entire iframe tag was pasted from YouTube embed
    if (clean.contains('<iframe') && clean.contains('src=')) {
      final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(clean) ??
          RegExp("src='([^']+)'").firstMatch(clean);
      if (srcMatch != null) {
        clean = srcMatch.group(1) ?? clean;
      }
    }

    // Direct 11-char ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(clean)) {
      return clean;
    }

    // Matches youtube.com, youtube-nocookie.com, youtu.be, m.youtube.com
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

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl.trim();
    final videoId = extractVideoId(url);

    if (videoId.isNotEmpty) {
      _isNativeVideo = false;
      _activeVideoId = videoId;
      _initYoutubePlayer(videoId);
    } else if (url.contains('.mp4') || url.contains('.m3u8') || (url.startsWith('http') && !url.contains('youtu'))) {
      _isNativeVideo = true;
      _initNativePlayer(url);
    } else {
      _isNativeVideo = false;
      _activeVideoId = '';
    }
  }

  void _initYoutubePlayer(String videoId) {
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        playsInline: true,
        enableJavaScript: true,
      ),
    );
  }

  void _initNativePlayer(String url) {
    _nativeController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isNativeInitialized = true;
          });
          _nativeController?.play();
        }
      }).catchError((err) {
        debugPrint("Native video player error: $err");
      });
  }

  @override
  void dispose() {
    _ytController?.close();
    _nativeController?.dispose();
    super.dispose();
  }

  Future<void> _openExternalVideo() async {
    final rawUrl = widget.videoUrl.trim();
    final targetUrl = _activeVideoId.isNotEmpty
        ? 'https://www.youtube.com/watch?v=$_activeVideoId'
        : rawUrl;

    if (targetUrl.isEmpty) return;
    final uri = Uri.parse(targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000F24) : AppTheme.backgroundLight;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDark ? const Color(0xFF071733) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFFFF7A00)),
            tooltip: 'Watch in YouTube App',
            onPressed: _openExternalVideo,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Container
          Container(
            width: double.infinity,
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildVideoView(),
            ),
          ),

          // External Watch Banner
          Container(
            width: double.infinity,
            color: const Color(0xFF071938),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.live_tv_rounded, color: Color(0xFFFF7A00), size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Smooth HD Stream • Tap open icon for YouTube App",
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: _openExternalVideo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFF7A00)),
                    ),
                    child: const Text(
                      'Open YouTube',
                      style: TextStyle(color: Color(0xFFFF7A00), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 7),
                              SizedBox(width: 4),
                              Text(
                                'LIVE NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.isLive ? 'Real-Time Class' : 'Recorded Lecture',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF071938) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFFF7A00),
                          child: Text(
                            widget.instructor.isNotEmpty ? widget.instructor[0].toUpperCase() : 'E',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.instructor,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Senior Subject Specialist • Examinantt Team',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About This Session',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time classroom session conducted by ${widget.instructor}. Keep your notebook ready and follow through concept explanations, previous year exam patterns, and problem solving steps.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (_isNativeVideo && _nativeController != null) {
      if (!_isNativeInitialized) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)));
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_nativeController!),
          IconButton(
            icon: Icon(
              _nativeController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 50,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            onPressed: () {
              setState(() {
                _nativeController!.value.isPlaying ? _nativeController!.pause() : _nativeController!.play();
              });
            },
          ),
        ],
      );
    }

    if (_ytController != null) {
      return YoutubePlayer(controller: _ytController!, aspectRatio: 16 / 9);
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 42),
          SizedBox(height: 8),
          Text(
            'Video Stream Currently Unavailable',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'No stream link has been configured for this class.',
            style: TextStyle(color: Colors.white54, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
