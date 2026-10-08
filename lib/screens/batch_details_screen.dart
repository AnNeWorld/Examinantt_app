import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../models/test_model.dart';
import '../services/firestore_service.dart';
import '../services/content_service.dart';
import '../services/test_service.dart';
import '../services/payment_service.dart';
import '../utils/app_theme.dart';
import '../widgets/create_edit_batch_sheet.dart';
import 'amazon_live_player_screen.dart';
import 'pdf_viewer_screen.dart';
import 'video_player_screen.dart';
import 'test_series_detail_screen.dart';

/// Complete Batch Screen:
/// 1. UNPURCHASED: Batch Overview & Landing Page with Syllabus, Highlights, and "Enroll Now" CTA.
/// 2. PURCHASED (Enrolled): Complete Classroom Portal with 5 tabs:
///    - 🔴 Live Classes (Real-time live streaming & schedule)
///    - 🎬 Recorded Videos (Complete lecture archives)
///    - 📊 PPTs & Notes (Presentation slide decks & lecture notes)
///    - 📁 Resources & DPPs (Practice sheets & study material)
///    - 📝 Test Series (Mock tests & quizzes)
class BatchDetailsScreen extends StatefulWidget {
  final CourseModel batch;

  const BatchDetailsScreen({super.key, required this.batch});

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentService _contentService = ContentService();
  final TestService _testService = TestService();
  final PaymentService _paymentService = PaymentService();
  final Set<String> _reminders = <String>{};
  bool _forceOverviewView = false; // Enrolled students can toggle to see overview
  Set<String> _cachedPurchasedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCachedPurchases();
    _paymentService.initialize(
      onSuccess: (res) async {
        await FirestoreService().addPurchase(
          id: widget.batch.id,
          itemId: widget.batch.id,
          title: widget.batch.title,
          type: 'Batch',
          price: widget.batch.price,
        );
        await FirestoreService().addNotification(
          title: 'Batch Unlocked! 🎉',
          subtitle: 'You are now enrolled in ${widget.batch.title}',
        );
        await _loadCachedPurchases();
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Successfully enrolled in ${widget.batch.title}!');
        setState(() {
          _forceOverviewView = false;
        });
      },
      onFailure: (res) {
        if (!mounted) return;
        AppTheme.showErrorSnackBar(context, 'Enrollment failed: ${res.message ?? "Transaction Cancelled"}');
      },
      onExternalWallet: (res) {},
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
    _tabController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  bool _isUserEnrolled(List<Map<String, dynamic>> purchases, CourseModel currentBatch) {
    // 0. If batch is free (price == 0), automatically unlocked
    if (currentBatch.price <= 0) return true;

    // 1. Instant local persistent cache check (persists permanently across app reboots/offline)
    final bId = currentBatch.id.trim();
    final bTitle = currentBatch.title.trim().toLowerCase();
    if (bId.isNotEmpty && _cachedPurchasedIds.contains(bId)) return true;
    if (bTitle.isNotEmpty && _cachedPurchasedIds.contains(bTitle)) return true;

    // 2. Check if current user ID is in batch document's enrolledStudentIds list
    final uid = FirestoreService().effectiveUid ?? '';
    if (uid.isNotEmpty && currentBatch.enrolledStudentIds.contains(uid)) {
      return true;
    }

    // 3. Check Firestore user purchases stream
    return purchases.any((p) {
      final pId = (p['id'] ?? '').toString().trim();
      final pItemId = (p['itemId'] ?? '').toString().trim();
      final pTitle = (p['title'] ?? '').toString().trim().toLowerCase();

      if (bId.isNotEmpty && (pId == bId || pItemId == bId)) return true;
      if (bTitle.isNotEmpty && pTitle.isNotEmpty && pTitle == bTitle) return true;
      return false;
    });
  }

  bool _matchesBatch(LiveClass c, CourseModel batch) {
    if (c.batchId.isNotEmpty &&
        (c.batchId == batch.id || c.batchId.toLowerCase() == batch.id.toLowerCase())) {
      return true;
    }
    if (batch.liveClassIds.contains(c.id)) {
      return true;
    }
    if (c.batchName.isNotEmpty &&
        (c.batchName.toLowerCase() == batch.title.toLowerCase() ||
            batch.title.toLowerCase().contains(c.batchName.toLowerCase()) ||
            c.batchName.toLowerCase().contains(batch.title.toLowerCase()))) {
      return true;
    }
    if (batch.examCategory.isNotEmpty && c.examCategory.isNotEmpty) {
      final bCat = batch.examCategory.toLowerCase().trim();
      final cCat = c.examCategory.toLowerCase().trim();
      if (bCat == cCat || bCat.contains(cCat) || cCat.contains(bCat)) {
        return true;
      }
    }
    return false;
  }

  void _openLivePlayer(LiveClass c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmazonLivePlayerScreen(liveClass: c),
      ),
    );
  }

  void _openVideoPlayer(LiveClass c) {
    final playUrl = c.recordingUrl.isNotEmpty
        ? c.recordingUrl
        : (c.videoUrl.isNotEmpty ? c.videoUrl : '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          title: c.title,
          instructor: c.instructor,
          videoUrl: playUrl,
          isLive: false,
        ),
      ),
    );
  }

  void _openPdfNotes(String title, String subject, String url) {
    if (url.trim().isEmpty) {
      AppTheme.showWarningSnackBar(context, 'PPT / Notes will be available shortly for this lecture.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfData: ResourceItem(
            id: 'ppt_${DateTime.now().millisecondsSinceEpoch}',
            title: '$title - Class PPT & Notes',
            subtitle: '$subject • Presentation Slide Deck',
            category: subject,
            subject: subject,
            type: 'PPT',
            fileType: 'PDF / PPT',
            fileSize: '4.8 MB',
            badge: 'BATCH PPT',
            badgeColorHex: '#38BDF8',
            downloads: '1.2k',
            rating: 4.9,
            exam: widget.batch.examCategory,
            price: 0.0,
            isPublic: true,
            description: 'Faculty classroom presentation slides and annotated lecture notes.',
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
        AppTheme.showSuccessSnackBar(context, '🔔 Reminder set! You will be alerted before $title starts.');
      }
    });
  }

  void _showWaitingRoom(LiveClass c, bool isDark, Color cardBg, Color textColor, Color subTextColor, Color borderColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('UPCOMING BATCH CLASS', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.title,
                style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'By ${c.instructor} • Scheduled: ${c.time}',
                style: TextStyle(color: subTextColor, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF030E1F) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class will stream live in this batch', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Live stream with real-time doubts clearance on Amazon AWS infrastructure.', style: TextStyle(color: subTextColor, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleReminder(c.id, c.title);
                  },
                  icon: Icon(_reminders.contains(c.id) ? Icons.notifications_active : Icons.notifications_none_rounded),
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

  void _showDeleteConfirmation(CourseModel batch) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0C2040) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Batch?',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.darkSlate,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${batch.title}"? Resources, live classes, and tests attached to this batch will remain available in the system.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deleteBatch(batch.id);
                if (!mounted) return;
                Navigator.pop(context);
                AppTheme.showSuccessSnackBar(context, 'Batch "${batch.title}" deleted successfully.');
              } catch (e) {
                if (!mounted) return;
                AppTheme.showErrorSnackBar(context, 'Failed to delete batch: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF020B18) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF071938) : Colors.white;
    final subCardBg = isDark ? const Color(0xFF041228) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF152E54) : Colors.grey.shade200;

    return StreamBuilder<List<CourseModel>>(
      stream: FirestoreService().getBatchesStream(),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        final currentBatch = batches.firstWhere(
          (b) => b.id == widget.batch.id,
          orElse: () => widget.batch,
        );

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getUserPurchasesStream(),
          builder: (context, purchaseSnap) {
            final purchases = purchaseSnap.data ?? [];
            final isPurchased = _isUserEnrolled(purchases, currentBatch);

            return StreamBuilder<List<LiveClass>>(
              stream: _contentService.getLiveClasses(),
              builder: (context, classSnap) {
                final allClasses = classSnap.data ?? [];
                final batchClasses = allClasses.where((c) => _matchesBatch(c, currentBatch)).toList();

                final liveNowClasses = batchClasses.where((c) => c.isLive).toList();
                final upcomingClasses = batchClasses.where((c) => c.isUpcoming).toList();
                final recordedClasses = batchClasses.where((c) => c.isRecorded).toList();

                // If NOT purchased, OR if enrolled user explicitly clicked "About Batch"
                if (!isPurchased || _forceOverviewView) {
                  return _buildBatchLandingPage(
                    currentBatch: currentBatch,
                    isPurchased: isPurchased,
                    batchClassesCount: batchClasses.length,
                    liveNowCount: liveNowClasses.length,
                    recordedCount: recordedClasses.length,
                    isDark: isDark,
                    scaffoldBg: scaffoldBg,
                    cardBg: cardBg,
                    subCardBg: subCardBg,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                  );
                }

                // IF PURCHASED: SHOW COMPLETE BATCH CLASSROOM (THE 5 TABS)
                return _buildBatchClassroomPage(
                  currentBatch: currentBatch,
                  batchClasses: batchClasses,
                  liveNowClasses: liveNowClasses,
                  upcomingClasses: upcomingClasses,
                  recordedClasses: recordedClasses,
                  isDark: isDark,
                  scaffoldBg: scaffoldBg,
                  cardBg: cardBg,
                  subCardBg: subCardBg,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                );
              },
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 1. UNPURCHASED: BATCH LANDING & PURCHASE PAGE (WHAT USER SEES BEFORE BUYING)
  // ===========================================================================
  Widget _buildBatchLandingPage({
    required CourseModel currentBatch,
    required bool isPurchased,
    required int batchClassesCount,
    required int liveNowCount,
    required int recordedCount,
    required bool isDark,
    required Color scaffoldBg,
    required Color cardBg,
    required Color subCardBg,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    final double discount = currentBatch.originalPrice > currentBatch.price && currentBatch.originalPrice > 0
        ? (((currentBatch.originalPrice - currentBatch.price) / currentBatch.originalPrice) * 100).roundToDouble()
        : 60.0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06142A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentBatch.title,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w900),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (isPurchased)
            TextButton.icon(
              onPressed: () => setState(() => _forceOverviewView = false),
              icon: const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 16),
              label: const Text('Open Classroom', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: const Color(0xFF0070F3),
              tooltip: 'Edit Batch',
              onPressed: () => CreateEditBatchSheet.show(context, existingBatch: currentBatch),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: Colors.redAccent,
              tooltip: 'Delete Batch',
              onPressed: () => _showDeleteConfirmation(currentBatch),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0C2448), const Color(0xFF071938)]
                      : [Colors.white, const Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF0070F3).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          currentBatch.examCategory.isNotEmpty ? currentBatch.examCategory.toUpperCase() : 'ALL EXAMS',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ADMISSION OPEN 2027', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w900)),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(currentBatch.validity, style: const TextStyle(color: Colors.orange, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentBatch.title,
                    style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentBatch.shortDescription.isNotEmpty ? currentBatch.shortDescription : currentBatch.description,
                    style: TextStyle(color: subTextColor, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Real Batch Stats & Verification
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Official Curriculum',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                        ],
                      ),
                      if (currentBatch.enrolledStudentIds.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        Row(
                          children: [
                            const Icon(Icons.group_rounded, color: Color(0xFF38BDF8), size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${currentBatch.enrolledStudentIds.length} Enrolled',
                              style: TextStyle(color: subTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Master Faculty Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0070F3).withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBatch.instructorName.isNotEmpty ? currentBatch.instructorName : 'Senior Master Faculty',
                          style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentBatch.instructorTitle.isNotEmpty ? currentBatch.instructorTitle : 'Examinant Master Faculty',
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        const Text('Top 1% Educator • Proven Selection Track Record', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: What this batch includes (Features)
            Text(
              'WHAT YOU GET IN THIS BATCH',
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            _buildFeatureTile(
              icon: Icons.live_tv_rounded,
              iconColor: Colors.redAccent,
              title: 'Interactive Live Classes',
              subtitle: 'Daily live streaming sessions on Amazon AWS IVS with instant chat doubt resolution.',
              cardBg: cardBg,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            _buildFeatureTile(
              icon: Icons.video_library_rounded,
              iconColor: const Color(0xFF38BDF8),
              title: 'Full Recorded Lectures Archive',
              subtitle: 'Missed a live class? Watch high-definition recordings anytime with speed controls.',
              cardBg: cardBg,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            _buildFeatureTile(
              icon: Icons.slideshow_rounded,
              iconColor: Colors.orange,
              title: 'Presentation Slide Decks & PPT Notes',
              subtitle: 'Faculty PowerPoint presentations and annotated classroom slide notes for 1-tap reading.',
              cardBg: cardBg,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            _buildFeatureTile(
              icon: Icons.folder_special_outlined,
              iconColor: const Color(0xFF10B981),
              title: 'DPPs, Worksheets & Formula Booklets',
              subtitle: '${currentBatch.resourceIds.length} downloadable practice problem sheets and revision notes.',
              cardBg: cardBg,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            _buildFeatureTile(
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFFA855F7),
              title: 'Mock Test Series & Chapter Quizzes',
              subtitle: '${currentBatch.testSeriesIds.length} exam-pattern mock tests with in-depth analytics.',
              cardBg: cardBg,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),

            // Locked Classroom Content Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFFFFA000), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Batch Classroom is Currently Locked',
                          style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Enroll in this batch to unlock real-time live classes, recorded lecture videos, PPT presentation slides, DPPs, and mock tests.',
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Purchase Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF06142A) : Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${currentBatch.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (currentBatch.originalPrice > currentBatch.price)
                        Text(
                          '₹${currentBatch.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SAVE ${discount.toStringAsFixed(0)}% TODAY',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      PaymentService().payAndUnlock(
                        context: context,
                        itemId: currentBatch.id,
                        title: currentBatch.title,
                        price: currentBatch.price,
                        itemType: 'Batch',
                        subtitle: 'Full batch access with Live Classes, Recordings, PPTs & Tests',
                        onSuccess: () async {
                          await _loadCachedPurchases();
                          if (mounted) {
                            setState(() {
                              _forceOverviewView = false;
                            });
                          }
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0070F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'ENROLL NOW',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PURCHASED: FULL BATCH CLASSROOM (THE 5 TABS: LIVE, RECORDED, PPT, ETC.)
  // ===========================================================================
  Widget _buildBatchClassroomPage({
    required CourseModel currentBatch,
    required List<LiveClass> batchClasses,
    required List<LiveClass> liveNowClasses,
    required List<LiveClass> upcomingClasses,
    required List<LiveClass> recordedClasses,
    required bool isDark,
    required Color scaffoldBg,
    required Color cardBg,
    required Color subCardBg,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06142A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentBatch.title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            color: const Color(0xFF38BDF8),
            tooltip: 'View Batch Overview & Syllabus',
            onPressed: () => setState(() => _forceOverviewView = true),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: const Color(0xFF0070F3),
            tooltip: 'Edit Batch',
            onPressed: () => CreateEditBatchSheet.show(context, existingBatch: currentBatch),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: Colors.redAccent,
            tooltip: 'Delete Batch',
            onPressed: () => _showDeleteConfirmation(currentBatch),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enrolled Hero Header
          _buildEnrolledHeader(currentBatch, isDark, cardBg, textColor, subTextColor, borderColor),

          // If a class in this batch is LIVE right now, show prominent Glowing Banner
          if (liveNowClasses.isNotEmpty)
            _buildLiveNowBanner(liveNowClasses.first, isDark, textColor, subTextColor),

          // 5 Comprehensive Tabs for this Batch
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF06142A) : Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF0070F3),
              unselectedLabelColor: subTextColor,
              indicatorColor: const Color(0xFF0070F3),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: liveNowClasses.isNotEmpty ? Colors.redAccent : const Color(0xFF0070F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Live Classes (${liveNowClasses.length + upcomingClasses.length})'),
                    ],
                  ),
                ),
                Tab(
                  icon: const Icon(Icons.video_library_rounded, size: 16),
                  text: 'Recorded Videos (${recordedClasses.length})',
                ),
                const Tab(
                  icon: Icon(Icons.slideshow_rounded, size: 16),
                  text: 'PPTs & Notes',
                ),
                Tab(
                  icon: const Icon(Icons.folder_special_outlined, size: 16),
                  text: 'Resources (${currentBatch.resourceIds.length})',
                ),
                Tab(
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  text: 'Test Series (${currentBatch.testSeriesIds.length})',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: LIVE CLASSES (Live Now & Upcoming)
                _buildLiveClassesTab(
                  currentBatch,
                  liveNowClasses,
                  upcomingClasses,
                  isDark,
                  cardBg,
                  subCardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),

                // TAB 2: RECORDED VIDEOS (Previous lectures & replays)
                _buildRecordedVideosTab(
                  currentBatch,
                  recordedClasses,
                  isDark,
                  cardBg,
                  subCardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),

                // TAB 3: PPTS & CLASS NOTES (Presentation slide decks & notes)
                _buildPptAndNotesTab(
                  currentBatch,
                  batchClasses,
                  isDark,
                  cardBg,
                  subCardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),

                // TAB 4: RESOURCES & DPPS
                _buildResourcesTab(
                  currentBatch,
                  isDark,
                  cardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),

                // TAB 5: TEST SERIES
                _buildTestSeriesTab(
                  currentBatch,
                  isDark,
                  cardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enrolled Header Widget
  Widget _buildEnrolledHeader(
    CourseModel batch,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ENROLLED BATCH ✓',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      batch.validity,
                      style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  batch.title,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(() => _forceOverviewView = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF38BDF8)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Overview', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- TOP LIVE ALERT BANNER (WHEN CLASS IS RUNNING LIVE IN THIS BATCH) ---
  Widget _buildLiveNowBanner(
    LiveClass liveClass,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: isDark ? 0.7 : 0.85),
            const Color(0xFFB91C1C),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE IN PROGRESS IN THIS BATCH',
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${liveClass.activeViewers} Watching',
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  liveClass.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${liveClass.subject} • Faculty: ${liveClass.instructor}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openLivePlayer(liveClass),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Join Stream', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: LIVE CLASSES TAB (LIVE NOW + UPCOMING SESSIONS) ---
  Widget _buildLiveClassesTab(
    CourseModel batch,
    List<LiveClass> liveNowClasses,
    List<LiveClass> upcomingClasses,
    bool isDark,
    Color cardBg,
    Color subCardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final combined = [...liveNowClasses, ...upcomingClasses];

    if (combined.isEmpty) {
      return _buildEmptyState(
        icon: Icons.live_tv_rounded,
        title: 'No Live Classes Right Now',
        message: 'Upcoming live sessions for ${batch.title} will be scheduled and streamed live here.',
        actionLabel: null,
        onAction: null,
        isDark: isDark,
        textColor: textColor,
        subTextColor: subTextColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final c = combined[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.isLive
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (c.isLive) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('LIVE NOW', style: TextStyle(color: Colors.red, fontSize: 9.5, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          Text('• ${c.activeViewers} Watching', style: TextStyle(color: subTextColor, fontSize: 9)),
                        ] else ...[
                          const Icon(Icons.schedule_rounded, color: Colors.orange, size: 12),
                          const SizedBox(width: 4),
                          const Text('UPCOMING LIVE', style: TextStyle(color: Colors.orange, fontSize: 9.5, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          Text('• ${c.time}', style: TextStyle(color: subTextColor, fontSize: 9.5)),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.subject,
                        style: TextStyle(color: c.color, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (c.chapter.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        c.chapter,
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Faculty & Action Buttons Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: c.color.withValues(alpha: 0.2),
                          child: Text(
                            c.instructor.isNotEmpty ? c.instructor[0] : 'T',
                            style: TextStyle(color: c.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c.instructor,
                            style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Secondary Action: Class PPT / Notes button
                        if (c.notesUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: OutlinedButton.icon(
                              onPressed: () => _openPdfNotes(c.title, c.subject, c.notesUrl),
                              icon: const Icon(Icons.slideshow_rounded, size: 12),
                              label: const Text('PPT Notes', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF38BDF8),
                                side: const BorderSide(color: Color(0xFF38BDF8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),

                        // Primary Action Button
                        ElevatedButton.icon(
                          onPressed: () {
                            if (c.isLive) {
                              _openLivePlayer(c);
                            } else {
                              _showWaitingRoom(c, isDark, cardBg, textColor, subTextColor, borderColor);
                            }
                          },
                          icon: Icon(
                            c.isLive ? Icons.sensors_rounded : (_reminders.contains(c.id) ? Icons.notifications_active : Icons.notifications_none_rounded),
                            size: 13,
                          ),
                          label: Text(
                            c.isLive ? 'Join Stream' : (_reminders.contains(c.id) ? 'Reminder Set' : 'Set Reminder'),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.isLive ? Colors.red : const Color(0xFF0070F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
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

  // --- TAB 2: RECORDED VIDEOS / CLASSES TAB ---
  Widget _buildRecordedVideosTab(
    CourseModel batch,
    List<LiveClass> recordedClasses,
    bool isDark,
    Color cardBg,
    Color subCardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    if (recordedClasses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_rounded,
        title: 'No Recorded Classes Yet',
        message: 'Completed live lecture recordings for ${batch.title} will be stored and indexed here.',
        actionLabel: null,
        onAction: null,
        isDark: isDark,
        textColor: textColor,
        subTextColor: subTextColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: recordedClasses.length,
      itemBuilder: (context, index) {
        final c = recordedClasses[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF38BDF8), size: 13),
                        const SizedBox(width: 4),
                        const Text(
                          'RECORDED VIDEO LECTURE',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        Text('• ${c.durationMinutes} mins', style: TextStyle(color: subTextColor, fontSize: 9)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.subject,
                        style: TextStyle(color: c.color, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (c.chapter.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        c.chapter,
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Faculty & Action Buttons Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: c.color.withValues(alpha: 0.2),
                          child: Text(
                            c.instructor.isNotEmpty ? c.instructor[0] : 'T',
                            style: TextStyle(color: c.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c.instructor,
                            style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Secondary Action: View PPT / Notes
                        if (c.notesUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: OutlinedButton.icon(
                              onPressed: () => _openPdfNotes(c.title, c.subject, c.notesUrl),
                              icon: const Icon(Icons.slideshow_rounded, size: 12),
                              label: const Text('PPT Slides', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10B981),
                                side: const BorderSide(color: Color(0xFF10B981)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),

                        // Primary Action: Watch Video
                        ElevatedButton.icon(
                          onPressed: () => _openVideoPlayer(c),
                          icon: const Icon(Icons.play_arrow_rounded, size: 14),
                          label: const Text('Watch Lecture', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0070F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
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

  // --- TAB 3: PPTS & CLASS NOTES TAB ---
  Widget _buildPptAndNotesTab(
    CourseModel batch,
    List<LiveClass> batchClasses,
    bool isDark,
    Color cardBg,
    Color subCardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return StreamBuilder<List<ResourceItem>>(
      stream: FirestoreService().getResourcesStream(),
      builder: (context, snapshot) {
        final allResources = snapshot.data ?? [];
        final batchResources = allResources.where((r) {
          return r.batchIds.contains(batch.id) || batch.resourceIds.contains(r.id);
        }).toList();

        // Collect PPTs from live/recorded classes that have notesUrl:
        final classPpts = batchClasses.where((c) => c.notesUrl.trim().isNotEmpty).toList();

        // Also collect resources with type PPT / Notes / Slides
        final resourcePpts = batchResources.where((r) {
          final t = r.type.toLowerCase();
          final ft = r.fileType.toLowerCase();
          final tit = r.title.toLowerCase();
          return t.contains('ppt') ||
              t.contains('slide') ||
              t.contains('notes') ||
              ft.contains('ppt') ||
              tit.contains('ppt') ||
              tit.contains('slide');
        }).toList();

        if (classPpts.isEmpty && resourcePpts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.slideshow_rounded,
            title: 'No PPTs or Slides in this Batch Yet',
            message: 'Classroom PPT presentation slides and annotated lecture notes will appear here.',
            actionLabel: null,
            onAction: null,
            isDark: isDark,
            textColor: textColor,
            subTextColor: subTextColor,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Section 1: Class Lecture PPTs (Direct from batch classes)
            if (classPpts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.co_present_rounded, color: Color(0xFF38BDF8), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'CLASS LECTURE PPTS & SLIDES (${classPpts.length})',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ...classPpts.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                        ),
                        child: const Center(
                          child: Icon(Icons.slideshow_rounded, color: Color(0xFF38BDF8), size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: c.color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c.subject,
                                    style: TextStyle(color: c.color, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PPT / SLIDES',
                                    style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${c.title} - Slide Deck',
                              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'By ${c.instructor} • Lecture Handouts & Presentation',
                              style: TextStyle(color: subTextColor, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _openPdfNotes(c.title, c.subject, c.notesUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0070F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Open PPT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded, size: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Section 2: Batch Presentation Resources
            if (resourcePpts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.folder_shared_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'BATCH STUDY SLIDES & HANDOUTS (${resourcePpts.length})',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ...resourcePpts.map((res) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: const Center(
                          child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    res.subject,
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(res.fileSize, style: TextStyle(color: subTextColor, fontSize: 9.5)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              res.title,
                              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (res.subtitle.isNotEmpty)
                              Text(
                                res.subtitle,
                                style: TextStyle(color: subTextColor, fontSize: 10.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          backgroundColor: const Color(0xFF0070F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Open', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded, size: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  // --- TAB 4: RESOURCES TAB ---
  Widget _buildResourcesTab(
    CourseModel batch,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return StreamBuilder<List<ResourceItem>>(
      stream: FirestoreService().getResourcesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allResources = snapshot.data ?? [];
        final batchResources = allResources.where((r) {
          return r.batchIds.contains(batch.id) || batch.resourceIds.contains(r.id);
        }).toList();

        if (batchResources.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No Resources in this Batch',
            message: 'Supplementary study materials & DPPs have not been attached to this batch yet.',
            actionLabel: null,
            onAction: null,
            isDark: isDark,
            textColor: textColor,
            subTextColor: subTextColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: batchResources.length,
          itemBuilder: (context, index) {
            final res = batchResources[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                res.subject,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              res.fileSize,
                              style: TextStyle(color: subTextColor, fontSize: 9.5),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✓ IN BATCH',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          res.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (res.subtitle.isNotEmpty)
                          Text(
                            res.subtitle,
                            style: TextStyle(color: subTextColor, fontSize: 10.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      backgroundColor: const Color(0xFF0070F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, size: 8),
                      ],
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

  // --- TAB 5: TEST SERIES TAB ---
  Widget _buildTestSeriesTab(
    CourseModel batch,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return StreamBuilder<List<TestCategory>>(
      stream: _testService.getCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSeries = snapshot.data ?? [];
        final batchSeries = allSeries.where((s) {
          return batch.testSeriesIds.contains(s.id);
        }).toList();

        if (batchSeries.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Test Series in this Batch',
            message: 'No Test Series have been attached to this batch yet.',
            actionLabel: null,
            onAction: null,
            isDark: isDark,
            textColor: textColor,
            subTextColor: subTextColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: batchSeries.length,
          itemBuilder: (context, index) {
            final series = batchSeries[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF0070F3).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          series.badge.isNotEmpty ? series.badge : 'PREMIUM',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '✓ INCLUDED WITH BATCH',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    series.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),

                  Text(
                    '${series.examCategory} • ${series.testsCount}',
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: series.features.take(3).map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF071428) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(color: subTextColor, fontSize: 9.5),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestSeriesDetailScreen(
                                categoryId: series.id,
                                title: series.title,
                                badge: series.badge,
                                price: '0',
                                originalPrice: '₹1499',
                                features: series.features,
                                badgeColor: const Color(0xFF10B981),
                                imageUrl: series.iconUrl,
                                isPurchased: true,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0070F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore Series', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 9),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- EMPTY STATE REUSABLE WIDGET ---
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String? actionLabel,
    required VoidCallback? onAction,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF091C38) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: subTextColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: subTextColor, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0070F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
