import 'package:examinantt_app/utils/app_navigator.dart';
// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'test_history_screen.dart';
import '../constants/app_colors.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import 'test_series_detail_screen.dart';
import '../widgets/notification_bell_action.dart';
import '../widgets/test_page_sections.dart';

class TestSeriesScreen extends StatefulWidget {
  final int initialTab;
  const TestSeriesScreen({super.key, this.initialTab = 0});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  final PaymentService _paymentService = PaymentService();

  final TestService _testService = TestService();
  late final Stream<List<TestCategory>> _categoriesStream;
  String _selectedCategoryFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _categoriesStream = _testService.getCategoriesStream();
    _paymentService.initialize(
      onSuccess: (PaymentSuccessResponse response) {
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Payment Successful! Series Unlocked.');
        setState(() {});
      },
      onFailure: (PaymentFailureResponse response) {
        if (!mounted) return;
        AppTheme.showErrorSnackBar(
          context,
          PaymentService.cleanErrorMessage(response),
        );
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // Top App Bar matching Home, Batches & PDF Header
              _buildTopAppBar(),

              // Test Page Sections containing: My Test, All Test, Included with Batch
              Expanded(
                child: TestPageSections(
                  initialTab: widget.initialTab,
                  onOpenHistory: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCenter(bool isDark) {
    final filters = ['All', 'Full Mocks', 'Chapter Tests', 'Unit Tests', 'Previous Years'];
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & History Bar
            Row(
              children: [
                Expanded(
                  child: Container(
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
                      style: TextStyle(fontSize: 13, color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Search mock tests, series...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0070F3), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'History',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0070F3),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = _selectedCategoryFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedCategoryFilter = f);
                      },
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Real-time Test Series Stream
            StreamBuilder<List<TestCategory>>(
              stream: _categoriesStream,
              initialData: TestService.cachedCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && TestService.cachedCategories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                var list = snapshot.data ?? TestService.cachedCategories;
                if (_searchQuery.isNotEmpty) {
                  list = list.where((c) => c.title.toLowerCase().contains(_searchQuery)).toList();
                }
                if (_selectedCategoryFilter != 'All') {
                  list = list.where((c) =>
                    c.title.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()) ||
                    c.badge.toLowerCase().contains(_selectedCategoryFilter.toLowerCase())
                  ).toList();
                }

                if (list.isEmpty) {
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
                        Icon(Icons.assignment_outlined, size: 54, color: isDark ? Colors.white24 : Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No Test Series Found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try choosing another filter or search term.',
                          style: TextStyle(color: subtitleColor, fontSize: 12.5),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: list.map((cat) => _buildTestCard(cat, isDark)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(TestCategory cat, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white : AppTheme.darkSlate;
    final headerBarBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC);
    final headerBorder = isDark ? const Color(0xFF1E293B) : Colors.grey.shade100;

    Color badgeColor = const Color(0xFFC0C0C0);
    if (cat.badge.toLowerCase().contains('gold')) {
      badgeColor = const Color(0xFFFF9500);
    } else if (cat.badge.toLowerCase().contains('free')) {
      badgeColor = const Color(0xFF10B981);
    } else if (cat.badge.isNotEmpty) {
      badgeColor = const Color(0xFF0070F3);
    }

    final priceStr = cat.price == 0 ? 'FREE' : '₹${cat.price.toInt()}';
    final origPriceStr = cat.originalPrice > cat.price ? '₹${cat.originalPrice.toInt()}' : '';
    final testsCountStr = cat.testsCount.isNotEmpty ? cat.testsCount : 'All India Mock Series';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Badge & Test Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBarBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: headerBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    cat.badge.isNotEmpty ? cat.badge.toUpperCase() : 'PREMIUM',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      testsCountStr,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (cat.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    cat.description,
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.grey.shade600, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Key Features List
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: (cat.features.isEmpty
                          ? ['Chapter-wise Tests', 'Subject Mocks', 'AI Analysis', 'All India Rank']
                          : cat.features.take(4))
                      .map((feat) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          feat,
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Price and Actions
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              priceStr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                              ),
                            ),
                            if (origPriceStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                origPriceStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Text(
                          '1 Year Complete Access',
                          style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => _openSeries(cat, isPurchased: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: titleColor,
                        side: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (cat.price == 0) {
                          _openSeries(cat, isPurchased: true);
                        } else {
                          PaymentService().payAndUnlock(
                            context: context,
                            title: cat.title,
                            price: cat.price,
                            itemType: 'Test Series',
                            subtitle: 'Full Mock Tests with All India Percentile & Rank',
                            onSuccess: () {
                              if (mounted) setState(() {});
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text(
                        cat.price == 0 ? 'Start Free' : 'Unlock Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
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

  void _openSeries(TestCategory cat, {bool isPurchased = false}) {
    Color badgeColor = const Color(0xFFC0C0C0);
    if (cat.badge.toLowerCase().contains('gold')) {
      badgeColor = const Color(0xFFFF9500);
    } else if (cat.badge.toLowerCase().contains('free')) {
      badgeColor = const Color(0xFF10B981);
    }

    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestSeriesDetailScreen(
          categoryId: cat.id,
          title: cat.title,
          badge: cat.badge.isNotEmpty ? cat.badge : 'PREMIUM',
          price: cat.price.toStringAsFixed(0),
          originalPrice: cat.originalPrice.toStringAsFixed(0),
          features: cat.features.isEmpty
              ? ['Chapter-wise Tests', 'Full Length Mocks']
              : cat.features,
          badgeColor: badgeColor,
          imageUrl: cat.iconUrl,
          isPurchased: isPurchased,
        ),
      ),
    );
  }

  // Standard Header matching PDF: Shield + EXAMINANTT TEST CENTER + Bell + Back Button
  Widget _buildTopAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF071326) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final canPop = Navigator.canPop(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: scaffoldBg,
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),
          ],
          // Logo Badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFFFFA000), size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EXAMINANTT',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'TEST CENTER',
                  style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          NotificationBellAction(color: textColor),
        ],
      ),
    );
  }
}
