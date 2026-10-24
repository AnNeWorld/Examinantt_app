import 'package:examinantt_app/utils/app_navigator.dart';
// ignore_for_file: unused_element, unused_field
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/app_theme.dart';
import '../screens/quiz_screen.dart';
import '../screens/test_series_detail_screen.dart';
import '../services/test_service.dart';
import '../services/firestore_service.dart';
import '../models/test_model.dart';
import '../services/payment_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/analytics_service.dart';
import '../models/analytics_model.dart';
import '../screens/analytics_screen.dart';
import '../screens/my_preparation_screen.dart';
import '../screens/test_history_screen.dart';
import 'safe_app_image.dart';

/// Complete Test Center UI Widget matching all 7 pages of `test page.pdf`.
class TestPageSections extends StatefulWidget {
  final VoidCallback? onOpenHistory;
  final Function(String examName)? onExamChanged;
  final int initialTab;

  const TestPageSections({
    super.key,
    this.onOpenHistory,
    this.onExamChanged,
    this.initialTab = 0,
  });

  @override
  State<TestPageSections> createState() => _TestPageSectionsState();
}

class _TestPageSectionsState extends State<TestPageSections> with SingleTickerProviderStateMixin {
  // Navigation:
  // 0: My Test, 1: All Test, 2: Included with Batch
  static const int tabMyTests = 0;
  static const int tabAllTests = 1;
  static const int tabIncludedWithBatch = 2;

  late int _activeTabIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTab.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: _activeTabIndex);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.index != _activeTabIndex) {
      setState(() {
        _activeTabIndex = _tabController.index;
        _isViewingSeriesDetail = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // Whether currently viewing a series detail screen (Page 5 of PDF)
  bool _isViewingSeriesDetail = false;
  final String _currentSeriesTitle = 'JEE Main 2027 Gold Test Series';
  final String _currentSeriesBadge = 'GOLD';

  // Selected Exam
  String _selectedExam = 'JEE Main 2027';

  // Sort & Filters
  String _mySeriesSort = 'Recent';
  final String _allSeriesSort = 'Popularity';
  String _mySeriesFilter = 'All';
  String _allSeriesFilter = 'Test Series';
  String _allTestsSearchQuery = '';
  String _performanceTimeframe = 'Last 30 Days';

  // Page 5 (Series Detail) state
  int _seriesDetailSubTabIndex = 1; // 0: Overview, 1: Tests (Active), 2: Analysis, 3: Leaderboard, 4: Solutions
  int _testsCategoryIndex = 0; // 0: Chapter Tests, 1: Unit Tests, 2: Subject Tests, 3: Full Length Tests
  String _testSubjectFilter = 'Physics';
  String _testStatusFilter = 'All Status';
  String _testDifficultyFilter = 'All Difficulty';
  String _testSortFilter = 'Sort by: Newest';

  // Bookmark tracking for tests
  final Set<String> _bookmarkededTestIds = {'test_01'};

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'My Test', 'icon': Icons.assignment_turned_in_outlined},
    {'title': 'All Test', 'icon': Icons.format_list_bulleted_rounded},
    {'title': 'Included with Batch', 'icon': Icons.card_giftcard_outlined},
  ];

  void _switchTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      if (_tabController.index != index) {
        _tabController.animateTo(index);
      }
    }
    setState(() {
      _activeTabIndex = index;
      _isViewingSeriesDetail = false;
    });
  }

  void _openSeriesDetail({
    String id = '',
    String title = 'JEE Main 2027 Gold Test Series',
    String badge = 'GOLD',
    String price = '499',
    String origPrice = '999',
    Color badgeColor = const Color(0xFFFFD700),
    List<String> features = const [
      'Chapter-wise Tests',
      'Unit-wise Tests',
      'Subject Tests',
      'Full Length Mocks',
      'AI Analysis & Insights',
      'All India Ranking',
    ],
  }) {
    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestSeriesDetailScreen(
          categoryId: id.isNotEmpty ? id : badge.toLowerCase(),
          title: title,
          badge: badge,
          price: price,
          originalPrice: origPrice,
          features: features,
          badgeColor: badgeColor,
          imageUrl: '',
          isPurchased: false,
        ),
      ),
    );
  }

  void _closeSeriesDetail() {
    setState(() {
      _isViewingSeriesDetail = false;
    });
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get _subCardBg => _isDark ? const Color(0xFF071326) : const Color(0xFFF8FAFC);
  Color get _titleColor => _isDark ? Colors.white : AppTheme.darkSlate;
  Color get _subColor => _isDark ? Colors.white70 : const Color(0xFF64748B);
  Color get _mutedColor => _isDark ? Colors.white54 : Colors.grey.shade500;
  Color get _borderColor => _isDark ? Colors.white12 : Colors.grey.shade200;
  Color get _dialogBg => _isDark ? const Color(0xFF0F172A) : Colors.white;

  // ---------------------------------------------------------------------------
  // INTERACTIVE DIALOGS & BOTTOM SHEETS
  // ---------------------------------------------------------------------------

  void _showChangeExamDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.school, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text('Select Target Exam', style: TextStyle(color: _titleColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: StreamBuilder<List<String>>(
              stream: FirestoreService().getExamsStream(),
              initialData: FirestoreService.fallbackExams,
              builder: (context, examSnap) {
                final liveExams = examSnap.data ?? FirestoreService.fallbackExams;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: liveExams.map((exam) {
                    final isSel = _selectedExam.toLowerCase().trim() == exam.toLowerCase().trim();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent.withValues(alpha: 0.2) : (_isDark ? Colors.white10 : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSel ? Icons.check_circle : Icons.school_outlined,
                          color: isSel ? AppColors.accent : (_isDark ? Colors.white70 : AppTheme.darkSlate),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        exam,
                        style: TextStyle(
                          color: isSel ? AppColors.accent : _titleColor,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSel
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedExam = exam);
                        Provider.of<UserProvider>(context, listen: false).updateTargetExam(exam);
                        widget.onExamChanged?.call(exam);
                        Navigator.pop(ctx);
                        AppTheme.showSuccessSnackBar(context, 'Exam switched to $exam');
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showTestStructureDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.account_tree_outlined, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Test Structure Breakdown',
                style: TextStyle(color: _titleColor, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStructureRow('Chapter Tests', '243 Tests', 'Topic-wise concept mastery (25-30 Qs, 30-35 mins)'),
              Divider(color: _borderColor, height: 16),
              _buildStructureRow('Unit Tests', '65 Tests', 'Combined multi-chapter review (45 Qs, 60 mins)'),
              Divider(color: _borderColor, height: 16),
              _buildStructureRow('Subject Tests', '15 Tests', 'Full physics/chemistry/maths papers (75 Qs, 90 mins)'),
              Divider(color: _borderColor, height: 16),
              _buildStructureRow('Full Length Mocks', '20 Tests', 'Simulated real NTA CBT format (300 Marks, 3 Hours)'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Got It', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureRow(String title, String count, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(count, style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: _subColor, fontSize: 11)),
      ],
    );
  }

  void _showWhySequenceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _dialogBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  Text('Why Sequence Unlocking?', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Our scientific pedagogical algorithm ensures you build fundamental concepts before tackling complex application problems.',
                style: TextStyle(color: _subColor, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              _buildBulletPoint('Foundational concepts unlock corresponding advanced problems.'),
              _buildBulletPoint('Prevents burnout and builds exam momentum step-by-step.'),
              _buildBulletPoint('Proven 34% higher retention compared to random practice.'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Understand & Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: _subColor, fontSize: 12))),
        ],
      ),
    );
  }

  void _showStartTestDialog(String testName, String questions, String duration) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start $testName', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Duration: $duration', style: TextStyle(color: _subColor, fontSize: 13)),
            const SizedBox(height: 4),
            Text('• Questions: $questions', style: TextStyle(color: _subColor, fontSize: 13)),
            const SizedBox(height: 4),
            Text('• Marking: +4 for Correct, -1 for Incorrect', style: TextStyle(color: _subColor, fontSize: 13)),
            const SizedBox(height: 4),
            Text('• Anti-cheat & timer auto-submit enabled', style: TextStyle(color: _subColor, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _mutedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppNavigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    testId: 'test_${testName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
                    testName: testName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Begin Test Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTestResultDialog(String testName, String score, String accuracy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text('$testName Result', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Your Score', style: TextStyle(color: _subColor, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(score, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Container(height: 30, width: 1, color: _borderColor),
                  Column(
                    children: [
                      Text('Accuracy', style: TextStyle(color: _subColor, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(accuracy, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Great job! You scored higher than 84% of candidates in this topic.', style: TextStyle(color: _subColor, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: _mutedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppNavigator.push(context, const TestHistoryScreen());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('View Solutions', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReattemptDialog(String testName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reattempt $testName?', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Your previous attempt score will be saved in your test history. The timer will start immediately.',
          style: TextStyle(color: _subColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _mutedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppNavigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    testId: 'test_reattempt_${testName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
                    testName: testName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            child: const Text('Start Reattempt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog(String unlockRequirement) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Test Locked',
                style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '$unlockRequirement to unlock this test. Sequential practice ensures high conceptual mastery.',
          style: TextStyle(color: _subColor, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final activeExam = userProvider.selectedExam;
    if (_selectedExam != activeExam) {
      _selectedExam = activeExam;
    }

    // If currently viewing Page 5 (Series Detail):
    if (_isViewingSeriesDetail) {
      return _buildPage5SeriesDetailView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Tab Bar (Overview, My Test, All Test, Included with Batch, Other Exams, My Performance)
        _buildHorizontalTabs(),

        // Active Tab Content
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFFA000),
            backgroundColor: _cardBg,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 650));
              if (mounted) setState(() {});
            },
            child: _buildActiveTabContent(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOP SUB HEADER (Preparing for JEE Main 2027 v | Change Exam)
  // ---------------------------------------------------------------------------

  Widget _buildTopSubHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: _showChangeExamDialog,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                child: Row(
                  children: [
                    Text(
                      'Preparing for ',
                      style: TextStyle(color: _subColor, fontSize: 13),
                    ),
                    Flexible(
                      child: Text(
                        _selectedExam,
                        style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _showChangeExamDialog,
            icon: Icon(Icons.swap_horiz_rounded, color: _subColor, size: 14),
            label: Text(
              'Change Exam',
              style: TextStyle(color: _titleColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HORIZONTAL NAVIGATION TABS (Matching PDF pages)
  // ---------------------------------------------------------------------------

  Widget _buildHorizontalTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF071326) : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          controller: _tabController,
          onTap: _switchTab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: AppColors.accent,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'MY TEST'),
            Tab(text: 'ALL TEST'),
            Tab(text: 'INCLUDED WITH BATCH'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case tabMyTests:
        return _buildPage2MySeries();
      case tabAllTests:
        return _buildPage4AllSeries();
      case tabIncludedWithBatch:
        return _buildPage3IncludedWithBatch();
      default:
        return _buildPage2MySeries();
    }
  }

  // ===========================================================================
  // PAGE 1: OVERVIEW TAB (test_p1.png)
  // ===========================================================================

  Widget _buildPage1Overview() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle text from PDF
          Text(
            'Smart Practice. Better Analysis. Higher Scores.',
            style: TextStyle(color: _subColor, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          // 4 Metric KPI Cards (Dynamic live data from Firestore)
          StreamBuilder<List<TestCategory>>(
            stream: TestService().getCategoriesStream(),
            builder: (context, catSnap) {
              final catList = catSnap.data ?? [];
              final allTestSeriesCount = catList.isNotEmpty ? catList.length.toString() : '0';

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getUserPurchasesStream(),
                builder: (context, pSnap) {
                  final purchases = pSnap.data ?? [];
                  final pIds = purchases.map((p) => (p['id'] ?? p['seriesId'] ?? '').toString()).toSet();
                  final myCount = catList.where((c) => c.price == 0 || pIds.contains(c.id)).length;
                  final myTestSeriesCount = (myCount > 0 ? myCount : purchases.length).toString();
                  final user = Provider.of<UserProvider>(context, listen: false).user;
                  final userTestsAttempted = (user?.testsAttempted ?? 0).toString();
                  final userAvgAccuracy = user?.accuracy != null && user!.accuracy > 0
                      ? '${user.accuracy.toStringAsFixed(1)}%'
                      : '0%';

                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricKpiCard(
                          icon: Icons.school_outlined,
                          color: const Color(0xFF38BDF8),
                          value: myTestSeriesCount,
                          label: 'My Test',
                          onTap: () => _switchTab(tabMyTests),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricKpiCard(
                          icon: Icons.format_list_bulleted,
                          color: const Color(0xFF34D399),
                          value: allTestSeriesCount,
                          label: 'All Test',
                          onTap: () => _switchTab(tabAllTests),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricKpiCard(
                          icon: Icons.track_changes_rounded,
                          color: const Color(0xFFFB923C),
                          value: userTestsAttempted,
                          label: 'Tests Attempted',
                          onTap: () => _switchTab(tabMyTests),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricKpiCard(
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFFA78BFA),
                          value: userAvgAccuracy,
                          label: 'Avg. Accuracy',
                          onTap: () => _switchTab(tabMyTests),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick Actions Section (Take Full Mock, Chapter Tests, PYQ Tests, Performance)
          const Text(
            'Quick Actions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF38BDF8),
                  label: 'Take Full Mock',
                  onTap: () {
                    _openSeriesDetail(title: 'JEE Main 2027 Mock Test Series', badge: 'MOCK');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF34D399),
                  label: 'Chapter Tests',
                  onTap: () {
                    _openSeriesDetail(title: 'JEE Main 2027 Gold Test Series', badge: 'GOLD');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.description_outlined,
                  color: const Color(0xFFFB923C),
                  label: 'PYQ Tests',
                  onTap: () {
                    _openSeriesDetail(title: 'JEE Main 2027 Gold Test Series', badge: 'GOLD');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFFA78BFA),
                  label: 'My Tests',
                  onTap: () => _switchTab(tabMyTests),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Featured Gold Test Series Banner Card
          _buildFeaturedGoldBanner(),
          const SizedBox(height: 24),

          // Overview Live Test Series section
          _buildOverviewLiveSeriesSection(),
          const SizedBox(height: 24),

          // Overview Live Tests & Mocks section
          _buildOverviewLiveTestsSection(),
          const SizedBox(height: 24),

          // Recent Activity Section
          _buildOverviewRecentActivitySection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricKpiCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: _isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: _subColor, fontSize: 9.5),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: _isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: _titleColor, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedGoldBanner() {
    return StreamBuilder<List<TestCategory>>(
      stream: TestService().getCategoriesStream(),
      builder: (context, snapshot) {
        final allSeries = snapshot.data ?? [];
        TestCategory? featuredSeries;
        if (allSeries.isNotEmpty) {
          featuredSeries = allSeries.firstWhere(
            (s) => s.badge.toUpperCase().contains('GOLD') || s.title.toUpperCase().contains('GOLD'),
            orElse: () => allSeries.first,
          );
        }

        final title = featuredSeries?.title ?? 'Gold Test Series';
        final testsCount = featuredSeries?.testsCount ?? '150+ Tests  •  5000+ Questions  •  All Features';
        final priceStr = (featuredSeries != null && featuredSeries.price > 0)
            ? '₹${featuredSeries.price.toInt()} Value'
            : '₹999 Value';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDark
                  ? const [Color(0xFF0A2244), Color(0xFF071426)]
                  : const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.4)),
            boxShadow: _isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing gift box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFA000), size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 11),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Verified Admin Test Series',
                              style: TextStyle(color: Color(0xFFFFA000), fontSize: 9.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      testsCount,
                      style: TextStyle(color: _subColor, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(priceStr, style: const TextStyle(color: Color(0xFFFFA000), fontSize: 10.5, fontWeight: FontWeight.bold)),
                        Text('•', style: TextStyle(color: _mutedColor, fontSize: 10.5)),
                        const Text('Available Now', style: TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (featuredSeries != null) {
                    _openSeriesDetail(
                      id: featuredSeries.id,
                      title: featuredSeries.title,
                      badge: featuredSeries.badge,
                      price: featuredSeries.price.toInt().toString(),
                      origPrice: featuredSeries.originalPrice.toInt().toString(),
                      features: featuredSeries.features,
                    );
                  } else {
                    _openSeriesDetail(title: 'JEE Main 2027 Gold Test Series', badge: 'GOLD');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Open Series', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 15),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewLiveSeriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFA000), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Live Test Series',
                  style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _switchTab(tabAllTests),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFFFFA000), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TestCategory>>(
          stream: TestService().getCategoriesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFFFFA000)),
              ));
            }
            final seriesList = snapshot.data ?? [];
            if (seriesList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _mutedColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Test series added by admin will appear here automatically.',
                        style: TextStyle(color: _subColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: seriesList.length,
                itemBuilder: (ctx, idx) {
                  final cat = seriesList[idx];
                  final isGold = cat.badge.toUpperCase().contains('GOLD') || cat.title.toLowerCase().contains('gold');
                  final isSilver = cat.badge.toUpperCase().contains('SILVER') || cat.title.toLowerCase().contains('silver');
                  final badgeColor = isGold
                      ? const Color(0xFFFFD700)
                      : (isSilver ? const Color(0xFFCBD5E1) : const Color(0xFF38BDF8));

                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      boxShadow: _isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: InkWell(
                      onTap: () => _openSeriesDetail(
                        id: cat.id,
                        title: cat.title,
                        badge: cat.badge,
                        price: cat.price.toInt().toString(),
                        origPrice: cat.originalPrice.toInt().toString(),
                        badgeColor: badgeColor,
                        features: cat.features,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  cat.badge.toUpperCase(),
                                  style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                cat.price == 0 ? 'FREE' : '₹${cat.price.toInt()}',
                                style: TextStyle(
                                  color: cat.price == 0 ? const Color(0xFF34D399) : const Color(0xFFFFA000),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.title,
                            style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, color: _mutedColor, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cat.testsCount,
                                  style: TextStyle(color: _subColor, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFA000), size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewLiveTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz_outlined, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Live Tests & Mocks',
                  style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                _switchTab(tabAllTests);
                setState(() {
                  _allSeriesFilter = 'Individual Tests';
                });
              },
              child: const Text(
                'View All Tests',
                style: TextStyle(color: Color(0xFFFFA000), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TestItem>>(
          stream: TestService().getLatestTestsStream(limit: 3),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFFFFA000)),
              ));
            }
            final tests = snapshot.data ?? [];
            if (tests.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: tests.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                    boxShadow: _isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFF38BDF8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${t.totalQuestions} Questions • ${t.durationMinutes} Mins • ${t.totalMarks} Marks',
                              style: TextStyle(color: _subColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          AppNavigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                testId: t.id,
                                testName: t.title,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA000),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewRecentActivitySection() {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id ?? 'local_user';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            GestureDetector(
              onTap: () {
                widget.onOpenHistory?.call();
              },
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFFFFA000), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TestResult>>(
          stream: TestService().getRecentTestResults(userId, limit: 2),
          builder: (context, snapshot) {
            final results = snapshot.data ?? [];
            if (results.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 36, color: _mutedColor),
                    const SizedBox(height: 8),
                    Text(
                      'No recent test attempts found',
                      style: TextStyle(color: _titleColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attempt tests above to view your real-time analytics and scorecards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _subColor, fontSize: 11),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: results.map((r) {
                final accuracy = (r.totalQuestions > 0)
                    ? '${((r.correctAnswers / r.totalQuestions) * 100).toInt()}% Accuracy'
                    : '100% Accuracy';
                return _buildRecentActivityCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF34D399),
                  title: r.testTitle,
                  subtitle: '${r.totalQuestions} Questions • Completed',
                  score: '${r.score} / ${r.totalMarks}',
                  accuracy: accuracy,
                  scoreColor: const Color(0xFF34D399),
                  onTap: () => _showTestResultDialog(r.testTitle, '${r.score} / ${r.totalMarks}', accuracy),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String score,
    required String accuracy,
    required Color scoreColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: _isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: _subColor, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score, style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(accuracy, style: TextStyle(color: _subColor, fontSize: 10.5)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: _mutedColor, size: 18),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 2: MY SERIES TAB (test_p2.png)
  // ===========================================================================

  Widget _buildPage2MySeries() {
    final subFilters = ['All', 'Test Series', 'Individual Tests'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Tests & Test Series', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 2),
                  Text('All tests and series you have access to', style: TextStyle(color: _subColor, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButton<String>(
                value: _mySeriesSort,
                dropdownColor: _dialogBg,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, color: _subColor, size: 18),
                style: TextStyle(color: _titleColor, fontSize: 11.5),
                items: ['Recent', 'Progress', 'Alphabetical'].map((val) {
                  return DropdownMenuItem<String>(value: val, child: Text('Sort by: $val'));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _mySeriesSort = v);
                },
              ),
            ),
          ],
        ),
      ),
      // Filter tabs: All, Test Series, Individual Tests
      SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: subFilters.length,
          itemBuilder: (ctx, idx) {
            final f = subFilters[idx];
            final isSel = _mySeriesFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(f, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.black : _titleColor)),
                selected: isSel,
                selectedColor: const Color(0xFFFFA000),
                backgroundColor: _cardBg,
                side: BorderSide(color: isSel ? const Color(0xFFFFA000) : _borderColor),
                onSelected: (val) {
                  if (val) setState(() => _mySeriesFilter = f);
                },
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _mySeriesFilter == 'Individual Tests'
            ? _buildIndividualTestsList()
            : StreamBuilder<List<TestCategory>>(
          stream: TestService().getCategoriesStream(),
          builder: (context, catSnapshot) {
            if (catSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA000)));
            }

            final allSeries = catSnapshot.data ?? [];
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getUserPurchasesStream(),
              builder: (context, purchaseSnapshot) {
                final purchases = purchaseSnapshot.data ?? [];
                final purchasedIds = purchases.map((p) => (p['id'] ?? p['seriesId'] ?? p['courseId'] ?? '').toString()).toSet();
                final purchasedTitles = purchases.map((p) => (p['title'] ?? '').toString().toLowerCase()).toSet();

                List<TestCategory> mySeries = [];
                if (allSeries.isNotEmpty) {
                  mySeries = List<TestCategory>.from(allSeries);
                } else {
                  mySeries = [];
                }

                if (mySeries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 48, color: _mutedColor),
                          const SizedBox(height: 12),
                          Text(
                            'No Test Series Enrolled Yet',
                            style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Explore mock tests and test series to start practicing.',
                            style: TextStyle(color: _subColor, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _switchTab(tabAllTests),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA000),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Browse All Tests', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Sort items
                  if (_mySeriesSort == 'Alphabetical') {
                    mySeries.sort((a, b) => a.title.compareTo(b.title));
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mySeries.length,
                    itemBuilder: (ctx, idx) {
                      final cat = mySeries[idx];
                      final isGold = cat.badge.toUpperCase().contains('GOLD') || cat.title.toLowerCase().contains('gold');
                      final isSilver = cat.badge.toUpperCase().contains('SILVER') || cat.title.toLowerCase().contains('silver');
                      final isMock = cat.badge.toUpperCase().contains('MOCK') || cat.title.toLowerCase().contains('mock');

                      final badgeColor = isGold
                          ? const Color(0xFFFFD700)
                          : (isSilver ? const Color(0xFFCBD5E1) : (isMock ? const Color(0xFFA78BFA) : const Color(0xFF38BDF8)));
                      final badgeType = isGold ? 'GOLD' : (isSilver ? 'SILVER' : (isMock ? 'MOCK' : cat.badge.toUpperCase()));
                      
                      final isPurchased = purchasedIds.contains(cat.id) || purchasedTitles.contains(cat.title.toLowerCase());
                      final isFree = cat.price == 0 || cat.badge.toLowerCase().contains('free');

                      String subBadgeText = 'Included with Batch';
                      Color subBadgeColor = const Color(0xFFFFA000);
                      if (isPurchased) {
                        subBadgeText = 'Purchased & Active';
                        subBadgeColor = const Color(0xFF38BDF8);
                      } else if (isFree) {
                        subBadgeText = 'Free Access';
                        subBadgeColor = const Color(0xFF34D399);
                      }

                      return _buildMySeriesBigCard(
                        title: cat.title,
                        iconUrl: cat.iconUrl,
                        badgeType: badgeType,
                        badgeColor: badgeColor,
                        subBadgeText: subBadgeText,
                        subBadgeColor: subBadgeColor,
                        description: cat.description,
                        pills: [cat.testsCount, ...cat.features.take(2)],
                        progress: 0.0,
                        progressFraction: '0 / ${cat.testsCount}',
                        progressColor: subBadgeColor,
                        onTapContinue: () => _openSeriesDetail(
                          id: cat.id,
                          title: cat.title,
                          badge: badgeType,
                          price: cat.price.toInt().toString(),
                          origPrice: cat.originalPrice.toInt().toString(),
                          badgeColor: badgeColor,
                          features: cat.features,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualTestsList({String filter = 'All', String searchQuery = ''}) {
    return StreamBuilder<List<TestItem>>(
      stream: TestService().getLatestTestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA000)));
        }

        var tests = snapshot.data ?? [];

        // Category filter
        final f = filter.toLowerCase();
        if (f.contains('chapter')) {
          tests = tests.where((t) =>
            t.description.toLowerCase().contains('chapter') ||
            t.title.toLowerCase().contains('chapter')
          ).toList();
        } else if (f.contains('unit')) {
          tests = tests.where((t) =>
            t.description.toLowerCase().contains('unit') ||
            t.title.toLowerCase().contains('unit')
          ).toList();
        } else if (f.contains('mock') || f.contains('full')) {
          tests = tests.where((t) =>
            t.description.toLowerCase().contains('mock') ||
            t.description.toLowerCase().contains('full') ||
            t.title.toLowerCase().contains('mock') ||
            t.title.toLowerCase().contains('full')
          ).toList();
        }

        // Search query filter
        if (searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          tests = tests.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q)
          ).toList();
        }

        if (tests.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 48, color: Colors.white38),
                      const SizedBox(height: 12),
                      Text(
                        searchQuery.isNotEmpty
                            ? 'No tests match "$searchQuery"'
                            : (filter != 'All'
                                ? 'No tests found in "$filter"'
                                : 'No tests uploaded yet by admin.'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      if (filter != 'All' || searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _allSeriesFilter = 'All';
                              _allTestsSearchQuery = '';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA000),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Show All Tests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: tests.length,
          itemBuilder: (ctx, idx) {
            final test = tests[idx];
            final descLower = test.description.toLowerCase();
            final titleLower = test.title.toLowerCase();
            final isChapter = descLower.contains('chapter') || titleLower.contains('chapter');
            final isUnit = descLower.contains('unit') || titleLower.contains('unit');
            final badgeColor = isChapter
                ? const Color(0xFF38BDF8)
                : (isUnit ? const Color(0xFFA78BFA) : const Color(0xFFFFA000));
            final badgeText = test.description.isNotEmpty
                ? test.description
                : (isChapter ? 'chapter_wise' : (isUnit ? 'unit_wise' : 'mock_test'));

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
                boxShadow: _isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.assignment_outlined, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${test.totalMarks} Marks',
                              style: TextStyle(color: _mutedColor, fontSize: 10.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          test.title,
                          style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${test.totalQuestions} Questions • ${test.durationMinutes} Mins',
                          style: TextStyle(color: _subColor, fontSize: 11),
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
                          builder: (context) => QuizScreen(
                            testId: test.id,
                            testName: test.title,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMySeriesBigCard({
    required String title,
    String? iconUrl,
    required String badgeType,
    required Color badgeColor,
    required String subBadgeText,
    required Color subBadgeColor,
    required String description,
    required List<String> pills,
    required double progress,
    required String progressFraction,
    required Color progressColor,
    required VoidCallback onTapContinue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield emblem
              _buildEmblemBadge(badgeType, badgeColor, iconUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: subBadgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: subBadgeColor, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            subBadgeText,
                            style: TextStyle(color: subBadgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(color: _subColor, fontSize: 11),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: pills.map((p) => _buildPillChip(p)).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Circular progress indicator ring matching PDF
              Column(
                children: [
                  Icon(Icons.more_vert_rounded, color: _mutedColor, size: 20),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4.5,
                          backgroundColor: _borderColor,
                          color: progressColor,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text('Completed', style: TextStyle(color: _mutedColor, fontSize: 7)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(progressFraction, style: TextStyle(color: _subColor, fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTapContinue,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: progressColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Testing',
                    style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: progressColor, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmblemBadge(String type, Color color, [String? iconUrl]) {
    if (iconUrl != null && iconUrl.trim().isNotEmpty) {
      return SafeAppImage(
        imageUrl: iconUrl.trim(),
        width: 68,
        height: 78,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(10),
        errorWidget: _buildDefaultEmblem(type, color),
      );
    }
    return _buildDefaultEmblem(type, color);
  }

  Widget _buildDefaultEmblem(String type, Color color) {
    return Container(
      width: 68,
      height: 78,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), const Color(0xFF091426)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'GOLD'
                ? Icons.emoji_events_rounded
                : (type == 'SILVER' ? Icons.shield_rounded : Icons.speed_rounded),
            color: color,
            size: 28,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              type,
              style: const TextStyle(color: Color(0xFF00112A), fontWeight: FontWeight.w900, fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: _subColor, fontSize: 9.5)),
    );
  }

  // ===========================================================================
  // PAGE 3: INCLUDED WITH BATCH TAB
  // ===========================================================================

  Widget _buildPage3IncludedWithBatch() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getUserPurchasesStream(),
      builder: (context, purchaseSnapshot) {
        if (purchaseSnapshot.connectionState == ConnectionState.waiting && !purchaseSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA000)));
        }

        final purchases = purchaseSnapshot.data ?? [];
        final batchPurchases = purchases.where((p) {
          final t = (p['type'] ?? '').toString().toLowerCase();
          return t.contains('batch') || p['courseId'] != null;
        }).toList();

        return StreamBuilder<List<TestCategory>>(
          stream: TestService().getCategoriesStream(),
          builder: (context, catSnapshot) {
            final allSeries = catSnapshot.data ?? [];
            final includedSeries = allSeries.where((cat) {
              return cat.price == 0 ||
                  cat.badge.toLowerCase().contains('free') ||
                  cat.badge.toLowerCase().contains('batch');
            }).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFA000), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Included with Your Batch',
                              style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              batchPurchases.isNotEmpty
                                  ? 'Active enrolled batches: ${batchPurchases.length}'
                                  : 'Enroll in a batch to get auto-unlocked test series.',
                              style: TextStyle(color: _subColor, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${includedSeries.length} Available',
                          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (includedSeries.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.card_giftcard_outlined, size: 48, color: _mutedColor),
                          const SizedBox(height: 12),
                          Text(
                            'No Batch Tests Available',
                            style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Test series included with enrolled batches will appear here automatically.',
                            style: TextStyle(color: _subColor, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _switchTab(tabAllTests),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA000),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Explore All Tests', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...includedSeries.map((cat) => _buildStoreCard(cat)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPage4AllSeries() {
    final filters = [
      'Test Series',
      'Chapter Tests',
      'Unit Tests',
      'Full Mocks',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _allTestsSearchQuery = v),
              style: TextStyle(color: _titleColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search test series or tests...',
                hintStyle: TextStyle(color: _mutedColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: _subColor, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        // Filter chips horizontal scroll
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filters.length,
            itemBuilder: (ctx, idx) {
              final f = filters[idx];
              final isSel = _allSeriesFilter == f;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      color: isSel ? Colors.black : _titleColor,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSel,
                  onSelected: (val) => setState(() => _allSeriesFilter = f),
                  backgroundColor: _cardBg,
                  selectedColor: const Color(0xFFFFA000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSel ? const Color(0xFFFFA000) : _borderColor),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Series Cards or Individual Tests List
        Expanded(
          child: _allSeriesFilter == 'Test Series'
              ? StreamBuilder<List<TestCategory>>(
                  stream: TestService().getCategoriesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA000)));
                    }
                    var allSeries = snapshot.data ?? [];
                    if (_allTestsSearchQuery.trim().isNotEmpty) {
                      final q = _allTestsSearchQuery.trim().toLowerCase();
                      allSeries = allSeries.where((c) =>
                        c.title.toLowerCase().contains(q) ||
                        c.description.toLowerCase().contains(q) ||
                        c.badge.toLowerCase().contains(q)
                      ).toList();
                    }

                    if (allSeries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_outlined, size: 48, color: _mutedColor),
                              const SizedBox(height: 12),
                              Text(
                                _allTestsSearchQuery.isNotEmpty
                                    ? 'No test series match "$_allTestsSearchQuery"'
                                    : 'No test series published yet by admin.',
                                style: TextStyle(color: _subColor, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allSeries.length,
                      itemBuilder: (ctx, index) {
                        return _buildStoreCard(allSeries[index]);
                      },
                    );
                  },
                )
              : _buildIndividualTestsList(filter: _allSeriesFilter, searchQuery: _allTestsSearchQuery),
        ),
      ],
    );
  }

  Widget _buildStoreCard(TestCategory cat) {
    final isGold = cat.badge.toUpperCase().contains('GOLD') || cat.title.toLowerCase().contains('gold');
    final isSilver = cat.badge.toUpperCase().contains('SILVER') || cat.title.toLowerCase().contains('silver');
    final isMock = cat.badge.toUpperCase().contains('MOCK') || cat.title.toLowerCase().contains('mock');
    final isFree = cat.price == 0 || cat.badge.toLowerCase().contains('free');

    final badgeColor = isGold
        ? const Color(0xFFFFD700)
        : (isSilver ? const Color(0xFFCBD5E1) : (isMock ? const Color(0xFFA78BFA) : (isFree ? const Color(0xFF34D399) : const Color(0xFF38BDF8))));
    final badgeType = isGold ? 'GOLD' : (isSilver ? 'SILVER' : (isMock ? 'MOCK' : (isFree ? 'FREE' : cat.badge.toUpperCase())));

    final priceStr = isFree ? 'FREE' : '₹${cat.price.toInt()}';
    final origPriceStr = cat.originalPrice > cat.price ? '₹${cat.originalPrice.toInt()}' : '';
    final discountStr = cat.price > 0 && cat.originalPrice > cat.price
        ? '${(((cat.originalPrice - cat.price) / cat.originalPrice) * 100).toInt()}% OFF'
        : (isFree ? '100% FREE' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmblemBadge(badgeType, badgeColor, cat.iconUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeType,
                            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (cat.testsCount.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            cat.testsCount,
                            style: TextStyle(color: _mutedColor, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.title,
                      style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cat.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        cat.description,
                        style: TextStyle(color: _subColor, fontSize: 11.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (cat.features.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...cat.features.take(3).map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 12),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(f, style: TextStyle(color: _subColor, fontSize: 11)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _borderColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(priceStr, style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900, fontSize: 18)),
                  if (origPriceStr.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(origPriceStr, style: TextStyle(color: _mutedColor, decoration: TextDecoration.lineThrough, fontSize: 12)),
                  ],
                  if (discountStr.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(discountStr, style: const TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _openSeriesDetail(
                      id: cat.id,
                      title: cat.title,
                      badge: badgeType,
                      price: cat.price.toInt().toString(),
                      origPrice: cat.originalPrice.toInt().toString(),
                      badgeColor: badgeColor,
                      features: cat.features,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text('Details', style: TextStyle(color: _titleColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (isFree) {
                        _openSeriesDetail(
                          id: cat.id,
                          title: cat.title,
                          badge: badgeType,
                          price: '0',
                          origPrice: '0',
                          badgeColor: badgeColor,
                          features: cat.features,
                        );
                      } else {
                        PaymentService().payAndUnlock(
                          context: context,
                          title: cat.title,
                          price: cat.price,
                          itemType: 'Test Series',
                          subtitle: 'Full Mock Series with All India Percentile & Rank',
                          onSuccess: () {
                            if (mounted) setState(() {});
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isFree ? 'Start Free' : 'Unlock Now',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
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

  // ===========================================================================
  // PAGE 5: TEST SERIES DETAIL & TESTS LIST SCREEN (test_p5.png)
  // ===========================================================================

  Widget _buildPage5SeriesDetailView() {
    final subTabs = ['Overview', 'Tests', 'Analysis', 'Leaderboard', 'Solutions'];
    final categoryTabs = [
      {'title': 'Chapter Tests', 'count': '243 Tests'},
      {'title': 'Unit Tests', 'count': '65 Tests'},
      {'title': 'Subject Tests', 'count': '15 Tests'},
      {'title': 'Full Length Tests', 'count': '20 Tests'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Series Header (Back Arrow + Gold Emblem + Title + Progress)
        Container(
          padding: const EdgeInsets.all(14),
          color: _subCardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: _titleColor),
                    onPressed: _closeSeriesDetail,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSeriesTitle,
                          style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 11),
                            SizedBox(width: 4),
                            Text('Included with Selection Batch', style: TextStyle(color: Color(0xFFFFA000), fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('74% Completed', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('112 / 150 Tests', style: TextStyle(color: _subColor, fontSize: 9.5)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 0.74,
                            backgroundColor: _borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sub-tabs row: Overview, Tests (Active), Analysis, Leaderboard, Solutions
        Container(
          height: 40,
          color: _cardBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: subTabs.asMap().entries.map((entry) {
              final idx = entry.key;
              final name = entry.value;
              final isSel = _seriesDetailSubTabIndex == idx;

              return InkWell(
                onTap: () {
                  setState(() => _seriesDetailSubTabIndex = idx);
                  if (idx != 1) {
                    AppTheme.showSuccessSnackBar(context, 'Navigating to $name for $_currentSeriesTitle');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSel ? const Color(0xFFFFA000) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSel ? const Color(0xFFFFA000) : _subColor,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Tests List Header & Category Selector
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tests List', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text('Choose a category and start practicing', style: TextStyle(color: _subColor, fontSize: 11.5)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _showTestStructureDialog,
                      icon: Icon(Icons.account_tree_outlined, color: _subColor, size: 14),
                      label: Text('View Test Structure', style: TextStyle(color: _titleColor, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Category Tabs (Chapter Tests | 243 Tests, Unit Tests | 65 Tests, etc.)
                Row(
                  children: categoryTabs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSel = _testsCategoryIndex == idx;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _testsCategoryIndex = idx),
                        child: Container(
                          margin: EdgeInsets.only(right: idx < 3 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFFFA000).withValues(alpha: 0.15) : _cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? const Color(0xFFFFA000) : _borderColor,
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                item['title']!,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFFFFA000) : _titleColor,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 10.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['count']!,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFFFFA000) : _subColor,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Filter Dropdowns Row (Physics v, All Status v, All Difficulty v, Sort by: Newest v)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInlineFilterDropdown(
                        icon: Icons.science_outlined,
                        value: _testSubjectFilter,
                        items: ['Physics', 'Chemistry', 'Mathematics'],
                        onChanged: (v) => setState(() => _testSubjectFilter = v),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineFilterDropdown(
                        icon: null,
                        value: _testStatusFilter,
                        items: ['All Status', 'Attempted', 'Not Attempted', 'Completed', 'Locked'],
                        onChanged: (v) => setState(() => _testStatusFilter = v),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineFilterDropdown(
                        icon: null,
                        value: _testDifficultyFilter,
                        items: ['All Difficulty', 'Easy', 'Medium', 'Hard'],
                        onChanged: (v) => setState(() => _testDifficultyFilter = v),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineFilterDropdown(
                        icon: null,
                        value: _testSortFilter,
                        items: ['Sort by: Newest', 'Sort by: Oldest', 'Sort by: Most Attempted'],
                        onChanged: (v) => setState(() => _testSortFilter = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                                // Dynamic tests loaded from TestService
                FutureBuilder<List<TestItem>>(
                  future: TestService().getCourses().then((courses) => TestService().getTestsByCategory('')),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: Color(0xFFFFA000))));
                    }
                    final tests = snapshot.data ?? [];
                    if (tests.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.quiz_outlined, size: 40, color: _mutedColor),
                            const SizedBox(height: 10),
                            Text('No tests published in this series yet.', style: TextStyle(color: _subColor, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: tests.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final test = entry.value;
                        return _buildTestListItem(
                          id: test.id,
                          number: (idx + 1).toString().padLeft(2, '0'),
                          icon: Icons.quiz_rounded,
                          iconColor: const Color(0xFF38BDF8),
                          title: test.title,
                          type: test.description.isNotEmpty ? test.description : 'Test',
                          difficulty: 'Standard',
                          difficultyColor: const Color(0xFFFFA000),
                          meta: '${test.totalQuestions} Questions  •  ${test.durationMinutes} Minutes',
                          statusText: 'Not Attempted',
                          statusColor: _subColor,
                          actionButton: ElevatedButton(
                            onPressed: () => _showStartTestDialog(test.title, '${test.totalQuestions} Questions', '${test.durationMinutes} Minutes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Start Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                Icon(Icons.chevron_right_rounded, size: 16),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),


                const SizedBox(height: 16),

                // Bottom Callout: "Complete tests in sequence to unlock the next tests."
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFFFA000), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete tests in sequence to unlock the next tests.',
                              style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This helps you follow the right learning path.',
                              style: TextStyle(color: _subColor, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showWhySequenceBottomSheet,
                        child: const Row(
                          children: [
                            Text(
                              'Why Sequence?',
                              style: TextStyle(color: Color(0xFFFFA000), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: Color(0xFFFFA000), size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineFilterDropdown({
    IconData? icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _subColor),
            const SizedBox(width: 4),
          ],
          DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            dropdownColor: _dialogBg,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: _subColor, size: 16),
            style: TextStyle(color: _titleColor, fontSize: 11),
            items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestListItem({
    required String id,
    required String number,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String type,
    required String difficulty,
    required Color difficultyColor,
    required String meta,
    required String statusText,
    required Color statusColor,
    required Widget actionButton,
  }) {
    final isBookmarked = _bookmarkededTestIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section number box (01, 02...)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              // Topic Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(type, style: TextStyle(color: _subColor, fontSize: 10.5)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: difficultyColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(color: difficultyColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(meta, style: TextStyle(color: _mutedColor, fontSize: 10)),
                  ],
                ),
              ),
              // Bookmark icon
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? const Color(0xFFFFA000) : _mutedColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isBookmarked) {
                      _bookmarkededTestIds.remove(id);
                      AppTheme.showSuccessSnackBar(context, 'Removed bookmark from $title');
                    } else {
                      _bookmarkededTestIds.add(id);
                      AppTheme.showSuccessSnackBar(context, 'Bookmarked $title for quick practice!');
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: _borderColor, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              actionButton,
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE 6: OTHER EXAMS TAB (test_p6.png)
  // ===========================================================================

  Widget _buildPage6OtherExams() {
    final exams = [
      {
        'title': 'NEET UG 2027',
        'subtitle': 'Medical',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF34D399),
        'tests': '200+ Tests',
        'questions': '5000+ Questions',
      },
      {
        'title': 'CUET UG 2027',
        'subtitle': 'UG Entrance',
        'icon': Icons.school_outlined,
        'color': const Color(0xFFA78BFA),
        'tests': '120+ Tests',
        'questions': '3000+ Questions',
      },
      {
        'title': 'GATE 2027',
        'subtitle': 'Engineering',
        'icon': Icons.settings_suggest_outlined,
        'color': const Color(0xFF38BDF8),
        'tests': '180+ Tests',
        'questions': '4500+ Questions',
      },
      {
        'title': 'SSC CGL 2027',
        'subtitle': 'Government Exams',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFFF59E0B),
        'tests': '250+ Tests',
        'questions': '6000+ Questions',
      },
      {
        'title': 'Defence Exams',
        'subtitle': 'NDA, CDS, AFCAT',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF2DD4BF),
        'tests': '100+ Tests',
        'questions': '2500+ Questions',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore Tests for Other Exams', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Prepare for various competitive exams with our comprehensive test series.', style: TextStyle(color: _subColor, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _showChangeExamDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Text('View All Exams >', style: TextStyle(color: _subColor, fontSize: 11)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ...exams.map((item) {
                final color = item['color'] as Color;
                final title = item['title'] as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '📄 ${item['tests']}   •   ❓ ${item['questions']}',
                              style: TextStyle(color: _subColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedExam = title;
                          });
                          _switchTab(tabAllTests);
                          widget.onExamChanged?.call(title);
                          AppTheme.showSuccessSnackBar(context, 'Switched to $title series!');
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore Now', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: color, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Bottom Banner matching PDF 6
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFA000), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('One platform, many exams, unlimited practice!', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text('Switch exams anytime and access the best test series for your preparation.', style: TextStyle(color: _subColor, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PAGE 7: MY PERFORMANCE TAB (test_p7.png)
  // ===========================================================================

  Widget _buildPage7MyPerformance() {
    final user = Provider.of<UserProvider>(context).user;

    return StreamBuilder<List<TestResult>>(
      stream: AnalyticsService().getUserTestResultsStream(user?.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFFFA000)),
            ),
          );
        }

        final allResults = snapshot.data ?? [];

        DateRangeFilter dateFilter;
        switch (_performanceTimeframe) {
          case 'Last 7 Days':
            dateFilter = DateRangeFilter.last7Days;
            break;
          case 'Last 30 Days':
            dateFilter = DateRangeFilter.last30Days;
            break;
          case 'Last 90 Days':
          case 'All Time':
          default:
            dateFilter = DateRangeFilter.allTime;
            break;
        }

        final analytics = AnalyticsService().getOverallAnalytics(allResults, dateFilter: dateFilter);
        final hasData = allResults.isNotEmpty && analytics.totalTests > 0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
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
                        Text('Your Test Performance', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text('Track your progress and improve every day.', style: TextStyle(color: _subColor, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderColor),
                    ),
                    child: DropdownButton<String>(
                      value: _performanceTimeframe,
                      dropdownColor: _dialogBg,
                      underline: const SizedBox(),
                      isDense: true,
                      icon: Icon(Icons.arrow_drop_down, color: _subColor, size: 16),
                      style: TextStyle(color: _subColor, fontSize: 11),
                      items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'All Time'].map((val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _performanceTimeframe = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (!hasData)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.insights_rounded, color: Color(0xFFFFA000), size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Test Performance Data Yet',
                        style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attempt mock tests and chapter quizzes to unlock your real accuracy charts, subject breakdowns, and weak topic insights.',
                        style: TextStyle(color: _subColor, fontSize: 12, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _switchTab(tabAllTests);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA000),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Browse All Tests', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else ...[
                // Real 5 KPI Cards
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPerformanceKpiCard(
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFFA78BFA),
                        value: '${analytics.totalTests}',
                        label: 'Tests Attempted',
                        change: 'Real test count',
                      ),
                      _buildPerformanceKpiCard(
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF34D399),
                        value: '${analytics.attemptedQuestions}',
                        label: 'Questions Solved',
                        change: '${analytics.correctAnswers} correct',
                      ),
                      _buildPerformanceKpiCard(
                        icon: Icons.track_changes_rounded,
                        color: const Color(0xFFFFA000),
                        value: '${analytics.averageAccuracy.toStringAsFixed(1)}%',
                        label: 'Average Accuracy',
                        change: 'Peak: ${analytics.peakAccuracy.toStringAsFixed(1)}%',
                      ),
                      _buildPerformanceKpiCard(
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFF38BDF8),
                        value: '${analytics.averageScore.toStringAsFixed(1)}%',
                        label: 'Average Score',
                        change: 'Across all tests',
                      ),
                      _buildPerformanceKpiCard(
                        icon: Icons.emoji_events_outlined,
                        color: const Color(0xFF2DD4BF),
                        value: '${analytics.highestScore.toStringAsFixed(0)} pts',
                        label: 'Best Score',
                        change: 'Top performance',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Real Trend Line Chart Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Performance Trend', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14.5)),
                              const SizedBox(width: 6),
                              Icon(Icons.info_outline_rounded, color: _mutedColor, size: 14),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _borderColor),
                            ),
                            child: Text('Last ${math.min(allResults.length, 10)} Tests', style: TextStyle(color: _subColor, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _TestPerformanceTrendChartPainter(
                            accuracyPoints: allResults.take(7).map((r) => r.accuracy).toList(),
                            scorePoints: allResults.take(7).map((r) => r.totalMarks > 0 ? (r.score / r.totalMarks * 100).toDouble() : 0.0).toList(),
                            dates: allResults.take(7).map((r) => '${r.attemptedAt.day}/${r.attemptedAt.month}').toList(),
                            isDark: _isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ChartLegendDot(label: 'Score (%)', color: const Color(0xFFFFA000), textColor: _subColor),
                          const SizedBox(width: 24),
                          _ChartLegendDot(label: 'Accuracy (%)', color: const Color(0xFF38BDF8), textColor: _subColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Real Subject Wise Accuracy Donut Chart Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subject Wise Accuracy', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14.5)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(100, 100),
                                  painter: _DonutAccuracyChartPainter(
                                    physicsAcc: analytics.subjectAnalytics.isNotEmpty ? analytics.subjectAnalytics[0].accuracy : analytics.averageAccuracy,
                                    chemAcc: analytics.subjectAnalytics.length > 1 ? analytics.subjectAnalytics[1].accuracy : 0.0,
                                    mathAcc: analytics.subjectAnalytics.length > 2 ? analytics.subjectAnalytics[2].accuracy : 0.0,
                                    isDark: _isDark,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Overall', style: TextStyle(color: _subColor, fontSize: 8.5)),
                                    Text('${analytics.averageAccuracy.toStringAsFixed(1)}%', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                if (analytics.subjectAnalytics.isNotEmpty)
                                  ...analytics.subjectAnalytics.take(3).map((sub) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildSubjectAccuracyRow(sub.subjectName, '${sub.accuracy.toStringAsFixed(1)}%', const Color(0xFF38BDF8)),
                                  ))
                                else
                                  _buildSubjectAccuracyRow('Overall', '${analytics.averageAccuracy.toStringAsFixed(1)}%', const Color(0xFF38BDF8)),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    AppNavigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: _borderColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: Text('View Detailed Analysis >', style: TextStyle(color: _subColor, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Preparation Insights Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Preparation Insights', style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 14.5)),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline_rounded, color: _mutedColor, size: 14),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Total questions attempted: ${analytics.attemptedQuestions} with ${analytics.correctAnswers} correct answers (${analytics.averageAccuracy.toStringAsFixed(1)}% accuracy).',
                        style: TextStyle(color: _subColor, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            AppNavigator.push(context, MaterialPageRoute(builder: (_) => const MyPreparationScreen()));
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFA000)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Go to My Preparation >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Insight for You Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFA000), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Insight for You', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 12.5)),
                            const SizedBox(height: 4),
                            Text(
                              analytics.averageAccuracy >= 75
                                  ? 'Outstanding consistency! Keep practicing full-length tests to maintain speed and precision under timed conditions.'
                                  : 'Target your weaker subjects with chapter-wise tests to bring your average accuracy above 75%.',
                              style: TextStyle(color: _subColor, fontSize: 11.5, height: 1.35),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                AppNavigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFFA000)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: const Text('View Detailed Analytics >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceKpiCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required String change,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: TextStyle(color: _subColor, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            change,
            style: TextStyle(
              color: change.contains('↑') ? const Color(0xFF34D399) : _mutedColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAccuracyRow(String name, String acc, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(color: _subColor, fontSize: 12)),
          ],
        ),
        Text(acc, style: TextStyle(color: _titleColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildTopicBar(String topic, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(topic, style: TextStyle(color: _titleColor, fontSize: 11.5)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _ChartLegendDot({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor ?? Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PERFORMANCE TREND LINE CHART PAINTER (Dynamic)
// -----------------------------------------------------------------------------

class _TestPerformanceTrendChartPainter extends CustomPainter {
  final List<double> accuracyPoints;
  final List<double> scorePoints;
  final List<String> dates;
  final bool isDark;

  const _TestPerformanceTrendChartPainter({
    required this.accuracyPoints,
    required this.scorePoints,
    required this.dates,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.5),
      fontSize: 9,
    );

    const levels = ['100%', '75%', '50%', '25%', '0%'];
    const paddingLeft = 32.0;
    const paddingBottom = 20.0;
    final chartWidth = size.width - paddingLeft;
    final chartHeight = size.height - paddingBottom;

    for (int i = 0; i < levels.length; i++) {
      final y = chartHeight * i / (levels.length - 1);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridPaint);

      final span = TextSpan(text: levels[i], style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    if (dates.length < 2) {
      return;
    }

    final xStep = chartWidth / (dates.length - 1);

    for (int i = 0; i < dates.length; i++) {
      final x = paddingLeft + i * xStep;
      final span = TextSpan(text: dates[i], style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }

    Offset getPoint(int index, double value) {
      final x = paddingLeft + index * xStep;
      final y = chartHeight * (1.0 - (value / 100.0).clamp(0.0, 1.0));
      return Offset(x, y);
    }

    if (accuracyPoints.isNotEmpty) {
      _drawCurvedLine(canvas, accuracyPoints, getPoint, const Color(0xFF38BDF8));
    }

    if (scorePoints.isNotEmpty) {
      _drawCurvedLine(canvas, scorePoints, getPoint, const Color(0xFFFFA000));
    }
  }

  void _drawCurvedLine(
    Canvas canvas,
    List<double> points,
    Offset Function(int, double) getPoint,
    Color color,
  ) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final p0 = getPoint(0, points[0]);
    path.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < points.length; i++) {
      final prev = getPoint(i - 1, points[i - 1]);
      final curr = getPoint(i, points[i]);
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(getPoint(i, points[i]), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// DONUT CHART PAINTER (Dynamic)
// -----------------------------------------------------------------------------

class _DonutAccuracyChartPainter extends CustomPainter {
  final double physicsAcc;
  final double chemAcc;
  final double mathAcc;
  final bool isDark;

  const _DonutAccuracyChartPainter({
    this.physicsAcc = 0.0,
    this.chemAcc = 0.0,
    this.mathAcc = 0.0,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final total = physicsAcc + chemAcc + mathAcc;
    if (total <= 0) return;

    final arcPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final physSweep = (physicsAcc / total) * 2 * math.pi;
    final mathSweep = (mathAcc / total) * 2 * math.pi;
    final chemSweep = (chemAcc / total) * 2 * math.pi;

    if (physicsAcc > 0) {
      arcPaint.color = const Color(0xFF38BDF8);
      canvas.drawArc(rect, -math.pi / 2, physSweep, false, arcPaint);
    }

    if (mathAcc > 0) {
      arcPaint.color = const Color(0xFF34D399);
      canvas.drawArc(rect, -math.pi / 2 + physSweep, mathSweep, false, arcPaint);
    }

    if (chemAcc > 0) {
      arcPaint.color = const Color(0xFFFFA000);
      canvas.drawArc(rect, -math.pi / 2 + physSweep + mathSweep, chemSweep, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
