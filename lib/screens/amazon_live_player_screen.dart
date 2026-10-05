import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_models.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import 'checkout_screen.dart';
import 'pdf_viewer_screen.dart';

class AmazonLivePlayerScreen extends StatefulWidget {
  final LiveClass liveClass;

  const AmazonLivePlayerScreen({
    super.key,
    required this.liveClass,
  });

  @override
  State<AmazonLivePlayerScreen> createState() => _AmazonLivePlayerScreenState();
}

class _AmazonLivePlayerScreenState extends State<AmazonLivePlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _isFullscreen = false;
  bool _hasError = false;
  String _errorMessage = '';

  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF000F24) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF071733) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : AppTheme.darkSlate;
  Color get _subTextColor => _isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLiveStream();
  }

  void _initLiveStream() {
    final streamUrl = widget.liveClass.videoUrl.trim();
    if (streamUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Live stream link is not available yet. Please check back at scheduled time.';
      });
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            _controller?.play();
          }
        }).catchError((error) {
          debugPrint("[AmazonLivePlayerScreen] Video init error: $error");
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Unable to connect to live stream. Checking connection...';
            });
          }
        });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video stream: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _sendChatMessage(String currentUserName, String currentUid) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    _firestoreService.sendLiveClassChatMessage(
      liveClassId: widget.liveClass.id,
      text: text,
      senderName: currentUserName.isNotEmpty ? currentUserName : 'Student',
      senderUid: currentUid,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          title: widget.liveClass.title,
          price: widget.liveClass.price,
          originalPrice: widget.liveClass.originalPrice,
          itemType: 'Live Class',
          itemId: widget.liveClass.id,
          subtitle: 'Live Interactive Session by ${widget.liveClass.instructor}',
          features: [
            'Full HD Live Interactive Stream (Amazon AWS IVS)',
            'Real-Time Live Chat & Doubt Clearance',
            'Downloadable PDF Class Handouts & Annotated Notes',
            'Lifetime Unlimited Access to Lecture Recording',
          ],
          onPaymentSuccess: () {
            AppTheme.showSuccessSnackBar(context, 'Live Class Access Granted! 🎉');
            setState(() {
              _initLiveStream();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? userProvider.user?.id ?? '';
    final currentUserName = userProvider.user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Student';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getUserPurchasesStream(),
      builder: (context, purchasesSnap) {
        final purchases = purchasesSnap.data ?? [];
        final purchasedItemIds = purchases
            .map((p) => (p['itemId'] ?? p['id'] ?? '').toString())
            .toSet();
        final purchasedBatchIds = purchases
            .where((p) => (p['type'] ?? '').toString().toLowerCase().contains('batch'))
            .map((p) => (p['itemId'] ?? p['id'] ?? '').toString())
            .toSet();

        final bool isAuthorized = widget.liveClass.isUserEnrolled(
          uid: currentUid,
          purchasedBatchIds: purchasedBatchIds,
          purchasedItemIds: purchasedItemIds,
        );

        if (_isFullscreen) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Center(child: _buildVideoPlayerArea(isAuthorized)),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 28),
                    onPressed: _toggleFullscreen,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: _scaffoldBg,
          appBar: AppBar(
            backgroundColor: _cardBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 6),
                          SizedBox(width: 4),
                          Text('AMAZON IVS LIVE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.liveClass.title,
                        style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'By ${widget.liveClass.instructor} • ${widget.liveClass.subject}',
                  style: TextStyle(color: _subTextColor, fontSize: 10),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Video Player Section
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildVideoPlayerArea(isAuthorized),
              ),

              // Classroom Tabs (Chat / Notes & Details)
              Container(
                color: _cardBg,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFF7A00),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFFF7A00),
                  unselectedLabelColor: _subTextColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Live Doubts & Chat'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Class Details & Notes'),
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
                    _buildLiveChatTab(currentUserName, currentUid, isAuthorized),
                    _buildClassDetailsTab(context, isAuthorized),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayerArea(bool isAuthorized) {
    if (!isAuthorized) {
      return Container(
        color: const Color(0xFF000F24),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: Color(0xFFFF7A00), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Premium Live Class',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join this exclusive Amazon AWS live stream with doubt clearing for ₹${widget.liveClass.price.toStringAsFixed(0)}.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _openCheckout(context),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text('Enroll Now (₹${widget.liveClass.price.toStringAsFixed(0)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: const Color(0xFF000F24),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 36),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isInitialized = false;
                    });
                    _initLiveStream();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: const Color(0xFF000F24),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF7A00)),
              SizedBox(height: 10),
              Text(
                'Connecting to Amazon IVS Live Stream...',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),

          // Stream Control Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 20),
                    onPressed: _toggleMute,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.liveClass.activeViewers.isNotEmpty ? widget.liveClass.activeViewers : "1.2k"} Watching',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: 22),
                    onPressed: _toggleFullscreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatTab(String currentUserName, String currentUid, bool isAuthorized) {
    return Column(
      children: [
        // Live chat banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: _isDark ? const Color(0xFF051124) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFFF7A00), size: 15),
              const SizedBox(width: 6),
              Text(
                'Live Doubts Chat • Direct interaction with ${widget.liveClass.instructor}',
                style: TextStyle(color: _subTextColor, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Chat Messages Stream
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getLiveClassChatStream(widget.liveClass.id),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: _subTextColor.withValues(alpha: 0.4), size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Live Chat is Open!',
                        style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ask questions and doubts directly to the faculty.',
                        style: TextStyle(color: _subTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderUid'] == currentUid;
                  final isInstructor = msg['isInstructor'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isInstructor
                          ? const Color(0xFFFF7A00).withValues(alpha: 0.15)
                          : (_isDark ? const Color(0xFF071938) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isInstructor
                            ? const Color(0xFFFF7A00)
                            : (_isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isInstructor
                              ? const Color(0xFFFF7A00)
                              : (isMe ? const Color(0xFF38BDF8) : Colors.grey.shade400),
                          child: Text(
                            (msg['senderName'] ?? 'S').toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    msg['senderName'] ?? 'Student',
                                    style: TextStyle(
                                      color: isInstructor ? const Color(0xFFFF7A00) : _textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isInstructor) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF7A00),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text('FACULTY', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(color: _textColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border(top: BorderSide(color: _isDark ? Colors.white12 : Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF00122C) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _chatController,
                    onSubmitted: (_) => _sendChatMessage(currentUserName, currentUid),
                    style: TextStyle(color: _textColor, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: isAuthorized ? 'Ask a doubt or message...' : 'Enroll to chat with faculty',
                      hintStyle: TextStyle(color: _subTextColor, fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    enabled: isAuthorized,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFFFF7A00), size: 20),
                onPressed: isAuthorized ? () => _sendChatMessage(currentUserName, currentUid) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassDetailsTab(BuildContext context, bool isAuthorized) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Faculty Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: widget.liveClass.color.withValues(alpha: 0.2),
                child: Text(
                  widget.liveClass.instructor.isNotEmpty ? widget.liveClass.instructor[0] : 'E',
                  style: TextStyle(color: widget.liveClass.color, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.liveClass.instructor,
                      style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.liveClass.qualification,
                      style: TextStyle(color: _subTextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.liveClass.subject} • ${widget.liveClass.examCategory}',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Session Specs Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Overview',
                style: TextStyle(color: _textColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSpecRow(Icons.schedule_rounded, 'Duration', '${widget.liveClass.durationMinutes} Minutes'),
              _buildSpecRow(Icons.event_available_rounded, 'Class Time', widget.liveClass.time),
              _buildSpecRow(Icons.cloud_done_rounded, 'Streaming Infrastructure', widget.liveClass.streamServer),
              _buildSpecRow(Icons.library_books_rounded, 'Chapter / Topic', widget.liveClass.chapter),
              if (widget.liveClass.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.liveClass.description,
                  style: TextStyle(color: _subTextColor, fontSize: 11.5, height: 1.4),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Download Class PDF Notes Button
        if (widget.liveClass.notesUrl.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      pdfData: ResourceItem(
                        id: 'notes_${widget.liveClass.id}',
                        title: '${widget.liveClass.title} - Lecture Handout',
                        subtitle: '${widget.liveClass.subject} • Live Class Notes',
                        category: widget.liveClass.subject,
                        subject: widget.liveClass.subject,
                        type: 'Notes',
                        fileType: 'PDF',
                        fileSize: '3.4 MB',
                        badge: 'INCLUDED',
                        badgeColorHex: '#10B981',
                        downloads: '1.2k',
                        rating: 4.9,
                        exam: widget.liveClass.examCategory,
                        price: 0.0,
                        isPublic: true,
                        description: 'Official verified faculty class presentation and annotated lecture notes.',
                        url: widget.liveClass.notesUrl,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Download Session PDF Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF7A00)),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: _subTextColor, fontSize: 11.5)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
