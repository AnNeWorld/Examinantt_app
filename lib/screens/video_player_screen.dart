import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  YoutubePlayerController? _ytController;
  VideoPlayerController? _nativeController;
  bool _isNativeVideo = false;
  bool _isNativeInitialized = false;
  String _activeVideoId = '';

  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

  String get _chatClassId {
    final clean = widget.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'video_$clean';
  }

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
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
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

  void _sendChatMessage(String currentUserName, String currentUid) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    _firestoreService.sendLiveClassChatMessage(
      liveClassId: _chatClassId,
      text: text,
      senderName: currentUserName.isNotEmpty ? currentUserName : 'Student',
      senderUid: currentUid,
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(dynamic timestamp, [String fallback = '']) {
    if (fallback.isNotEmpty) return fallback;
    if (timestamp == null) {
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      final minute = now.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    }
    DateTime date = DateTime.now();
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000F24) : AppTheme.backgroundLight;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700];

    final userProvider = Provider.of<UserProvider>(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? userProvider.user?.id ?? '';
    final currentUserName = userProvider.user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Student';

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
            color: isDark ? const Color(0xFF071938) : const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.live_tv_rounded, color: Color(0xFFFF7A00), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Smooth HD Stream • Tap open icon for YouTube App",
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.darkSlate, fontSize: 11.5, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs (Live Discussion & Doubts / Session Overview)
          Container(
            color: isDark ? const Color(0xFF071733) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF7A00),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFF7A00),
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('Live Discussion'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF10B981), size: 5),
                            SizedBox(width: 3),
                            Text(
                              'Real-time',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Session Overview'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveChatTab(currentUserName, currentUid, isDark, textColor),
                _buildOverviewTab(isDark, textColor, secondaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatTab(String currentUserName, String currentUid, bool isDark, Color textColor) {
    final subTextColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF071733) : Colors.white;

    return Column(
      children: [
        // Live chat banner with real-time indicators
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          color: isDark ? const Color(0xFF040D1C) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFFF7A00), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Live Student Discussion • Direct doubt solving with ${widget.instructor}',
                  style: TextStyle(color: subTextColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF10B981), size: 5),
                    SizedBox(width: 4),
                    Text(
                      'Real-time',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Messages Stream
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getLiveClassChatStream(_chatClassId),
            builder: (context, snapshot) {
              final liveMessages = snapshot.data ?? [];

              final List<Map<String, dynamic>> seedMessages = [
                {
                  'id': 'seed_mod_1',
                  'senderName': 'Examinant Moderator',
                  'isInstructor': true,
                  'isModerator': true,
                  'text': 'Welcome students! Keep your formula notebooks ready for live problem drills.',
                  'time': '10:00 AM',
                },
                {
                  'id': 'seed_stu_1',
                  'senderName': 'Aryan Sharma',
                  'isInstructor': false,
                  'text': "Good morning sir, ready for today's high-yield shortcuts!",
                  'time': '10:02 AM',
                },
                {
                  'id': 'seed_stu_2',
                  'senderName': 'Priya Verma',
                  'isInstructor': false,
                  'text': 'Audio and board clarity is excellent today 🚀',
                  'time': '10:04 AM',
                },
                {
                  'id': 'seed_stu_3',
                  'senderName': 'Rohan Gupta',
                  'isInstructor': false,
                  'text': 'Sir will the class PDF notes be available right after this stream?',
                  'time': '10:05 AM',
                },
              ];

              final List<Map<String, dynamic>> allMessages = [];
              allMessages.addAll(seedMessages);
              allMessages.addAll(liveMessages);

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: allMessages.length,
                itemBuilder: (context, index) {
                  final msg = allMessages[index];
                  return _buildMessageBubble(msg, currentUid, isDark, textColor);
                },
              );
            },
          ),
        ),

        // Chat Input Bar with Quick Doubt Chips
        _buildChatInputArea(currentUserName, currentUid, isDark, cardBg, textColor, subTextColor),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, String currentUid, bool isDark, Color textColor) {
    final senderName = (msg['senderName'] ?? 'Student').toString();
    final isMe = msg['senderUid'] == currentUid;
    final isInstructor = msg['isInstructor'] == true || senderName == widget.instructor;
    final isModerator = msg['isModerator'] == true || senderName.toLowerCase().contains('moderator');
    final text = (msg['text'] ?? '').toString();
    final timeStr = _formatMessageTime(msg['timestamp'], (msg['time'] ?? '').toString());

    Color nameColor = const Color(0xFF38BDF8); // Student Sky Blue
    if (isModerator) {
      nameColor = const Color(0xFFFF6B6B); // Moderator Coral/Red
    } else if (isInstructor) {
      nameColor = const Color(0xFFFF7A00); // Faculty Orange
    } else if (isMe) {
      nameColor = const Color(0xFF34D399); // My message Emerald
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isModerator
            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
            : (isInstructor
                ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF071938) : Colors.white)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isModerator
              ? const Color(0xFFEF4444).withValues(alpha: 0.45)
              : (isInstructor
                  ? const Color(0xFFFF7A00).withValues(alpha: 0.45)
                  : (isDark ? Colors.white12 : Colors.grey.shade200)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                senderName,
                style: TextStyle(
                  color: nameColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 6),
              if (isModerator)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('MODERATOR', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                )
              else if (isInstructor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('FACULTY', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                )
              else if (isMe)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea(
    String currentUserName,
    String currentUid,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickDoubtChips(currentUserName, currentUid, isDark),
          const SizedBox(height: 4),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                child: Text(
                  currentUserName.isNotEmpty ? currentUserName[0].toUpperCase() : 'S',
                  style: const TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00122C) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendChatMessage(currentUserName, currentUid),
                    style: TextStyle(color: textColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Ask a doubt or participate in discussion...',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A00), Color(0xFFFF9E00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                  onPressed: () => _sendChatMessage(currentUserName, currentUid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDoubtChips(String currentUserName, String currentUid, bool isDark) {
    final chips = [
      '👍 Audio & Board Clear',
      '❓ Please repeat once',
      '⚡ Formula doubt here',
      '🚀 Clear concept sir!',
      '📄 Where are PDF notes?',
      '✋ 1 question in step 2',
    ];

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final chip = chips[i];
          return InkWell(
            onTap: () {
              _chatController.text = chip;
              _sendChatMessage(currentUserName, currentUid);
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E38) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3557) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade800,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark, Color textColor, Color? secondaryTextColor) {
    return SingleChildScrollView(
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
                          fontSize: 12,
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
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Senior Subject Specialist • Examinantt Team',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12.5,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Real-time classroom session conducted by ${widget.instructor}. Keep your notebook ready and follow through concept explanations, previous year exam patterns, and problem solving steps.',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              height: 1.45,
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
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'No stream link has been configured for this class.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
