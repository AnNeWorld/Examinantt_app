import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../utils/app_navigator.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import '../models/content_models.dart';
import '../models/live_class_session_models.dart';
import '../providers/user_provider.dart';
import '../services/content_service.dart';
import '../services/firestore_service.dart';
import '../services/ivs_live_service.dart';
import '../services/payment_service.dart';
import 'amazon_live_player_screen.dart';
import 'batch_details_screen.dart';
import 'jitsi_live_meeting_screen.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/safe_app_image.dart';
import '../widgets/notification_bell_action.dart';

class CoursesScreen extends StatefulWidget {
  final int initialTab;
  const CoursesScreen({super.key, this.initialTab = 0});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _getBackgroundColor => _isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
  Color get _getCardColor => _isDark ? AppColors.surfaceDark : Colors.white;
  Color get _getBorderColor => _isDark ? AppColors.greyDark : Colors.grey.shade200;
  Color get _getTextColor => _isDark ? AppColors.textDark : AppColors.text;
  Color get _getSecondaryTextColor => _isDark ? AppColors.textDarkSecondary : AppColors.textLight;

  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();
  final ContentService _contentService = ContentService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _liveSearchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  Set<String> _cachedPurchasedIds = <String>{};

  // Live Classroom State (matching https://www.examinantt.com/dashboard/courses)
  String _liveReplaySubjectFilter = 'All';
  String _liveSearchQuery = '';
  final Set<String> _liveReminders = <String>{};
  String? _joiningClassId;
  late final Stream<List<Map<String, dynamic>>> _purchasesStream;
  late final Stream<List<CourseModel>> _batchesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab.clamp(0, 4));
    _purchasesStream = FirestoreService().getUserPurchasesStream();
    _batchesStream = FirestoreService().getBatchesStream();
    _loadCachedPurchases();
    
    // Seed and sync real AWS live classes from Firestore
    FirestoreService().ensureRealAwsLiveClassesExist();

    _paymentService.initialize(
      onSuccess: (PaymentSuccessResponse response) async {
        if (!mounted) return;
        await _loadCachedPurchases();
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Payment Successful! Batch Unlocked 🎉');
        setState(() {});
      },
      onFailure: (PaymentFailureResponse response) {
        if (!mounted) return;
        AppTheme.showErrorSnackBar(
          context,
          PaymentService.cleanErrorMessage(response),
        );
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  Future<void> _loadCachedPurchases() async {
    final cached = await FirestoreService.getCachedPurchasedIds();
    if (mounted) {
      setState(() {
        _cachedPurchasedIds = cached;
      });
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _searchController.dispose();
    _liveSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _isBatchEnrolled(CourseModel batch, List<Map<String, dynamic>> purchases) {
    if (batch.price <= 0) return true;
    final bId = batch.id.trim();
    final bTitle = batch.title.trim().toLowerCase();

    if (bId.isNotEmpty && _cachedPurchasedIds.contains(bId)) return true;
    if (bTitle.isNotEmpty && _cachedPurchasedIds.contains(bTitle)) return true;

    final uid = FirestoreService().effectiveUid ?? '';
    if (uid.isNotEmpty && batch.enrolledStudentIds.contains(uid)) return true;

    return purchases.any((p) {
      final pId = (p['id'] ?? p['categoryId'] ?? p['itemId'] ?? '').toString().trim();
      final pTitle = (p['title'] ?? '').toString().trim().toLowerCase();
      if (bId.isNotEmpty && pId == bId) return true;
      if (bTitle.isNotEmpty && pTitle.isNotEmpty && pTitle == bTitle) return true;
      return false;
    });
  }

  void _enrollFreeBatch(CourseModel batch) async {
    try {
      await FirestoreService().addPurchase(
        id: batch.id,
        itemId: batch.id,
        title: batch.title,
        type: 'Batch',
        price: 0,
      );
      await FirestoreService().addNotification(
        title: 'Batch Unlocked 🎉',
        subtitle: 'Successfully enrolled in ${batch.title} for free!',
      );
      await _loadCachedPurchases();
      if (!mounted) return;
      AppTheme.showSuccessSnackBar(context, '🎉 Enrolled in ${batch.title} for Free!');
      setState(() {});
      AppNavigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BatchDetailsScreen(batch: batch),
        ),
      );
    } catch (e) {
      debugPrint('Error enrolling free batch: $e');
      if (!mounted) return;
      AppTheme.showErrorSnackBar(context, 'Could not complete enrollment: $e');
    }
  }

  void _buyBatch(CourseModel batch) {
    PaymentService().payAndUnlock(
      context: context,
      itemId: batch.id,
      title: batch.title,
      price: batch.price,
      itemType: 'Batch',
      subtitle: 'Comprehensive batch with live classes, mock tests & mentor access',
      onSuccess: () async {
        await _loadCachedPurchases();
        if (!mounted) return;
        setState(() {});
        AppNavigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BatchDetailsScreen(batch: batch),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    return Scaffold(
      backgroundColor: _getBackgroundColor,
      appBar: AppBar(
        leadingWidth: 42,
        titleSpacing: 6,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getTextColor),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0070F3) : AppTheme.primaryColor).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.video_library_rounded, color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Video Classroom',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _getTextColor,
                    fontSize: 16.5,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Digital Learning Hub',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF071326) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          NotificationBellAction(color: _getTextColor),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: AppColors.accent,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text('LIVE CLASSROOM'),
                ],
              ),
            ),
            const Tab(text: 'ALL BATCHES'),
            const Tab(text: 'FULL PREPARATION'),
            const Tab(text: 'CRASH COURSES'),
            const Tab(text: 'MY BATCHES'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _purchasesStream,
        initialData: FirestoreService.cachedPurchases,
        builder: (context, purchasesSnap) {
          final purchases = purchasesSnap.data ?? FirestoreService.cachedPurchases;

          return StreamBuilder<List<CourseModel>>(
            stream: _batchesStream,
            initialData: FirestoreService.cachedBatches,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && FirestoreService.cachedBatches.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              final allBatches = snapshot.data ?? FirestoreService.cachedBatches;

              // Full Prep Batches
              final fullPrepBatches = allBatches.where((b) {
                final t = b.title.toLowerCase();
                final d = b.shortDescription.toLowerCase();
                final isCrash = t.contains('crash') || t.contains('fast') || t.contains('revision') || d.contains('crash');
                return !isCrash;
              }).toList();

              // Crash Courses
              final crashBatches = allBatches.where((b) {
                final t = b.title.toLowerCase();
                final d = b.shortDescription.toLowerCase();
                return t.contains('crash') ||
                    t.contains('fast') ||
                    t.contains('rapid') ||
                    t.contains('revision') ||
                    t.contains('booster') ||
                    t.contains('mcq') ||
                    d.contains('crash');
              }).toList();

              // My Enrolled Batches
              final enrolledBatches = allBatches.where((b) => _isBatchEnrolled(b, purchases)).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveClassroomTab(purchases),
                  _buildAllBatchesTab(allBatches, purchases),
                  _buildFilteredTab(
                    fullPrepBatches,
                    purchases,
                    emptyTitle: 'No Full Preparation Batches Yet',
                    emptySubtitle: 'Check back soon or explore all available batches in the All Batches tab.',
                  ),
                  _buildFilteredTab(
                    crashBatches,
                    purchases,
                    emptyTitle: 'No Crash Courses Available Right Now',
                    emptySubtitle: 'Upcoming fast-track and revision batches will appear here as soon as announced.',
                  ),
                  _buildMyBatchesTab(enrolledBatches, allBatches, purchases),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // LIVE CLASSROOM ACTIONS & HANDLERS
  // ==========================================
  Future<void> _openLiveClass(
    LiveClass c, {
    Set<String> purchasedBatchIds = const {},
    Set<String> purchasedItemIds = const {},
  }) async {
    if (_joiningClassId != null) return;

    setState(() {
      _joiningClassId = c.id;
    });

    if (c.isJitsi) {
      try {
        await AppNavigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JitsiLiveMeetingScreen(
              liveClass: c,
              sessionId: c.id,
              roomName: c.roomName,
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _joiningClassId = null;
          });
        }
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF071733),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Connecting to Video Classroom...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                'Verifying student enrollment & live stream access',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? userProvider.user?.id;
      final name = userProvider.user?.name ?? FirebaseAuth.instance.currentUser?.displayName;

      final LiveClassAccessSession session = await IvsLiveService().requestJoinAccess(
        liveClass: c,
        currentUid: uid,
        currentUserName: name,
        purchasedBatchIds: purchasedBatchIds,
        purchasedItemIds: purchasedItemIds,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      if (session.isAuthorized) {
        AppNavigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AmazonLivePlayerScreen(
              liveClass: c,
              accessSession: session,
            ),
          ),
        );
      } else {
        AppTheme.showWarningSnackBar(
          context,
          session.message ?? 'Access could not be authorized. Please enroll in this session.',
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        AppTheme.showErrorSnackBar(context, 'Failed to join live stream: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _joiningClassId = null;
        });
      }
    }
  }

  void _openPdfNotes(String title, String subject, String url) {
    if (url.isEmpty) {
      AppTheme.showWarningSnackBar(context, 'PDF Notes will be available shortly after session.');
      return;
    }
    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfData: ResourceItem(
            id: 'notes_${title.hashCode}',
            title: '$title Notes',
            category: 'Class Notes',
            type: 'PDF',
            url: url,
            price: 0,
            isPublic: true,
            description: 'Class presentation and reference notes for $title',
            subject: subject,
          ),
        ),
      ),
    );
  }

  Widget _buildPullRefresh({required Widget child}) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: _isDark ? AppColors.surfaceDark : Colors.white,
      onRefresh: () async {
        await _loadCachedPurchases();
        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) setState(() {});
      },
      child: child,
    );
  }

  // ==========================================
  // TAB 0: LIVE CLASSROOM (MATCHING https://www.examinantt.com/dashboard/courses)
  // ==========================================
  Widget _buildLiveClassroomTab(List<Map<String, dynamic>> purchases) {
    final purchasedBatchIds = purchases.map((p) => (p['id'] ?? p['categoryId'] ?? p['itemId'] ?? '').toString()).toSet();
    final purchasedItemIds = purchases.map((p) => (p['itemId'] ?? p['id'] ?? '').toString()).toSet();

    return StreamBuilder<List<LiveClass>>(
      stream: _contentService.getLiveClasses(),
      builder: (context, snapshot) {
        List<LiveClass> allClasses = snapshot.data ?? [];
        if (allClasses.isEmpty) {
          allClasses = _getDefaultLiveClassesFallback();
        }

        // Active Live, Upcoming, and Replays
        final activeLiveList = allClasses.where((c) => c.isLive).toList();
        final upcomingList = allClasses.where((c) => c.isUpcoming).toList();
        final recordedList = allClasses.where((c) => c.isRecorded || (!c.isLive && !c.isUpcoming)).toList();

        // Filter Replays by Subject & Search Query
        final filteredReplays = recordedList.where((c) {
          final matchesSub = _liveReplaySubjectFilter == 'All' ||
              c.subject.toLowerCase().contains(_liveReplaySubjectFilter.toLowerCase());
          final q = _liveSearchQuery.toLowerCase().trim();
          final matchesQ = q.isEmpty ||
              c.title.toLowerCase().contains(q) ||
              c.instructor.toLowerCase().contains(q) ||
              c.subject.toLowerCase().contains(q) ||
              c.chapter.toLowerCase().contains(q);
          return matchesSub && matchesQ;
        }).toList();

        return _buildPullRefresh(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Digital Learning Hub Hero Banner
                _buildDigitalLearningHubHeader(),
                const SizedBox(height: 20),

                // 2. Active Live Broadcast Section
                if (activeLiveList.isNotEmpty)
                  _buildActiveLiveBroadcastCard(activeLiveList.first, purchasedBatchIds, purchasedItemIds)
                else
                  _buildNoLiveBroadcastBanner(),
                const SizedBox(height: 28),

                // 3. Upcoming Live Sessions Section
                _buildUpcomingLiveSessionsSection(upcomingList),
                const SizedBox(height: 28),

                // 4. Past Live Class Replays Section (matching 6 replays on website)
                _buildPastLiveReplaysSection(filteredReplays, purchasedBatchIds, purchasedItemIds),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------
  // HEADER: DIGITAL LEARNING HUB
  // ------------------------------------------
  Widget _buildDigitalLearningHubHeader() {
    final isDark = _isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06152F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : Colors.blue.shade100,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_rounded, size: 12, color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor),
                    const SizedBox(width: 5),
                    Text(
                      'DIGITAL LEARNING HUB',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _tabController.animateTo(1); // Jump to All Batches tab
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Browse All Batches',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Video Classroom',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _getTextColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join live interactive classes and stream recorded batch lectures anytime.',
            style: TextStyle(
              fontSize: 12.5,
              color: _getSecondaryTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // ACTIVE LIVE BROADCAST CARD
  // ------------------------------------------
  Widget _buildActiveLiveBroadcastCard(
    LiveClass c,
    Set<String> purchasedBatchIds,
    Set<String> purchasedItemIds,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'LIVE BROADCAST',
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      c.activeViewers.isNotEmpty ? '${c.activeViewers} watching' : '1.4K watching',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            c.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          if (c.chapter.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              c.chapter,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  c.instructor.isNotEmpty ? c.instructor[0] : 'F',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.instructor,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      c.qualification,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                ),
                child: Text(
                  c.subject.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _openLiveClass(c, purchasedBatchIds: purchasedBatchIds, purchasedItemIds: purchasedItemIds),
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Join Live Stream ⚡',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // NO ACTIVE LIVE BROADCAST BANNER (EXACT WEBSITE MATCH)
  // ------------------------------------------
  Widget _buildNoLiveBroadcastBanner() {
    final isDark = _isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081938) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF001F4D) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF0070F3).withValues(alpha: 0.3) : Colors.blue.shade100),
            ),
            child: const Icon(Icons.videocam_outlined, color: Color(0xFF38BDF8), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'NO ACTIVE LIVE BROADCAST',
                        style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'All Live Classes are Currently on Schedule',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _getTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check the upcoming schedule below and set reminders to get notified when faculty goes live.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSecondaryTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // UPCOMING LIVE SESSIONS SECTION
  // ------------------------------------------
  Widget _buildUpcomingLiveSessionsSection(List<LiveClass> upcomingList) {
    final isDark = _isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Live Sessions (${upcomingList.length})',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _getTextColor,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Scheduled',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getSecondaryTextColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF071938) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor),
            ),
            child: Column(
              children: [
                Icon(Icons.event_available_rounded, size: 36, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                Text(
                  'No upcoming live sessions scheduled at the moment.',
                  style: TextStyle(color: _getTextColor, fontWeight: FontWeight.w700, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Please check back later or explore completed lecture replays below.',
                  style: TextStyle(color: _getSecondaryTextColor, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingList.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = upcomingList[index];
              final hasReminder = _liveReminders.contains(c.id);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF071938) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 4),
                              Text(
                                c.time.isNotEmpty ? c.time : 'Scheduled Soon',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getSubjectColor(c.subject).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.subject.toUpperCase(),
                            style: TextStyle(
                              color: _getSubjectColor(c.subject),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _getTextColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Faculty: ${c.instructor}',
                      style: TextStyle(fontSize: 12, color: _getSecondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${c.durationMinutes} Mins Duration',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getSecondaryTextColor),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (hasReminder) {
                                _liveReminders.remove(c.id);
                              } else {
                                _liveReminders.add(c.id);
                                FirestoreService().addNotification(
                                  title: 'Reminder Set: ${c.title}',
                                  subtitle: 'Class scheduled with ${c.instructor}. You will receive an alert before it starts.',
                                );
                                AppTheme.showSuccessSnackBar(context, 'Reminder set! We will notify you before class starts.');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: hasReminder ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF0070F3).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: hasReminder ? const Color(0xFF10B981) : const Color(0xFF0070F3).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                  size: 14,
                                  color: hasReminder ? const Color(0xFF10B981) : const Color(0xFF0070F3),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  hasReminder ? 'Reminder Set ✓' : 'Remind Me',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: hasReminder ? const Color(0xFF10B981) : const Color(0xFF0070F3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ------------------------------------------
  // PAST LIVE CLASS REPLAYS (MATCHING 6 REPLAYS ON WEBSITE)
  // ------------------------------------------
  Widget _buildPastLiveReplaysSection(
    List<LiveClass> replays,
    Set<String> purchasedBatchIds,
    Set<String> purchasedItemIds,
  ) {
    final subjects = ['All', 'Physics', 'Mathematics', 'Chemistry', 'Biology', 'General'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Past Live Class Replays (${replays.length})',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: _getTextColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Missed a live session? Watch complete replays anytime.',
          style: TextStyle(fontSize: 12, color: _getSecondaryTextColor),
        ),
        const SizedBox(height: 14),

        // Search Input for Replays
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF001530) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _getBorderColor),
          ),
          child: TextField(
            controller: _liveSearchController,
            onChanged: (val) {
              setState(() {
                _liveSearchQuery = val;
              });
            },
            style: TextStyle(color: _getTextColor, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search replays by topic or faculty...',
              hintStyle: TextStyle(color: _getSecondaryTextColor, fontSize: 12.5),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: _getSecondaryTextColor),
              suffixIcon: _liveSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _liveSearchController.clear();
                        setState(() {
                          _liveSearchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subject Filter Pills
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final sub = subjects[i];
              final isSelected = _liveReplaySubjectFilter == sub;

              return InkWell(
                onTap: () {
                  setState(() {
                    _liveReplaySubjectFilter = sub;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor)
                        : (_isDark ? const Color(0xFF001838) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (_isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : _getSecondaryTextColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Replay Cards List
        if (replays.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF071938) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor),
            ),
            child: Column(
              children: [
                Icon(Icons.video_library_outlined, size: 36, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                Text(
                  'No replays found for this filter.',
                  style: TextStyle(color: _getTextColor, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: replays.length,
            separatorBuilder: (_, index) => const SizedBox(height: 14),
            itemBuilder: (context, idx) {
              final c = replays[idx];
              return _buildReplayCard(c, purchasedBatchIds, purchasedItemIds);
            },
          ),
      ],
    );
  }

  // ------------------------------------------
  // INDIVIDUAL REPLAY CARD
  // ------------------------------------------
  Widget _buildReplayCard(
    LiveClass c,
    Set<String> purchasedBatchIds,
    Set<String> purchasedItemIds,
  ) {
    final isDark = _isDark;
    final subjectColor = _getSubjectColor(c.subject);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071938) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _getBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Thumbnail Header with Play Overlay
          GestureDetector(
            onTap: () => _openLiveClass(c, purchasedBatchIds: purchasedBatchIds, purchasedItemIds: purchasedItemIds),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        subjectColor.withValues(alpha: 0.8),
                        const Color(0xFF091426),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),

              // Subject Tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    c.subject.toUpperCase(),
                    style: TextStyle(
                      color: subjectColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // Duration Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 11, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${c.durationMinutes} Mins',
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _getTextColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.chapter.isNotEmpty ? c.chapter : (c.description.isNotEmpty ? c.description : 'High-yield exam session.'),
                  style: TextStyle(fontSize: 12, color: _getSecondaryTextColor, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Faculty Profile Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: subjectColor.withValues(alpha: 0.2),
                      child: Text(
                        c.instructor.isNotEmpty ? c.instructor[0] : 'F',
                        style: TextStyle(color: subjectColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.instructor,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getTextColor),
                          ),
                          Text(
                            c.qualification,
                            style: TextStyle(fontSize: 10.5, color: _getSecondaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _openLiveClass(c, purchasedBatchIds: purchasedBatchIds, purchasedItemIds: purchasedItemIds),
                          icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Watch Replay & Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0070F3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    if (c.notesUrl.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () => _openPdfNotes(c.title, c.subject, c.notesUrl),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFEF4444)),
                          label: Text(
                            'Notes PDF',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _getTextColor,
                            side: BorderSide(color: _getBorderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return const Color(0xFF3B82F6);
    if (s.contains('math')) return const Color(0xFF8B5CF6);
    if (s.contains('chem')) return const Color(0xFF10B981);
    if (s.contains('bio')) return const Color(0xFFEC4899);
    return const Color(0xFFF59E0B);
  }

  // ------------------------------------------
  // EXACT WEBSITE REPLAY FALLBACK LIST (6 REPLAYS FROM https://www.examinantt.com/dashboard/courses)
  // ------------------------------------------
  List<LiveClass> _getDefaultLiveClassesFallback() {
    return [
      LiveClass(
        id: 'live_aws_kinematics_401',
        title: 'Kinematics: 2D Projectile Motion & Relative Velocity',
        instructor: 'Er. Aman Verma',
        qualification: 'IIT Delhi • Senior Physics Master Faculty',
        subject: 'Physics',
        examCategory: 'JEE Main 2027',
        chapter: 'Motion in a Plane • River Boat Problems & Air Wind Problems',
        description: 'Complete recorded video class with slide deck PPT presentation and step-by-step derivations.',
        time: '3 days ago',
        durationMinutes: 70,
        status: 'completed',
        isLive: false,
        isUpcoming: false,
        isRecorded: true,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        notesUrl: 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        batchName: 'JEE Main 2027 Conqueror Batch',
      ),
      LiveClass(
        id: 'live_aws_maths_calculus_301',
        title: 'Integral Calculus: Definite Integrals & Area Under Curves',
        instructor: 'Prof. Rajesh Khanna',
        qualification: 'Ex-HOD Mathematics • 15+ Yrs Experience',
        subject: 'Mathematics',
        examCategory: 'JEE Main 2027',
        chapter: 'Properties of Definite Integrals & Advanced Shortcut Methods',
        description: 'Complete live lecture recording with full chapter notes and high-frequency numerical practice.',
        time: 'Yesterday',
        durationMinutes: 85,
        status: 'completed',
        isLive: false,
        isUpcoming: false,
        isRecorded: true,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        notesUrl: 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        batchName: 'JEE Main 2027 Conqueror Batch',
      ),
      LiveClass(
        id: 'live_aws_optics_101',
        title: 'Wave Optics & Interference (Live Problem Solving)',
        instructor: 'Er. Aman Verma',
        qualification: 'IIT Delhi • Senior Physics Master Faculty',
        subject: 'Physics',
        examCategory: 'JEE Main 2027',
        chapter: 'Wave Optics • Superposition & Young\'s Double Slit Experiment',
        description: 'Real-time live problem solving, previous years trick questions, and doubt clearance on Amazon AWS IVS streaming infrastructure.',
        time: 'Live Now',
        durationMinutes: 90,
        status: 'live',
        isLive: true,
        isUpcoming: false,
        isRecorded: false,
        activeViewers: '1,420',
        videoUrl: 'https://fcc3ddae5994.us-west-2.playback.live-video.net/api/video/v1/us-west-2.896176387943.channel.DmumNckWFTqz.m3u8',
        notesUrl: 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        batchName: 'JEE Main 2027 Conqueror Batch',
      ),
      LiveClass(
        id: 'live_aws_organic_chem_201',
        title: 'Organic Chemistry: Aldehydes, Ketones & Carboxylic Acids',
        instructor: 'Dr. Pooja Sharma',
        qualification: 'Ph.D Organic Chemistry • 12+ Yrs Top Faculty',
        subject: 'Chemistry',
        examCategory: 'NEET UG 2027',
        chapter: 'Reaction Mechanisms, Cannizzaro & Aldol Condensation Masterclass',
        description: 'Comprehensive live session with step-by-step mechanism breakdown, exam tricks, and live student doubt answering.',
        time: 'Today, 6:00 PM',
        durationMinutes: 75,
        status: 'upcoming',
        isLive: false,
        isUpcoming: true,
        isRecorded: false,
        videoUrl: 'https://fcc3ddae5994.us-west-2.playback.live-video.net/api/video/v1/us-west-2.896176387943.channel.DmumNckWFTqz.m3u8',
        notesUrl: 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        batchName: 'NEET UG 2027 Victory Batch',
      ),
      LiveClass(
        id: 'live_class_neha_501',
        title: 'Class',
        instructor: 'Neha Ma\'am',
        qualification: 'Examinantt Master Faculty',
        subject: 'General',
        examCategory: 'All Exams',
        chapter: 'Special Foundation Class & Core Concepts',
        description: 'Interactive foundation session focusing on fundamental problem solving and conceptual clarity.',
        time: '4 days ago',
        durationMinutes: 60,
        status: 'completed',
        isLive: false,
        isUpcoming: false,
        isRecorded: true,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        notesUrl: 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        batchName: 'Foundation Learning Batch',
      ),
      LiveClass(
        id: 'live_class_trigo_601',
        title: 'Trigonometry 01',
        instructor: 'Aditya kushwaha Sir',
        qualification: 'Senior Mathematics Faculty',
        subject: 'Mathematics',
        examCategory: 'JEE Main 2027',
        chapter: 'Trigonometric Functions, Identities & Compound Angles',
        description: 'Comprehensive live lecture recording covering core trigonometric identities and previous years questions.',
        time: '5 days ago',
        durationMinutes: 60,
        status: 'completed',
        isLive: false,
        isUpcoming: false,
        isRecorded: true,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        notesUrl: 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        batchName: 'JEE Main 2027 Conqueror Batch',
      ),
    ];
  }

  // ==========================================
  // TAB 1: ALL BATCHES
  // ==========================================
  Widget _buildAllBatchesTab(List<CourseModel> batches, List<Map<String, dynamic>> purchases) {
    if (batches.isEmpty) {
      return _buildPullRefresh(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No Batches Available Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Any batches created on the website or admin portal will automatically show up here in real-time.',
                      style: TextStyle(color: _getSecondaryTextColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Dynamic Categories
    final categories = <String>{'All'};
    for (final b in batches) {
      if (b.examCategory.trim().isNotEmpty) {
        categories.add(b.examCategory.trim());
      }
    }

    // Filter by Search Query & Category
    final filtered = batches.where((b) {
      final matchesCat = _selectedCategory == 'All' ||
          b.examCategory.toLowerCase().trim() == _selectedCategory.toLowerCase().trim();
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.examCategory.toLowerCase().contains(q) ||
          b.shortDescription.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();

    final featuredBatch = batches.firstWhere(
      (b) => b.price > 0,
      orElse: () => batches.first,
    );

    return _buildPullRefresh(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            _buildSearchBar(),

            // Category Chips Bar
            if (categories.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isSel = _selectedCategory.toLowerCase() == cat.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.accent
                              : (_isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? AppColors.accent
                                : (_isDark ? AppColors.greyDark : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? Colors.white : _getTextColor,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Featured Batch Banner (Top of page)
            if (_searchQuery.isEmpty && _selectedCategory == 'All') ...[
              _buildFeaturedBanner(featuredBatch, purchases),
              const SizedBox(height: 20),
            ],

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Available ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _getTextColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Batches (${filtered.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                if (_selectedCategory != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No batches match "$_searchQuery"',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching by exam category like NEET, JEE, or CUET',
                        style: TextStyle(color: _getSecondaryTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.asMap().entries.map((entry) {
                final index = entry.key;
                final batch = entry.value;
                final isEnrolled = _isBatchEnrolled(batch, purchases);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BatchCard(
                    batch: batch,
                    isEnrolled: isEnrolled,
                    isDark: _isDark,
                    cardColor: _getCardColor,
                    borderColor: _getBorderColor,
                    textColor: _getTextColor,
                    secondaryTextColor: _getSecondaryTextColor,
                    onOpenDetails: () {
                      AppNavigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BatchDetailsScreen(batch: batch),
                        ),
                      );
                    },
                    onEnrollFree: () => _enrollFreeBatch(batch),
                    onBuyBatch: () => _buyBatch(batch),
                  ),
                ).animate().fade(delay: Duration(milliseconds: 60 * index)).slideY(
                      begin: 0.08,
                      end: 0,
                      curve: Curves.easeOutQuad,
                      duration: 350.ms,
                    );
              }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2 & 3: FILTERED BATCHES
  // ==========================================
  Widget _buildFilteredTab(
    List<CourseModel> batches,
    List<Map<String, dynamic>> purchases, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (batches.isEmpty) {
      return _buildPullRefresh(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      emptyTitle,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _getTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptySubtitle,
                      style: TextStyle(color: _getSecondaryTextColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _buildPullRefresh(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final batch = batches[index];
          final isEnrolled = _isBatchEnrolled(batch, purchases);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _BatchCard(
              batch: batch,
              isEnrolled: isEnrolled,
              isDark: _isDark,
              cardColor: _getCardColor,
              borderColor: _getBorderColor,
              textColor: _getTextColor,
              secondaryTextColor: _getSecondaryTextColor,
              onOpenDetails: () {
                AppNavigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BatchDetailsScreen(batch: batch),
                  ),
                );
              },
              onEnrollFree: () => _enrollFreeBatch(batch),
              onBuyBatch: () => _buyBatch(batch),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 4: MY ENROLLED BATCHES
  // ==========================================
  Widget _buildMyBatchesTab(
    List<CourseModel> enrolledBatches,
    List<CourseModel> allBatches,
    List<Map<String, dynamic>> purchases,
  ) {
    if (enrolledBatches.isEmpty) {
      return _buildPullRefresh(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No Enrolled Batches Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse the ALL BATCHES tab to unlock free or premium batches with daily live classes & mock tests.',
                      style: TextStyle(color: _getSecondaryTextColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        _tabController.animateTo(0);
                      },
                      icon: const Icon(Icons.explore_rounded, size: 16),
                      label: const Text('Browse All Batches', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _buildPullRefresh(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: enrolledBatches.length,
        itemBuilder: (context, index) {
          final batch = enrolledBatches[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF10B981),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ENROLLED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                          if (batch.examCategory.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              batch.examCategory,
                              style: TextStyle(color: _getSecondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        batch.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _getTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Validity: ${batch.validity}',
                        style: TextStyle(color: _getSecondaryTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BatchDetailsScreen(batch: batch),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Open >',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SEARCH BAR
  // ==========================================
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDark ? AppColors.greyDark : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _getTextColor, fontSize: 14),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search batches by name or exam (NEET, JEE, CUET)...',
          hintStyle: TextStyle(
            color: _getSecondaryTextColor.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _getSecondaryTextColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ==========================================
  // FEATURED BANNER
  // ==========================================
  Widget _buildFeaturedBanner(CourseModel batch, List<Map<String, dynamic>> purchases) {
    final isEnrolled = _isBatchEnrolled(batch, purchases);
    final isFree = batch.price <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDark ? null : Colors.white,
        gradient: _isDark
            ? const LinearGradient(
                colors: [Color(0xFF0B1E43), Color(0xFF00122C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDark ? AppColors.accent.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDark ? AppColors.accent.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF9500)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  batch.examCategory.isNotEmpty ? batch.examCategory.toUpperCase() : 'FEATURED BATCH',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Text('100% FREE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                )
              else if (batch.originalPrice > batch.price)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    '${(((batch.originalPrice - batch.price) / batch.originalPrice) * 100).round()}% OFF',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            batch.title,
            style: TextStyle(
              color: _isDark ? Colors.white : AppTheme.darkSlate,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          if (batch.shortDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              batch.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isFree ? 'FREE' : '₹${batch.price.toInt()}',
                    style: TextStyle(
                      color: isFree ? const Color(0xFF10B981) : (_isDark ? Colors.white : AppTheme.darkSlate),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!isFree && batch.originalPrice > batch.price) ...[
                    const SizedBox(width: 6),
                    Text(
                      '₹${batch.originalPrice.toInt()}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  AppNavigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BatchDetailsScreen(batch: batch),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled ? const Color(0xFF10B981) : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isEnrolled ? 'Open Batch >' : 'View Batch >',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE BATCH CARD COMPONENT
// ==========================================
class _BatchCard extends StatelessWidget {
  final CourseModel batch;
  final bool isEnrolled;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onOpenDetails;
  final VoidCallback onEnrollFree;
  final VoidCallback onBuyBatch;

  const _BatchCard({
    required this.batch,
    required this.isEnrolled,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onOpenDetails,
    required this.onEnrollFree,
    required this.onBuyBatch,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = batch.price <= 0;
    final int discountPercent = batch.originalPrice > batch.price && batch.originalPrice > 0
        ? (((batch.originalPrice - batch.price) / batch.originalPrice) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch Thumbnail Banner if uploaded from examinantt.com
          if (batch.thumbnailUrl.trim().isNotEmpty || batch.bannerUrl.trim().isNotEmpty) ...[
            GestureDetector(
              onTap: onOpenDetails,
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: SafeAppImage(
                  imageUrl: batch.thumbnailUrl.trim().isNotEmpty ? batch.thumbnailUrl.trim() : batch.bannerUrl.trim(),
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                  fallbackIcon: Icons.school_rounded,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Top Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0070F3) : AppTheme.primaryColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 11, color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      batch.examCategory.isNotEmpty ? batch.examCategory.toUpperCase() : 'BATCH',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 10, color: Color(0xFF10B981)),
                      SizedBox(width: 3),
                      Text(
                        'FREE BATCH',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
              else if (discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$discountPercent% OFF',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const Spacer(),
              if (isEnrolled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ ENROLLED',
                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Batch Title
          InkWell(
            onTap: onOpenDetails,
            child: Text(
              batch.title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Short Description / Highlights
          if (batch.shortDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              batch.shortDescription,
              style: TextStyle(color: secondaryTextColor, fontSize: 11.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Instructor info
          if (batch.instructorName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_pin_rounded, size: 13, color: secondaryTextColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${batch.instructorName} • ${batch.instructorTitle}',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Feature chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChip('📁 ${batch.resourceIds.length} Resources'),
              _buildChip('📝 ${batch.testSeriesIds.length} Test Series'),
              _buildChip('🎥 Live + Recorded'),
              _buildChip(batch.validity),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),

          // Bottom Pricing & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isFree ? 'FREE' : '₹${batch.price.toInt()}',
                        style: TextStyle(
                          color: isFree ? const Color(0xFF10B981) : textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!isFree && batch.originalPrice > batch.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${batch.originalPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isFree && batch.originalPrice > batch.price) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Save ₹${(batch.originalPrice - batch.price).toInt()}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),

              // Action Buttons
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onOpenDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : AppTheme.primaryColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Details >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (isEnrolled)
                    ElevatedButton.icon(
                      onPressed: onOpenDetails,
                      icon: const Icon(Icons.play_circle_fill, size: 14, color: Colors.white),
                      label: const Text('Open Batch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else if (isFree)
                    ElevatedButton.icon(
                      onPressed: onEnrollFree,
                      icon: const Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                      label: const Text('Enroll Free', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: onBuyBatch,
                      icon: const Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                      label: Text('Enroll (₹${batch.price.toInt()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
