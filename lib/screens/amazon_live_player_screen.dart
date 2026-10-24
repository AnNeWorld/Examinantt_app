import 'package:examinantt_app/utils/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/content_models.dart';
import '../models/live_class_session_models.dart';
import '../services/firestore_service.dart';
import '../services/ivs_live_service.dart';
import '../services/ivs_chat_service.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/ivs_video_player_view.dart';
import 'checkout_screen.dart';
import 'pdf_viewer_screen.dart';
import 'jitsi_live_meeting_screen.dart';

/// Screen for Amazon IVS Live Class playback and real-time interactive IVS Chat.
class AmazonLivePlayerScreen extends StatefulWidget {
  final LiveClass liveClass;
  final LiveClassAccessSession? accessSession;

  const AmazonLivePlayerScreen({
    super.key,
    required this.liveClass,
    this.accessSession,
  });

  @override
  State<AmazonLivePlayerScreen> createState() => _AmazonLivePlayerScreenState();
}

class _AmazonLivePlayerScreenState extends State<AmazonLivePlayerScreen>
    with SingleTickerProviderStateMixin {
  LiveClassAccessSession? _accessSession;
  bool _isAuthorizing = false;
  String? _authorizationError;

  bool _isGoogleMeetOrZoom = false;
  bool _isFullscreen = false;
  bool _isFullscreenChatOpen = false;

  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final IvsLiveService _ivsLiveService = IvsLiveService();
  IvsChatService? _chatService;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF000F24) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF071733) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : AppTheme.darkSlate;
  Color get _subTextColor => _isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _accessSession = widget.accessSession;
    _checkMeetingLinks();

    if (!widget.liveClass.isJitsi && widget.liveClass.roomName.isEmpty) {
      // If accessSession wasn't passed, request join access from backend
      if (_accessSession == null) {
        _requestJoinSession();
      } else {
        _initChat();
      }
    }
  }

  void _checkMeetingLinks() {
    if (widget.liveClass.isJitsi || widget.liveClass.roomName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppNavigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => JitsiLiveMeetingScreen(
                liveClass: widget.liveClass,
                sessionId: widget.liveClass.id,
                roomName: widget.liveClass.roomName,
              ),
            ),
          );
        }
      });
      return;
    }

    final streamUrl = widget.liveClass.videoUrl.trim();
    if (widget.liveClass.isGoogleMeet ||
        widget.liveClass.isZoom ||
        streamUrl.contains('meet.google.com') ||
        streamUrl.contains('zoom.us')) {
      _isGoogleMeetOrZoom = true;
    }
  }

  Future<void> _requestJoinSession() async {
    setState(() {
      _isAuthorizing = true;
      _authorizationError = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? userProvider.user?.id;
      final name = userProvider.user?.name ?? FirebaseAuth.instance.currentUser?.displayName;

      final session = await _ivsLiveService.requestJoinAccess(
        liveClass: widget.liveClass,
        currentUid: uid,
        currentUserName: name,
      );

      if (!mounted) return;

      setState(() {
        _accessSession = session;
        _isAuthorizing = false;
        if (!session.isAuthorized) {
          _authorizationError = session.message ?? 'Access not authorized for this session.';
        }
      });

      if (session.isAuthorized) {
        _initChat();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthorizing = false;
        _authorizationError = 'Failed to authorize live session: $e';
      });
    }
  }

  void _initChat() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? userProvider.user?.id ?? 'anon_user';
    final name = userProvider.user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Student';
    final avatar = userProvider.profileImage ?? '';

    _chatService?.dispose();
    _chatService = IvsChatService(
      liveClassId: widget.liveClass.id,
      awsRegion: _accessSession?.awsRegion ?? widget.liveClass.awsRegion,
      chatRoomArn: _accessSession?.chatRoomArn ?? widget.liveClass.chatRoomArn,
      chatToken: _accessSession?.chatToken ?? widget.liveClass.chatToken,
      currentUserId: uid,
      currentUserName: name,
      currentUserAvatar: avatar,
      onRefreshToken: () => _ivsLiveService.refreshChatToken(
        classId: widget.liveClass.id,
        chatRoomArn: _accessSession?.chatRoomArn ?? widget.liveClass.chatRoomArn,
        currentUid: uid,
      ),
    );

    _chatService!.addListener(_onChatUpdated);
    _chatService!.connect();
  }

  void _onChatUpdated() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty || _chatService == null) return;

    _chatController.clear();
    _chatService!.sendMessage(text);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (!_isFullscreen) {
        _isFullscreenChatOpen = false;
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  void _openCheckout(BuildContext context) {
    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          title: widget.liveClass.title,
          price: widget.liveClass.price,
          originalPrice: widget.liveClass.originalPrice,
          itemType: 'Live Class',
          itemId: widget.liveClass.id,
          subtitle: 'Live Interactive Session by ${widget.liveClass.instructor}',
          features: const [
            'Full HD Live Interactive Stream (Amazon AWS IVS)',
            'Real-Time Live Chat & Doubt Clearance',
            'Downloadable PDF Class Handouts & Annotated Notes',
            'Lifetime Unlimited Access to Lecture Recording',
          ],
          onPaymentSuccess: () {
            AppTheme.showSuccessSnackBar(context, 'Live Class Access Granted! 🎉');
            _requestJoinSession();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatService?.removeListener(_onChatUpdated);
    _chatService?.dispose();
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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

        final bool isAuthorized = _accessSession?.isAuthorized ??
            widget.liveClass.isUserEnrolled(
              uid: currentUid,
              purchasedBatchIds: purchasedBatchIds,
              purchasedItemIds: purchasedItemIds,
            );

        if (_isFullscreen) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Row(
                  children: [
                    Expanded(child: Center(child: _buildVideoPlayerArea(isAuthorized))),
                    if (_isFullscreenChatOpen)
                      Container(
                        width: 320,
                        color: const Color(0xFF071326),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              color: const Color(0xFF030A17),
                              child: Row(
                                children: [
                                  const Icon(Icons.forum_rounded, color: Color(0xFFFF7A00), size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Live Student Discussion',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                                    onPressed: () => setState(() => _isFullscreenChatOpen = false),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: _buildChatMessagesList(currentUid)),
                            _buildChatInputArea(currentUserName, currentUid, isAuthorized),
                          ],
                        ),
                      ),
                  ],
                ),
                Positioned(
                  top: 14,
                  right: _isFullscreenChatOpen ? 334 : 14,
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _isFullscreenChatOpen = !_isFullscreenChatOpen),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isFullscreenChatOpen
                                  ? const Color(0xFFFF7A00)
                                  : Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isFullscreenChatOpen ? 'Hide Chat' : 'Live Chat',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 28),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
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
                          Text('AMAZON IVS LIVE', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.liveClass.title,
                        style: TextStyle(color: _textColor, fontSize: 15.5, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'By ${widget.liveClass.instructor} • ${widget.liveClass.subject}',
                  style: TextStyle(color: _subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Video Player Section
              _buildVideoPlayerArea(isAuthorized),

              // Website-style Instructor & Active Audience Bar
              _buildStreamSubHeader(),

              // Classroom Tabs (Live Discussion / Class Details & Notes)
              Container(
                color: _cardBg,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFF7A00),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFFF7A00),
                  unselectedLabelColor: _subTextColor,
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
                          _buildChatStatusBadge(),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 16),
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

  Widget _buildChatStatusBadge() {
    final status = _chatService?.status ?? IvsChatConnectionStatus.disconnected;
    Color color;
    String text;

    switch (status) {
      case IvsChatConnectionStatus.connected:
        color = const Color(0xFF10B981);
        text = 'Active';
        break;
      case IvsChatConnectionStatus.connecting:
      case IvsChatConnectionStatus.reconnecting:
        color = const Color(0xFFF59E0B);
        text = 'Connecting';
        break;
      case IvsChatConnectionStatus.error:
      case IvsChatConnectionStatus.disconnected:
        color = const Color(0xFFEF4444);
        text = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 5),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerArea(bool isAuthorized) {
    if (_isAuthorizing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF000F24),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Authorizing Amazon IVS Stream...',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Requesting stream token & room authorization',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isAuthorized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
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
                    'Enrollment Required',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _authorizationError ??
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
        ),
      );
    }

    // Google Meet / Zoom alternative
    if (_isGoogleMeetOrZoom) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF071326),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 10),
              Text(
                widget.liveClass.title,
                style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.liveClass.instructor} • Live Interactive Classroom',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (widget.liveClass.isJitsi || widget.liveClass.roomName.isNotEmpty) {
                    AppNavigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JitsiLiveMeetingScreen(
                          liveClass: widget.liveClass,
                          sessionId: widget.liveClass.id,
                          roomName: widget.liveClass.roomName,
                        ),
                      ),
                    );
                    return;
                  }

                  final rawUrl = widget.liveClass.videoUrl.trim();
                  final uri = Uri.tryParse(rawUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text('Join Live Class Directly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Official Amazon IVS Player View
    final effectivePlaybackUrl = (_accessSession != null && _accessSession!.playbackUrl.isNotEmpty)
        ? _accessSession!.playbackUrl
        : widget.liveClass.videoUrl;

    return IvsVideoPlayerView(
      streamUrl: effectivePlaybackUrl,
      fallbackRecordingUrl: widget.liveClass.recordingUrl,
      isLive: widget.liveClass.isLive,
      isRecorded: widget.liveClass.isRecorded,
      isFullscreen: _isFullscreen,
      onToggleFullscreen: _toggleFullscreen,
    );
  }

  Widget _buildStreamSubHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _cardBg,
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: widget.liveClass.color.withValues(alpha: 0.2),
            child: Text(
              widget.liveClass.instructor.isNotEmpty ? widget.liveClass.instructor[0] : 'E',
              style: TextStyle(
                color: widget.liveClass.color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.liveClass.instructor,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.liveClass.qualification,
                  style: TextStyle(color: _subTextColor, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, color: Color(0xFFEF4444), size: 13),
                const SizedBox(width: 4),
                Text(
                  '${widget.liveClass.activeViewers.isNotEmpty ? widget.liveClass.activeViewers : "120"} live',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatTab(String currentUserName, String currentUid, bool isAuthorized) {
    return Column(
      children: [
        // Live chat banner with real-time indicators
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          color: _isDark ? const Color(0xFF040D1C) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFFF7A00), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Amazon IVS Chat • Direct doubts with ${widget.liveClass.instructor}',
                  style: TextStyle(color: _subTextColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_chatService?.status == IvsChatConnectionStatus.error)
                InkWell(
                  onTap: () => _chatService?.retry(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Tap to reconnect', style: TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),

        // Chat Messages List
        Expanded(
          child: _buildChatMessagesList(currentUid),
        ),

        // Chat Input Bar with Quick Doubt Chips
        _buildChatInputArea(currentUserName, currentUid, isAuthorized),
      ],
    );
  }

  Widget _buildChatMessagesList(String currentUid) {
    final messages = _chatService?.messages ?? [];

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 40, color: _subTextColor.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              Text(
                'Live Chat is Ready',
                style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to ask a doubt or greet the faculty!',
                style: TextStyle(color: _subTextColor, fontSize: 11.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildIvsMessageBubble(msg, currentUid);
      },
    );
  }

  Widget _buildIvsMessageBubble(IvsChatMessage msg, String currentUid) {
    final isMe = msg.isSelf || msg.senderId == currentUid;
    final isInstructor = msg.isInstructor || msg.senderName == widget.liveClass.instructor;
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    Color nameColor = const Color(0xFF38BDF8);
    if (isInstructor) {
      nameColor = const Color(0xFFFF7A00);
    } else if (isMe) {
      nameColor = const Color(0xFF34D399);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isInstructor
            ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
            : (_isDark ? const Color(0xFF071938) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isInstructor
              ? const Color(0xFFFF7A00).withValues(alpha: 0.3)
              : (_isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isMe ? 'You' : msg.senderName,
                style: TextStyle(
                  color: nameColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (isInstructor) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'FACULTY',
                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(color: _subTextColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            msg.text,
            style: TextStyle(
              color: _textColor,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea(String currentUserName, String currentUid, bool isAuthorized) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      color: _cardBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuthorized) ...[
            _buildQuickDoubtChips(isAuthorized),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF00122C) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: _isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => isAuthorized ? _sendChatMessage() : null,
                    style: TextStyle(color: _textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isAuthorized ? 'Ask doubt to instructor or chat...' : 'Enroll to chat with faculty',
                      hintStyle: TextStyle(color: _subTextColor, fontSize: 11.5),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    enabled: isAuthorized,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: isAuthorized
                      ? const LinearGradient(
                          colors: [Color(0xFFFF7A00), Color(0xFFFF9E00)],
                        )
                      : null,
                  color: isAuthorized ? null : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  boxShadow: isAuthorized
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                  onPressed: isAuthorized ? _sendChatMessage : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDoubtChips(bool isAuthorized) {
    final chips = [
      '👍 Audio & Board Clear',
      '❓ Please repeat once',
      '⚡ Formula doubt here',
      '🚀 Concept clear sir!',
      '📝 Taking notes',
    ];

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final chip = chips[i];
          return InkWell(
            onTap: isAuthorized
                ? () {
                    _chatController.text = chip;
                    _sendChatMessage();
                  }
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F1E38) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDark ? const Color(0xFF1E3557) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  color: _isDark ? const Color(0xFF94A3B8) : Colors.grey.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
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
                      style: TextStyle(color: _textColor, fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.liveClass.qualification,
                      style: TextStyle(color: _subTextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.liveClass.subject} • ${widget.liveClass.examCategory}',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5, fontWeight: FontWeight.bold),
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
                style: TextStyle(color: _textColor, fontSize: 15.5, fontWeight: FontWeight.bold),
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
                  style: TextStyle(color: _subTextColor, fontSize: 13, height: 1.4),
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
                AppNavigator.push(
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
          Text('$label: ', style: TextStyle(color: _subTextColor, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
