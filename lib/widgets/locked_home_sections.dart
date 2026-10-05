// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../models/community_message_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../screens/courses_screen.dart';
import '../screens/test_series_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/pyqs_screen.dart';
import '../screens/analytics_screen.dart';
import '../services/analytics_service.dart';
import '../models/test_model.dart';
import '../screens/doubts_screen.dart';
import '../screens/community_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/live_classes_screen.dart';
import '../screens/video_player_screen.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Complete Locked Home Screen Sections Widget matching all 8 pages of `locked home.pdf`.
/// Displayed whenever a student logs in and has not purchased any batch yet.
class LockedHomeSections extends StatefulWidget {
  final VoidCallback? onExploreBatches;

  const LockedHomeSections({
    super.key,
    this.onExploreBatches,
  });

  @override
  State<LockedHomeSections> createState() => _LockedHomeSectionsState();
}

class _LockedHomeSectionsState extends State<LockedHomeSections> {
  // Active states
  int _activeAnalyticsTabIndex = 0;
  String _activeResourceFilter = 'All Resources';

  void _navigateToBatches() {
    if (widget.onExploreBatches != null) {
      widget.onExploreBatches!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoursesScreen()),
      );
    }
  }

  void _purchaseSelectionBatch() {
    widget.onExploreBatches?.call();
  }

  void _showAllBenefitsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFA000), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'All Batch Benefits',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  children: [
                    _buildModalBenefitTile(Icons.videocam_rounded, const Color(0xFFF43F5E), 'Live Interactive Classes', 'Daily scheduled classes with India\'s top faculty and real-time live chat doubts.', const LiveClassesScreen(initialTab: 0)),
                    _buildModalBenefitTile(Icons.play_circle_fill_rounded, const Color(0xFF38BDF8), 'Recorded HD Lectures', 'Full library of past lectures accessible anytime in HD with 2x speed control.', const LiveClassesScreen(initialTab: 2)),
                    _buildModalBenefitTile(Icons.description_rounded, const Color(0xFF34D399), 'Comprehensive Study Notes', 'Chapter-wise revision notes, mind maps, formula sheets & PDFs.', const ResourcesScreen()),
                    _buildModalBenefitTile(Icons.edit_note_rounded, const Color(0xFFFBBF24), 'Practice Question Bank', '5,000+ chapter-wise and level-wise practice questions with detailed video solutions.', const ResourcesScreen()),
                    _buildModalBenefitTile(Icons.assignment_turned_in_rounded, const Color(0xFFA855F7), 'Full Length Test Series', 'Chapter tests, unit tests, and full-length all-India mock tests with percentile rankings.', const TestSeriesScreen()),
                    _buildModalBenefitTile(Icons.menu_book_rounded, const Color(0xFF8B5CF6), 'Previous Year Papers (PYQs)', '15+ years solved papers with step-by-step detailed explanations.', const PyqsScreen()),
                    _buildModalBenefitTile(Icons.history_rounded, const Color(0xFFE11D48), 'Quick Revision & Formula Sheets', 'Complete syllabus revision notes, formulas and mind maps.', const ResourcesScreen()),
                    _buildModalBenefitTile(Icons.insights_rounded, const Color(0xFF06B6D4), 'Smart AI Analytics', 'Detailed weak area analysis, speed metrics, accuracy trends, and chapter breakdown.', const AnalyticsScreen()),
                    _buildModalBenefitTile(Icons.headset_mic_rounded, const Color(0xFF10B981), '24x7 Doubt Support', 'Dedicated doubt solving forum with expert responses under 15 minutes.', const DoubtsScreen()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToBatches();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Explore Batches Now →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalBenefitTile(IconData icon, Color color, String title, String subtitle, [Widget? destination]) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else {
          _navigateToBatches();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Video Card (Shown first at the top of the home screen)
        _buildTopLiveStreamHero(),

        // Section 01: Hero & What You Get With Our Batches (Page 1)
        _buildSection01Hero(),
        const SizedBox(height: 16),

        // Section 02: Exam Preparation Overview (Page 2)
        _buildSection02Overview(),
        const SizedBox(height: 16),

        // Section 03: Today's Study Plan (Page 3)
        _buildSection03StudyPlan(),
        const SizedBox(height: 16),

        // Section 04: Live Classroom (Page 4)
        _buildSection04LiveClassroom(),
        const SizedBox(height: 16),

        // Section 05: Continue Learning (Page 5)
        _buildSection05ContinueLearning(),
        const SizedBox(height: 16),

        // Section 06: Performance & Analytics (Page 6)
        _buildSection06Analytics(),
        const SizedBox(height: 16),

        // Section 07: Community & Support (Page 7)
        _buildSection07Community(),
        const SizedBox(height: 16),

        // Section 08: Resources & Study Tools (Page 8)
        _buildSection08Resources(),
        const SizedBox(height: 20),
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

  // ===========================================================================
  // SECTION 01: HERO & WHAT YOU GET (Page 1)
  // ===========================================================================
  Widget _buildSection01Hero() {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedExam = userProvider.selectedExam;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C1B3E), Color(0xFF091024)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: 01 Badge + Greeting + Circular Unlock Progress
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge 01 NOT PURCHASED with shield
              _buildBadgeBox(
                number: '01',
                subText: 'NOT PURCHASED',
                icon: Icons.shield_rounded,
                accentColor: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 14),

              // Title & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What are you preparing for?', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      selectedExam,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join the right batch and get everything you need to crack $selectedExam with confidence.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _purchaseSelectionBatch,
                          icon: const Icon(Icons.bolt, color: Colors.amber, size: 16),
                          label: const Text('⚡ Enroll Now (₹1,999)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0070F3),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _navigateToBatches,
                          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 15),
                          label: const Text('Explore Batches →', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1E3A68)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Right Card: Unlock Your Progress Preview
          GestureDetector(
            onTap: _navigateToBatches,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  // Glowing circular lock meter
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 3),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 2),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, color: Color(0xFFFFA000), size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Your Preparation Overview',
                              style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Unlock Your Progress',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Join a batch to track your preparation, practice, test and improve.',
                          style: TextStyle(color: Colors.white60, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom: What You Get With Our Batches (7 items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1633),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: Color(0xFF38BDF8), size: 17),
                        SizedBox(width: 6),
                        Text(
                          'What You Get With Our Batches',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _showAllBenefitsModal,
                      child: const Text(
                        'View All Benefits >',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildBenefitPill(Icons.videocam_rounded, const Color(0xFFF43F5E), 'Live Classes', 'Interactive sessions\nwith faculty', const LiveClassesScreen(initialTab: 0)),
                      _buildBenefitPill(Icons.play_circle_fill_rounded, const Color(0xFF38BDF8), 'Recorded Lectures', 'Learn anytime with\nhigh quality videos', const LiveClassesScreen(initialTab: 2)),
                      _buildBenefitPill(Icons.description_rounded, const Color(0xFF34D399), 'Study Notes', 'Comprehensive notes\nfor quick revision', const ResourcesScreen()),
                      _buildBenefitPill(Icons.edit_note_rounded, const Color(0xFFFBBF24), 'Practice Questions', '5000+ chapter-wise\npractice questions', const ResourcesScreen()),
                      _buildBenefitPill(Icons.assignment_turned_in_rounded, const Color(0xFFA855F7), 'Test Series', 'Unit, subject & full\nlength tests', const TestSeriesScreen()),
                      _buildBenefitPill(Icons.menu_book_rounded, const Color(0xFF8B5CF6), 'PYQs', 'Previous Year Papers\nwith solutions', const PyqsScreen()),
                      _buildBenefitPill(Icons.history_rounded, const Color(0xFFE11D48), 'Revision', 'Revision Notes &\nFormula sheets', const ResourcesScreen()),
                      _buildBenefitPill(Icons.insights_rounded, const Color(0xFF06B6D4), 'Analytics', 'Detailed performance\n& progress insights', const AnalyticsScreen()),
                      _buildBenefitPill(Icons.headset_mic_rounded, const Color(0xFF10B981), 'Doubt Support', 'Get your doubts\nresolved 24x7', const DoubtsScreen()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitPill(IconData icon, Color color, String title, String subtitle, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else {
          _showAllBenefitsModal();
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 9, height: 1.2), maxLines: 2),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 02: EXAM PREPARATION OVERVIEW (Page 2)
  // ===========================================================================
  Widget _buildSection02Overview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '02',
                subText: 'OVERVIEW\nNOT PURCHASED',
                icon: Icons.bar_chart_rounded,
                accentColor: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Exam Preparation Overview ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Track your overall progress across all subjects with powerful insights and analytics.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Text('“ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 16, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              'Track today, improve tomorrow, succeed in your exam.',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Floating Card: Unlock Your Progress (Amber CTA)
          GestureDetector(
            onTap: _navigateToBatches,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E3D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFFA000), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unlock Your Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                        Text('Join a batch to track your preparation and get personalized analytics.', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _navigateToBatches,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Explore →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Overall Preparation (64% Blurred meter) + Subject Wise Progress
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1938),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overall Preparation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Donut gauge with 64% Prepared (blurred effect)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 6),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('64%', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w900)),
                              Text('Prepared', style: TextStyle(color: Colors.white38, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BulletPoint(icon: Icons.track_changes_rounded, text: 'Overall preparation score across all subjects'),
                            SizedBox(height: 6),
                            _BulletPoint(icon: Icons.trending_up_rounded, text: 'Track improvement week by week'),
                            SizedBox(height: 6),
                            _BulletPoint(icon: Icons.pie_chart_outline_rounded, text: 'Study time, tests & more all in one place'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFFFFA000), size: 12),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Join a batch to see your overall preparation score',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),

                  // Subject Wise Progress
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subject Wise Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSubjectProgressItem(Icons.science_outlined, const Color(0xFF38BDF8), 'Physics', '71% Good', 'Syllabus Completion: 71%', 0.71),
                  const SizedBox(height: 8),
                  _buildSubjectProgressItem(Icons.biotech_outlined, const Color(0xFF34D399), 'Chemistry', '63% Average', 'Syllabus Completion: 63%', 0.63),
                  const SizedBox(height: 8),
                  _buildSubjectProgressItem(Icons.functions_rounded, const Color(0xFFFFA000), 'Mathematics', '58% Focus', 'Syllabus Completion: 58%', 0.58),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressItem(IconData icon, Color color, String name, String rating, String sub, double val) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(rating, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 03: TODAY'S STUDY PLAN (Page 3)
  // ===========================================================================
  Widget _buildSection03StudyPlan() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '03',
                subText: 'TODAY\'S PLAN\nNOT PURCHASED',
                icon: Icons.calendar_today_rounded,
                accentColor: const Color(0xFFA855F7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Today\'s Study Plan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Color(0xFFC084FC), size: 10),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('d MMM').format(DateTime.now()),
                                style: const TextStyle(color: Color(0xFFC084FC), fontSize: 9.5, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Get a personalized plan every day and stay on track from start to success.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Preview of Your Daily Plan with Center Purple Lock Overlay
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview of Your Daily Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                // Schedule card with centered lock overlay
                GestureDetector(
                  onTap: _navigateToBatches,
                  child: Stack(
                    children: [
                      // Mock blurred schedule items behind
                      Column(
                        children: [
                          _buildScheduleMockRow('Physics — Current Electricity', '45 min', const Color(0xFF10B981), const CoursesScreen()),
                          _buildScheduleMockRow('Chemistry — Chemical Bonding', '30 min', const Color(0xFF38BDF8), const ResourcesScreen()),
                          _buildScheduleMockRow('Mathematics — Integration', '30 min', const Color(0xFFA855F7), const PyqsScreen()),
                          _buildScheduleMockRow('Revision — Today\'s Topics', '30 min', const Color(0xFFF43F5E), const ResourcesScreen()),
                        ],
                      ),

                      // Overlay blur & unlock prompt
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_rounded, color: Color(0xFFA855F7), size: 24),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Unlock your personalized daily study plan',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'You\'ll see your classes, practice, tests and revision all in one place.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60, fontSize: 9.5),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
                                },
                                icon: const Icon(Icons.lock_open_rounded, size: 14),
                                label: const Text('UNLOCK TODAY\'S PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA855F7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Points of what your daily plan will include
                const Text('Your Daily Plan Will Include', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildPlanFeature(Icons.calendar_month_rounded, const Color(0xFFA855F7), 'Personalized Daily Schedule', 'What to study, in what order and for how long.'),
                _buildPlanFeature(Icons.track_changes_rounded, const Color(0xFF38BDF8), 'Smart Time Allocation', 'Balanced plan for learning, practice, tests & revision.'),
                _buildPlanFeature(Icons.bar_chart_rounded, const Color(0xFF10B981), 'Progress Tracking', 'Track completion, time spent and consistency.'),
                _buildPlanFeature(Icons.notifications_active_rounded, const Color(0xFFFFA000), 'Reminders & Notifications', 'Never miss your plan with smart reminders.'),
                _buildPlanFeature(Icons.trending_up_rounded, const Color(0xFFF43F5E), 'Goal Driven Preparation', 'Stay focused and move closer to your exam goal.'),
                const SizedBox(height: 12),

                // Button: Explore Batches + Trust badge
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToBatches,
                    icon: const Icon(Icons.lock_outline_rounded, color: Colors.black, size: 16),
                    label: const Text('EXPLORE BATCHES →', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 13),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Trusted by 50K+ Students Preparing with Examinantt',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleMockRow(String title, String duration, Color dotColor, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else {
          _navigateToBatches();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11))),
            Text(duration, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, Color color, String title, String subtitle) {
    return GestureDetector(
      onTap: _navigateToBatches,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 04: LIVE CLASSROOM (Page 4)
  // ===========================================================================
  Widget _buildSection04LiveClassroom() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '04',
                subText: 'LIVE\nCLASSROOM',
                icon: Icons.wifi_tethering_rounded,
                accentColor: const Color(0xFFF43F5E),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Live Classroom ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Join live classes, interact with expert faculty and learn in real time.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real Firestore Live Classroom Integration
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<List<LiveClass>>(
                  stream: ContentService().getLiveClasses(),
                  builder: (context, snapshot) {
                    final classes = snapshot.data ?? [];
                    final liveList = classes.where((c) => c.isLive).toList();
                    final upcomingList = classes.where((c) => c.isUpcoming).toList();
                    final LiveClass? activeClass = liveList.isNotEmpty
                        ? liveList.first
                        : (upcomingList.isNotEmpty ? upcomingList.first : null);

                    if (activeClass != null) {
                      final bool isLive = activeClass.isLive;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LiveClassesScreen(initialTab: 0),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLive
                                  ? const [Color(0xFF260D1E), Color(0xFF0F1A3B)]
                                  : const [Color(0xFF0F264C), Color(0xFF0A1832)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLive ? Colors.redAccent.withValues(alpha: 0.6) : const Color(0xFF224B85),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isLive ? const Color(0xFFEF4444) : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, color: isLive ? Colors.white : const Color(0xFF38BDF8), size: 6),
                                        const SizedBox(width: 4),
                                        Text(
                                          isLive ? 'LIVE NOW' : 'UPCOMING SESSION',
                                          style: TextStyle(
                                            color: isLive ? Colors.white : const Color(0xFF38BDF8),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    activeClass.time,
                                    style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                activeClass.title,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${activeClass.instructor} • ${activeClass.subject}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E1F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.sensors_off_rounded, color: Color(0xFF38BDF8), size: 30),
                          SizedBox(height: 8),
                          Text(
                            'No Live Classes Active Right Now',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Live lectures scheduled by faculty will appear here in real time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Experience real-time teaching, doubt solving and live interaction like never before.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveClassesScreen()));
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text('EXPLORE LIVE CLASSES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Available with Premium Batches', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
                ),
                const SizedBox(height: 14),

                // What you'll get in Live Classroom (5 items)
                const Text('What you\'ll get in Live Classroom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildLiveClassFeature(Icons.videocam_rounded, const Color(0xFFF43F5E), 'Live Interactive Classes', 'Attend live classes, ask doubts and interact with faculty in real time.', const LiveClassesScreen(initialTab: 0)),
                _buildLiveClassFeature(Icons.question_answer_rounded, const Color(0xFF38BDF8), 'Live Doubt Solving', 'Get your doubts solved instantly during or after the class.', const DoubtsScreen()),
                _buildLiveClassFeature(Icons.event_note_rounded, const Color(0xFF10B981), 'Scheduled Classes', 'Follow a fixed timetable and never miss an important topic.', const LiveClassesScreen(initialTab: 1)),
                _buildLiveClassFeature(Icons.video_library_rounded, const Color(0xFFFFA000), 'Class Recordings', 'Watch recordings anytime and revise at your convenience.', const LiveClassesScreen(initialTab: 2)),
                _buildLiveClassFeature(Icons.groups_rounded, const Color(0xFFA855F7), 'Peer Interaction', 'Learn together with thousands of aspiring students.', const CommunityScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassFeature(IconData icon, Color color, String title, String subtitle, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else {
          _navigateToBatches();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 05: CONTINUE LEARNING (Page 5)
  // ===========================================================================
  Widget _buildSection05ContinueLearning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '05',
                subText: 'CONTINUE\nLEARNING',
                icon: Icons.menu_book_rounded,
                accentColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Continue Learning ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Pick up where you left off and keep your momentum going.', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Color(0xFF10B981), size: 13),
                          SizedBox(width: 4),
                          Text('Unlock All Courses >', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Featured Lecture (Current Electricity: Lecture 4)
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E3D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video thumbnail with green lock
                      Container(
                        width: 90,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B192E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.electrical_services_rounded, color: Colors.white24, size: 36),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                              child: const Icon(Icons.lock_rounded, color: Colors.black, size: 14),
                            ),
                            const Positioned(
                              bottom: 2,
                              child: Text('Locked Preview', style: TextStyle(color: Colors.white60, fontSize: 8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('PHYSICS', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            const Text('Current Electricity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Lecture 4: Combination of Resistors', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _SmallBullet(Icons.play_circle_outline, 'Access full lecture videos'),
                      _SmallBullet(Icons.download_outlined, 'Download notes & PDFs'),
                      _SmallBullet(Icons.list_alt_rounded, 'Track your progress'),
                      _SmallBullet(Icons.bookmark_border_rounded, 'Bookmark important topics'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Available for enrolled students only',
                          style: TextStyle(color: Colors.white38, fontSize: 9.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
                        },
                        icon: const Icon(Icons.lock_open_rounded, size: 13),
                        label: const Text('Unlock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // What you can explore next (Preview) - 4 cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: Color(0xFF38BDF8), size: 15),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'What you can explore next (Preview)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
                },
                child: const Text('View All Courses >', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCoursePreviewCard('CHEMISTRY', 'Chemical Bonding', 'Lecture 3: Hybridization', Icons.bubble_chart_rounded, const Color(0xFF38BDF8)),
                _buildCoursePreviewCard('MATHEMATICS', 'Integration', 'Lecture 2: Basic Integrals', Icons.functions_rounded, const Color(0xFFA855F7)),
                _buildCoursePreviewCard('PHYSICS', 'Kinematics', 'Lecture 1: Motion in 1D', Icons.speed_rounded, const Color(0xFF10B981)),
                _buildCoursePreviewCard('BIOLOGY', 'Human Physiology', 'Lecture 2: Blood Circulation', Icons.favorite_border_rounded, const Color(0xFFF43F5E)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursePreviewCard(String sub, String title, String lec, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen()));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(sub, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1),
            Text(lec, style: const TextStyle(color: Colors.white60, fontSize: 9), maxLines: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 10),
                    SizedBox(width: 2),
                    Text('Locked', style: TextStyle(color: Color(0xFFFFA000), fontSize: 9)),
                  ],
                ),
                InkWell(
                  onTap: _navigateToBatches,
                  child: Text('Preview', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 06: PERFORMANCE & ANALYTICS (Page 6)
  // ===========================================================================
  Widget _buildSection06Analytics() {
    final tabs = ['Overview', 'Subjects 🔒', 'Tests 🔒', 'Topics 🔒', 'Time Analysis 🔒', 'Comparative 🔒'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '06',
                subText: 'PERFORMANCE\n& ANALYTICS',
                icon: Icons.insights_rounded,
                accentColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Performance & Analytics ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your progress, analyze performance and get insights to improve every day.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tabs row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (idx) {
                final isSel = _activeAnalyticsTabIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(tabs[idx], style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selected: isSel,
                    onSelected: (v) {
                      if (idx != 0) {
                        AppTheme.showSuccessSnackBar(context, 'Join a batch to unlock ${tabs[idx].replaceAll('🔒', '').trim()} analytics!');
                      } else {
                        setState(() => _activeAnalyticsTabIndex = idx);
                      }
                    },
                    backgroundColor: const Color(0xFF0F172A),
                    selectedColor: const Color(0xFF38BDF8),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSel ? const Color(0xFF38BDF8) : Colors.white12)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // 4 Stat Tiles (Dynamically calculated from real user test results)
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

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildStatTile(Icons.track_changes_rounded, const Color(0xFF38BDF8), 'Tests Attempted', attemptedStr, '${stats.totalTests} Tests Total', const TestSeriesScreen()),
                      _buildStatTile(Icons.check_circle_outline_rounded, const Color(0xFF10B981), 'Accuracy', accuracyStr, 'Overall Accuracy', const AnalyticsScreen()),
                      _buildStatTile(Icons.emoji_events_outlined, const Color(0xFFA855F7), 'Average Score', avgScoreStr, 'Peak: ${stats.highestScore.toStringAsFixed(0)}%', const AnalyticsScreen()),
                      _buildStatTile(Icons.timer_outlined, const Color(0xFFFFA000), 'Total Study Time', studyTimeStr, 'Practice Duration', const AnalyticsScreen()),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),

          // Floating Card: Unlock Powerful Analytics (Upgrade Now)
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1065), Color(0xFF0F1E3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.3), blurRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unlock Powerful Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                            SizedBox(height: 2),
                            Text('Get complete access to your performance data and personalized insights.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(child: _CheckPill('Track exact progress')),
                      Expanded(child: _CheckPill('Identify weak areas')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Expanded(child: _CheckPill('Analyze over time')),
                      Expanded(child: _CheckPill('Improve smartly, score high!')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
                      },
                      icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                      label: const Text('UPGRADE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Strip: All detailed analytics are locked
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFFFFA000), size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All detailed analytics are locked • Unlock advanced insights with a batch',
                      style: TextStyle(color: Colors.white60, fontSize: 9.5),
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

  Widget _buildStatTile(IconData icon, Color color, String title, String val, String trend, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const AnalyticsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
                  Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(trend, style: TextStyle(color: color, fontSize: 8.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 07: COMMUNITY & SUPPORT (Page 7)
  // ===========================================================================
  Widget _buildSection07Community() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '07',
                subText: 'COMMUNITY\n& SUPPORT',
                icon: Icons.groups_rounded,
                accentColor: const Color(0xFF06B6D4),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Community & Support ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Learn together, grow together and get the support you need on your learning journey.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Community Feature Cards (Student Community, Ask Doubts, Leaderboards, Achievements)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildCommunityCard(Icons.chat_bubble_outline_rounded, const Color(0xFFA855F7), 'Student Community', 'Connect with thousands of students.', const CommunityScreen()),
              _buildCommunityCard(Icons.help_outline_rounded, const Color(0xFF38BDF8), 'Ask Doubts', 'Get quick solutions from top faculty.', const DoubtsScreen()),
              _buildCommunityCard(Icons.leaderboard_rounded, const Color(0xFF10B981), 'Leaderboards', 'Climb ranks with top performers.', const LeaderboardScreen()),
              _buildCommunityCard(Icons.military_tech_rounded, const Color(0xFFFFA000), 'Achievements', 'Earn badges and celebrate milestones.', const AnalyticsScreen()),
            ],
          ),
          const SizedBox(height: 14),

          // We're Here to Help (3D Headset art)
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E3D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF06B6D4), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('We\'re Here to Help!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Facing an issue or need guidance? Our support team is just a click away.', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSupportOption(Icons.chat_rounded, 'Live Chat', 'Available 9 AM - 9 PM', const HelpSupportScreen()),
                  _buildSupportOption(Icons.email_outlined, 'Email Support', 'support@examinantt.com', const HelpSupportScreen()),
                  _buildSupportOption(Icons.phone_in_talk_rounded, 'WhatsApp Support', '+91 9123456789', const HelpSupportScreen()),
                  _buildSupportOption(Icons.help_center_outlined, 'Help Center', 'FAQs & Guides', const HelpSupportScreen()),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('⏱ Average response time: Under 2 minutes', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Trending in Community (Preview)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.trending_up_rounded, color: Color(0xFFF43F5E), size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Trending in Community (Preview)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DoubtsScreen()));
                      },
                      child: const Text('View More →', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<CommunityMessage>>(
                  stream: FirestoreService().streamCommunityMessages(channel: 'general'),
                  builder: (context, snapshot) {
                    final List<CommunityMessage> messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: Text(
                            'No community discussions yet. Ask a doubt to start!',
                            style: TextStyle(color: Colors.white38, fontSize: 10.5),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: messages.take(4).map((CommunityMessage msg) {
                        return _buildForumQuestion(
                          msg.text,
                          '${msg.senderName} • ${msg.senderTag.isNotEmpty ? msg.senderTag : 'Student'}',
                          'Active discussion',
                          const DoubtsScreen(),
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

  Widget _buildCommunityCard(IconData icon, Color color, String title, String sub, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const DoubtsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 11),
              ],
            ),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
            Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 9), maxLines: 2),
            Text('Explore >', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(IconData icon, String title, String val, [Widget? destination]) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const HelpSupportScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF38BDF8), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(val, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildForumQuestion(String q, String author, String meta, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const DoubtsScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('$author • $meta', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 08: RESOURCES & STUDY TOOLS (Page 8)
  // ===========================================================================
  Widget _buildSection08Resources() {
    final filters = [
      'All Resources',
      'Notes & PDFs 🔒',
      'Practice Material 🔒',
      'Exam Prep 🔒',
      'Career & Guidance 🔒',
      'Tools & Calculators 🔒',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A122C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadgeBox(
                number: '08',
                subText: 'RESOURCES &\nSTUDY TOOLS',
                icon: Icons.library_books_rounded,
                accentColor: const Color(0xFFFFA000),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Resources & Study Tools ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Icon(Icons.description_rounded, color: Color(0xFFFFA000), size: 15),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Everything you need to study smarter, revise better and ace every exam.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSel = _activeResourceFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(f, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selected: isSel,
                    onSelected: (v) {
                      if (f != 'All Resources') {
                        AppTheme.showSuccessSnackBar(context, 'Join a batch to unlock ${f.replaceAll('🔒', '').trim()}!');
                      } else {
                        setState(() => _activeResourceFilter = f);
                      }
                    },
                    backgroundColor: const Color(0xFF0F172A),
                    selectedColor: const Color(0xFFFFA000),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSel ? const Color(0xFFFFA000) : Colors.white12)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 4 Main Resource Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildMainResourceCard(Icons.description_rounded, const Color(0xFF38BDF8), 'Notes & Study Material', '120+', 'Detailed notes, formulas, mind maps and important PDFs.', const ResourcesScreen()),
              _buildMainResourceCard(Icons.quiz_rounded, const Color(0xFFA855F7), 'Practice Question Bank', '5000+', 'Topic-wise, chapter-wise and exam-wise question banks.', const ResourcesScreen()),
              _buildMainResourceCard(Icons.history_edu_rounded, const Color(0xFF10B981), 'Previous Year Papers', '50+', 'Download and practice PYQs with solutions & analysis.', const PyqsScreen()),
              _buildMainResourceCard(Icons.video_library_rounded, const Color(0xFFFFA000), 'Recorded Lectures', '300+', 'Watch high-quality recorded lectures anytime, anywhere.', const CoursesScreen()),
            ],
          ),
          const SizedBox(height: 16),

          // Smart Study Tools (6 items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.build_rounded, color: Color(0xFFA855F7), size: 16),
                    SizedBox(width: 6),
                    Text('Smart Study Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildToolTile(Icons.analytics_outlined, 'Mock Test Analysis', const AnalyticsScreen()),
                    _buildToolTile(Icons.timer_outlined, 'Exam Countdown', const AnalyticsScreen()),
                    _buildToolTile(Icons.calendar_today_outlined, 'Revision Planner', const ResourcesScreen()),
                    _buildToolTile(Icons.pie_chart_outline, 'Weightage Analyzer', const AnalyticsScreen()),
                    _buildToolTile(Icons.functions_rounded, 'Formula Sheet', const ResourcesScreen()),
                    _buildToolTile(Icons.bookmark_outline, 'Bookmark Manager', const BookmarksScreen()),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
                    },
                    icon: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFFFA000)),
                    label: const Text('Explore All Smart Tools →', style: TextStyle(color: Color(0xFFFFA000), fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFA000)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Download Center (4 items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_download_rounded, color: Color(0xFF38BDF8), size: 16),
                    SizedBox(width: 6),
                    Text('Download Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDownloadItem('Physics Formulas Sheet', 'PDF • 1.2 MB', const ResourcesScreen()),
                _buildDownloadItem('Chemistry Quick Revision Notes', 'PDF • 2.4 MB', const ResourcesScreen()),
                _buildDownloadItem('Mathematics Important Formulas', 'PDF • 1.8 MB', const ResourcesScreen()),
                _buildDownloadItem('Biology Diagrams Collection', 'PDF • 3.1 MB', const ResourcesScreen()),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
                    },
                    icon: const Icon(Icons.download_rounded, size: 14, color: Color(0xFF38BDF8)),
                    label: const Text('Open Notes & Resources →', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildMainResourceCard(IconData icon, Color color, String title, String count, String subtitle, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const ResourcesScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(count, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5), maxLines: 1),
            Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 9), maxLines: 2),
            Row(
              children: [
                Text('Open Now', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 9),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile(IconData icon, String title, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const ResourcesScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 15),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10.5))),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 9),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadItem(String title, String meta, [Widget? destination]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination ?? const ResourcesScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFF43F5E), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  Text(meta, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
          ],
        ),
      ),
    );
  }

  // Helper Badge Box
  Widget _buildBadgeBox({
    String? number,
    required String subText,
    required IconData icon,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: _navigateToBatches,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E3D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(height: 6),
            const Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 12),
            const SizedBox(height: 4),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFA000), fontSize: 8, fontWeight: FontWeight.bold, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10.5))),
      ],
    );
  }
}

class _SmallBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallBullet(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 13),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _CheckPill extends StatelessWidget {
  final String text;

  const _CheckPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 9.5), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
