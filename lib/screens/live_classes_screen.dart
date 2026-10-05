import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';
import '../utils/app_theme.dart';
import 'video_player_screen.dart';
import 'pdf_viewer_screen.dart';

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
  Color get _textColor => _isDark ? Colors.white : AppTheme.darkSlate;
  Color get _subTextColor => _isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
  Color get _borderColor => _isDark ? Colors.white12 : Colors.grey.shade200;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ContentService _contentService = ContentService();
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
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
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

  void _openLivePlayer(String title, String teacher, String url, bool isLive) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          title: title,
          instructor: teacher,
          videoUrl: url,
          isLive: isLive,
        ),
      ),
    );
  }

  void _openPdfNotes(String title, String subject, String url) {
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
            exam: 'JEE / NEET 2027',
            price: 0.0,
            isPublic: true,
            description: 'Official verified faculty class presentation and annotated lecture notes.',
            url: url,
          ),
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
      backgroundColor: const Color(0xFF0F1E3D),
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
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'By ${c.instructor} • ${c.time}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class will start on scheduled time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: 2),
                          Text('Keep your notebook and pen ready. Faculty will start stream directly.', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Classroom',
                  style: TextStyle(color: _textColor, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Interactive sessions, recordings & doubt clearing',
                  style: TextStyle(color: _subTextColor, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              tabs: const [
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
                      Text('Batch Materials & Tests'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<LiveClass>>(
        stream: _contentService.getLiveClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
            );
          }
          final List<LiveClass> allClasses = snapshot.data ?? [];

          // Dynamically compute subjects list
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

          final liveNowFiltered = allClasses.where((c) => c.isLive && _matchesFilter(c)).toList();
          final upcomingFiltered = allClasses.where((c) => c.isUpcoming && _matchesFilter(c)).toList();
          final recordingsFiltered = allClasses.where((c) => c.isRecorded && _matchesFilter(c)).toList();

          return Column(
            children: [
              // Search & Subject Filter Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: const Color(0xFF071938),
                child: Column(
                  children: [
                    // Search field
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00122C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search chapter, topic, or faculty...',
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF7A00), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
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

                    // Dynamic Subject Filter Chips
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
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 11.5,
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF7A00),
                              backgroundColor: const Color(0xFF00122C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFFFF7A00) : Colors.white12,
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

              // Real-Time Live Sync Status Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F264C), Color(0xFF08172F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF224B85)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sync_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.batchTitle ?? 'Examinantt Live Arena',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('LIVE SYNC ✓', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Real-time streaming • Auto-synced with examinantt.com • DPPs & Handouts',
                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views with Real-Time Stream Data
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLiveNowTab(liveNowFiltered),
                    _buildUpcomingTab(upcomingFiltered),
                    _buildRecordingsTab(recordingsFiltered),
                    _buildMaterialsAndTestsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 1: LIVE NOW (Real-time synced)
  // ===========================================================================
  Widget _buildLiveNowTab(List<LiveClass> filtered) {
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sensors_off_rounded,
        title: 'No Live Classes Right Now',
        subtitle: 'Check the "Upcoming" tab for today\'s scheduled live sessions or watch previous recordings.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final color = c.color;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF071938),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                    ),
                    Row(
                      children: [
                        if (c.activeViewers.isNotEmpty && c.activeViewers != '0') ...[
                          const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${c.activeViewers} watching',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (c.remainingTime.isNotEmpty) ...[
                          const Icon(Icons.timelapse_rounded, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            c.remainingTime,
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Title & Info
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
                        if (c.examCategory.isNotEmpty && c.examCategory != 'All Exams') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.examCategory.toUpperCase(),
                              style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.chapter,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                    ),
                    const SizedBox(height: 8),

                    // Teacher card
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
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                c.qualification,
                                style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Action Buttons Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF00122C),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _openLivePlayer(
                          c.title,
                          c.instructor,
                          c.videoUrl,
                          true,
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                        label: const Text('JOIN LIVE NOW'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _openPdfNotes(
                          c.title,
                          c.subject,
                          c.notesUrl,
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: const Text('Class Notes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 2: UPCOMING SCHEDULE (Real-time synced)
  // ===========================================================================
  Widget _buildUpcomingTab(List<LiveClass> filtered) {
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No Upcoming Classes Found',
        subtitle: 'Try clearing the search query or selecting "All" subjects.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final id = c.id;
        final isReminderSet = _reminders.contains(id);
        final color = c.color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF071938),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Box
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00122C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      c.time.split(',').first,
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Icon(Icons.schedule, color: Colors.white54, size: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          c.time,
                          style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.subject,
                            style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.chapter} • ${c.instructor}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                    const SizedBox(height: 8),

                    // Actions
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _toggleReminder(id, c.title),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isReminderSet
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : const Color(0xFFFF7A00).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isReminderSet ? const Color(0xFF10B981) : const Color(0xFFFF7A00),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isReminderSet ? Icons.notifications_active : Icons.notifications_none_rounded,
                                  size: 13,
                                  color: isReminderSet ? const Color(0xFF10B981) : const Color(0xFFFF7A00),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isReminderSet ? 'Reminder Set' : 'Set Reminder',
                                  style: TextStyle(
                                    color: isReminderSet ? const Color(0xFF10B981) : const Color(0xFFFF7A00),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _showWaitingRoom(c),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Waiting Room >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: RECORDINGS (Real-time synced)
  // ===========================================================================
  Widget _buildRecordingsTab(List<LiveClass> filtered) {
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No Recorded Classes Found',
        subtitle: 'Try changing your subject filter or search terms.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final color = c.color;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF071938),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video thumbnail representation with play icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00122C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.video_collection_rounded, color: color.withValues(alpha: 0.3), size: 40),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7A00),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c.remainingTime,
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  c.subject.toUpperCase(),
                                  style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.time,
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.instructor + (c.examCategory.isNotEmpty && c.examCategory != 'All Exams' ? ' • ${c.examCategory}' : ''),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Button Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF00122C),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openLivePlayer(
                          c.title,
                          c.instructor,
                          c.videoUrl,
                          false,
                        ),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                        label: const Text('Watch Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openPdfNotes(
                          c.title,
                          c.subject,
                          c.notesUrl,
                        ),
                        icon: const Icon(Icons.description_outlined, size: 15),
                        label: const Text('PDF Notes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
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
        final filtered = resources.where((item) {
          if (_selectedSubject != 'All') {
            final sub = item.subject;
            final title = item.title;
            if (!sub.toLowerCase().contains(_selectedSubject.toLowerCase()) &&
                !title.toLowerCase().contains(_selectedSubject.toLowerCase())) {
              return false;
            }
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final full = '${item.title} ${item.subtitle} ${item.category}'.toLowerCase();
            return full.contains(q);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.menu_book_rounded,
            title: 'No Study Materials Found',
            subtitle: 'No real notes or materials match your active search and filter criteria in Firestore.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            final Color itemColor = item.subject.toLowerCase().contains('chem')
                ? const Color(0xFFF59E0B)
                : item.subject.toLowerCase().contains('math')
                    ? const Color(0xFFA855F7)
                    : const Color(0xFF38BDF8);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF071938),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: itemColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.subject.toUpperCase()} • ${item.type.toUpperCase()}',
                          style: TextStyle(color: itemColor, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 10),
                            SizedBox(width: 3),
                            Text(
                              'INCLUDED IN BATCH',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 7.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.subtitle.isNotEmpty ? item.subtitle : item.description} • ${item.fileSize}',
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPdfNotes(
                        item.title,
                        item.subject,
                        item.url,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                      label: const Text(
                        'Read Notes (PDF)',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: itemColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
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
