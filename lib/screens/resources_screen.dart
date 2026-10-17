import 'package:examinantt_app/utils/app_navigator.dart';
// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/app_colors.dart';

import '../models/content_models.dart';
import '../services/content_service.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/notification_bell_action.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _pendingResourceTitle;
  double? _pendingResourcePrice;
  int _activeTabIndex = 0;
  String _selectedCategoryFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  late final Stream<List<ResourceItem>> _resourcesStream;

  @override
  void initState() {
    super.initState();
    _resourcesStream = ContentService().getResources();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final title = _pendingResourceTitle ?? 'Study Resource';
    final price = _pendingResourcePrice ?? 49.0;
    final resId = 'res_${title.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    await FirestoreService().addPurchase(
      id: resId,
      title: title,
      type: 'Resource',
      price: price,
    );

    await FirestoreService().addNotification(
      title: 'Resource Unlocked 📖',
      subtitle: 'Successfully unlocked $title in real-time!',
    );
    if (!mounted) return;
    AppTheme.showSuccessSnackBar(context, 'Payment Successful: $title Unlocked in Real-Time!');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    FirestoreService().addNotification(
      title: 'Payment Cancelled/Failed ❌',
      subtitle: 'Attempt to unlock resource was cancelled or failed.',
    );
    if (!mounted) return;
    AppTheme.showErrorSnackBar(
      context,
      PaymentService.cleanErrorMessage(response),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    AppTheme.showSuccessSnackBar(context, 'External Wallet: ${response.walletName ?? ""}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF001638), Color(0xFF000F29)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.transparent : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar matching Home, Batches, Tests & PDF Header
              _buildTopAppBar(),

              // Unified Resource Center for both dark and light modes (same functions)
              Expanded(
                child: _buildResourceCenter(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCenter(bool isDark) {
    final categories = ['All', 'Formulas', 'Notes', 'PYQs', 'Mock PDFs', 'Question Bank'];
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: cardBg,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                style: TextStyle(fontSize: 14, color: titleColor),
                decoration: InputDecoration(
                  hintText: 'Search formula sheets, notes, PDFs...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedCategoryFilter = cat);
                      },
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF10B981) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Stream of Study Material & PDFs
            StreamBuilder<List<ResourceItem>>(
              stream: _resourcesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                var items = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  items = items.where((r) =>
                    r.title.toLowerCase().contains(_searchQuery) ||
                    r.subtitle.toLowerCase().contains(_searchQuery) ||
                    r.subject.toLowerCase().contains(_searchQuery)
                  ).toList();
                }
                if (_selectedCategoryFilter != 'All') {
                  items = items.where((r) =>
                    r.category.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()) ||
                    r.type.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()) ||
                    r.title.toLowerCase().contains(_selectedCategoryFilter.toLowerCase())
                  ).toList();
                }

                if (items.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.library_books_outlined, size: 54, color: isDark ? Colors.white24 : Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No Study Resources Found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try choosing another filter or search keyword.',
                          style: TextStyle(color: subtitleColor, fontSize: 12.5),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: items.map((res) => _buildResourceCard(res, isDark)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(ResourceItem res, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white : AppTheme.darkSlate;
    final badgeBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9);
    final badgeTextColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF64748B);

    final isPdf = res.url.toLowerCase().endsWith('.pdf') || res.type.toLowerCase().contains('pdf') || res.type.toLowerCase().contains('notes');
    final iconColor = isPdf ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = isPdf ? Icons.picture_as_pdf_rounded : Icons.menu_book_rounded;
    final priceStr = res.price == 0 ? 'FREE' : '₹${res.price.toInt()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: isDark ? 0.35 : 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 26),
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
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        res.subject.toUpperCase(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: badgeTextColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      priceStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: res.price == 0 ? const Color(0xFF10B981) : const Color(0xFFFF7A00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  res.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  res.subtitle,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (res.fileSize.isNotEmpty) ...[
                      Icon(Icons.description_outlined, size: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(res.fileSize, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                      const SizedBox(width: 12),
                    ],
                    if (res.downloads.isNotEmpty) ...[
                      Icon(Icons.file_download_outlined, size: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(res.downloads, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (res.price == 0 || res.isFree) {
                          AppNavigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerScreen(pdfData: res),
                            ),
                          );
                        } else {
                          PaymentService().payAndUnlock(
                            context: context,
                            title: res.title,
                            price: res.price,
                            itemType: 'Study Material',
                            subtitle: 'Instant PDF download and reading access',
                            onSuccess: () {
                              if (mounted) setState(() {});
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: res.price == 0 ? const Color(0xFF10B981) : const Color(0xFF0070F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        res.price == 0 ? 'Open PDF' : 'Unlock PDF',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
  }

  // Standard Header matching PDF: Shield Badge + EXAMINANTT RESOURCE CENTER + Bell (3) + Search
  Widget _buildTopAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? Colors.transparent : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scaffoldBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Logo Badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFFFFA000), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EXAMINANTT',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'RESOURCE CENTER',
                  style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          NotificationBellAction(color: textColor),
          IconButton(
            icon: Icon(Icons.search_rounded, color: textColor),
            onPressed: () {
              AppTheme.showSuccessSnackBar(context, 'Search notes, question papers & formulas...');
            },
          ),
        ],
      ),
    );
  }
}
