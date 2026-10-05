// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'test_history_screen.dart';
import '../widgets/test_page_sections.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import 'test_series_detail_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
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
          'Payment Failed: ${response.message ?? "User cancelled or transaction failed"}',
        );
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  final TestService _testService = TestService();
  String _selectedCategoryFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

              // When dark mode is on, render TestPageSections. When dark mode is off, render 100% white native Test Center.
              Expanded(
                child: isDark
                    ? TestPageSections(
                        onOpenHistory: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
                          );
                        },
                      )
                    : _buildLightTestCenter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightTestCenter() {
    final filters = ['All', 'Full Mocks', 'Chapter Tests', 'Unit Tests', 'Previous Years'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    style: const TextStyle(fontSize: 13, color: AppTheme.darkSlate),
                    decoration: InputDecoration(
                      hintText: 'Search mock tests, series...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_rounded, color: Color(0xFF0070F3), size: 18),
                      SizedBox(width: 4),
                      Text(
                        'History',
                        style: TextStyle(
                          color: Color(0xFF0070F3),
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
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
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
            stream: _testService.getCategoriesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              var list = snapshot.data ?? [];
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'No Test Series Found',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkSlate),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try choosing another filter or search term.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: list.map((cat) => _buildLightTestCard(cat)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLightTestCard(TestCategory cat) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    cat.badge.isNotEmpty ? cat.badge.toUpperCase() : 'PREMIUM',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      testsCountStr,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkSlate,
                    letterSpacing: -0.3,
                  ),
                ),
                if (cat.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    cat.description,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
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
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (origPriceStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                origPriceStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Text(
                          '1 Year Complete Access',
                          style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => _openSeries(cat, isPurchased: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.darkSlate,
                        side: BorderSide(color: Colors.grey.shade300),
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

    Navigator.push(
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

  // Standard Header matching PDF: Hamburger / Shield + EXAMINANTT TEST CENTER + Bell + Search
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
                  'TEST CENTER',
                  style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification with badge 3 matching PDF
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: textColor),
                onPressed: () {
                  AppTheme.showSuccessSnackBar(context, 'You have 3 new test notifications!');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA000),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: textColor),
            onPressed: () {
              AppTheme.showSuccessSnackBar(context, 'Search mock tests & question banks...');
            },
          ),
        ],
      ),
    );
  }
}
