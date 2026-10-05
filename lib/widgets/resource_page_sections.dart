// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/content_models.dart';
import '../models/user_model.dart';
import '../screens/pdf_viewer_screen.dart';
import 'community_chat_view.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'create_edit_resource_sheet.dart';

/// Complete Resource Center Sections Widget matching all 7 pages of `Resource page.pdf`.
class ResourcePageSections extends StatefulWidget {
  final Function(String examName)? onExamChanged;
  final Function(String title)? onResourceOpened;
  final Function(String title, double price)? onUnlockRequested;
  final ValueChanged<int>? onTabChanged;

  const ResourcePageSections({
    super.key,
    this.onExamChanged,
    this.onResourceOpened,
    this.onUnlockRequested,
    this.onTabChanged,
  });

  @override
  State<ResourcePageSections> createState() => _ResourcePageSectionsState();
}

class _ResourcePageSectionsState extends State<ResourcePageSections> {
  // Navigation:
  // 0: Overview, 1: Community, 2: My Resources, 3: Included with Batch, 4: Explore Resources, 5: Categories/Notes, 6: Other Exams, 7: Recommended
  int _activeTabIndex = 0;

  // Whether currently deep-diving into Page 5 (Notes / Category Detail View)
  bool _isViewingNotesDeepDive = false;

  // Selected Target Exam
  String _selectedExam = 'JEE Main 2027';

  // Page 2: My Resources filter
  String _myResourcesFilter = 'All';

  // Page 4: Explore Resources category filter
  String _exploreCategoryFilter = 'All';

  // Page 5 (Notes Deep Dive) state:
  String _notesSubjectFilter = 'Physics';
  String _notesAccessFilter = 'All (512)';
  String _notesSortOption = 'Sort by: Recommended';
  String _notesSearchQuery = '';

  // Page 5 Right Filter Sidebar toggles:
  final Set<String> _sidebarAccessFilters = {'Included with Batch', 'Free'};
  final Set<String> _sidebarFileTypeFilters = {'PDF'};
  bool _sidebarDownloadedOnly = false;
  bool _sidebarBookmarkedOnly = false;

  // Bookmarks state
  final Set<String> _bookmarkedIds = {'my_res_01', 'note_01', 'note_03'};

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Overview', 'icon': Icons.home_outlined},
    {'title': 'Community', 'icon': Icons.forum_rounded},
    {'title': 'My Resources', 'icon': Icons.folder_outlined},
    {'title': 'Included with Batch', 'icon': Icons.card_giftcard_outlined},
    {'title': 'Explore Resources', 'icon': Icons.menu_book_outlined},
    {'title': 'Categories', 'icon': Icons.grid_view_outlined},
    {'title': 'Other Exams', 'icon': Icons.school_outlined},
    {'title': 'Recommended', 'icon': Icons.star_border_rounded},
  ];

  void _switchTab(int index) {
    setState(() {
      _activeTabIndex = index;
      _isViewingNotesDeepDive = false;
    });
    widget.onTabChanged?.call(index);
  }

  void _openNotesDeepDive() {
    setState(() {
      _isViewingNotesDeepDive = true;
    });
    widget.onTabChanged?.call(-1);
  }

  void _closeNotesDeepDive() {
    setState(() {
      _isViewingNotesDeepDive = false;
    });
    widget.onTabChanged?.call(_activeTabIndex);
  }

  void _toggleBookmark(String id, String title, [String subject = 'Resource', bool isCurrentlyBookmarked = false]) {
    FirestoreService().toggleBookmark(
      questionId: id,
      questionText: title,
      subject: subject,
      testName: 'Resource Note',
    );
    AppTheme.showSuccessSnackBar(
      context,
      isCurrentlyBookmarked ? 'Removed bookmark from $title' : 'Bookmarked $title in real-time! 🔖',
    );
  }

  void _openPdfResource(ResourceItem item) {
    FirestoreService().recordResourceView(item, 0.85);
    widget.onResourceOpened?.call(item.title);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfData: item),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE DIALOGS
  // ---------------------------------------------------------------------------

  void _showChangeExamDialog() {
    final exams = [
      'JEE Main 2027',
      'NEET UG 2027',
      'CUET UG 2027',
      'GATE 2027',
      'SSC CGL 2027',
      'Defence Exams',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Target Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                const Text('Choose your exam to customize notes, formula sheets, and lectures.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                ...exams.map((exam) {
                  final isSel = _selectedExam == exam;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFFFA000).withValues(alpha: 0.2) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isSel ? Icons.check_circle : Icons.school_outlined, color: isSel ? const Color(0xFFFFA000) : Colors.white70, size: 18),
                    ),
                    title: Text(exam, style: TextStyle(color: isSel ? const Color(0xFFFFA000) : Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSel
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFA000), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Active', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedExam = exam);
                      Provider.of<UserProvider>(context, listen: false).updateTargetExam(exam);
                      FirestoreService().updateTargetExam(exam);
                      widget.onExamChanged?.call(exam);
                      Navigator.pop(ctx);
                      AppTheme.showSuccessSnackBar(context, 'Exam switched to $exam in real-time!');
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHowResourcesWorkDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFFFFA000)),
            SizedBox(width: 10),
            Text('How Resources Work?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bullet(title: 'Included with Batch', desc: 'Auto-unlocked when enrolled in JEE Selection Batch.'),
            SizedBox(height: 8),
            _Bullet(title: 'Free Material', desc: 'Chapter notes, mind maps, formula sheets & PYQs free to read.'),
            SizedBox(height: 8),
            _Bullet(title: 'Premium Vault', desc: 'Specialized 2027 crash notes available for direct unlock.'),
            SizedBox(height: 8),
            _Bullet(title: 'Offline & Bookmarks', desc: 'Save for later and access anytime without internet.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
            child: const Text('Understood', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResourceDetailsDialog({
    required String title,
    required String category,
    required String meta,
    required String badge,
    required double price,
    ResourceItem? resourceItem,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge, style: const TextStyle(color: Color(0xFFFFA000), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text('Category: $category', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Specifications: $meta', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            const Text(
              'High-yield revision notes curated by top IITian faculties. Includes short tricks, formulas, solved examples and past 15-year questions.',
              style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (price > 0)
              Row(
                children: [
                  const Text('Unlock Price: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (price > 0) {
                widget.onUnlockRequested?.call(title, price);
                AppTheme.showSuccessSnackBar(context, 'Proceeding to unlock $title for ₹${price.toStringAsFixed(0)}');
              } else {
                if (resourceItem != null) {
                  _openPdfResource(resourceItem);
                } else {
                  widget.onResourceOpened?.call(title);
                  AppTheme.showSuccessSnackBar(context, 'Opening $title...');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
            child: Text(price > 0 ? 'Unlock Now' : 'Open Resource', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    if (userProvider.selectedExam.isNotEmpty) {
      _selectedExam = userProvider.selectedExam;
    }

    return StreamBuilder<UserModel?>(
      stream: FirestoreService().currentUserStream,
      builder: (context, userSnap) {

        return StreamBuilder<List<ResourceItem>>(
          stream: FirestoreService().getResourcesStream(exam: _selectedExam),
          builder: (context, resourcesSnap) {
            final liveResources = resourcesSnap.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getUserPurchasesStream(),
              builder: (context, purchasesSnap) {
                final purchases = purchasesSnap.data ?? [];
                final purchasedIds = purchases.map((p) => p['id']?.toString() ?? '').toSet();

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getBookmarksStream(),
                  builder: (context, bookmarksSnap) {
                    final bookmarks = bookmarksSnap.data ?? [];
                    final bookmarkedIds = bookmarks.map((b) => (b['questionId'] ?? b['id'])?.toString() ?? '').toSet();

                    return StreamBuilder<List<ResourceItem>>(
                      stream: FirestoreService().getRecentResourcesStream(),
                      builder: (context, recentSnap) {
                        final recentResources = recentSnap.data ?? [];

                        if (_isViewingNotesDeepDive) {
                          return _buildPage5NotesDeepDive(
                            liveResources: liveResources,
                            purchasedIds: purchasedIds,
                            bookmarkedIds: bookmarkedIds,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sub-header (Preparing for JEE Main 2027 v + Change Exam)
                            _buildTopSubHeader(),

                            // Horizontal Tabs Bar (Overview, My Resources, Included with Batch, Explore, Categories, Other Exams, Recommended)
                            _buildHorizontalTabs(),

                            // Active Content
                            Expanded(
                              child: _buildActiveTabContent(
                                liveResources: liveResources,
                                purchasedIds: purchasedIds,
                                bookmarkedIds: bookmarkedIds,
                                recentResources: recentResources,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

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
                    const Text(
                      'Preparing for ',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    Flexible(
                      child: Text(
                        _selectedExam,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFA000), size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _showChangeExamDialog,
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 14),
            label: const Text(
              'Change Exam',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabs() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _activeTabIndex == index;
          final tab = _tabs[index];

          return InkWell(
            onTap: () => _switchTab(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFFFFA000) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 15,
                    color: isSelected ? const Color(0xFFFFA000) : Colors.white60,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab['title'] as String,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFFA000) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTabContent({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
    required List<ResourceItem> recentResources,
  }) {
    switch (_activeTabIndex) {
      case 0:
        return _buildPage1Overview(liveResources: liveResources, purchasedIds: purchasedIds, bookmarkedIds: bookmarkedIds);
      case 1:
        return const CommunityChatView(isEmbedded: true);
      case 2:
        return _buildPage2MyResources(liveResources: liveResources, purchasedIds: purchasedIds, bookmarkedIds: bookmarkedIds, recentResources: recentResources);
      case 3:
        return _buildPage3IncludedWithBatch(liveResources: liveResources, purchasedIds: purchasedIds);
      case 4:
        return _buildPage4ExploreResources(liveResources: liveResources, purchasedIds: purchasedIds, bookmarkedIds: bookmarkedIds);
      case 5:
        return _buildPage5CategoriesSelector(liveResources: liveResources, purchasedIds: purchasedIds, bookmarkedIds: bookmarkedIds);
      case 6:
        return _buildPage6OtherExams(liveResources: liveResources);
      case 7:
        return _buildPage7Recommended(liveResources: liveResources, purchasedIds: purchasedIds, bookmarkedIds: bookmarkedIds);
      default:
        return _buildPage1Overview(liveResources: liveResources, purchasedIds: purchasedIds, bookmarkedIds: bookmarkedIds);
    }
  }

  // ===========================================================================
  // PAGE 1: OVERVIEW (resource_p1.png)
  // ===========================================================================

  Widget _buildPage1Overview({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
  }) {
    final navItems = [
      {'title': 'Community Chat', 'icon': Icons.forum_rounded, 'tab': 1},
      {'title': 'My Resources', 'icon': Icons.folder_outlined, 'tab': 2},
      {'title': 'Included with Batch', 'icon': Icons.card_giftcard_outlined, 'tab': 3},
      {'title': 'Explore Resources', 'icon': Icons.menu_book_outlined, 'tab': 4},
      {'title': 'Categories', 'icon': Icons.grid_view_outlined, 'tab': 5},
      {'title': 'Other Exams', 'icon': Icons.school_outlined, 'tab': 6},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Graphic Banner matching Page 1
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2142), Color(0xFF071426)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.collections_bookmark_rounded, color: Color(0xFFFFA000), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${liveResources.isNotEmpty ? liveResources.length : 13} Live Collections in Real-Time',
                            style: TextStyle(color: Colors.orange.shade200, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your Digital Study Library',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Instant access to chapter notes, high-yield formula sheets, lecture slides and past 15-year questions.',
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Glowing Folder Graphic
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFA000).withValues(alpha: 0.2), blurRadius: 16),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_rounded, color: Color(0xFFFFA000), size: 30),
                      SizedBox(height: 4),
                      Text('RESOURCES', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Student Community & Faculty Chat Interactive Card
          InkWell(
            onTap: () => _switchTab(1),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2648), Color(0xFF09172B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.forum_rounded, color: Color(0xFFFFA000), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            const Text(
                              'Student & Faculty Community',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('LIVE', style: TextStyle(color: Color(0xFF34D399), fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Chat with peers, ask doubts & get verified faculty answers.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _switchTab(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 6 Quick Nav Tiles (2 rows of 3)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: navItems.map((item) {
              return InkWell(
                onTap: () => _switchTab(item['tab'] as int),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData, color: const Color(0xFFFFA000), size: 24),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Real-time live resources feed
          if (liveResources.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFFFA000), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Live Real-Time Notes ⚡',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _switchTab(5),
                  child: const Text('View All >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...liveResources.take(3).map((r) {
              final isPurchased = purchasedIds.contains(r.id);
              final isBookmarked = bookmarkedIds.contains(r.id);
              return _buildMyResourceRowCard(
                id: r.id,
                icon: r.type == 'Mind Map'
                    ? Icons.psychology_rounded
                    : (r.type == 'Formula Sheet'
                        ? Icons.science_rounded
                        : (r.type == 'Lecture' ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded)),
                iconColor: r.price > 0 ? const Color(0xFFFFA000) : const Color(0xFFA78BFA),
                badge: isPurchased ? 'PURCHASED ✔' : (r.price > 0 ? 'PREMIUM 🔒' : (r.badge == 'INCLUDED' ? 'INCLUDED' : 'FREE')),
                badgeColor: isPurchased ? Colors.green : (r.price > 0 ? const Color(0xFFFFA000) : const Color(0xFF34D399)),
                title: r.title,
                subtitle: r.subtitle.isNotEmpty ? r.subtitle : r.description,
                meta: '${r.subject} • ${r.fileSize}',
                progressText: '${(r.progress * 100).toInt()}% Progress',
                progressVal: r.progress > 0 ? r.progress : (isPurchased ? 1.0 : 0.05),
                progressColor: isPurchased ? Colors.green : const Color(0xFFA78BFA),
                actionLabel: isPurchased ? 'Open Notes >' : (r.price > 0 ? 'Unlock ₹${r.price.toInt()}' : 'Open Notes >'),
                isCompleted: r.isCompleted || isPurchased,
                isBookmarked: isBookmarked,
                onAction: () {
                  if (r.price > 0 && !isPurchased) {
                    widget.onUnlockRequested?.call(r.title, r.price);
                  } else {
                    _openPdfResource(r);
                  }
                },
                onBookmarkToggle: () {
                  _toggleBookmark(r.id, r.title, r.subject, isBookmarked);
                },
              );
            }),
            const SizedBox(height: 18),
          ],

          // Bottom Callout Banner matching Page 1
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.layers_rounded, color: Color(0xFFFFA000), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Everything you need to learn, revise & master your exam.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Notes, PYQs, Study Material, Mind Maps, PPTs and more.',
                        style: TextStyle(color: Colors.white60, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: _showHowResourcesWorkDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFA000)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('How It Works >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String type, [String fileType = '']) {
    final t = ('$type $fileType').toLowerCase();
    if (t.contains('video') || t.contains('lecture')) return Icons.play_circle_fill_rounded;
    if (t.contains('pyq') || t.contains('quiz') || t.contains('question')) return Icons.quiz_rounded;
    if (t.contains('mind map') || t.contains('map')) return Icons.psychology_rounded;
    if (t.contains('formula')) return Icons.science_rounded;
    if (t.contains('ppt') || t.contains('slideshow')) return Icons.slideshow_rounded;
    if (t.contains('material') || t.contains('book')) return Icons.description_rounded;
    return Icons.picture_as_pdf_rounded;
  }

  Color _getResourceColor(String type, [String subject = '']) {
    final s = subject.toLowerCase();
    if (s.contains('chem')) return const Color(0xFF38BDF8);
    if (s.contains('math')) return const Color(0xFFFB923C);
    if (s.contains('bio')) return const Color(0xFF34D399);
    final t = type.toLowerCase();
    if (t.contains('video') || t.contains('lecture')) return const Color(0xFF38BDF8);
    if (t.contains('pyq')) return const Color(0xFF2DD4BF);
    if (t.contains('mind map')) return const Color(0xFF34D399);
    if (t.contains('formula')) return const Color(0xFF06B6D4);
    return const Color(0xFFA78BFA);
  }

  Color _getBadgeColor(String badge, bool isFree, bool isBatchIncluded, bool isPurchased) {
    if (isPurchased) return const Color(0xFFFFA000);
    if (isFree) return const Color(0xFF2DD4BF);
    if (isBatchIncluded) return const Color(0xFF34D399);
    final b = badge.toUpperCase();
    if (b.contains('FREE')) return const Color(0xFF2DD4BF);
    if (b.contains('INCLUDED')) return const Color(0xFF34D399);
    return const Color(0xFFFFA000);
  }

  // ===========================================================================
  // PAGE 2: MY RESOURCES (resource_p2.png)
  // ===========================================================================

  Widget _buildPage2MyResources({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
    required List<ResourceItem> recentResources,
  }) {
    final filters = ['All', 'Recently Viewed', 'Downloaded', 'Bookmarks'];

    List<ResourceItem> displayItems = [];
    if (_myResourcesFilter == 'All') {
      displayItems = liveResources.where((r) =>
        purchasedIds.contains(r.id) ||
        bookmarkedIds.contains(r.id) ||
        r.isFree ||
        r.isBatchIncluded
      ).toList();
      if (displayItems.isEmpty) {
        displayItems = liveResources.take(5).toList();
      }
    } else if (_myResourcesFilter == 'Recently Viewed') {
      displayItems = recentResources.isNotEmpty ? recentResources : liveResources.take(3).toList();
    } else if (_myResourcesFilter == 'Downloaded') {
      displayItems = liveResources.where((r) => r.isFree || purchasedIds.contains(r.id) || r.isBatchIncluded).take(4).toList();
    } else if (_myResourcesFilter == 'Bookmarks') {
      displayItems = liveResources.where((r) => bookmarkedIds.contains(r.id)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.folder_rounded, color: Color(0xFFFFA000), size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Resources', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Quick access to the resources you've used or saved.", style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => CreateEditResourceSheet.show(context),
                    icon: const Icon(Icons.add_rounded, size: 15, color: Color(0xFF10B981)),
                    label: const Text('Add Resource', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _switchTab(4),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFA000)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text('Explore All >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter chips row
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filters.length,
            itemBuilder: (ctx, idx) {
              final f = filters[idx];
              final isSel = _myResourcesFilter == f;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(f, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  selected: isSel,
                  onSelected: (val) => setState(() => _myResourcesFilter = f),
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFFFFA000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? const Color(0xFFFFA000) : Colors.white12)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal/Vertical Resource List with real-time stream items
        Expanded(
          child: displayItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _myResourcesFilter == 'Bookmarks' ? Icons.bookmark_border_rounded : Icons.folder_open_rounded,
                          color: Colors.white24,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _myResourcesFilter == 'Bookmarks' ? 'No Bookmarks Yet' : 'No items in $_myResourcesFilter',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _myResourcesFilter == 'Bookmarks'
                              ? 'Tap the bookmark icon on any resource or note to save it here in real-time!'
                              : 'Explore our rich library of notes, PYQs and formula sheets.',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _switchTab(4),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA000),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Explore Resources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayItems.length,
                  itemBuilder: (ctx, idx) {
                    final r = displayItems[idx];
                    final icon = _getResourceIcon(r.type, r.fileType);
                    final color = _getResourceColor(r.type, r.subject);
                    final isPurchased = purchasedIds.contains(r.id);
                    final badge = isPurchased ? 'PURCHASED' : (r.isFree ? 'FREE' : (r.isBatchIncluded ? 'INCLUDED' : (r.badge.isNotEmpty ? r.badge : 'PREMIUM')));
                    final badgeColor = _getBadgeColor(badge, r.isFree, r.isBatchIncluded, isPurchased);
                    final isBookmarked = bookmarkedIds.contains(r.id);

                    return _buildMyResourceRowCard(
                      id: r.id,
                      icon: icon,
                      iconColor: color,
                      badge: badge,
                      badgeColor: badgeColor,
                      title: r.title,
                      subtitle: r.subtitle.isNotEmpty ? r.subtitle : (r.chapter.isNotEmpty ? r.chapter : r.description),
                      meta: '${r.subject.isNotEmpty ? r.subject : r.exam} • ${r.fileType.isNotEmpty ? r.fileType : r.type}',
                      progressText: r.progress > 0 ? '${(r.progress * 100).toInt()}% Viewed' : (r.isCompleted ? '100% Viewed' : '0% Started'),
                      progressVal: r.progress > 0 ? r.progress : (r.isCompleted ? 1.0 : 0.05),
                      progressColor: color,
                      actionLabel: r.progress > 0 ? 'Continue Reading >' : 'Open Resource >',
                      isCompleted: r.isCompleted,
                      isBookmarkedOverride: isBookmarked,
                      onBookmarkToggle: () => _toggleBookmark(r.id, r.title),
                      onAction: () {
                        _openPdfResource(r);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMyResourceRowCard({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required String meta,
    required String progressText,
    required double progressVal,
    required Color progressColor,
    required String actionLabel,
    required VoidCallback onAction,
    bool isCompleted = false,
    bool? isBookmarked,
    bool? isBookmarkedOverride,
    VoidCallback? onBookmarkToggle,
  }) {
    final isItemBookmarked = isBookmarked ?? isBookmarkedOverride ?? _bookmarkedIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progressVal,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 13),
                    const SizedBox(width: 4),
                    Text(progressText, style: const TextStyle(color: Colors.white60, fontSize: 9.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                icon: Icon(isItemBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: isItemBookmarked ? const Color(0xFFFFA000) : Colors.white38, size: 20),
                onPressed: () {
                  if (onBookmarkToggle != null) {
                    onBookmarkToggle();
                  } else {
                    _toggleBookmark(id, title);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 3: INCLUDED WITH YOUR BATCH (resource_p3.png) - Dynamic Firebase
  // ==========================================

  Widget _buildPage3IncludedWithBatch({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
  }) {
    // Dynamically filter resources assigned to batches or marked as included
    final includedList = liveResources.where((r) =>
        r.isBatchIncluded ||
        r.batchIds.isNotEmpty ||
        purchasedIds.contains(r.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Included With Your Batch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Unlock premium resources included in your enrolled batches ✨', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${includedList.length} Included',
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (includedList.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard_rounded, size: 44, color: Color(0xFFFFA000)),
                  const SizedBox(height: 12),
                  const Text(
                    'No Batch Resources Available',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You do not have any resources linked to your batches yet. Explore all study resources or create one.',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _switchTab(4),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Explore All Resources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: includedList.length,
              itemBuilder: (ctx, idx) {
                final item = includedList[idx];
                final icon = _getResourceIcon(item.type, item.fileType);
                final color = _getResourceColor(item.type, item.subject);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.subject.isNotEmpty ? item.subject : item.exam} • ${item.fileSize}',
                              style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _openPdfResource(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA000),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Open', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE 4: EXPLORE RESOURCES (resource_p4.png)
  // ===========================================================================

  Widget _buildPage4ExploreResources({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
  }) {
    final categories = ['All', 'Notes', 'PYQs', 'Study Material', 'Mind Maps', 'PPTs', 'Formula Sheets', 'Revision Notes'];

    final filtered = _exploreCategoryFilter == 'All'
        ? liveResources
        : liveResources.where((i) {
            final q = _exploreCategoryFilter.toLowerCase();
            return i.type.toLowerCase().contains(q) ||
                   i.category.toLowerCase().contains(q) ||
                   i.title.toLowerCase().contains(q) ||
                   i.subtitle.toLowerCase().contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('| Explore Resources ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Discover high-quality resources to supercharge your preparation.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _switchTab(2),
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFFA000), size: 14),
                label: const Text('View My Purchases', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10.5, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFA000)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (ctx, idx) {
              final c = categories[idx];
              final isSel = _exploreCategoryFilter == c;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(c, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  selected: isSel,
                  onSelected: (val) => setState(() => _exploreCategoryFilter = c),
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFFFFA000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? const Color(0xFFFFA000) : Colors.white12)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Explore Cards List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text('No resources found in "$_exploreCategoryFilter"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => _exploreCategoryFilter = 'All'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
                          child: const Text('Show All Resources', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    final isPurchased = purchasedIds.contains(item.id);
                    final isUnlocked = isPurchased || item.isFree || item.isBatchIncluded;
                    final double price = isUnlocked ? 0.0 : item.price;
                    final icon = _getResourceIcon(item.type, item.fileType);
                    final iconColor = _getResourceColor(item.type, item.subject);
                    final badge = isPurchased
                        ? 'PURCHASED'
                        : (item.isFree
                            ? 'FREE'
                            : (item.isBatchIncluded
                                ? 'INCLUDED'
                                : (item.badge.isNotEmpty ? item.badge : (price > 0 ? 'PREMIUM' : 'FREE'))));
                    final badgeColor = _getBadgeColor(badge, item.isFree, item.isBatchIncluded, isPurchased);
                    final isBookmarked = bookmarkedIds.contains(item.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: iconColor, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      '★ ${item.rating > 0 ? item.rating.toStringAsFixed(1) : '4.8'} (${item.downloads.isNotEmpty ? item.downloads : '10K+'})',
                                      style: const TextStyle(color: Colors.amber, fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(
                                  item.subtitle.isNotEmpty
                                      ? item.subtitle
                                      : '${item.subject.isNotEmpty ? item.subject : item.exam} • ${item.fileType.isNotEmpty ? item.fileType : item.type}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: isBookmarked ? const Color(0xFFFFA000) : Colors.white38, size: 20),
                                onPressed: () => _toggleBookmark(item.id, item.title),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(height: 4),
                              if (price > 0) ...[
                                Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w900, fontSize: 15)),
                                const SizedBox(height: 4),
                              ],
                              ElevatedButton(
                                onPressed: () {
                                  if (price > 0) {
                                    _showResourceDetailsDialog(
                                      title: item.title,
                                      category: item.type,
                                      meta: '${item.subject} • ${item.fileType}',
                                      badge: badge,
                                      price: price,
                                      resourceItem: item,
                                    );
                                  } else {
                                    _openPdfResource(item);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA000),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(price > 0 ? 'View Details' : 'Open Resource >>', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PAGE 5: CATEGORY SELECTOR / DIRECT ACCESS TO NOTES (resource_p5.png)
  // ===========================================================================

  Widget _buildPage5CategoriesSelector({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
  }) {
    return _buildPage5NotesDeepDive(
      liveResources: liveResources,
      purchasedIds: purchasedIds,
      bookmarkedIds: bookmarkedIds,
    );
  }

  Widget _buildPage5NotesDeepDive({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
  }) {
    final subjects = ['All', 'Physics', 'Chemistry', 'Mathematics', 'Biology'];
    final accessTypes = ['All (${liveResources.length})', '✓ Included with Batch', 'Free', 'Purchased', 'Premium'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Back Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              if (_isViewingNotesDeepDive)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: _closeNotesDeepDive,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_isViewingNotesDeepDive) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFA78BFA).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFFA78BFA), size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Chapter-wise notes for complete revision', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ),

        // Search bar + Filter button (Page 5 of PDF)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _notesSearchQuery = val.toLowerCase().trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Search chapter notes, formulas, topics...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFFFA000), size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showFilterModalSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Color(0xFFFFA000), size: 16),
                      SizedBox(width: 4),
                      Text('Filter', style: TextStyle(color: Color(0xFFFFA000), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Subject Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subjects.map((sub) {
                final isSel = _notesSubjectFilter == sub;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(sub, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selected: isSel,
                    onSelected: (val) => setState(() => _notesSubjectFilter = sub),
                    backgroundColor: const Color(0xFF0F172A),
                    selectedColor: const Color(0xFFFFA000),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSel ? const Color(0xFFFFA000) : Colors.white12)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Access chips & Sort dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: accessTypes.map((type) {
                      final isSel = _notesAccessFilter == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(type, style: TextStyle(color: isSel ? const Color(0xFFFFA000) : Colors.white60, fontSize: 10)),
                          selected: isSel,
                          onSelected: (val) => setState(() => _notesAccessFilter = type),
                          backgroundColor: const Color(0xFF0F172A),
                          selectedColor: const Color(0xFFFFA000).withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isSel ? const Color(0xFFFFA000) : Colors.white10)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _notesSortOption,
                dropdownColor: const Color(0xFF0F172A),
                underline: const SizedBox(),
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                items: ['Sort by: Recommended', 'Sort by: Chapter Number', 'Sort by: Recently Updated'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _notesSortOption = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Notes List
        Expanded(
          child: Builder(
            builder: (context) {
              final filteredNotes = liveResources.where((n) {
                if (_notesSearchQuery.isNotEmpty) {
                  final title = n.title.toLowerCase();
                  final ch = n.chapter.toLowerCase();
                  final sub = n.subject.toLowerCase();
                  if (!title.contains(_notesSearchQuery) && !ch.contains(_notesSearchQuery) && !sub.contains(_notesSearchQuery)) {
                    return false;
                  }
                }
                if (_notesSubjectFilter != 'All' && n.subject.isNotEmpty) {
                  if (!n.subject.toLowerCase().contains(_notesSubjectFilter.toLowerCase())) {
                    return false;
                  }
                }
                final isPurchased = purchasedIds.contains(n.id);
                if (_notesAccessFilter.contains('Included')) {
                  if (!n.isBatchIncluded) return false;
                } else if (_notesAccessFilter == 'Free') {
                  if (!n.isFree) return false;
                } else if (_notesAccessFilter == 'Purchased') {
                  if (!isPurchased) return false;
                } else if (_notesAccessFilter == 'Premium') {
                  if (n.isFree || n.isBatchIncluded || isPurchased) return false;
                }
                if (_sidebarBookmarkedOnly && !bookmarkedIds.contains(n.id)) {
                  return false;
                }
                return true;
              }).toList();

              if (filteredNotes.isEmpty) {
                return const Center(
                  child: Text(
                    'No chapter notes found matching your search',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredNotes.length,
                itemBuilder: (ctx, idx) {
                  final n = filteredNotes[idx];
                  final id = n.id;
                  final isBookmarked = bookmarkedIds.contains(id);
                  final isPurchased = purchasedIds.contains(id);
                  final isUnlocked = isPurchased || n.isFree || n.isBatchIncluded;
                  final double price = isUnlocked ? 0.0 : n.price;
                  final chapterNumStr = n.chapterNum.isNotEmpty ? n.chapterNum : (idx + 1 < 10 ? '0${idx + 1}' : '${idx + 1}');
                  final color = _getResourceColor(n.type, n.subject);
                  final badge = isPurchased
                      ? 'PURCHASED'
                      : (n.isFree
                          ? 'FREE'
                          : (n.isBatchIncluded
                              ? 'INCLUDED ✔'
                              : (n.badge.isNotEmpty ? n.badge : (price > 0 ? 'PREMIUM 🔒' : 'FREE'))));
                  final badgeColor = _getBadgeColor(badge, n.isFree, n.isBatchIncluded, isPurchased);
                  final viewed = n.progress > 0
                      ? '${(n.progress * 100).toInt()}% viewed'
                      : (isUnlocked ? 'Ready to read' : 'Unlock to access');
                  final btn = price > 0 ? 'UNLOCK NOW >' : 'READ NOW >';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Number
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                              child: Text(chapterNumStr, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            // PDF icon
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(n.chapter.isNotEmpty ? n.chapter : '${n.subject} • Chapter $chapterNumStr', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('${n.fileType.isNotEmpty ? n.fileType : 'PDF'} • ${n.fileSize.isNotEmpty ? n.fileSize : '18 Pages'} • Updated 2026', style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: isBookmarked ? const Color(0xFFFFA000) : Colors.white38, size: 20),
                              onPressed: () => _toggleBookmark(id, n.title),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                ),
                                if (n.batchIds.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${n.batchIds.length} Batches',
                                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Text(viewed, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white70),
                                  tooltip: 'Edit & Assign Batches',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () => CreateEditResourceSheet.show(context, existingResource: n),
                                ),
                                const SizedBox(width: 4),
                                if (price > 0) ...[
                                  const Text('₹199', style: TextStyle(color: Colors.white38, decoration: TextDecoration.lineThrough, fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 8),
                                ],
                                ElevatedButton(
                                  onPressed: () {
                                    if (price > 0) {
                                      widget.onUnlockRequested?.call(n.title, price);
                                      AppTheme.showSuccessSnackBar(context, 'Proceeding to unlock ${n.title} for ₹${price.toStringAsFixed(0)}');
                                    } else {
                                      _openPdfResource(n);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA000),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(btn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterModalSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Access Type', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Included with Batch (245)', 'Free (96)', 'Purchased (32)', 'Premium (139)'].map((t) {
                    final key = t.split(' ')[0];
                    final isSel = _sidebarAccessFilters.contains(key);
                    return FilterChip(
                      label: Text(t, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10.5)),
                      selected: isSel,
                      onSelected: (v) {
                        setModalState(() {
                          setState(() {
                            v ? _sidebarAccessFilters.add(key) : _sidebarAccessFilters.remove(key);
                          });
                        });
                      },
                      backgroundColor: Colors.white10,
                      selectedColor: const Color(0xFFFFA000),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('File Type', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['PDF (498)', 'eBook (12)', 'DOC (2)'].map((t) {
                    final key = t.split(' ')[0];
                    final isSel = _sidebarFileTypeFilters.contains(key);
                    return FilterChip(
                      label: Text(t, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10.5)),
                      selected: isSel,
                      onSelected: (v) {
                        setModalState(() {
                          setState(() {
                            v ? _sidebarFileTypeFilters.add(key) : _sidebarFileTypeFilters.remove(key);
                          });
                        });
                      },
                      backgroundColor: Colors.white10,
                      selectedColor: const Color(0xFFFFA000),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Downloaded Only', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  value: _sidebarDownloadedOnly,
                  activeThumbColor: const Color(0xFFFFA000),
                  onChanged: (v) => setModalState(() => setState(() => _sidebarDownloadedOnly = v)),
                ),
                SwitchListTile(
                  title: const Text('Bookmarked Only', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  value: _sidebarBookmarkedOnly,
                  activeThumbColor: const Color(0xFFFFA000),
                  onChanged: (v) => setModalState(() => setState(() => _sidebarBookmarkedOnly = v)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
                    child: const Text('Apply Filters', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 6: OTHER EXAMS (resource_p6.png)
  // ===========================================================================

  Widget _buildPage6OtherExams({required List<ResourceItem> liveResources}) {
    final otherExams = [
      {
        'name': 'NEET UG 2027',
        'sub': 'Complete resources for NEET UG preparation',
        'badge': 'POPULAR',
        'badgeColor': const Color(0xFF34D399),
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF34D399),
        'pills': ['Notes', 'PYQs', 'Mind Maps', 'PPTs'],
        'count': '6,200+ Resources',
      },
      {
        'name': 'CUET UG 2027',
        'sub': 'Domain wise study material and practice resources',
        'badge': null,
        'badgeColor': Colors.transparent,
        'icon': Icons.school_outlined,
        'color': const Color(0xFFA78BFA),
        'pills': ['Notes', 'PYQs', 'Study Material', 'PPTs'],
        'count': '3,800+ Resources',
      },
      {
        'name': 'GATE 2027',
        'sub': 'Subject wise notes, PYQs and engineering resources',
        'badge': null,
        'badgeColor': Colors.transparent,
        'icon': Icons.settings_suggest_outlined,
        'color': const Color(0xFFFB923C),
        'pills': ['Notes', 'Formula Sheets', 'PYQs', 'PPTs'],
        'count': '4,100+ Resources',
      },
      {
        'name': 'SSC CGL 2027',
        'sub': 'Complete preparation resources for SSC CGL',
        'badge': null,
        'badgeColor': Colors.transparent,
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF38BDF8),
        'pills': ['Notes', 'PYQs', 'Practice Tests', 'Current Affairs'],
        'count': '5,900+ Resources',
      },
      {
        'name': 'Defence Exams',
        'sub': 'NDA, CDS, AFCAT and more defence exam resources',
        'badge': null,
        'badgeColor': Colors.transparent,
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF2DD4BF),
        'pills': ['Notes', 'PYQs', 'Practice Tests', 'PFT Guide'],
        'count': '2,400+ Resources',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('| Resources for Other Exams ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Explore high quality resources for all major exams', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _showChangeExamDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFA000)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text('View All Exams >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherExams.length,
            itemBuilder: (ctx, idx) {
              final e = otherExams[idx];
              final color = e['color'] as Color;
              final pills = e['pills'] as List<String>;
              final name = e['name'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Icon(e['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              if (e['badge'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: (e['badgeColor'] as Color).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                                  child: Text(e['badge'] as String, style: TextStyle(color: e['badgeColor'] as Color, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(e['sub'] as String, style: const TextStyle(color: Colors.white60, fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: pills.map((p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                              child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedExam = name;
                          _activeTabIndex = 4; // Explore Resources
                        });
                        FirestoreService().updateTargetExam(name);
                        widget.onExamChanged?.call(name);
                        AppTheme.showSuccessSnackBar(context, 'Switched to $name resources in real-time!');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e['count'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10.5)),
                          Icon(Icons.chevron_right_rounded, color: color, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PAGE 7: RECOMMENDED FOR YOU (resource_p7.png)
  // ===========================================================================

  Widget _buildPage7Recommended({
    required List<ResourceItem> liveResources,
    required Set<String> purchasedIds,
    required Set<String> bookmarkedIds,
  }) {
    final tags = ['HIGH PRIORITY', 'REVISION BOOST', 'CONTINUE LEARNING', 'PRACTICE MORE', 'NEWLY ADDED'];
    final tagColors = [
      const Color(0xFFEF4444),
      const Color(0xFFFFA000),
      const Color(0xFF38BDF8),
      const Color(0xFF34D399),
      const Color(0xFFEC4899),
    ];
    final reasons = [
      'Based on your weak areas',
      'Recommended for revision',
      'Continue from last session',
      'Recommended for you',
      'Just added',
    ];
    final reasonColors = [
      const Color(0xFFA78BFA),
      const Color(0xFFFFA000),
      const Color(0xFF38BDF8),
      const Color(0xFF34D399),
      const Color(0xFFEC4899),
    ];

    final displayItems = liveResources.isNotEmpty
        ? liveResources.take(5).toList()
        : <ResourceItem>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                    Text('| Recommended for You ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Resources curated based on your performance and study activity.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _switchTab(4),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFA000)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text('View All >', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Recommended Cards from live stream
          ...displayItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final tagColor = tagColors[idx % tagColors.length];
            final reasonColor = reasonColors[idx % reasonColors.length];
            final tag = tags[idx % tags.length];
            final reason = reasons[idx % reasons.length];
            final icon = _getResourceIcon(item.type, item.fileType);
            final iconColor = _getResourceColor(item.type, item.subject);
            final isPurchased = purchasedIds.contains(item.id);
            final isUnlocked = isPurchased || item.isFree || item.isBatchIncluded;
            final btn = item.progress > 0 ? 'RESUME >' : (isUnlocked ? 'OPEN NOW >' : 'VIEW >');

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text(tag, style: TextStyle(color: tagColor, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: reasonColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                              child: Text(reason, style: TextStyle(color: reasonColor, fontSize: 8.5, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          item.subtitle.isNotEmpty
                              ? item.subtitle
                              : (item.chapter.isNotEmpty ? item.chapter : 'Curated for fast score boost'),
                          style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.subject.isNotEmpty ? item.subject : item.exam} • ${item.fileType.isNotEmpty ? item.fileType : item.type}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (!isUnlocked && item.price > 0) {
                        widget.onUnlockRequested?.call(item.title, item.price);
                        AppTheme.showSuccessSnackBar(context, 'Proceeding to unlock ${item.title} for ₹${item.price.toStringAsFixed(0)}');
                      } else {
                        _openPdfResource(item);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(btn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Bottom Feature Banner matching Page 7
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2142), Color(0xFF071426)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFFFA000), shape: BoxShape.circle),
                      child: const Icon(Icons.track_changes_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your preparation, our priority.', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Text('We recommend the right resources at the right time to help you achieve your best.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPillarItem('Personalized Recommendations', 'Based on your performance', Icons.star_rounded, const Color(0xFFFFA000)),
                    _buildPillarItem('Performance Driven', 'Improving your weak areas', Icons.trending_up_rounded, const Color(0xFF38BDF8)),
                    _buildPillarItem('Smart Tracking', 'Track what you read and learn', Icons.bookmark_rounded, const Color(0xFF34D399)),
                    _buildPillarItem('Better Results Together', 'Learn smart, score high', Icons.emoji_events_rounded, const Color(0xFFA78BFA)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPillarItem(String title, String desc, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5), textAlign: TextAlign.center, maxLines: 2),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 8), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String title;
  final String desc;
  const _Bullet({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                TextSpan(text: desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
