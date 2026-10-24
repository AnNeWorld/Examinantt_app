import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_models.dart';
import '../models/jitsi_live_models.dart';
import '../services/jitsi_live_service.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_logger.dart';
import '../services/live_class_api.dart';
import 'pdf_viewer_screen.dart';

/// Full-featured Jitsi Live Classroom Meeting Screen for Students.
/// Synchronizes in real-time with the teacher on the website:
/// - Joins the exact same meeting room and server domain.
/// - Obtains authorized RSA-256 JWT tokens securely from backend without exposing secrets.
/// - Manages 4-state classroom lifecycle: Scheduled (Waiting) -> Live (Active) -> Ended.
/// - Automatic 15s background polling to auto-transition students when teacher goes live.
class JitsiLiveMeetingScreen extends StatefulWidget {
  final LiveClass? liveClass;
  final JitsiLiveSession? session;
  final String sessionId;
  final String? roomName;

  const JitsiLiveMeetingScreen({
    super.key,
    this.liveClass,
    this.session,
    required this.sessionId,
    this.roomName,
  });

  @override
  State<JitsiLiveMeetingScreen> createState() => _JitsiLiveMeetingScreenState();
}

class _JitsiLiveMeetingScreenState extends State<JitsiLiveMeetingScreen> with TickerProviderStateMixin {
  final JitsiLiveService _jitsiService = JitsiLiveService();

  JitsiClassroomState _classroomState = JitsiClassroomState.initial;
  JitsiLiveSession? _currentSession;
  JitsiLiveTokenInfo? tokenInfo;

  String? _errorMessage;
  bool _isAudioMuted = true;
  bool _isVideoMuted = true;
  int _participantCount = 1;

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  Timer? _elapsedTimer;
  Timer? _attendanceHeartbeatTimer;
  String? _joinedUid;
  String? _joinedStudentName;
  Duration _sessionElapsed = Duration.zero;
  bool _isJoinOperationInProgress = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeClassroom();
  }

  @override
  void dispose() {
    _isJoinOperationInProgress = false;
    _recordStudentAttendanceLeft();
    _firestoreSubscription?.cancel();
    _jitsiService.stopSessionPolling();
    _elapsedTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HOST ATTENDANCE & PARTICIPANT SYNCHRONIZATION
  // ---------------------------------------------------------------------------

  Future<void> _recordStudentAttendanceJoined({
    required String uid,
    required String name,
    required String email,
  }) async {
    _joinedUid = uid;
    _joinedStudentName = name;
    final sessionId = widget.sessionId;
    if (sessionId.isEmpty || uid.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. live_classes/{sessionId}/attendance/{uid}
      final attendanceDoc = FirebaseFirestore.instance
          .collection('live_classes')
          .doc(sessionId)
          .collection('attendance')
          .doc(uid);
      batch.set(attendanceDoc, {
        'uid': uid,
        'studentName': name,
        'name': name,
        'email': email,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'platform': 'app',
        'status': 'online',
        'role': 'student',
      }, SetOptions(merge: true));

      // 2. live_classes/{sessionId}/participants/{uid}
      final participantDoc = FirebaseFirestore.instance
          .collection('live_classes')
          .doc(sessionId)
          .collection('participants')
          .doc(uid);
      batch.set(participantDoc, {
        'uid': uid,
        'name': name,
        'studentName': name,
        'email': email,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'status': 'online',
        'role': 'student',
      }, SetOptions(merge: true));

      // 3. live_classes/{sessionId} main document
      final classDoc = FirebaseFirestore.instance.collection('live_classes').doc(sessionId);
      batch.set(classDoc, {
        'activeViewers': FieldValue.increment(1),
        'enrolledStudentIds': FieldValue.arrayUnion([uid]),
        'activeParticipants': FieldValue.arrayUnion([name]),
        'lastStudentJoined': name,
        'lastStudentJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      AppLogger.s('Student joined live class registered for host: $name ($uid)', tag: 'JITSI_SCREEN');

      // Heartbeat ping every 25 seconds
      _attendanceHeartbeatTimer?.cancel();
      _attendanceHeartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendAttendanceHeartbeat(sessionId, uid);
      });
    } catch (e) {
      AppLogger.w('Attendance registration error: $e', tag: 'JITSI_SCREEN');
    }
  }

  void _sendAttendanceHeartbeat(String sessionId, String uid) {
    try {
      FirebaseFirestore.instance
          .collection('live_classes')
          .doc(sessionId)
          .collection('attendance')
          .doc(uid)
          .set({'lastActiveAt': FieldValue.serverTimestamp(), 'status': 'online'}, SetOptions(merge: true));

      FirebaseFirestore.instance
          .collection('live_classes')
          .doc(sessionId)
          .collection('participants')
          .doc(uid)
          .set({'lastActiveAt': FieldValue.serverTimestamp(), 'isOnline': true}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _recordStudentAttendanceLeft() async {
    _attendanceHeartbeatTimer?.cancel();
    _attendanceHeartbeatTimer = null;

    final uid = _joinedUid;
    final name = _joinedStudentName;
    final sessionId = widget.sessionId;
    if (uid == null || uid.isEmpty || sessionId.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final attendanceDoc = FirebaseFirestore.instance
          .collection('live_classes')
          .doc(sessionId)
          .collection('attendance')
          .doc(uid);
      batch.set(attendanceDoc, {
        'status': 'left',
        'leftAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final participantDoc = FirebaseFirestore.instance
          .collection('live_classes')
          .doc(sessionId)
          .collection('participants')
          .doc(uid);
      batch.set(participantDoc, {
        'isOnline': false,
        'leftAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final classDoc = FirebaseFirestore.instance.collection('live_classes').doc(sessionId);
      batch.set(classDoc, {
        'activeViewers': FieldValue.increment(-1),
        if (name != null && name.isNotEmpty) 'activeParticipants': FieldValue.arrayRemove([name]),
      }, SetOptions(merge: true));

      await batch.commit();
      AppLogger.i('Student left session logged in Firestore: $uid', tag: 'JITSI_SCREEN');
    } catch (e) {
      AppLogger.w('Error logging student exit: $e', tag: 'JITSI_SCREEN');
    }
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE INITIALIZATION
  // ---------------------------------------------------------------------------

  Future<void> _initializeClassroom() async {
    setState(() {
      _classroomState = JitsiClassroomState.initial;
      _errorMessage = null;
    });

    try {
      // 1. Resolve Session Metadata immediately
      JitsiLiveSession? session = widget.session;

      // If LiveClass is passed directly, use it instantly (0ms delay!)
      if (session == null && widget.liveClass != null) {
        final lc = widget.liveClass!;
        final websiteRoom = JitsiLiveConfig.calculateWebsiteRoomName(
          roomName: lc.roomName.isNotEmpty ? lc.roomName : widget.roomName,
          classId: lc.id,
        );
        session = JitsiLiveSession(
          id: lc.id,
          courseId: lc.batchId,
          courseTitle: lc.batchName,
          title: lc.title,
          description: lc.description,
          instructorName: lc.instructor,
          status: lc.isLive ? 'live' : (lc.isRecorded ? 'completed' : 'scheduled'),
          roomName: websiteRoom,
          durationMinutes: lc.durationMinutes,
          recordingUrl: lc.recordingUrl,
        );
      }

      // If still null or room was empty, do a quick direct Firestore lookup
      if (session == null || session.roomName.isEmpty) {
        try {
          final doc = await FirebaseFirestore.instance.collection('live_classes').doc(widget.sessionId).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final lc = LiveClass.fromFirestore(data, doc.id);
            final websiteRoom = JitsiLiveConfig.calculateWebsiteRoomName(
              roomName: lc.roomName.isNotEmpty ? lc.roomName : widget.roomName,
              classId: lc.id,
            );
            session = JitsiLiveSession(
              id: lc.id,
              courseId: lc.batchId,
              courseTitle: lc.batchName,
              title: lc.title,
              description: lc.description,
              instructorName: lc.instructor,
              status: lc.isLive ? 'live' : (lc.isRecorded ? 'completed' : 'scheduled'),
              roomName: websiteRoom,
              durationMinutes: lc.durationMinutes,
              recordingUrl: lc.recordingUrl,
              rawData: data,
            );
          }
        } catch (e) {
          AppLogger.w('Firestore live_classes fetch: $e', tag: 'JITSI_SCREEN');
        }
      }

      final fallbackWebsiteRoom = JitsiLiveConfig.calculateWebsiteRoomName(
        roomName: widget.roomName,
        classId: widget.sessionId,
      );

      session ??= JitsiLiveSession(
        id: widget.sessionId,
        title: 'Live Interactive Session',
        roomName: fallbackWebsiteRoom,
      );

      _currentSession = session;

      // Realtime listener on Firestore to sync status updates from website
      _firestoreSubscription?.cancel();
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('live_classes')
          .doc(widget.sessionId)
          .snapshots()
          .listen((snapshot) {
        if (!mounted || !snapshot.exists || snapshot.data() == null) return;
        final data = snapshot.data()!;
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'completed' && _classroomState == JitsiClassroomState.live) {
          AppLogger.i('Teacher ended live class on website', tag: 'JITSI_SCREEN');
          setState(() {
            _classroomState = JitsiClassroomState.classEnded;
          });
        }
      });

      // 2. Check session status: If concluded with replay, show ended state
      if (session.isCompleted && session.recordingUrl.isNotEmpty) {
        setState(() {
          _classroomState = JitsiClassroomState.classEnded;
        });
        return;
      }

      // If session is scheduled far in the future (>30 min), enter waiting state
      if (session.isUpcoming &&
          session.scheduledStartTime != null &&
          session.scheduledStartTime!.isAfter(DateTime.now().add(const Duration(minutes: 30)))) {
        _enterScheduledWaitingState();
        return;
      }

      // Immediately launch live conference (0ms wait, matching user request)
      await _requestTokenAndJoin();
    } catch (e) {
      AppLogger.e('Error initializing classroom: $e', error: e, tag: 'JITSI_SCREEN');
      if (mounted) {
        setState(() {
          _classroomState = JitsiClassroomState.error;
          _errorMessage = 'Failed to connect to classroom: $e';
        });
      }
    }
  }

  /// State: Scheduled (Waiting for Instructor to start on website)
  void _enterScheduledWaitingState() {
    setState(() {
      _classroomState = JitsiClassroomState.scheduledWaiting;
    });

    // Start background polling every 15 seconds against GET /api/sessions/[id]
    _jitsiService.startSessionPolling(
      sessionId: widget.sessionId,
      interval: const Duration(seconds: 15),
      onStatusUpdated: (updated) {
        if (!mounted) return;
        AppLogger.i('Polling update received: status=${updated.status}', tag: 'JITSI_SCREEN');
        _currentSession = updated;

        if (updated.isLive && !_isJoinOperationInProgress && _classroomState != JitsiClassroomState.live) {
          _jitsiService.stopSessionPolling();
          AppLogger.s('Teacher started class on website! Auto-transitioning student...', tag: 'JITSI_SCREEN');
          AppTheme.showSuccessSnackBar(context, 'Instructor is live! Joining classroom...');
          _requestTokenAndJoin();
        } else if (updated.isCompleted) {
          _jitsiService.stopSessionPolling();
          setState(() {
            _classroomState = JitsiClassroomState.classEnded;
          });
        }
      },
    );
  }

  /// Requests authorized token and launches embedded Jitsi Meeting
  Future<void> _requestTokenAndJoin() async {
    if (!mounted) return;
    if (_isJoinOperationInProgress) {
      AppLogger.w('Join operation already in progress, ignoring duplicate trigger', tag: 'JITSI_SCREEN');
      return;
    }
    _isJoinOperationInProgress = true;

    setState(() {
      _classroomState = JitsiClassroomState.requestingToken;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? userProvider.user?.id ?? userProvider.user?.uid ?? 'student_${DateTime.now().millisecondsSinceEpoch}';
    final rawName = userProvider.user?.name ?? user?.displayName ?? '';
    final name = rawName.trim().isNotEmpty ? rawName.trim() : 'Student';
    final rawEmail = user?.email ?? userProvider.user?.email ?? '';
    final email = rawEmail.trim().isNotEmpty ? rawEmail.trim() : 'student@examinantt.com';

    // Resolve exact website room name matching examinantt.com (NEVER altered if already provided)
    final targetRoom = JitsiLiveConfig.calculateWebsiteRoomName(
      roomName: _currentSession?.roomName ?? widget.liveClass?.roomName ?? widget.roomName,
      classId: widget.sessionId,
    );

    // Resolve domain
    final rawServer = widget.liveClass?.streamServer ?? _currentSession?.rawData['streamServer'];
    final rawUrl = widget.liveClass?.videoUrl ?? _currentSession?.rawData['streamUrl'];
    String resolvedDomain = JitsiLiveConfig.resolveDomain(rawServer?.toString());
    if (rawUrl != null && rawUrl.toString().contains('8x8.vc')) {
      resolvedDomain = JitsiLiveConfig.defaultJaasDomain;
    } else if (rawUrl != null && rawUrl.toString().contains('meet.jit.si')) {
      resolvedDomain = JitsiLiveConfig.defaultPublicJitsiDomain;
    }

    // 1. Fetch authorized Live Token from LiveClassApi
    final tokenData = await LiveClassApi.getLiveToken(
      classId: widget.sessionId,
      roomId: targetRoom,
      studentName: name,
      studentEmail: email,
      studentId: uid,
    );

    final finalRoom = (tokenData?['roomName'] != null && tokenData!['roomName'].toString().isNotEmpty)
        ? tokenData['roomName'].toString()
        : targetRoom;
    final finalDomain = (tokenData?['domain'] != null && tokenData!['domain'].toString().isNotEmpty)
        ? tokenData['domain'].toString()
        : resolvedDomain;
    final finalToken = tokenData?['token']?.toString() ?? '';
    final subject = _currentSession?.title ?? widget.liveClass?.title ?? 'Examinantt Live Lecture';

    final tokenToUse = JitsiLiveTokenInfo(
      token: finalToken,
      roomName: finalRoom,
      domain: finalDomain,
      serverUrl: 'https://$finalDomain',
      subject: subject,
      status: 'live',
      isLive: true,
      startedAt: _currentSession?.startedAt ?? DateTime.now(),
    );

    tokenInfo = tokenToUse;

    if (!mounted) {
      _isJoinOperationInProgress = false;
      return;
    }
    setState(() {
      _classroomState = JitsiClassroomState.joining;
    });

    // Record student attendance & participant in Firestore so Host web panel immediately sees them
    _recordStudentAttendanceJoined(uid: uid, name: name, email: email);

    // Start elapsed timer
    _startElapsedTimer(tokenToUse.startedAt ?? DateTime.now());

    // Join via SDK embedded conference in-app
    try {
      await _jitsiService.joinConference(
        tokenInfo: tokenToUse,
        studentName: name,
        studentEmail: email,
        listener: JitsiMeetEventListener(
          conferenceWillJoin: (url) {
            AppLogger.i('Conference will join: $url', tag: 'JITSI_SDK');
            if (mounted) {
              setState(() {
                _classroomState = JitsiClassroomState.live;
              });
            }
          },
          conferenceJoined: (url) {
            AppLogger.s('Student successfully joined Jitsi conference: $url', tag: 'JITSI_SDK');
            if (mounted) {
              setState(() {
                _classroomState = JitsiClassroomState.live;
              });
            }
          },
          conferenceTerminated: (url, error) {
            AppLogger.i('Conference terminated: url=$url, error=$error', tag: 'JITSI_SDK');
            _isJoinOperationInProgress = false;
            _elapsedTimer?.cancel();
            _recordStudentAttendanceLeft();
            if (mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                if (error != null && error.toString().isNotEmpty) {
                  AppTheme.showWarningSnackBar(context, 'Live meeting ended: $error');
                } else {
                  AppTheme.showSuccessSnackBar(context, 'Live meeting ended.');
                }
              } else {
                setState(() {
                  _classroomState = JitsiClassroomState.classEnded;
                });
              }
            }
          },
          readyToClose: () {
            AppLogger.i('Jitsi readyToClose event received', tag: 'JITSI_SDK');
            _isJoinOperationInProgress = false;
            _recordStudentAttendanceLeft();
            if (mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                AppTheme.showSuccessSnackBar(context, 'You left the live meeting.');
              } else {
                setState(() {
                  _classroomState = JitsiClassroomState.leftLocally;
                });
              }
            }
          },
          audioMutedChanged: (muted) {
            if (mounted) setState(() => _isAudioMuted = muted);
          },
          videoMutedChanged: (muted) {
            if (mounted) setState(() => _isVideoMuted = muted);
          },
          participantJoined: (email, name, role, pId) {
            if (mounted) setState(() => _participantCount++);
          },
          participantLeft: (pId) {
            if (mounted && _participantCount > 1) setState(() => _participantCount--);
          },
        ),
      );

      // Transition immediately to live view once SDK has received the launch call
      if (mounted && _classroomState == JitsiClassroomState.joining) {
        setState(() {
          _classroomState = JitsiClassroomState.live;
        });
      }
    } catch (e) {
      _isJoinOperationInProgress = false;
      AppLogger.e('Error launching Jitsi conference: $e', error: e, tag: 'JITSI_SCREEN');
      if (mounted) {
        setState(() {
          _classroomState = JitsiClassroomState.error;
          _errorMessage = 'Failed to connect to conference: $e';
        });
      }
    }
  }

  void _startElapsedTimer(DateTime start) {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _sessionElapsed = DateTime.now().difference(start);
          if (_sessionElapsed.isNegative) _sessionElapsed = Duration.zero;
        });
      }
    });
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mins:$secs' : '$mins:$secs';
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD & VIEWS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF030D1C) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildCurrentStateView(isDark),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView(bool isDark) {
    switch (_classroomState) {
      case JitsiClassroomState.initial:
      case JitsiClassroomState.requestingToken:
      case JitsiClassroomState.joining:
        return _buildLoadingView(isDark);
      case JitsiClassroomState.scheduledWaiting:
        return _buildWaitingForTeacherView(isDark);
      case JitsiClassroomState.live:
        return _buildLiveMeetingView(isDark);
      case JitsiClassroomState.leftLocally:
        return _buildLeftLocallyView(isDark);
      case JitsiClassroomState.classEnded:
        return _buildClassEndedView(isDark);
      case JitsiClassroomState.error:
        return _buildErrorView(isDark);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. LOADING VIEW
  // ---------------------------------------------------------------------------
  Widget _buildLoadingView(bool isDark) {
    final statusText = _classroomState == JitsiClassroomState.requestingToken
        ? 'Authorizing secure room access...'
        : (_classroomState == JitsiClassroomState.joining ? 'Connecting to live classroom...' : 'Checking class status...');

    return Center(
      key: const ValueKey('loading_view'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0070F3).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0070F3)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentSession?.title ?? widget.liveClass?.title ?? 'Live Video Classroom',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _classroomState = JitsiClassroomState.live;
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Open Room Directly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. WAITING FOR TEACHER (SCHEDULED STATE)
  // ---------------------------------------------------------------------------
  Widget _buildWaitingForTeacherView(bool isDark) {
    final title = _currentSession?.title ?? widget.liveClass?.title ?? 'Interactive Live Class';
    final instructor = _currentSession?.instructorName ?? widget.liveClass?.instructor ?? 'Examinantt Faculty';
    final course = _currentSession?.courseTitle ?? widget.liveClass?.batchName ?? 'Enrolled Batch';

    return SingleChildScrollView(
      key: const ValueKey('waiting_view'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Text(
                      'SCHEDULED SESSION',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48), // balance back button
            ],
          ),
          const SizedBox(height: 30),

          // Pulsing Radar Graphic
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0070F3), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0070F3).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.cast_for_education_rounded, size: 54, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Waiting for Instructor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The class will begin automatically once the instructor launches the live stream on the website.',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Class Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1B36) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.toUpperCase(),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8), letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF0070F3).withValues(alpha: 0.2),
                      child: Text(
                        instructor.isNotEmpty ? instructor[0] : 'F',
                        style: const TextStyle(color: Color(0xFF0070F3), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instructor,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const Text(
                            'Master Faculty • Top Educator',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Polling status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white54 : Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Auto-detecting live status every 15s...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Direct Join Live Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _requestTokenAndJoin,
              icon: const Icon(Icons.videocam_rounded, size: 20, color: Colors.white),
              label: const Text('Enter Live Classroom Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Manual Check Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                final updated = await _jitsiService.fetchSessionDetails(widget.sessionId);
                if (updated != null && mounted) {
                  _currentSession = updated;
                  if (updated.isLive) {
                    _requestTokenAndJoin();
                  } else {
                    AppTheme.showSuccessSnackBar(context, 'Checked: Class is not live yet. Will auto-join when instructor begins.');
                  }
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check Live Status Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0070F3),
                side: const BorderSide(color: Color(0xFF0070F3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LIVE MEETING IN-APP OVERLAY VIEW
  // ---------------------------------------------------------------------------
  Widget _buildLiveMeetingView(bool isDark) {
    final title = _currentSession?.title ?? widget.liveClass?.title ?? 'Live Video Classroom';
    final instructor = _currentSession?.instructorName ?? widget.liveClass?.instructor ?? 'Examinantt Faculty';

    return Stack(
      key: const ValueKey('live_meeting_view'),
      children: [
        // Background Branding
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF071120),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.video_camera_front_rounded, size: 40, color: Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Meeting Room Active',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connected with $instructor',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE • ${_formatElapsed(_sessionElapsed)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.people_alt_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$_participantCount',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top App Bar
        Positioned(
          top: 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
                tooltip: 'Picture in Picture',
                onPressed: () => _jitsiService.enterPiP(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_end_rounded, color: Color(0xFFEF4444)),
                tooltip: 'Leave Class',
                onPressed: _showLeaveConfirmDialog,
              ),
            ],
          ),
        ),

        // Bottom Controls Strip
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mic Control
                IconButton(
                  icon: Icon(
                    _isAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isAudioMuted ? const Color(0xFFEF4444) : Colors.white,
                  ),
                  tooltip: _isAudioMuted ? 'Unmute Mic' : 'Mute Mic',
                  onPressed: () async {
                    final next = !_isAudioMuted;
                    await _jitsiService.setAudioMuted(next);
                    setState(() => _isAudioMuted = next);
                  },
                ),

                // Video Control
                IconButton(
                  icon: Icon(
                    _isVideoMuted ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    color: _isVideoMuted ? const Color(0xFFEF4444) : Colors.white,
                  ),
                  tooltip: _isVideoMuted ? 'Turn Camera On' : 'Turn Camera Off',
                  onPressed: () async {
                    final next = !_isVideoMuted;
                    await _jitsiService.setVideoMuted(next);
                    setState(() => _isVideoMuted = next);
                  },
                ),

                // Chat Control
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                  tooltip: 'Live Q&A Chat',
                  onPressed: () => _jitsiService.openChat(),
                ),

                // PDF Notes (if available)
                if ((widget.liveClass?.notesUrl ?? '').isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8)),
                    tooltip: 'Class Notes PDF',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            pdfData: ResourceItem(
                              id: 'notes_${DateTime.now().millisecondsSinceEpoch}',
                              title: '$title - Notes',
                              subtitle: 'Live Lecture Material',
                              category: 'Physics',
                              subject: 'Physics',
                              type: 'Notes',
                              fileType: 'PDF',
                              fileSize: '3 MB',
                              badge: 'INCLUDED',
                              badgeColorHex: '#10B981',
                              downloads: '1k',
                              rating: 5.0,
                              exam: 'JEE/NEET',
                              price: 0.0,
                              isPublic: true,
                              description: 'Handwritten class notes.',
                              url: widget.liveClass!.notesUrl,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Leave Meeting Button
                IconButton(
                  icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFEF4444)),
                  tooltip: 'Leave',
                  onPressed: _showLeaveConfirmDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLeaveConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Classroom?'),
        content: const Text('You can rejoin anytime while the instructor is still live.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _recordStudentAttendanceLeft();
              await _jitsiService.hangUp();
              setState(() {
                _classroomState = JitsiClassroomState.leftLocally;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Leave Room', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LEFT LOCALLY (STUDENT LEFT WHILE CLASS IS STILL LIVE)
  // ---------------------------------------------------------------------------
  Widget _buildLeftLocallyView(bool isDark) {
    return Center(
      key: const ValueKey('left_locally_view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.meeting_room_outlined, size: 54, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 24),
            Text(
              'You Left the Classroom',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The lecture is still live on the website. You can instantly rejoin and resume asking questions.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _requestTokenAndJoin,
                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                label: const Text('Rejoin Live Class Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Courses', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. CLASS ENDED VIEW (COMPLETED)
  // ---------------------------------------------------------------------------
  Widget _buildClassEndedView(bool isDark) {
    final title = _currentSession?.title ?? widget.liveClass?.title ?? 'Live Lecture';
    final instructor = _currentSession?.instructorName ?? widget.liveClass?.instructor ?? 'Examinantt Faculty';
    final recordingUrl = _currentSession?.recordingUrl ?? widget.liveClass?.recordingUrl ?? '';

    return Center(
      key: const ValueKey('class_ended_view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0070F3).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 54, color: Color(0xFF0070F3)),
            ),
            const SizedBox(height: 24),
            Text(
              'Live Class Completed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lecture ended by $instructor. The full recording & notes will be accessible in your batch archive.',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1B36) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 20, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (recordingUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppTheme.showSuccessSnackBar(context, 'Opening lecture replay...');
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                  label: const Text('Watch Lecture Replay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0070F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Video Classroom', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. ERROR VIEW
  // ---------------------------------------------------------------------------
  Widget _buildErrorView(bool isDark) {
    return Center(
      key: const ValueKey('error_view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 24),
            Text(
              'Classroom Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to connect to the Jitsi meeting room.',
              style: const TextStyle(fontSize: 13.5, color: Colors.grey, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _initializeClassroom,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0070F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
