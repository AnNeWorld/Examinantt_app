import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import 'amazon_live_player_screen.dart';
import 'checkout_screen.dart';
import 'pdf_viewer_screen.dart';
import 'batch_details_screen.dart';

class LiveClassesScreen extends StatefulWidget {
  final int initialTab;
  final String? batchTitle;
  final String? targetSubject;

  const LiveClassesScreen({
    super.key,
    this.initialTab = 0,
    this.batchTitle,
    this.targetSubject,
  });

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen>
    with SingleTickerProviderStateMixin {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF001026) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF071938) : Colors.white;
  Color get _subCardBg => _isDark ? const Color(0xFF00122C) : const Color(0xFFF1F5F9);
  Color get _textColor => _isDark ? Colors.white : AppTheme.darkSlate;
  Color get _subTextColor => _isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
  Color get _borderColor => _isDark ? Colors.white12 : Colors.grey.shade200;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ContentService _contentService = ContentService();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedSubject = 'All';
  String _searchQuery = '';
  final Set<String> _reminders = <String>{};

  final List<String> _defaultSubjects = [
    'All',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'General Awareness',
    'English',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.targetSubject != null && widget.targetSubject!.isNotEmpty) {
      _selectedSubject = widget.targetSubject!;
    }
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );

    // Initialize AWS Live stream seed if first time setup
    _firestoreService.ensureRealAwsLiveClassesExist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(LiveClass c) {
    if (_selectedSubject != 'All' &&
        !c.subject.toLowerCase().contains(_selectedSubject.toLowerCase())) {
      return false;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final full = '${c.subject} ${c.title} ${c.chapter} ${c.instructor} ${c.examCategory}'.toLowerCase();
      return full.contains(q);
    }
    return true;
  }

  void _openLiveClass(LiveClass c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmazonLivePlayerScreen(liveClass: c),
      ),
    );
  }

  void _openPdfNotes(String title, String subject, String url) {
    if (url.isEmpty) {
      AppTheme.showWarningSnackBar(context, 'PDF Notes will be available shortly after session.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfData: ResourceItem(
            id: 'notes_${DateTime.now().millisecondsSinceEpoch}',
            title: '$title - Class Notes',
            subtitle: '$subject • Live Session Handouts',
            category: subject,
            subject: subject,
            type: 'Notes',
            fileType: 'PDF',
            fileSize: '3.2 MB',
            badge: 'INCLUDED',
            badgeColorHex: '#34D399',
            downloads: '15k',
            rating: 4.9,
            exam: 'Examinantt Live Arena',
            price: 0.0,
            isPublic: true,
            description: 'Official verified faculty class presentation and annotated lecture notes.',
            url: url,
          ),
        ),
      ),
    );
  }

  void _navigateToBatch(LiveClass c) async {
    try {
      final batches = await _firestoreService.getBatchesStream().first;
      final match = batches.firstWhere(
        (b) =>
            (c.batchId.isNotEmpty && b.id == c.batchId) ||
            (c.batchName.isNotEmpty && b.title.toLowerCase() == c.batchName.toLowerCase()),
        orElse: () => CourseModel(
          id: c.batchId.isNotEmpty ? c.batchId : 'batch_general',
          title: c.batchName.isNotEmpty ? c.batchName : '${c.examCategory} Batch',
          examCategory: c.examCategory,
          price: c.price,
        ),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BatchDetailsScreen(batch: match),
        ),
      );
    } catch (e) {
      debugPrint("Error opening batch: $e");
    }
  }

  void _openCheckout(LiveClass c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          title: c.title,
          price: c.price,
          originalPrice: c.originalPrice,
          itemType: 'Live Class',
          itemId: c.id,
          subtitle: 'Live Interactive Session by ${c.instructor}',
          features: [
            'Full HD Live Interactive Stream (Amazon AWS IVS)',
            'Real-Time Live Chat & Doubt Clearance',
            'Downloadable PDF Class Handouts & Annotated Notes',
            'Lifetime Unlimited Access to Lecture Recording',
          ],
          onPaymentSuccess: () {
            AppTheme.showSuccessSnackBar(context, 'Live Class Access Granted! 🎉');
            _openLiveClass(c);
          },
        ),
      ),
    );
  }

  void _toggleReminder(String id, String title) {
    setState(() {
      if (_reminders.contains(id)) {
        _reminders.remove(id);
        AppTheme.showSuccessSnackBar(context, 'Reminder cancelled for $title');
      } else {
        _reminders.add(id);
        AppTheme.showSuccessSnackBar(context, '🔔 Reminder set! We will alert you 10 mins before $title starts.');
      }
    });
  }

  void _showWaitingRoom(LiveClass c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('WAITING ROOM', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.title,
                style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'By ${c.instructor} • ${c.time}',
                style: TextStyle(color: _subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _subCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class will start on scheduled time', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Live stream will begin automatically via Amazon AWS infrastructure.', style: TextStyle(color: _subTextColor, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleReminder(c.id, c.title);
                  },
                  icon: Icon(_reminders.contains(c.id) ? Icons.notifications_active : Icons.notifications_outlined),
                  label: Text(_reminders.contains(c.id) ? 'Reminder Active (Alert Set)' : 'Set Notification Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? userProvider.user?.id ?? '';

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_rounded, color: Color(0xFFEF4444), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Classroom',
                    style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Amazon AWS live streaming & doubt clearing',
                    style: TextStyle(color: _subTextColor, fontSize: 10, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFFFF7A00),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFF7A00),
              unselectedLabelColor: _subTextColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF7A00), size: 15),
                      SizedBox(width: 5),
                      Text('My Live Classes'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFFEF4444), size: 7),
                      SizedBox(width: 5),
                      Text('Live Now'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note_rounded, size: 14),
                      SizedBox(width: 5),
                      Text('Upcoming'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library_rounded, size: 14),
                      SizedBox(width: 5),
                      Text('Recordings'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 14),
                      SizedBox(width: 5),
                      Text('DPPs & Handouts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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

          return StreamBuilder<List<LiveClass>>(
            stream: _contentService.getLiveClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
                );
              }
              final List<LiveClass> allClasses = snapshot.data ?? [];

              // Compute dynamic subject chips
              final Set<String> dynamicSubjects = {'All'};
              for (final s in _defaultSubjects) {
                dynamicSubjects.add(s);
              }
              for (final c in allClasses) {
                if (c.subject.trim().isNotEmpty) {
                  dynamicSubjects.add(c.subject.trim());
                }
              }
              final List<String> subjectsList = dynamicSubjects.toList();

              // Filtered groups
              final myEnrolledFiltered = allClasses
                  .where((c) =>
                      c.isUserEnrolled(
                        uid: currentUid,
                        purchasedBatchIds: purchasedBatchIds,
                        purchasedItemIds: purchasedItemIds,
                      ) &&
                      _matchesFilter(c))
                  .toList();

              final liveNowFiltered = allClasses.where((c) => c.isLive && _matchesFilter(c)).toList();
              final upcomingFiltered = allClasses.where((c) => c.isUpcoming && _matchesFilter(c)).toList();
              final recordingsFiltered = allClasses.where((c) => c.isRecorded && _matchesFilter(c)).toList();

              return Column(
                children: [
                  // Search & Filter Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    color: _cardBg,
                    child: Column(
                      children: [
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: _subCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            style: TextStyle(color: _textColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search chapter, topic, or faculty...',
                              hintStyle: TextStyle(color: _subTextColor, fontSize: 12),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF7A00), size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close_rounded, color: _subTextColor, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: subjectsList.map((sub) {
                              final isSelected = _selectedSubject == sub;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(sub),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : _textColor,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    fontSize: 11.5,
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFFF7A00),
                                  backgroundColor: _subCardBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected ? const Color(0xFFFF7A00) : _borderColor,
                                    ),
                                  ),
                                  showCheckmark: false,
                                  onSelected: (val) {
                                    setState(() => _selectedSubject = sub);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Real-Time AWS Sync Banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDark
                            ? [const Color(0xFF0F264C), const Color(0xFF08172F)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isDark ? const Color(0xFF224B85) : const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.batchTitle ?? 'Amazon AWS Live Classroom',
                                    style: TextStyle(color: _textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('AWS IVS ACTIVE ✓', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ultra-low latency streaming • Real-time doubt chat • DPPs & Handouts',
                                style: TextStyle(color: _isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), fontSize: 8.5, fontWeight: FontWeight.w600),
                              ),
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
                        _buildMyLiveClassesTab(myEnrolledFiltered, currentUid, purchasedBatchIds, purchasedItemIds),
                        _buildClassListTab(liveNowFiltered, currentUid, purchasedBatchIds, purchasedItemIds, isLiveNowTab: true),
                        _buildClassListTab(upcomingFiltered, currentUid, purchasedBatchIds, purchasedItemIds, isUpcomingTab: true),
                        _buildClassListTab(recordingsFiltered, currentUid, purchasedBatchIds, purchasedItemIds, isRecordingTab: true),
                        _buildMaterialsAndTestsTab(),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 0: MY PURCHASED / ENROLLED LIVE CLASSES
  // ===========================================================================
  Widget _buildMyLiveClassesTab(
    List<LiveClass> enrolledClasses,
    String currentUid,
    Set<String> purchasedBatchIds,
    Set<String> purchasedItemIds,
  ) {
    if (enrolledClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF7A00), size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'No Enrolled Live Classes Yet',
                style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Any live classes you purchase or receive through enrolled batches will appear here automatically with direct 1-tap live access.',
                style: TextStyle(color: _subTextColor, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.explore_rounded, size: 16),
                label: const Text('Explore Active Live Classes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enrolledClasses.length,
      itemBuilder: (context, index) {
        final c = enrolledClasses[index];
        return _buildLiveClassCard(c, isEnrolled: true);
      },
    );
  }

  // ===========================================================================
  // TAB 1, 2, 3: CLASS LIST (Live Now, Upcoming, Recordings)
  // ===========================================================================
  Widget _buildClassListTab(
    List<LiveClass> list,
    String currentUid,
    Set<String> purchasedBatchIds,
    Set<String> purchasedItemIds, {
    bool isLiveNowTab = false,
    bool isUpcomingTab = false,
    bool isRecordingTab = false,
  }) {
    if (list.isEmpty) {
      String title = 'No Classes Found';
      String sub = 'Try adjusting your subject filters or search query.';
      if (isLiveNowTab) {
        title = 'No Live Classes Right Now';
        sub = 'Check "Upcoming" for today\'s scheduled live timetable or view past recordings.';
      } else if (isUpcomingTab) {
        title = 'No Upcoming Sessions';
        sub = 'New masterclasses are scheduled daily. Stay tuned!';
      } else if (isRecordingTab) {
        title = 'No Recordings Found';
        sub = 'Recordings will be published here after live sessions conclude.';
      }

      return _buildEmptyState(
        icon: isLiveNowTab
            ? Icons.sensors_off_rounded
            : (isUpcomingTab ? Icons.event_busy_rounded : Icons.video_library_outlined),
        title: title,
        subtitle: sub,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        final isEnrolled = c.isUserEnrolled(
          uid: currentUid,
          purchasedBatchIds: purchasedBatchIds,
          purchasedItemIds: purchasedItemIds,
        );
        return _buildLiveClassCard(c, isEnrolled: isEnrolled);
      },
    );
  }

  // ===========================================================================
  // REUSABLE LIVE CLASS CARD
  // ===========================================================================
  Widget _buildLiveClassCard(LiveClass c, {required bool isEnrolled}) {
    final color = c.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: c.isLive ? const Color(0xFFEF4444) : _borderColor,
          width: c.isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: c.isLive
                ? const Color(0xFFEF4444).withValues(alpha: _isDark ? 0.2 : 0.08)
                : Colors.black.withValues(alpha: _isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (c.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 7),
                        SizedBox(width: 4),
                        Text(
                          'LIVE NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (c.isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: Color(0xFF10B981), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'SCHEDULED',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_outline_rounded, color: Color(0xFF38BDF8), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'RECORDING AVAILABLE',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Enrolled / Price Badge
                Row(
                  children: [
                    if (isEnrolled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                            SizedBox(width: 4),
                            Text('ENROLLED ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      )
                    else if (c.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('FREE PREVIEW', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₹${c.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Title & Faculty Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.subject.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (c.batchName.isNotEmpty || c.batchId.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _navigateToBatch(c),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF0070F3).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.class_outlined, color: Color(0xFF38BDF8), size: 10),
                              const SizedBox(width: 3),
                              Text(
                                c.batchName.isNotEmpty ? c.batchName.toUpperCase() : 'BATCH',
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8.5, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (c.examCategory.isNotEmpty && c.examCategory != 'All Exams') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.examCategory.toUpperCase(),
                          style: TextStyle(color: _subTextColor, fontSize: 8.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.title,
                  style: TextStyle(color: _textColor, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  c.chapter,
                  style: TextStyle(color: _subTextColor, fontSize: 11.5),
                ),
                const SizedBox(height: 10),

                // Teacher Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Text(
                        c.instructor.isNotEmpty ? c.instructor[0] : 'E',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.instructor,
                            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            c.qualification,
                            style: TextStyle(color: _subTextColor, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          c.time,
                          style: TextStyle(color: _textColor, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${c.durationMinutes} mins',
                          style: TextStyle(color: _subTextColor, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _subCardBg,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isEnrolled) {
                        if (c.isLive || c.isRecorded) {
                          _openLiveClass(c);
                        } else {
                          _showWaitingRoom(c);
                        }
                      } else {
                        _openCheckout(c);
                      }
                    },
                    icon: Icon(
                      isEnrolled
                          ? (c.isLive
                              ? Icons.play_circle_fill_rounded
                              : (c.isRecorded ? Icons.replay_rounded : Icons.timer_outlined))
                          : Icons.shopping_bag_rounded,
                      size: 17,
                    ),
                    label: Text(
                      isEnrolled
                          ? (c.isLive
                              ? 'JOIN LIVE CLASS'
                              : (c.isRecorded ? 'WATCH RECORDING' : 'WAITING ROOM'))
                          : 'ENROLL (₹${c.price.toStringAsFixed(0)})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.isLive ? const Color(0xFFEF4444) : const Color(0xFFFF7A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _openPdfNotes(c.title, c.subject, c.notesUrl),
                    icon: const Icon(Icons.menu_book_rounded, size: 15),
                    label: const Text('PDF Notes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textColor,
                      side: BorderSide(color: _borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _subTextColor.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: _subTextColor, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: BATCH INCLUSIONS (MATERIALS & TESTS)
  // ===========================================================================
  Widget _buildMaterialsAndTestsTab() {
    return StreamBuilder<List<ResourceItem>>(
      stream: _contentService.getResources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)));
        }
        final resources = snapshot.data ?? [];
        if (resources.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No Handouts or DPPs Available',
            subtitle: 'Lecture materials and practice problem sheets will be uploaded after class.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final res = resources[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.title,
                          style: TextStyle(color: _textColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${res.subject} • ${res.fileSize}',
                          style: TextStyle(color: _subTextColor, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(pdfData: res),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    child: const Text('Open PDF'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
