import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../models/test_model.dart';
import '../services/firestore_service.dart';
import '../services/content_service.dart';
import '../services/test_service.dart';
import '../services/payment_service.dart';
import '../utils/app_theme.dart';
import '../widgets/create_edit_batch_sheet.dart';
import 'pdf_viewer_screen.dart';
import 'video_player_screen.dart';
import 'test_series_detail_screen.dart';

/// Batch Description & Details Page
/// Contains 3 dynamically linked tabs: Resources | Live Classes | Test Series
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _paymentService.initialize(
      onSuccess: (res) async {
        await FirestoreService().addPurchase(
          id: widget.batch.id,
          title: widget.batch.title,
          type: 'Batch',
          price: widget.batch.price,
        );
        await FirestoreService().addNotification(
          title: 'Batch Unlocked! 🎉',
          subtitle: 'You are now enrolled in ${widget.batch.title}',
        );
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Successfully enrolled in ${widget.batch.title}!');
        setState(() {});
      },
      onFailure: (res) {
        if (!mounted) return;
        AppTheme.showErrorSnackBar(context, 'Enrollment failed: ${res.message ?? "Transaction Cancelled"}');
      },
      onExternalWallet: (res) {},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentService.dispose();
    super.dispose();
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
          'Are you sure you want to delete "${batch.title}"? Resources attached to this batch will remain available in the library.',
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

    final scaffoldBg = isDark ? const Color(0xFF030D1E) : AppTheme.backgroundLight;
    final cardBg = isDark ? const Color(0xFF091C38) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF1B3A68) : Colors.grey.shade200;

    return StreamBuilder<List<CourseModel>>(
      stream: FirestoreService().getBatchesStream(),
      builder: (context, snapshot) {
        // Fallback to widget.batch if stream is loading or doc exists
        final batches = snapshot.data ?? [];
        final currentBatch = batches.firstWhere(
          (b) => b.id == widget.batch.id,
          orElse: () => widget.batch,
        );

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF071428) : Colors.white,
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
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getUserPurchasesStream(),
            builder: (context, purchaseSnap) {
              final purchases = purchaseSnap.data ?? [];
              final isPurchased = purchases.any(
                (p) => (p['id'] ?? '').toString() == currentBatch.id ||
                    (p['title'] ?? '').toString().toLowerCase() == currentBatch.title.toLowerCase(),
              );

              return Column(
                children: [
                  // Batch Hero Header Card
                  _buildBatchHeroHeader(currentBatch, isPurchased, isDark, cardBg, textColor, subTextColor, borderColor),

                  // 3 Dynamic Tabs: Resources | Live Classes | Test Series
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF071428) : Colors.white,
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF0070F3),
                      unselectedLabelColor: subTextColor,
                      indicatorColor: const Color(0xFF0070F3),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.folder_special_outlined, size: 18),
                          child: Text(
                            'Resources (${currentBatch.resourceIds.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Tab(
                          icon: Icon(Icons.live_tv_rounded, size: 18),
                          text: 'Live Classes',
                        ),
                        Tab(
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          child: Text(
                            'Test Series (${currentBatch.testSeriesIds.length})',
                            overflow: TextOverflow.ellipsis,
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
                        // TAB 1: RESOURCES
                        _buildResourcesTab(currentBatch, isPurchased, isDark, cardBg, textColor, subTextColor, borderColor),

                        // TAB 2: LIVE CLASSES
                        _buildLiveClassesTab(currentBatch, isDark, cardBg, textColor, subTextColor, borderColor),

                        // TAB 3: TEST SERIES
                        _buildTestSeriesTab(currentBatch, isDark, cardBg, textColor, subTextColor, borderColor),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // --- BATCH HERO HEADER ---
  Widget _buildBatchHeroHeader(
    CourseModel batch,
    bool isPurchased,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0070F3).withValues(alpha: 0.3)),
                ),
                child: Text(
                  batch.examCategory.isNotEmpty ? batch.examCategory : 'ALL EXAMS',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'ENROLLED',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.orange, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    batch.validity,
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            batch.title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          if (batch.shortDescription.isNotEmpty || batch.description.isNotEmpty)
            Text(
              batch.shortDescription.isNotEmpty ? batch.shortDescription : batch.description,
              style: TextStyle(color: subTextColor, fontSize: 11.5, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 10),

          // Faculty info & Price CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF0070F3).withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Color(0xFF38BDF8), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.instructorName.isNotEmpty ? batch.instructorName : 'Senior Master Faculty',
                        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        batch.instructorTitle.isNotEmpty ? batch.instructorTitle : 'Examinant Faculty',
                        style: TextStyle(color: subTextColor, fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isPurchased)
                ElevatedButton(
                  onPressed: () {
                    PaymentService().payAndUnlock(
                      context: context,
                      title: batch.title,
                      price: batch.price,
                      itemType: 'Batch',
                      subtitle: 'Enroll in ${batch.title} with full resources & tests',
                      onSuccess: () => setState(() {}),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0070F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Enroll ₹${batch.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 1: RESOURCES TAB ---
  Widget _buildResourcesTab(
    CourseModel batch,
    bool isPurchased,
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
        // Only show resources linked to this batch:
        final batchResources = allResources.where((r) {
          return r.batchIds.contains(batch.id) || batch.resourceIds.contains(r.id);
        }).toList();

        if (batchResources.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No Resources in this Batch',
            message: 'You have not attached any resources to this batch yet.',
            actionLabel: 'Attach Resources Now',
            onAction: () => CreateEditBatchSheet.show(context, existingBatch: batch),
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

  // --- TAB 2: LIVE CLASSES TAB ---
  Widget _buildLiveClassesTab(
    CourseModel batch,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return StreamBuilder<List<LiveClass>>(
      stream: _contentService.getLiveClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allClasses = snapshot.data ?? [];
        // Strictly show only live classes assigned to this batch
        final batchClasses = allClasses.where((c) {
          return c.batchId == batch.id ||
              (c.batchId.isNotEmpty && c.batchId.toLowerCase() == batch.id.toLowerCase());
        }).toList();

        if (batchClasses.isEmpty) {
          return _buildEmptyState(
            icon: Icons.live_tv_rounded,
            title: 'No Live Classes Scheduled',
            message: 'Classes for this batch will be streamed live soon according to schedule.',
            actionLabel: null,
            onAction: null,
            isDark: isDark,
            textColor: textColor,
            subTextColor: subTextColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: batchClasses.length,
          itemBuilder: (context, index) {
            final c = batchClasses[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.isLive
                          ? Colors.red.withValues(alpha: 0.12)
                          : (c.isUpcoming ? Colors.orange.withValues(alpha: 0.12) : const Color(0xFF0070F3).withValues(alpha: 0.12)),
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
                            ] else if (c.isUpcoming) ...[
                              const Icon(Icons.schedule, color: Colors.orange, size: 12),
                              const SizedBox(width: 4),
                              const Text('UPCOMING', style: TextStyle(color: Colors.orange, fontSize: 9.5, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              Text('• ${c.time}', style: TextStyle(color: subTextColor, fontSize: 9.5)),
                            ] else ...[
                              const Icon(Icons.play_circle_outline, color: Color(0xFF38BDF8), size: 12),
                              const SizedBox(width: 4),
                              const Text('RECORDED SESSION', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              Text('• ${c.remainingTime}', style: TextStyle(color: subTextColor, fontSize: 9.5)),
                            ],
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: c.color.withValues(alpha: 0.2),
                              child: Text(
                                c.instructor.isNotEmpty ? c.instructor[0] : 'T',
                                style: TextStyle(color: c.color, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.instructor,
                              style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerScreen(
                                      title: c.title,
                                      instructor: c.instructor,
                                      videoUrl: c.videoUrl,
                                      isLive: c.isLive,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                c.isLive ? Icons.sensors : (c.isUpcoming ? Icons.notifications_active : Icons.play_arrow_rounded),
                                size: 14,
                              ),
                              label: Text(
                                c.isLive ? 'Join Stream' : (c.isUpcoming ? 'Set Reminder' : 'Watch Lecture'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.isLive ? Colors.red : const Color(0xFF0070F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      },
    );
  }

  // --- TAB 3: TEST SERIES TAB ---
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
        // Only show test series associated with this batch:
        final batchSeries = allSeries.where((s) {
          return batch.testSeriesIds.contains(s.id);
        }).toList();

        if (batchSeries.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Test Series in this Batch',
            message: 'You have not attached any Test Series to this batch yet.',
            actionLabel: 'Attach Test Series',
            onAction: () => CreateEditBatchSheet.show(context, existingBatch: batch),
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
