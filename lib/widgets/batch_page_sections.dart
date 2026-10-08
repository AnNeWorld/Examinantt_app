// ignore_for_file: unused_field, unused_import, unused_element
import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../screens/test_series_screen.dart';
import '../screens/resources_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/live_classes_screen.dart';
import '../models/content_models.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import '../services/content_service.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/batch_details_screen.dart';
import 'create_edit_batch_sheet.dart';

/// Complete Batches Page Implementation from "batch page.pdf"
/// Contains all 8 comprehensive sections with full fidelity and interactive features
class BatchPageSections extends StatefulWidget {
  final ScrollController? scrollController;

  const BatchPageSections({super.key, this.scrollController});

  @override
  State<BatchPageSections> createState() => _BatchPageSectionsState();
}

class _BatchPageSectionsState extends State<BatchPageSections> {
  // Active Exam
  String _selectedExam = 'JEE Main 2027';

  // Section 04: Batch filter
  int _activeBatchFilter = 0; // 0: All Batches, 1: Full Prep, 2: Crash Course, 3: Subject Wise

  // Section 05: Comparison selected batches
  final Set<int> _selectedCompareBatches = {0, 1, 2};

  // Section 08: Wizard questions state
  String _wizardExam = 'JEE Main 2027';
  int _wizardPrepLevel = 0; // 0: Just Started, 1: 25-50%, 2: 50-75%, 3: Almost Complete
  int _wizardTimeAvailable = 0; // 0: 3+ Months, 1: 1-3 Months, 2: 15-30 Days, 3: <15 Days

  // Global Key to scroll to Section 08
  final GlobalKey _section08Key = GlobalKey();
  final GlobalKey _section07Key = GlobalKey();

  final PaymentService _paymentService = PaymentService();
  String? _lastCheckoutTitle;
  int? _lastCheckoutPrice;
  String? _lastCheckoutBatchId;
  Set<String> _cachedPurchasedBatchIds = <String>{};
  late final Stream<List<CourseModel>> _coursesStream;

  @override
  void initState() {
    super.initState();
    _coursesStream = ContentService().getCoursesStream();
    _loadCachedPurchases();
    _paymentService.initialize(
      onSuccess: (res) async {
        final title = _lastCheckoutTitle ?? 'Selection Batch';
        final price = (_lastCheckoutPrice ?? 1999).toDouble();
        final batchId = _lastCheckoutBatchId ?? 'batch_${DateTime.now().millisecondsSinceEpoch}';
        await FirestoreService().addPurchase(
          id: batchId,
          itemId: batchId,
          title: title,
          type: 'Batch',
          price: price,
        );
        await FirestoreService().addNotification(
          title: 'Batch Unlocked! 🎉',
          subtitle: 'Successfully enrolled in $title via Razorpay.',
        );
        await _loadCachedPurchases();
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Payment Successful: $title Unlocked!');
        setState(() {});
      },
      onFailure: (res) {
        if (!mounted) return;
        AppTheme.showErrorSnackBar(context, 'Payment Failed: ${res.message ?? "Transaction Cancelled"}');
      },
      onExternalWallet: (res) {},
    );
  }

  Future<void> _loadCachedPurchases() async {
    final cached = await FirestoreService.getCachedPurchasedIds();
    if (mounted) {
      setState(() {
        _cachedPurchasedBatchIds = cached;
      });
    }
  }

  bool _isCourseEnrolled(CourseModel course, List<Map<String, dynamic>> purchases) {
    if (course.price <= 0) return true;
    final bId = course.id.trim();
    final bTitle = course.title.trim().toLowerCase();

    // 1. Check local persistent storage cache
    if (bId.isNotEmpty && _cachedPurchasedBatchIds.contains(bId)) return true;
    if (bTitle.isNotEmpty && _cachedPurchasedBatchIds.contains(bTitle)) return true;

    // 2. Check enrolledStudentIds on batch
    final uid = FirestoreService().effectiveUid ?? '';
    if (uid.isNotEmpty && course.enrolledStudentIds.contains(uid)) return true;

    // 3. Check Firestore purchases stream
    return purchases.any((p) {
      final pId = (p['id'] ?? '').toString().trim();
      final pItemId = (p['itemId'] ?? '').toString().trim();
      final pTitle = (p['title'] ?? '').toString().trim().toLowerCase();

      if (bId.isNotEmpty && (pId == bId || pItemId == bId)) return true;
      if (bTitle.isNotEmpty && pTitle.isNotEmpty && pTitle == bTitle) return true;
      return false;
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

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

  void _confirmDeleteBatch(CourseModel batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C2040),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Delete Batch?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${batch.title}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deleteBatch(batch.id);
                _showSnack('Batch deleted successfully');
              } catch (e) {
                _showSnack('Error deleting batch: $e', color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _scrollToKey(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext ?? context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (_selectedExam != userProvider.selectedExam) {
      _selectedExam = userProvider.selectedExam;
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 01. Choose Your Exam Header & Popular Exams
          _buildSection01ChooseExam(),
          const SizedBox(height: 16),

          // 02. MY PURCHASED BATCHES
          _buildSection02PurchasedBatches(),
          const SizedBox(height: 16),

          // 03. RECOMMENDED FOR JEE MAIN 2027
          _buildSection03Recommended(),
          const SizedBox(height: 16),

          // 04. ALL BATCHES FOR JEE MAIN 2027
          _buildSection04AllBatches(),
          const SizedBox(height: 16),


          // 06. OTHER EXAMS
          _buildSection06OtherExams(),
          const SizedBox(height: 16),

          // 07. SPECIAL OFFERS
          Container(key: _section07Key, child: _buildSection07SpecialOffers()),
          const SizedBox(height: 16),

          // 08. NEED HELP CHOOSING?
          Container(key: _section08Key, child: _buildSection08NeedHelp()),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED SECTION SHELL WITH BLUE BADGE
  // ==========================================
  Widget _buildSectionShell({
    String? sectionNumber,
    required String sectionTag,
    required IconData sectionIcon,
    String? subtitle,
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
          // Ribbon Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2342), Color(0xFF071326)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF142B4D), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0070F3), Color(0xFF0051B3)]),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0070F3).withValues(alpha: 0.4), blurRadius: 6),
                          ],
                        ),
                        child: Icon(sectionIcon, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
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
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
  // 01. CHOOSE YOUR EXAM & POPULAR EXAMS (Page 1)
  // ==========================================
  Widget _buildSection01ChooseExam() {
    final popularExams = [
      {'name': 'JEE Main 2027', 'sub': 'Engineering Entrance', 'abbr': 'JEE', 'color': const Color(0xFF0070F3)},
      {'name': 'NEET UG 2027', 'sub': 'Medical Entrance', 'abbr': 'NEET', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF10B981)},
      {'name': 'CUET UG 2027', 'sub': 'University Entrance', 'abbr': 'CUET', 'icon': Icons.school_rounded, 'color': const Color(0xFFA855F7)},
      {'name': 'GATE 2027', 'sub': 'Engineering Entrance', 'abbr': 'GATE', 'icon': Icons.settings_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'SSC CGL 2027', 'sub': 'Govt. Job Exam', 'abbr': 'SSC', 'icon': Icons.groups_rounded, 'color': const Color(0xFF06B6D4)},
      {'name': 'Defence', 'sub': 'NDA, CDS & More', 'abbr': 'DEF', 'icon': Icons.shield_rounded, 'color': const Color(0xFFEAB308)},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF05132A), Color(0xFF081C3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E3A68), width: 1.2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0070F3).withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [Color(0xFF0070F3), Color(0xFF061A3A)]),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0070F3).withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Exam',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Select your goal. We\'ll show you the best batches to achieve it.',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active target box with 187 days
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B2144),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F4478)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _selectedExam,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_selectedExam Goal',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3 Feature chips
          Row(
            children: [
              Expanded(child: _buildSmallPill('Personalized Recs', Icons.gps_fixed_rounded)),
              const SizedBox(width: 6),
              Expanded(child: _buildSmallPill('Smart Tracking', Icons.insights_rounded)),
              const SizedBox(width: 6),
              Expanded(child: _buildSmallPill('Achieve Goal', Icons.emoji_events_rounded)),
            ],
          ),
          const SizedBox(height: 14),

          // Popular Exams Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Popular Exams',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showAllExamsModal(popularExams),
                child: const Text(
                  'View All Exams >',
                  style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal popular exams list
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: popularExams.length,
              itemBuilder: (context, index) {
                final exam = popularExams[index];
                final isCurrent = exam['name'] == _selectedExam;
                final Color itemColor = exam['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedExam = exam['name'] as String;
                    });
                    Provider.of<UserProvider>(context, listen: false).updateTargetExam(_selectedExam);
                    _showSnack('Exam switched to $_selectedExam!');
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFF112C57) : const Color(0xFF091C38),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF0070F3) : const Color(0xFF1C3A66),
                        width: isCurrent ? 1.6 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [BoxShadow(color: const Color(0xFF0070F3).withValues(alpha: 0.3), blurRadius: 6)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: itemColor.withValues(alpha: 0.2),
                              child: Text(
                                exam['abbr'] as String,
                                style: TextStyle(color: itemColor, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (isCurrent)
                              const Positioned(
                                right: -2,
                                top: -2,
                                child: CircleAvatar(
                                  radius: 6,
                                  backgroundColor: Color(0xFF0070F3),
                                  child: Icon(Icons.check, color: Colors.white, size: 8),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          exam['name'] as String,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          exam['sub'] as String,
                          style: const TextStyle(color: Colors.white38, fontSize: 6.5),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Icon(Icons.arrow_forward, color: isCurrent ? const Color(0xFF38BDF8) : Colors.white24, size: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPill(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1E3C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1B3B68)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 10),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 7.5, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2648),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1F4378)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllExamsModal(List<Map<String, dynamic>> exams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071326),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Target Exam', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: Color(0xFF1E3A68)),
              ...exams.map((e) {
                final isSelected = e['name'] == _selectedExam;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (e['color'] as Color).withValues(alpha: 0.2),
                    child: Text(e['abbr'] as String, style: TextStyle(color: e['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    e['name'] as String,
                    style: TextStyle(color: isSelected ? const Color(0xFF38BDF8) : Colors.white, fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal),
                  ),
                  subtitle: Text(e['sub'] as String, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF38BDF8)) : null,
                  onTap: () {
                    setState(() => _selectedExam = e['name'] as String);
                    Provider.of<UserProvider>(context, listen: false).updateTargetExam(_selectedExam);
                    Navigator.pop(context);
                    _showSnack('Active target exam updated to $_selectedExam!');
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillTag(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1E3C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF1A3D6E)),
        ),
        child: Text(title, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ==========================================
  // 02. MY PURCHASED BATCHES (Page 2) - Dynamic Firebase
  // ==========================================
  Widget _buildSection02PurchasedBatches() {
    return _buildSectionShell(
      sectionNumber: '02',
      sectionTag: 'MY PURCHASED BATCHES',
      sectionIcon: Icons.school_rounded,
      subtitle: 'Your active batches and learning progress',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserPurchasesStream(),
        builder: (context, purchasesSnap) {
          return StreamBuilder<List<CourseModel>>(
            stream: FirestoreService().getBatchesStream(),
            builder: (context, batchesSnap) {
              if (purchasesSnap.connectionState == ConnectionState.waiting && !purchasesSnap.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Color(0xFF0070F3)),
                  ),
                );
              }

              final purchases = purchasesSnap.data ?? [];
              final allBatches = batchesSnap.data ?? [];
              final enrolledBatches = allBatches
                  .where((b) => _isCourseEnrolled(b, purchases))
                  .toList();

              if (enrolledBatches.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081834),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1B3A68)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, size: 36, color: Color(0xFF38BDF8)),
                      const SizedBox(height: 8),
                      const Text(
                        'No Enrolled Batches Yet',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Browse available batches below and start your preparation with live classes & mock tests.',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _scrollToKey(_section08Key),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0070F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Explore Batches >', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: enrolledBatches.map((batch) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D254C), Color(0xFF081834)]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF20487E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0070F3).withValues(alpha: 0.2),
                                border: Border.all(color: const Color(0xFF0070F3)),
                              ),
                              child: Center(
                                child: Text(
                                  batch.examCategory.length > 3 ? batch.examCategory.substring(0, 3).toUpperCase() : 'BATCH',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('ENROLLED', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(batch.examCategory, style: const TextStyle(color: Colors.white54, fontSize: 8.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(batch.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                                  if (batch.shortDescription.isNotEmpty)
                                    Text(batch.shortDescription, style: const TextStyle(color: Colors.white54, fontSize: 8), maxLines: 1),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BatchDetailsScreen(batch: batch),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF38BDF8),
                                side: const BorderSide(color: Color(0xFF38BDF8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('Details >', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildPillTag('📁 ${batch.resourceIds.length} Resources', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BatchDetailsScreen(batch: batch),
                                ),
                              );
                            }),
                            _buildPillTag('📝 ${batch.testSeriesIds.length} Test Series', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BatchDetailsScreen(batch: batch),
                                ),
                              );
                            }),
                            _buildPillTag('🎥 Live Classes', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LiveClassesScreen(batchTitle: batch.title),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // 03. RECOMMENDED FOR YOU (Page 3) - Dynamic Firebase
  // ==========================================
  Widget _buildSection03Recommended() {
    return _buildSectionShell(
      sectionNumber: '03',
      sectionTag: 'RECOMMENDED FOR YOU',
      sectionIcon: Icons.thumb_up_alt_rounded,
      subtitle: 'Handpicked for your goal',
      child: StreamBuilder<List<CourseModel>>(
        stream: FirestoreService().getBatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF0070F3)),
              ),
            );
          }

          final batches = snapshot.data ?? [];
          if (batches.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF081C38),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1B3A68)),
              ),
              child: const Center(
                child: Text(
                  'No batches currently created in Firestore.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            );
          }

          final recommendedBatch = batches.firstWhere(
            (b) => b.examCategory.toLowerCase() == _selectedExam.toLowerCase(),
            orElse: () => batches.first,
          );

          final otherBatches = batches.where((b) => b.id != recommendedBatch.id).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recommended for Your Success ⭐', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('Based on ${recommendedBatch.examCategory} and preparation goals.', style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
              const SizedBox(height: 12),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BatchDetailsScreen(batch: recommendedBatch),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0E2750), Color(0xFF071833)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF224E8C), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                            child: const Text('🔥 FEATURED BATCH', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900)),
                          ),
                          if (recommendedBatch.originalPrice > recommendedBatch.price)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '${(((recommendedBatch.originalPrice - recommendedBatch.price) / recommendedBatch.originalPrice) * 100).round()}% OFF',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(recommendedBatch.examCategory, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold)),
                      Text(recommendedBatch.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      if (recommendedBatch.description.isNotEmpty)
                        Text(recommendedBatch.description, style: const TextStyle(color: Colors.white70, fontSize: 9.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(child: _MetricBadge('${recommendedBatch.resourceIds.length} Resources', Icons.folder_outlined)),
                          const SizedBox(width: 4),
                          Expanded(child: _MetricBadge('${recommendedBatch.testSeriesIds.length} Tests', Icons.assignment_outlined)),
                          const SizedBox(width: 4),
                          Expanded(child: _MetricBadge(recommendedBatch.validity, Icons.event_available_outlined)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('₹${recommendedBatch.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                              if (recommendedBatch.originalPrice > recommendedBatch.price) ...[
                                const SizedBox(width: 6),
                                Text('₹${recommendedBatch.originalPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white38, fontSize: 11, decoration: TextDecoration.lineThrough)),
                              ],
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BatchDetailsScreen(batch: recommendedBatch),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0070F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Batch Details >', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (otherBatches.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('More Top Batches For You', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: otherBatches.length,
                    itemBuilder: (context, index) {
                      final b = otherBatches[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BatchDetailsScreen(batch: b),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF091C38),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B3A68)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(b.examCategory, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.bold), maxLines: 1),
                              Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₹${b.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 10),
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
          );
        },
      ),
    );
  }

  // 04. ALL BATCHES FOR JEE MAIN 2027 (Page 4)
  // ==========================================
  Widget _buildSection04AllBatches() {
    final filters = ['All Batches', 'Full Preparation', 'Crash Course', 'Subject Wise'];



    return StreamBuilder<List<CourseModel>>(
      stream: _coursesStream,
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        final totalBatches = courses.length;
        final totalTests = courses.fold<int>(0, (sum, c) => sum + c.testSeriesIds.length);
        final totalResources = courses.fold<int>(0, (sum, c) => sum + c.resourceIds.length);

        List<CourseModel> displayCourses = courses;
        if (_activeBatchFilter == 1) {
          final filtered = courses.where((c) => !c.title.toLowerCase().contains('crash')).toList();
          if (filtered.isNotEmpty) displayCourses = filtered;
        } else if (_activeBatchFilter == 2) {
          final filtered = courses.where((c) => c.title.toLowerCase().contains('crash') || c.validity.contains('30') || c.validity.contains('Days')).toList();
          if (filtered.isNotEmpty) displayCourses = filtered;
        } else if (_activeBatchFilter == 3) {
          final filtered = courses.where((c) {
            final t = c.title.toLowerCase();
            return t.contains('physic') || t.contains('chem') || t.contains('math') || t.contains('bio');
          }).toList();
          if (filtered.isNotEmpty) displayCourses = filtered;
        }

        return _buildSectionShell(
          sectionNumber: '04',
          sectionTag: 'ALL BATCHES FOR ${_selectedExam.toUpperCase()}',
          sectionIcon: Icons.view_list_rounded,
          subtitle: 'Quality batches. Better preparation.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose the Right Batch for Your Journey 🎯', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              const Text('Explore expert-designed batches and find the perfect match for your goals.', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
              const SizedBox(height: 10),

              // 4 Dynamic Feature pillars
              Row(
                children: [
                  Expanded(child: _MiniPillar('$totalBatches', 'Batches', Icons.school_outlined)),
                  const SizedBox(width: 4),
                  Expanded(child: _MiniPillar(totalTests > 0 ? '$totalTests' : 'Full', 'Mock Tests', Icons.quiz_outlined)),
                  const SizedBox(width: 4),
                  Expanded(child: _MiniPillar(totalResources > 0 ? '$totalResources' : 'Full', 'Resources', Icons.folder_special_outlined)),
                  const SizedBox(width: 4),
                  const Expanded(child: _MiniPillar('Live+Rec', 'Classes', Icons.videocam_outlined)),
                ],
              ),
              const SizedBox(height: 10),

              // Filter bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.asMap().entries.map((e) {
                    final isSel = e.key == _activeBatchFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _activeBatchFilter = e.key),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF0070F3) : const Color(0xFF0A1E3C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? const Color(0xFF0070F3) : const Color(0xFF1E3A68)),
                        ),
                        child: Text(
                          e.value,
                          style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 9, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Help me choose recommendation card
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1E3C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E4072)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined, color: Color(0xFF38BDF8), size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Not sure which batch is best for you?', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          Text('Answer 3 quick questions for instant recommendation.', style: TextStyle(color: Colors.white54, fontSize: 7.5)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _scrollToKey(_section08Key),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Help Me Choose >', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (displayCourses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C2040),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1F4378)),
                  ),
                  child: const Center(
                    child: Text(
                      'No batches currently available in Firestore.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                )
              else
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getUserPurchasesStream(),
                  builder: (context, purchaseSnap) {
                    final purchases = purchaseSnap.data ?? [];

                    return Column(
                      children: displayCourses.map((course) {
                      final isEnrolled = _isCourseEnrolled(course, purchases);
                      final batchTitle = course.title;
                      final batchPrice = course.price.toInt();
                      const Color tagColor = Color(0xFF38BDF8);
                      const IconData tagIcon = Icons.stars_rounded;
                      final int discountPercent = course.originalPrice > course.price && course.originalPrice > 0
                          ? (((course.originalPrice - course.price) / course.originalPrice) * 100).round()
                          : 0;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BatchDetailsScreen(batch: course),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C2040), Color(0xFF071428)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1F4378), width: 1.2),
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
                              // Top Row: Tag badge + Discount pill + Menu (Edit / Delete / Details)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tagColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: tagColor.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(tagIcon, color: tagColor, size: 10),
                                        const SizedBox(width: 4),
                                        Text(
                                          course.examCategory.isNotEmpty ? course.examCategory : 'FEATURED BATCH',
                                          style: const TextStyle(
                                            color: tagColor,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (discountPercent > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '$discountPercent% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white60, size: 18),
                                    color: const Color(0xFF091C38),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'details',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF38BDF8)),
                                            SizedBox(width: 8),
                                            Text('Batch Details', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 16, color: Colors.amber),
                                            SizedBox(width: 8),
                                            Text('Edit Batch', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                            SizedBox(width: 8),
                                            Text('Delete Batch', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'details') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BatchDetailsScreen(batch: course),
                                          ),
                                        );
                                      } else if (val == 'edit') {
                                        CreateEditBatchSheet.show(context, existingBatch: course);
                                      } else if (val == 'delete') {
                                        _confirmDeleteBatch(course);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Title
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Subtitle / Instructor
                              Row(
                                children: [
                                  const Icon(Icons.school_rounded, color: tagColor, size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      course.instructorName.isNotEmpty ? course.instructorName : 'Examinant Expert Faculty',
                                      style: const TextStyle(
                                        color: tagColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Description
                              if (course.shortDescription.isNotEmpty || course.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    course.shortDescription.isNotEmpty ? course.shortDescription : course.description,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.35),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 4),

                              // Key Specs & Attached Counts as Chip Badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildSpecChip('📁 ${course.resourceIds.length} Resources'),
                                  _buildSpecChip('📝 ${course.testSeriesIds.length} Test Series'),
                                  _buildSpecChip('Live + Recorded'),
                                  _buildSpecChip(course.validity),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Divider(color: Colors.white.withValues(alpha: 0.08), height: 16),

                              // Bottom Row: Price + Actions CTA
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '₹${course.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          if (course.originalPrice > course.price) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              '₹${course.originalPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (course.originalPrice > course.price) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Save ₹${(course.originalPrice - course.price).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BatchDetailsScreen(batch: course),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF38BDF8),
                                          side: const BorderSide(color: Color(0xFF224E8C)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Details >', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      if (isEnrolled)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => BatchDetailsScreen(batch: course),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                                          label: const Text(
                                            'ENROLLED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        )
                                      else
                                        ElevatedButton.icon(
                                          onPressed: () => _openBatchCheckout(batchTitle, batchPrice, batchId: course.id),
                                          icon: const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                                          label: Text(
                                            'Enroll Now (₹${course.price.toStringAsFixed(0)})',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0070F3),
                                            foregroundColor: Colors.white,
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  // ==========================================
  // 06. OTHER EXAMS (Page 6)
  // ==========================================
  Widget _buildSection06OtherExams() {
    final otherExams = [
      {'name': 'NEET UG 2027', 'sub': 'Medical Entrance Exam', 'abbr': 'NEET', 'color': const Color(0xFF10B981), 'icon': Icons.medical_services_rounded},
      {'name': 'CUET UG 2027', 'sub': 'University Entrance', 'abbr': 'CUET', 'color': const Color(0xFFA855F7), 'icon': Icons.school_rounded},
      {'name': 'GATE 2027', 'sub': 'Engineering Entrance', 'abbr': 'GATE', 'color': const Color(0xFFF59E0B), 'icon': Icons.engineering_rounded},
      {'name': 'SSC CGL 2027', 'sub': 'Government Jobs', 'abbr': 'SSC', 'color': const Color(0xFF0070F3), 'icon': Icons.account_balance_rounded},
      {'name': 'DEFENCE', 'sub': 'NDA, CDS & More', 'abbr': 'DEFENCE', 'color': const Color(0xFF22C55E), 'icon': Icons.shield_rounded},
      {'name': 'STATE EXAMS', 'sub': 'State Government Jobs', 'abbr': 'STATE', 'color': const Color(0xFFEC4899), 'icon': Icons.public_rounded},
    ];

    return _buildSectionShell(
      sectionNumber: '06',
      sectionTag: 'OTHER EXAMS',
      sectionIcon: Icons.category_rounded,
      subtitle: 'One Platform. Many Possibilities.',
      child: StreamBuilder<List<CourseModel>>(
        stream: _coursesStream,
        builder: (context, snap) {
          final courses = snap.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prepare for Other Exams 🌐', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Explore batches for top competitive exams.', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                    ],
                  ),
                  InkWell(
                    onTap: () => _scrollToKey(_section07Key),
                    child: const Text('View Offers >', style: TextStyle(color: Colors.orange, fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6 Exam Cards Grid with Dynamic Counts
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: otherExams.length,
                itemBuilder: (context, index) {
                  final e = otherExams[index];
                  final Color itemColor = e['color'] as Color;
                  final examName = (e['name'] as String).toLowerCase();
                  final abbr = (e['abbr'] as String).toLowerCase();

                  final matching = courses.where((c) {
                    final cat = c.examCategory.toLowerCase();
                    return cat.contains(abbr) || cat.contains(examName);
                  }).toList();

                  final bCount = matching.length;
                  final tCount = matching.fold<int>(0, (s, b) => s + b.testSeriesIds.length);
                  final rCount = matching.fold<int>(0, (s, b) => s + b.resourceIds.length);

                  final dynamicStat = bCount > 0
                      ? '$bCount ${bCount == 1 ? 'Batch' : 'Batches'} • ${tCount > 0 ? '$tCount Tests' : '$rCount Resources'}'
                      : 'Live Syllabus & Prep';

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081C38),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A3966)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: itemColor.withValues(alpha: 0.2),
                              child: Icon(e['icon'] as IconData, color: itemColor, size: 12),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _selectedExam = e['name'] as String);
                                _showSnack('Switched target exam to ${e['name']}');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: Text('Explore >', style: TextStyle(color: itemColor, fontSize: 7.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        Text(e['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                        Text(e['sub'] as String, style: const TextStyle(color: Colors.white54, fontSize: 7.5), maxLines: 1),
                        Text(dynamicStat, style: const TextStyle(color: Colors.white38, fontSize: 7), maxLines: 1),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Your Goal, Our Guidance bar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1E3C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1B3B69)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniTag('Expert Faculty', Icons.school),
                    _MiniTag('Smart Prep', Icons.psychology),
                    _MiniTag('Proven Results', Icons.star),
                    _MiniTag('24x7 Doubts', Icons.support_agent),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 07. SPECIAL OFFERS (Page 7)
  // ==========================================
  Widget _buildSection07SpecialOffers() {
    return _buildSectionShell(
      sectionNumber: '07',
      sectionTag: 'SPECIAL OFFERS',
      sectionIcon: Icons.local_offer_rounded,
      subtitle: 'Best Deals. Bigger Savings.',
      borderColor: Colors.amber.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BIG SAVINGS FOR BIG DREAMS! 🎉', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    Text('Unlock premium batches at never-before prices.', style: TextStyle(color: Colors.white54, fontSize: 8.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Countdown Timer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF261805), Color(0xFF140D02)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UP TO 50% OFF', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
                    Text('Offer ends soon!', style: TextStyle(color: Colors.white54, fontSize: 7.5)),
                  ],
                ),
                SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _CountdownTimerWidget(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic Deals Grid from Firestore
          StreamBuilder<List<CourseModel>>(
            stream: _coursesStream,
            builder: (context, snap) {
              final courses = snap.data ?? [];
              final discounted = courses.where((c) => c.originalPrice > c.price).toList();
              final offerCourses = (discounted.isNotEmpty ? discounted : courses).take(4).toList();

              if (offerCourses.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081C38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Check back soon for exclusive batch offers!', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                );
              }

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getUserPurchasesStream(),
                builder: (context, purchaseSnap) {
                  final purchases = purchaseSnap.data ?? [];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: offerCourses.length,
                    itemBuilder: (context, index) {
                      final c = offerCourses[index];
                      final isEnrolled = _isCourseEnrolled(c, purchases);
                      final Color dealColor = index % 2 == 0 ? const Color(0xFF0070F3) : const Color(0xFFA855F7);
                      final hasDiscount = c.originalPrice > c.price;
                      final offText = hasDiscount
                          ? '${(((c.originalPrice - c.price) / c.originalPrice) * 100).round()}% OFF'
                          : 'SPECIAL';
                      final saveText = hasDiscount
                          ? 'Save ₹${(c.originalPrice - c.price).round()}'
                          : 'Top Rated';

                      return InkWell(
                        onTap: () {
                          if (isEnrolled) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BatchDetailsScreen(batch: c)),
                            );
                          } else {
                            _openBatchCheckout(c.title, c.price.round(), batchId: c.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081C38),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1A3866)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isEnrolled ? Colors.green : Colors.redAccent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      isEnrolled ? 'ENROLLED' : offText,
                                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  Text(saveText, style: const TextStyle(color: Color(0xFF10B981), fontSize: 7.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                              Row(
                                children: [
                                  Text('₹${c.price.round()}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                                  if (hasDiscount) ...[
                                    const SizedBox(width: 4),
                                    Text('₹${c.originalPrice.round()}', style: const TextStyle(color: Colors.white38, fontSize: 9, decoration: TextDecoration.lineThrough)),
                                  ],
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isEnrolled) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => BatchDetailsScreen(batch: c)),
                                      );
                                    } else {
                                      _openBatchCheckout(c.title, c.price.round(), batchId: c.id);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEnrolled ? const Color(0xFF10B981) : dealColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: Text(isEnrolled ? 'Open Batch >' : 'Grab Now >', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),

          // Security Trust Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _MiniBadge('Best Price', Icons.verified),
              _MiniBadge('100% Secure', Icons.lock),
              _MiniBadge('14D Refund', Icons.replay),
              _MiniBadge('24x7 Help', Icons.headset_mic),
            ],
          ),
        ],
      ),
    );
  }



  // ==========================================
  // 08. NEED HELP CHOOSING? (Page 8)
  // ==========================================
  Widget _buildSection08NeedHelp() {
    final prepLevels = ['Just Started', '25 - 50%', '50 - 75%', 'Almost Done'];
    final timeSlots = ['3+ Months', '1 - 3 Months', '15 - 30 Days', '< 15 Days'];

    return _buildSectionShell(
      sectionNumber: '08',
      sectionTag: 'NEED HELP CHOOSING?',
      sectionIcon: Icons.help_outline_rounded,
      subtitle: 'We\'re here to guide you!',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Not sure which batch is right for you? 🤔', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Answer 3 quick questions and get an instant AI recommendation.', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
          const SizedBox(height: 12),

          // 3-Step Wizard Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F254B), Color(0xFF071833)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF224E8C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 1: Exam
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF0070F3), shape: BoxShape.circle),
                      child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Which exam are you preparing for?', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0A1E3C), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                    value: _wizardExam,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0A1E3C),
                    underline: const SizedBox(),
                    items: ['JEE Main 2027', 'NEET UG 2027', 'CUET UG 2027', 'GATE 2027', 'SSC CGL 2027', 'Defence']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 11))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _wizardExam = val);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Step 2: Prep Level
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF0070F3), shape: BoxShape.circle),
                      child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Text('What is your current preparation level?', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: prepLevels.asMap().entries.map((e) {
                    final isSel = e.key == _wizardPrepLevel;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _wizardPrepLevel = e.key),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0070F3) : const Color(0xFF0A1E3C),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF1E3D6E)),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Step 3: Time Available
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF0070F3), shape: BoxShape.circle),
                      child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Text('How much time do you have for the exam?', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: timeSlots.asMap().entries.map((e) {
                    final isSel = e.key == _wizardTimeAvailable;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _wizardTimeAvailable = e.key),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0070F3) : const Color(0xFF0A1E3C),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF1E3D6E)),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Get Recommendation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showRecommendationModal,
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Get My Recommendation →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0070F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('✔ 100% Free • No Signup Needed • Instant Result', style: TextStyle(color: Color(0xFF10B981), fontSize: 8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showRecommendationModal() async {
    List<CourseModel> batches = [];
    try {
      batches = await FirestoreService().getBatchesStream().first;
    } catch (_) {}

    final examW = _wizardExam.toLowerCase();
    final prefix = examW.split(' ').first;

    final candidates = batches.where((b) {
      final cat = b.examCategory.toLowerCase();
      return cat.contains(prefix) || cat.contains(examW);
    }).toList();

    CourseModel? recommendedBatch;
    String reason = '';

    if (candidates.isNotEmpty) {
      if (_wizardTimeAvailable >= 2 || _wizardPrepLevel >= 2) {
        recommendedBatch = candidates.firstWhere(
          (b) => b.title.toLowerCase().contains('crash') || b.title.toLowerCase().contains('revision') || b.title.toLowerCase().contains('fast'),
          orElse: () => candidates.first,
        );
        reason = 'Tailored for rapid high-impact preparation and target-focused revision.';
      } else {
        recommendedBatch = candidates.firstWhere(
          (b) => b.title.toLowerCase().contains('conqueror') || b.title.toLowerCase().contains('selection') || b.title.toLowerCase().contains('complete') || b.title.toLowerCase().contains('foundation'),
          orElse: () => candidates.first,
        );
        reason = 'Comprehensive full-length syllabus coverage with live classes and complete test series.';
      }
    } else if (batches.isNotEmpty) {
      recommendedBatch = batches.first;
      reason = 'Premier preparation batch designed by top faculty for maximum score.';
    }

    if (recommendedBatch == null) {
      if (mounted) _showSnack('No batches currently available for $_wizardExam.');
      return;
    }

    final batchToOpen = recommendedBatch;
    final int price = batchToOpen.price.round();
    final isEnrolled = _cachedPurchasedBatchIds.contains(batchToOpen.id) ||
        _cachedPurchasedBatchIds.contains(batchToOpen.title.toLowerCase());

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF091C38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Your AI Recommendation', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Based on your exam ($_wizardExam) and preparation time:', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2750),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batchToOpen.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(reason, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price: ₹$price', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                        if (batchToOpen.validity.isNotEmpty)
                          Text(batchToOpen.validity, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isEnrolled) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BatchDetailsScreen(batch: batchToOpen)),
                  );
                } else {
                  _openBatchCheckout(batchToOpen.title, price, batchId: batchToOpen.id);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: isEnrolled ? const Color(0xFF10B981) : const Color(0xFF0070F3)),
              child: Text(isEnrolled ? 'Open Batch >' : 'Enroll Now >', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openBatchCheckout(String title, int price, {String? batchId}) {
    _lastCheckoutTitle = title;
    _lastCheckoutPrice = price;
    _lastCheckoutBatchId = batchId;

    PaymentService().payAndUnlock(
      context: context,
      itemId: batchId,
      title: title,
      price: price.toDouble(),
      itemType: 'Batch',
      subtitle: 'Comprehensive preparation batch with live classes, mock tests & mentor access',
      onSuccess: () async {
        await _loadCachedPurchases();
        if (mounted) setState(() {});
      },
    );
  }
}

// Helper Widgets
class _MetricBadge extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MetricBadge(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFF0A1E3C), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 10),
          const SizedBox(width: 3),
          Flexible(
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w600), maxLines: 1),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 9),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 7.5)),
      ],
    );
  }
}

class _MiniPillar extends StatelessWidget {
  final String top;
  final String bottom;
  final IconData icon;

  const _MiniPillar(this.top, this.bottom, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF081C38), borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 12),
          const SizedBox(height: 2),
          Text(top, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold), maxLines: 1),
          Text(bottom, style: const TextStyle(color: Colors.white38, fontSize: 6.5), maxLines: 1),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MiniBadge(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 10),
        const SizedBox(width: 3),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 7.5)),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MiniTag(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 11),
        const SizedBox(width: 3),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    );
  }
}

class _CountdownTimerWidget extends StatefulWidget {
  const _CountdownTimerWidget();

  @override
  State<_CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<_CountdownTimerWidget> {
  late Timer _timer;
  Duration _remainingTime = const Duration(days: 2, hours: 15, minutes: 42, seconds: 18);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingTime -= const Duration(seconds: 1);
          });
        }
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remainingTime.inDays.toString().padLeft(2, '0');
    final hrs = (_remainingTime.inHours % 24).toString().padLeft(2, '0');
    final mins = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeBox(days, 'DAYS'),
        const Text(' : ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        _buildTimeBox(hrs, 'HRS'),
        const Text(' : ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        _buildTimeBox(mins, 'MINS'),
        const Text(' : ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        _buildTimeBox(secs, 'SECS'),
      ],
    );
  }

  Widget _buildTimeBox(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF332007), borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(val, style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.amberAccent, fontSize: 5.5)),
        ],
      ),
    );
  }
}
