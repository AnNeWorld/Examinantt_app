import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../models/community_message_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../constants/app_colors.dart';
import '../screens/courses_screen.dart';
import '../screens/test_series_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/pyqs_screen.dart';
import '../screens/doubts_screen.dart';
import '../screens/analytics_screen.dart';
import '../services/analytics_service.dart';
import '../models/analytics_model.dart';
import '../screens/community_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/live_classes_screen.dart';
import '../screens/video_player_screen.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';

/// Master container for all 9 sections from "unlocked home.pdf"
class UnlockedHomeSections extends StatefulWidget {
  const UnlockedHomeSections({super.key});

  @override
  State<UnlockedHomeSections> createState() => _UnlockedHomeSectionsState();
}

class _UnlockedHomeSectionsState extends State<UnlockedHomeSections> {
  // Global / shared state across unlocked sections
  int _activeAnalyticsTab = 0;
  int _activeResourceTab = 0;

  // Study plan interactive states
  final Set<int> _completedPlanTasks = {0, 1}; // Default first 2 completed
  final Set<int> _reminderSetClasses = {}; // Track reminders set

  void _showSnack(String message, {Color color = AppColors.accent, IconData icon = Icons.check_circle_rounded}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final studentName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim().split(' ').first
        : 'Student';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Live Video Card (Shown first whenever a live class is active)
        _buildTopLiveStreamHero(),

        // Section 01: Active Batch
        _buildSection01ActiveBatch(studentName),
        const SizedBox(height: 16),

        // Section 02: Exam Preparation Overview
        _buildSection02Overview(),
        const SizedBox(height: 16),

        // Section 03: Today's Study Plan
        _buildSection03StudyPlan(),
        const SizedBox(height: 16),

        // Section 04: Live Classroom
        _buildSection04LiveClassroom(),
        const SizedBox(height: 16),

        // Section 05: Continue Learning
        _buildSection05ContinueLearning(),
        const SizedBox(height: 16),

        // Section 06: Performance & Analytics
        _buildSection06PerformanceAnalytics(),
        const SizedBox(height: 16),

        // Section 07: Community & Support
        _buildSection07CommunitySupport(),
        const SizedBox(height: 16),

        // Section 08: Resources & Study Tools
        _buildSection08ResourcesTools(),
        const SizedBox(height: 16),

        // Section 09: Progress & Performance
        _buildSection09ProgressPerformance(studentName),
        const SizedBox(height: 32),
      ],
    );
  }

  // ==========================================
  // SHARED SECTION CARD DECORATION & BADGE
  // ==========================================
  Widget _buildSectionShell({
    String? sectionNumber,
    required String sectionTag,
    required IconData sectionIcon,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF071326),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? const Color(0xFF162D50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D2342),
                  const Color(0xFF071326),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF142B4D), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0070F3), Color(0xFF0051B3)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0070F3).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(sectionIcon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sectionTag,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BATCH BENEFITS MODAL (Bottom Sheet)
  // ==========================================
  void _showAllBenefitsModal(List<Map<String, dynamic>> benefits, String targetExam) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1326),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0070F3), Color(0xFF0052CC)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$targetExam • Batch Benefits',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'All 9 premium features are unlocked and active',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2242),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1C3A66)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildModalStatPill('9 / 9', 'Features Active', const Color(0xFF10B981)),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildModalStatPill('Till Exam', 'Batch Validity', const Color(0xFF38BDF8)),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildModalStatPill('Full Access', 'Premium Pass', const Color(0xFFFBBF24)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Benefits List
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: benefits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final b = benefits[index];
                        final Color itemColor = b['color'] as Color;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => b['dest'] as Widget),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1E3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: itemColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: itemColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Icon(b['icon'] as IconData, color: itemColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            b['title'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, color: Color(0xFF10B981), size: 9),
                                                SizedBox(width: 2),
                                                Text(
                                                  'UNLOCKED',
                                                  style: TextStyle(color: Color(0xFF10B981), fontSize: 7.5, fontWeight: FontWeight.w800),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        b['desc'] as String,
                                        style: const TextStyle(color: Colors.white60, fontSize: 10.5, height: 1.25),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Open',
                                        style: TextStyle(color: itemColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.arrow_forward_ios_rounded, color: itemColor, size: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Button
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Start Studying', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildModalStatPill(String title, String subtitle, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 1),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 8.5)),
      ],
    );
  }

  // ===========================================================================
  // TOP LIVE STREAM HERO: Real-time Live Class from Website / Firestore
  // ===========================================================================
  Widget _buildTopLiveStreamHero() {
    return StreamBuilder<List<LiveClass>>(
      stream: ContentService().getLiveClasses(),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        if (classes.isEmpty) return const SizedBox.shrink();

        final liveClasses = classes.where((c) => c.isLive).toList();
        if (liveClasses.isEmpty) return const SizedBox.shrink();

        final heroClass = liveClasses.first;
        final color = heroClass.color;

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2B0A1A), Color(0xFF0F1A3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Badge + Viewers / Time
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
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
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (heroClass.activeViewers.isNotEmpty && heroClass.activeViewers != '0')
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF38BDF8), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${heroClass.activeViewers} watching',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      Text(
                        heroClass.time,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),

              // Title & Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                            heroClass.subject.toUpperCase(),
                            style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (heroClass.examCategory.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              heroClass.examCategory.toUpperCase(),
                              style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      heroClass.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      heroClass.chapter,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Teacher details
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Text(
                            heroClass.instructor.isNotEmpty ? heroClass.instructor[0] : 'E',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heroClass.instructor,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                              Text(
                                heroClass.qualification,
                                style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF001128),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                title: heroClass.title,
                                instructor: heroClass.instructor,
                                videoUrl: heroClass.videoUrl,
                                isLive: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                        label: const Text(
                          'JOIN LIVE STREAM',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LiveClassesScreen(initialTab: 0),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF224B85)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('All Classes', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
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

  // ==========================================
  // SECTION 01: ACTIVE BATCH (Page 2)
  // ==========================================
  Widget _buildSection01ActiveBatch(String studentName) {
    final userProvider = Provider.of<UserProvider>(context);
    final displayExam = userProvider.selectedExam;

    final batchBenefits = [
      {
        'title': 'Live Classes',
        'tag': 'Daily Live',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFFF43F5E),
        'dest': const LiveClassesScreen(initialTab: 0),
        'desc': 'Interactive classes with top IITian faculty & real-time chat doubts.',
      },
      {
        'title': 'Recorded Lectures',
        'tag': '1080p HD',
        'icon': Icons.play_circle_fill_rounded,
        'color': const Color(0xFF38BDF8),
        'dest': const LiveClassesScreen(initialTab: 2),
        'desc': '24/7 unlimited playback with 2x speed control and chapter bookmarks.',
      },
      {
        'title': 'Study Notes',
        'tag': 'PDF Notes',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF10B981),
        'dest': const ResourcesScreen(),
        'desc': 'Comprehensive chapter notes, mind maps and formula cheat sheets.',
      },
      {
        'title': 'Practice Questions',
        'tag': '5,000+ Qs',
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFFF59E0B),
        'dest': const ResourcesScreen(),
        'desc': 'Level-wise chapter question bank with step-by-step solutions.',
      },
      {
        'title': 'Test Series',
        'tag': 'All India',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFFA855F7),
        'dest': const TestSeriesScreen(),
        'desc': 'Chapter tests, full mocks with All-India rank & percentile prediction.',
      },
      {
        'title': 'PYQs',
        'tag': '15+ Years',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF6366F1),
        'dest': const PyqsScreen(),
        'desc': 'Past 15 years solved papers with question pattern analysis.',
      },
      {
        'title': 'Revision',
        'tag': 'Formula Books',
        'icon': Icons.history_rounded,
        'color': const Color(0xFFEC4899),
        'dest': const ResourcesScreen(),
        'desc': 'Quick glance formula sheets, mind maps & one-shot revision notes.',
      },
      {
        'title': 'Analytics',
        'tag': 'AI Radar',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF06B6D4),
        'dest': const AnalyticsScreen(),
        'desc': 'AI strength & weakness analysis, accuracy rate and speed metrics.',
      },
      {
        'title': 'Doubt Support',
        'tag': '24x7 Faculty',
        'icon': Icons.help_outline_rounded,
        'color': const Color(0xFF14B8A6),
        'dest': const DoubtsScreen(),
        'desc': 'Ask unlimited doubts & get verified faculty answers in minutes.',
      },
    ];

    return _buildSectionShell(
      sectionNumber: '01',
      sectionTag: 'ACTIVE BATCH',
      sectionIcon: Icons.shield_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE ENROLLMENT',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'You are preparing for',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayExam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0070F3), Color(0xFF0052CC)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 11),
                          SizedBox(width: 4),
                          Text(
                            'Selection Batch ★',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Batch Validity: Till Exam Day',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side metrics (Days + Circular Ring)
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1E3C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E3F70)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132F5C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Text('DAYS TO EXAM', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('187', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            Text('Days Remaining', style: TextStyle(color: Colors.white54, fontSize: 8)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 0.64,
                              strokeWidth: 6,
                              backgroundColor: const Color(0xFF152D54),
                              color: const Color(0xFF38BDF8),
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '64%',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                Text(
                                  'Overall Prep',
                                  style: TextStyle(color: Colors.white54, fontSize: 7),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Your Batch Includes container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1B36), Color(0xFF071224)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1B3C6B)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0070F3).withValues(alpha: 0.08),
                  blurRadius: 16,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF38BDF8), size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Batch Includes',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                            ),
                            Text(
                              '9 of 9 Features Active',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showAllBenefitsModal(batchBenefits, displayExam),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All Benefits',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 9 Batch Benefits Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.08,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: batchBenefits.length,
                  itemBuilder: (context, index) {
                    final item = batchBenefits[index];
                    final Color itemColor = item['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => item['dest'] as Widget));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F3D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: itemColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: itemColor, size: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 8),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['tag'] as String,
                                  style: TextStyle(
                                    color: itemColor.withValues(alpha: 0.9),
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 02: EXAM PREPARATION OVERVIEW (Page 3)
  // ==========================================
  Widget _buildSection02Overview() {
    return _buildSectionShell(
      sectionNumber: '02',
      sectionTag: 'OVERVIEW',
      sectionIcon: Icons.pie_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Preparation Overview ⓘ',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your overall progress across all subjects',
                      style: TextStyle(color: Colors.white54, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2244),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('187 Days Left', style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quote banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF091C38),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E4072)),
            ),
            child: const Row(
              children: [
                Icon(Icons.format_quote_rounded, color: Color(0xFF38BDF8), size: 14),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Consistency today, excellence tomorrow. Keep going! You\'re doing great.',
                    style: TextStyle(color: Colors.white70, fontSize: 9, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Overall Preparation Box + Progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF091B36),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E3D6E)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 0.64,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFF132A4F),
                            color: const Color(0xFF0070F3),
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('64%', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              Text('Prepared', style: TextStyle(color: Colors.white54, fontSize: 7)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You\'re ahead of 62% of your batchmates',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '↑ +8% Improved from last week',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.white54, size: 10),
                              SizedBox(width: 3),
                              Text('Study Time: 128h 45m', style: TextStyle(color: Colors.white70, fontSize: 8.5)),
                            ],
                          ),
                          const Row(
                            children: [
                              Icon(Icons.assignment_turned_in_outlined, color: Colors.white54, size: 10),
                              SizedBox(width: 3),
                              Text('Tests Attempted: 48', style: TextStyle(color: Colors.white70, fontSize: 8.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                    },
                    icon: const Icon(Icons.bar_chart_rounded, size: 14),
                    label: const Text('VIEW DETAILED ANALYSIS >', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0070F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subject Wise Progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF091B36),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E3D6E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subject Wise Progress', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                      },
                      child: const Text('View All >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSubjectProgressRow('Physics', 0.71, '71%', 'Good', const Color(0xFF3B82F6), Icons.science_outlined),
                const SizedBox(height: 6),
                _buildSubjectProgressRow('Chemistry', 0.63, '63%', 'Average', const Color(0xFF10B981), Icons.biotech_outlined),
                const SizedBox(height: 6),
                _buildSubjectProgressRow('Mathematics', 0.58, '58%', 'Focus', const Color(0xFFF97316), Icons.functions_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressRow(String subject, double progress, String percentage, String status, Color color, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 12),
                  const SizedBox(width: 4),
                  Text(subject, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  Text(percentage, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF152A4A),
            color: color,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 03: TODAY'S STUDY PLAN (Page 4)
  // ==========================================
  Widget _buildSection03StudyPlan() {
    return StreamBuilder<List<ResourceItem>>(
      stream: ContentService().getResources(),
      builder: (context, snapshot) {
        final resources = snapshot.data ?? [];
        final planItems = resources.take(5).map((r) => {
          'title': '${r.subject.isNotEmpty ? r.subject : 'Preparation'} – ${r.title}',
          'sub': '${r.type} • ${r.description.isNotEmpty ? r.description : 'Study Module'}',
          'duration': '30 min',
          'dest': r.url.isNotEmpty 
              ? PdfViewerScreen(pdfData: r)
              : const ResourcesScreen(),
        }).toList();

        return _buildSectionShell(
          sectionNumber: '03',
          sectionTag: 'TODAY\'S PLAN',
          sectionIcon: Icons.event_note_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Today\'s Study Plan',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0070F3), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0070F3).withValues(alpha: 0.35),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 9),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('d MMM').format(DateTime.now()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Personalized daily plan for consistent progress', style: TextStyle(color: Colors.white54, fontSize: 9.5), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showSnack('Plan Settings opened'),
                    icon: const Icon(Icons.settings, size: 11),
                    label: const Text('Settings', style: TextStyle(fontSize: 9)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF1E3A68)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Plan KPI row
              Row(
                children: [
                  Expanded(child: _buildBadgeMini('Tasks', '${_completedPlanTasks.length}/${planItems.length}', 'Completed', Icons.checklist, const Color(0xFFA855F7))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildBadgeMini('Progress', planItems.isNotEmpty ? '${((_completedPlanTasks.length / planItems.length) * 100).toInt()}%' : '0%', 'Real-time', Icons.pie_chart, const Color(0xFF10B981))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildBadgeMini('Pending', '${planItems.length - _completedPlanTasks.length}', 'Remaining', Icons.hourglass_bottom, const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 12),

              // Tasks list or empty state
              if (planItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF091C36),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1B3864)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_available_rounded, color: Colors.white24, size: 28),
                      SizedBox(height: 6),
                      Text(
                        'No study tasks scheduled for today',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Explore batches and resources to begin your daily learning plan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 9),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: planItems.length,
                  itemBuilder: (context, index) {
                    final task = planItems[index];
                    final isDone = _completedPlanTasks.contains(index);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091C36),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFF1B3864),
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isDone) {
                                  _completedPlanTasks.remove(index);
                                } else {
                                  _completedPlanTasks.add(index);
                                }
                              });
                              _showSnack(isDone ? 'Marked task as pending' : 'Great job! Task completed 🎉');
                            },
                            child: Icon(
                              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isDone ? const Color(0xFF10B981) : Colors.white38,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => task['dest'] as Widget));
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title'] as String,
                                    style: TextStyle(
                                      color: isDone ? Colors.white54 : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    task['sub'] as String,
                                    style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFF0070F3).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task['duration'] as String,
                              style: TextStyle(
                                color: isDone ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => task['dest'] as Widget));
                            },
                            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 6),

              // Daily Goal & Streak mini bar
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C203E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF173562)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 14),
                          SizedBox(width: 4),
                          Text('Daily Goal Active', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('View Detailed Plan', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8.5, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 7.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 04: LIVE CLASSROOM (Page 5)
  // ==========================================
  Widget _buildSection04LiveClassroom() {
    return StreamBuilder<List<LiveClass>>(
      stream: ContentService().getLiveClasses(),
      builder: (context, snapshot) {
        final List<LiveClass> classes = snapshot.data ?? [];
        final liveClasses = classes.where((c) => c.isLive).toList();
        final upcomingClasses = classes.where((c) => c.isUpcoming).toList();
        final LiveClass? heroClass = liveClasses.isNotEmpty
            ? liveClasses.first
            : (upcomingClasses.isNotEmpty ? upcomingClasses.first : (classes.isNotEmpty ? classes.first : null));

        final bool isCurrentlyLive = heroClass?.isLive == true;

        return _buildSectionShell(
          sectionNumber: '04',
          sectionTag: 'LIVE CLASSROOM',
          sectionIcon: Icons.sensors_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Live Classroom', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 5),
                      Icon(Icons.circle, color: isCurrentlyLive ? Colors.red : const Color(0xFF10B981), size: 8),
                      const SizedBox(width: 4),
                      if (isCurrentlyLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LIVE NOW', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveClassesScreen(initialTab: 1)));
                    },
                    child: const Text('View Full Schedule >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Green banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 12),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You\'re all set! Join live classes, interact with faculty and learn in real time.',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Hero Live / Upcoming Card
              if (heroClass != null)
                GestureDetector(
                  onTap: () {
                    if (isCurrentlyLive) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            title: heroClass.title,
                            instructor: heroClass.instructor,
                            videoUrl: heroClass.videoUrl,
                            isLive: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveClassesScreen(initialTab: 0)));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCurrentlyLive
                            ? const [Color(0xFF260D1E), Color(0xFF0F1A3B)]
                            : const [Color(0xFF0F264C), Color(0xFF0A1832)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentlyLive ? Colors.redAccent.withValues(alpha: 0.6) : const Color(0xFF224B85),
                        width: isCurrentlyLive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrentlyLive ? Colors.red : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, color: Colors.white, size: 6),
                                  const SizedBox(width: 3),
                                  Text(
                                    isCurrentlyLive ? 'LIVE NOW' : 'UPCOMING SESSION',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isCurrentlyLive ? '${heroClass.remainingTime} left' : heroClass.time,
                              style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: heroClass.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: heroClass.color.withValues(alpha: 0.4)),
                              ),
                              child: Icon(Icons.school, color: heroClass.color, size: 30),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    heroClass.subject.toUpperCase(),
                                    style: TextStyle(color: heroClass.color, fontSize: 8, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    heroClass.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    heroClass.chapter,
                                    style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${heroClass.instructor} • ${heroClass.qualification}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, color: Colors.white54, size: 11),
                            const SizedBox(width: 3),
                            Text('${heroClass.activeViewers} Students Live', style: const TextStyle(color: Colors.white54, fontSize: 8.5)),
                            const SizedBox(width: 12),
                            const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 11),
                            const SizedBox(width: 3),
                            const Text('Live Chat Active', style: TextStyle(color: Colors.white54, fontSize: 8.5)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (isCurrentlyLive) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          title: heroClass.title,
                                          instructor: heroClass.instructor,
                                          videoUrl: heroClass.videoUrl,
                                          isLive: true,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveClassesScreen(initialTab: 0)));
                                  }
                                },
                                icon: const Icon(Icons.play_circle_fill_rounded, size: 14),
                                label: Text(isCurrentlyLive ? 'JOIN LIVE NOW' : 'VIEW DETAILS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCurrentlyLive ? const Color(0xFFFF5722) : const Color(0xFFFF7A00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LiveClassesScreen(initialTab: 2),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF224B85)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Recordings', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF071938),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1B3A68)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sensors_off_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Live Classes Active',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Live sessions scheduled by faculty will appear here in real-time.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Upcoming classes list
              const Text('Upcoming Classes', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              if (upcomingClasses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081C38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('No more scheduled classes today. Check full schedule.', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                  ),
                )
              else
                ...upcomingClasses.take(3).map((c) {
                  final isReminderSet = _reminderSetClasses.contains(c.id.hashCode);
                  final Color itemColor = c.color;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveClassesScreen(initialTab: 1)));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081C38),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1B3A68)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 32,
                            decoration: BoxDecoration(
                              color: itemColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c.subject.toUpperCase()} • ${c.time}',
                                  style: TextStyle(color: itemColor, fontSize: 8, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  c.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${c.chapter} • ${c.instructor}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 8),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                final id = c.id.hashCode;
                                if (isReminderSet) {
                                  _reminderSetClasses.remove(id);
                                } else {
                                  _reminderSetClasses.add(id);
                                }
                              });
                              _showSnack(isReminderSet ? 'Reminder cancelled' : 'Reminder set for ${c.title}! 🔔');
                            },
                            icon: Icon(
                              isReminderSet ? Icons.notifications_active : Icons.notifications_none,
                              size: 11,
                              color: isReminderSet ? Colors.amber : const Color(0xFF38BDF8),
                            ),
                            label: Text(
                              isReminderSet ? 'Set' : 'Remind',
                              style: TextStyle(
                                fontSize: 8.5,
                                color: isReminderSet ? Colors.amber : const Color(0xFF38BDF8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              // 4 Live Classroom Benefits
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildClassFeatureItem('Live Interaction', 'Instant doubt clearing', Icons.forum_rounded, 0)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildClassFeatureItem('Recordings', 'Available 24/7 anytime', Icons.play_circle_outline_rounded, 2)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildClassFeatureItem('Class Notes', 'Shared as PDFs', Icons.note_alt_outlined, 2)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildClassFeatureItem('Never Miss', 'Smart push alerts', Icons.alarm_on_rounded, 1)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassFeatureItem(String title, String sub, IconData icon, [int tabIndex = 0]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LiveClassesScreen(initialTab: tabIndex)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF091C36),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16325B)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 14),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 6.5), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 05: CONTINUE LEARNING (Page 6)
  // ==========================================
  Widget _buildSection05ContinueLearning() {
    return StreamBuilder<List<LiveClass>>(
      stream: ContentService().getLiveClasses(),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];

        return _buildSectionShell(
          sectionNumber: '05',
          sectionTag: 'CONTINUE LEARNING',
          sectionIcon: Icons.play_lesson_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Continue Learning', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                        SizedBox(height: 2),
                        Text('Pick up where you left off', style: TextStyle(color: Colors.white54, fontSize: 9.5), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
                    },
                    child: const Text('View All Courses >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (classes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C2448),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E4378)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.video_collection_outlined, color: Colors.white24, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'No ongoing lectures found',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse batches and live classes to start your journey.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 9.5),
                      ),
                    ],
                  ),
                )
              else ...[
                // Primary Continue Card from latest class
                Builder(
                  builder: (context) {
                    final heroClass = classes.first;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0C2448), Color(0xFF07172F)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1E4378)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(
                                        title: heroClass.title,
                                        instructor: heroClass.instructor,
                                        videoUrl: heroClass.videoUrl,
                                        isLive: heroClass.isLive,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 75,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF173562),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2A5796)),
                                  ),
                                  child: const Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.video_library_rounded, color: Colors.white24, size: 28),
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Color(0xFF10B981),
                                        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${heroClass.subject.toUpperCase()} • IN PROGRESS',
                                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7.5, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      heroClass.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      heroClass.chapter,
                                      style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, color: Colors.white54, size: 10),
                                        const SizedBox(width: 3),
                                        Text(heroClass.instructor, style: const TextStyle(color: Colors.white70, fontSize: 8)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          title: heroClass.title,
                                          instructor: heroClass.instructor,
                                          videoUrl: heroClass.videoUrl,
                                          isLive: heroClass.isLive,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_circle_fill_rounded, size: 14),
                                  label: const Text('Resume Learning', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0070F3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                const SizedBox(height: 12),

                // Classes list
                if (classes.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Other Lectures', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveClassesScreen(initialTab: 0)));
                        },
                        child: const Text('See All >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: classes.length - 1,
                      itemBuilder: (context, index) {
                        final item = classes[index + 1];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  title: item.title,
                                  instructor: item.instructor,
                                  videoUrl: item.videoUrl,
                                  isLive: item.isLive,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF071C38),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1B3B69)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.subject.toUpperCase(),
                                  style: TextStyle(color: item.color, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.chapter,
                                  style: const TextStyle(color: Colors.white54, fontSize: 8),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.white38, size: 9),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        item.instructor,
                                        style: const TextStyle(color: Colors.white70, fontSize: 7.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 06: PERFORMANCE & ANALYTICS (Page 7)
  // ==========================================
  Widget _buildSection06PerformanceAnalytics() {
    final subTabs = ['Overview', 'Subjects', 'Tests', 'Topics', 'Time', 'Comparative'];

    return _buildSectionShell(
      sectionNumber: '06',
      sectionTag: 'PERFORMANCE & ANALYTICS',
      sectionIcon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Performance & Analytics 📈', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('Track progress and improve every day', style: TextStyle(color: Colors.white54, fontSize: 9.5), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showSnack('Analytics Report downloaded! 📥'),
                icon: const Icon(Icons.download, size: 10),
                label: const Text('Report', style: TextStyle(fontSize: 8.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16345C),
                  foregroundColor: const Color(0xFF38BDF8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sub-tabs row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subTabs.asMap().entries.map((e) {
                final isSel = e.key == _activeAnalyticsTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeAnalyticsTab = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF0070F3) : const Color(0xFF0C2244),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? const Color(0xFF0070F3) : const Color(0xFF1A3866)),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.white70,
                        fontSize: 9,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Dynamic Performance Analytics Stream
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final uid = userProvider.user?.uid;
              return StreamBuilder<List<TestResult>>(
                stream: AnalyticsService().getUserTestResultsStream(uid),
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  final stats = AnalyticsService().getOverallAnalytics(results);
                  final attemptedStr = '${stats.totalTests}';
                  final accuracyStr = '${stats.averageAccuracy.toStringAsFixed(1)}%';
                  final avgScoreStr = stats.totalTests > 0 ? '${stats.averageScore.toStringAsFixed(0)}%' : '0%';
                  final studyTimeStr = stats.formattedTotalStudyTime;

                  final sortedByAccDesc = List<SubjectAnalytics>.from(stats.subjectAnalytics)
                    ..sort((a, b) => b.accuracy.compareTo(a.accuracy));
                  final sortedByAccAsc = List<SubjectAnalytics>.from(stats.subjectAnalytics)
                    ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

                  final topStrengths = sortedByAccDesc.take(3).toList();
                  final topWeaknesses = sortedByAccAsc.take(3).toList();

                  final latestScoreStr = results.isNotEmpty
                      ? 'Latest: ${results.first.score} / ${results.first.totalMarks}'
                      : 'No tests yet';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 Metric KPI Cards Row
                      Row(
                        children: [
                          Expanded(child: _buildAnalyticsMetricCard('Attempted', attemptedStr, '${stats.totalTests} Tests', Icons.assignment_outlined, const Color(0xFF38BDF8))),
                          const SizedBox(width: 4),
                          Expanded(child: _buildAnalyticsMetricCard('Accuracy', accuracyStr, 'Overall', Icons.center_focus_strong, const Color(0xFF10B981))),
                          const SizedBox(width: 4),
                          Expanded(child: _buildAnalyticsMetricCard('Avg Score', avgScoreStr, 'Peak ${stats.highestScore.toStringAsFixed(0)}%', Icons.military_tech_outlined, const Color(0xFFA855F7))),
                          const SizedBox(width: 4),
                          Expanded(child: _buildAnalyticsMetricCard('Study Time', studyTimeStr, 'Duration', Icons.timer_outlined, const Color(0xFFF59E0B))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Overall Progress graph card
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081C38),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B3B69)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Overall Progress Trend', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text(latestScoreStr, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 70,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _ProgressChartPainter(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: results.take(4).map((r) => Text(
                                  '${r.attemptedAt.day}/${r.attemptedAt.month}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 7),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Strengths & Weaknesses
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081C38),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B3B69)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF10B981), size: 12),
                                        SizedBox(width: 4),
                                        Text('Your Strengths', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (topStrengths.isNotEmpty)
                                      ...topStrengths.map((s) => _buildBulletItem('${s.subjectName} (${s.accuracy.toStringAsFixed(0)}%)'))
                                    else
                                      _buildBulletItem('Complete tests to unlock strengths'),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 60, color: const Color(0xFF1B3B69)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 12),
                                        SizedBox(width: 4),
                                        Text('Areas to Improve', style: TextStyle(color: Colors.orangeAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (topWeaknesses.isNotEmpty)
                                      ...topWeaknesses.map((w) => _buildBulletItem('${w.subjectName} (${w.accuracy.toStringAsFixed(0)}%)'))
                                    else
                                      _buildBulletItem('Complete tests to track weak areas'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMetricCard(String title, String val, String change, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF091C36),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1A3864)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900), maxLines: 1),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 7)),
            Text('↑ $change', style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.white38, size: 4),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 8), maxLines: 1)),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 07: COMMUNITY & SUPPORT (Page 8)
  // ==========================================
  Widget _buildSection07CommunitySupport() {
    final supportOptions = [
      {'title': 'Live Chat', 'sub': 'Online now (Instant)', 'icon': Icons.chat_rounded, 'action': 'Opening live chat...'},
      {'title': 'Email Support', 'sub': 'support@examinantt.com', 'icon': Icons.email_rounded, 'action': 'Email sent to support@examinantt.com'},
      {'title': 'WhatsApp Support', 'sub': '+91 9123456789', 'icon': Icons.phone_android_rounded, 'action': 'Opening WhatsApp support...'},
      {'title': 'Help Center', 'sub': 'Browse FAQs & Guides', 'icon': Icons.help_center_rounded, 'action': 'Opening Help Center...'},
    ];


    return _buildSectionShell(
      sectionNumber: '07',
      sectionTag: 'COMMUNITY & SUPPORT',
      sectionIcon: Icons.forum_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Community & Support 👥', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Learn together, grow together. Never feel alone on your journey.', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
          const SizedBox(height: 10),

          // 4 Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildCommunityActionCard(
                  'Community',
                  'Join Discussions',
                  Icons.groups_rounded,
                  const Color(0xFF38BDF8),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen())),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCommunityActionCard(
                  'Ask Doubts',
                  'Instant Solutions',
                  Icons.help_center_rounded,
                  const Color(0xFF10B981),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoubtsScreen())),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCommunityActionCard(
                  'Leaderboard',
                  'Top Performers',
                  Icons.emoji_events_rounded,
                  const Color(0xFFF59E0B),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Talk to Our Support Team Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F264C), Color(0xFF071730)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E4378)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: Color(0xFF38BDF8), size: 16),
                    SizedBox(width: 6),
                    Text('Talk to Our Support Team', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Average response time: Under 2 minutes', style: TextStyle(color: Color(0xFF10B981), fontSize: 8)),
                const SizedBox(height: 8),

                ...supportOptions.map((opt) {
                  return InkWell(
                    onTap: () {
                      _showSnack(opt['action'] as String);
                      if (opt['title'] == 'Help Center') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1E3C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(opt['icon'] as IconData, color: const Color(0xFF38BDF8), size: 13),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                Text(opt['sub'] as String, style: const TextStyle(color: Colors.white54, fontSize: 7.5)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 9),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // What's Happening in the Community Feed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('What\'s Happening in Community', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen())),
                child: const Text('View All >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          StreamBuilder<List<CommunityMessage>>(
            stream: FirestoreService().streamCommunityMessages(channel: 'general'),
            builder: (context, snapshot) {
              final List<CommunityMessage> messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'No community posts yet. Join the conversation!',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                );
              }
              return Column(
                children: messages.take(4).map((CommunityMessage msg) {
                  final initial = msg.senderName.isNotEmpty ? msg.senderName[0] : 'S';
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen())),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081C38),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF173562)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                            child: Text(initial, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg.senderName, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                Text(msg.text, style: const TextStyle(color: Colors.white60, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 8),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityActionCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF091C36),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1B3864)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 6.5), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 08: RESOURCES & STUDY TOOLS (Page 9)
  // ==========================================
  Widget _buildSection08ResourcesTools() {
    final resourceTabs = ['All', 'Notes & PDFs', 'Practice', 'Exam Prep', 'Calculators'];

    final tools = [
      {'title': 'Notes & Study Material', 'count': '120+', 'icon': Icons.description_outlined, 'color': const Color(0xFF38BDF8), 'dest': const ResourcesScreen()},
      {'title': 'Question Bank', 'count': '5000+', 'icon': Icons.quiz_outlined, 'color': const Color(0xFFA855F7), 'dest': const ResourcesScreen()},
      {'title': 'Previous Year Papers', 'count': '50+', 'icon': Icons.history_edu_outlined, 'color': const Color(0xFF10B981), 'dest': const PyqsScreen()},
      {'title': 'Recorded Lectures', 'count': '300+', 'icon': Icons.video_collection_outlined, 'color': const Color(0xFFF59E0B), 'dest': const CoursesScreen()},
    ];

    // Dynamic Download Center populated directly from Firestore Resources

    return _buildSectionShell(
      sectionNumber: '08',
      sectionTag: 'RESOURCES & STUDY TOOLS',
      sectionIcon: Icons.menu_book_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resources & Study Tools 📄', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber, size: 10),
                    SizedBox(width: 2),
                    Text('Premium Access', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: resourceTabs.asMap().entries.map((e) {
                final isSel = e.key == _activeResourceTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeResourceTab = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF0070F3) : const Color(0xFF0B1E3B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSel ? const Color(0xFF0070F3) : const Color(0xFF1B3864)),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 8.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 4 Big Resource Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              final Color toolColor = tool['color'] as Color;

              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => tool['dest'] as Widget));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF091C36),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1B3B69)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: toolColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(tool['icon'] as IconData, color: toolColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tool['title'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tool['count'] as String,
                              style: TextStyle(color: toolColor, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Download Center List
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF091B36),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3D6E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Download Center', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
                      },
                      child: const Text('View All >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                StreamBuilder<List<ResourceItem>>(
                  stream: ContentService().getResources(),
                  builder: (context, snapshot) {
                    final resList = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting && resList.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    if (resList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: Text(
                            'No downloadable documents found in this batch',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: resList.take(4).map((doc) {
                        return GestureDetector(
                          onTap: () {
                            if (doc.url.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewerScreen(
                                    pdfData: doc,
                                  ),
                                ),
                              );
                            } else {
                              _showSnack('Opening ${doc.title}... 📄');
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF061426),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.title, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 1),
                                      Text('${doc.subject} • ${doc.type}', style: const TextStyle(color: Colors.white38, fontSize: 7)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, color: Color(0xFF38BDF8), size: 14),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    _showSnack('Downloaded ${doc.title} successfully! 📄');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 09: PROGRESS & PERFORMANCE (Page 10)
  // ==========================================
  Widget _buildSection09ProgressPerformance(String studentName) {
    final user = Provider.of<UserProvider>(context).user;
    final testsAttempted = user?.testsAttempted ?? 0;
    final accuracyVal = user?.accuracy ?? 0.0;
    final accuracyStr = '${accuracyVal.toInt()}%';
    final streakStr = '${user?.currentStreak ?? 0} Days';

    return _buildSectionShell(
      sectionNumber: '09',
      sectionTag: 'PROGRESS & PERFORMANCE',
      sectionIcon: Icons.auto_graph_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress & Performance 🚀', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Track growth, analyze your performance and stay ahead', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
          const SizedBox(height: 10),

          // Badges row
          Row(
            children: [
              Expanded(child: _buildBadgeMini('Tests', '$testsAttempted', 'Total', Icons.assignment_turned_in, Colors.cyan)),
              const SizedBox(width: 4),
              Expanded(child: _buildBadgeMini('Streak', streakStr, 'Active', Icons.local_fire_department, Colors.orange)),
              const SizedBox(width: 4),
              Expanded(child: _buildBadgeMini('Accuracy', accuracyStr, accuracyVal >= 75 ? 'Excellent' : (accuracyVal >= 50 ? 'Good' : 'Keep Going'), Icons.star_rounded, Colors.purpleAccent)),
              const SizedBox(width: 4),
              Expanded(child: _buildBadgeMini('Score', '${(user?.averageScore ?? 0).toInt()}', 'Average', Icons.emoji_events, Colors.amber)),
            ],
          ),
          const SizedBox(height: 12),

          // 72% Big Gauge Card
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F264C), Color(0xFF081A36)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E4378)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 0.72,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFF152D54),
                              color: const Color(0xFF0070F3),
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('72%', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                Text('Completed', style: TextStyle(color: Colors.white54, fontSize: 7)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Great going, $studentName!', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                            const Text('Keep pushing your limits!', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.assignment_turned_in, color: Colors.white54, size: 10),
                                const SizedBox(width: 3),
                                Text('Tests Attempted: $testsAttempted', style: const TextStyle(color: Colors.white70, fontSize: 8.5)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white54, size: 10),
                                const SizedBox(width: 3),
                                Text('Overall Accuracy: $accuracyStr', style: const TextStyle(color: Colors.white70, fontSize: 8.5)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.av_timer, color: Colors.white54, size: 10),
                                const SizedBox(width: 3),
                                Text('Study Time: ${(user?.totalStudyTimeMinutes ?? 0) ~/ 60}h ${(user?.totalStudyTimeMinutes ?? 0) % 60}m', style: const TextStyle(color: Colors.white70, fontSize: 8.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subject progress list
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF081C38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1B3B69)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subject Wise Progress', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildSubjectProgressRow('Physics', 0.82, '82%', '82%', const Color(0xFF8B5CF6), Icons.science),
                const SizedBox(height: 4),
                _buildSubjectProgressRow('Chemistry', 0.76, '76%', '76%', const Color(0xFF3B82F6), Icons.biotech),
                const SizedBox(height: 4),
                _buildSubjectProgressRow('Mathematics', 0.68, '68%', '68%', const Color(0xFF10B981), Icons.functions),
                const SizedBox(height: 4),
                _buildSubjectProgressRow('Biology', 0.74, '74%', '74%', const Color(0xFFEC4899), Icons.eco),
                const SizedBox(height: 4),
                _buildSubjectProgressRow('Mock Tests', 0.80, '80%', '80%', const Color(0xFFF59E0B), Icons.quiz),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Recent Activity Log
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF081C38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1B3B69)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                      child: const Text('View All >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                StreamBuilder<List<TestResult>>(
                  stream: TestService().getRecentTestResults(user?.uid ?? '', limit: 4),
                  builder: (context, snapshot) {
                    final List<TestResult> results = snapshot.data ?? [];
                    if (results.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            'No recent activity yet. Take a test to see your progress here!',
                            style: TextStyle(color: Colors.white38, fontSize: 9.5),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: results.map((TestResult res) {
                        final accuracy = (res.totalQuestions > 0)
                            ? '${((res.correctAnswers / res.totalQuestions) * 100).toInt()}%'
                            : '100%';
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(res.testTitle, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      Text('Scored ${res.score}/${res.totalMarks} ($accuracy accuracy)', style: const TextStyle(color: Colors.white54, fontSize: 7.5)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 8),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeMini(String title, String val, String sub, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF091C36),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1A3864)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900), maxLines: 1),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 6.5)),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for Section 06 trend graph
class _ProgressChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF163259)
      ..strokeWidth = 0.5;

    // Draw grid lines
    canvas.drawLine(Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), gridPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF0070F3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF0070F3).withValues(alpha: 0.3), const Color(0xFF0070F3).withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.65),
      Offset(size.width * 0.4, size.height * 0.55),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.8, size.height * 0.38),
      Offset(size.width, size.height * 0.2),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Fill area
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    canvas.drawPath(path, linePaint);

    // Draw dots
    for (final pt in points) {
      canvas.drawCircle(pt, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
