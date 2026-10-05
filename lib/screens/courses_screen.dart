// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import '../widgets/batch_page_sections.dart';
import '../widgets/create_edit_batch_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';

import '../services/payment_service.dart';
import '../widgets/course_card_widget.dart';
import '../services/firestore_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'test_series_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _getBackgroundColor => _isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
  Color get _getCardColor => _isDark ? AppColors.surfaceDark : Colors.white;
  Color get _getBorderColor => _isDark ? AppColors.greyDark : Colors.grey.shade200;
  Color get _getTextColor => _isDark ? AppColors.textDark : AppColors.text;
  Color get _getSecondaryTextColor => _isDark ? AppColors.textDarkSecondary : AppColors.textLight;

  late TabController _tabController;
  final TestService _testService = TestService();
  final PaymentService _paymentService = PaymentService();

  String? _pendingPurchaseCourseTitle;
  String? _pendingPurchaseCourseId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _paymentService.initialize(
      onSuccess: (PaymentSuccessResponse response) async {
        if (!mounted) return;
        
        if (_pendingPurchaseCourseId != null && _pendingPurchaseCourseTitle != null) {
          await FirestoreService().addPurchase(
            id: _pendingPurchaseCourseId!,
            title: _pendingPurchaseCourseTitle!,
            type: 'Batch',
            price: 0,
          );
        }

        await FirestoreService().addNotification(
          title: 'Course Unlocked 🎉',
          subtitle: 'Successfully purchased ${_pendingPurchaseCourseTitle ?? "Premium Test Series"}!',
        );
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(
          context,
          'Payment Successful! Unlocked ${_pendingPurchaseCourseTitle ?? "Premium Test Series"}',
        );
      },
      onFailure: (PaymentFailureResponse response) {
        if (!mounted) return;
        FirestoreService().addNotification(
          title: 'Payment Cancelled/Failed ❌',
          subtitle: 'Attempt to unlock ${_pendingPurchaseCourseTitle ?? "Premium Course"} was cancelled or failed.',
        );
        AppTheme.showErrorSnackBar(
          context,
          'Payment Failed: ${response.message ?? "User cancelled or transaction failed"}',
        );
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050F1E),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0070F3).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: Color(0xFF38BDF8), size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Batches & Programs',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF071326),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF38BDF8), size: 22),
            tooltip: 'Create Batch',
            onPressed: () => CreateEditBatchSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_create_batch',
        onPressed: () => CreateEditBatchSheet.show(context),
        backgroundColor: const Color(0xFF0070F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: const BatchPageSections(),
    );
  }

  Widget _buildPurchasesTab(List<TestCategory> categories) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getUserPurchasesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final purchases = snapshot.data ?? [];
        final purchasedIds = purchases.map((p) => (p['id'] ?? p['categoryId'] ?? '').toString()).toSet();
        final purchasedTitles = purchases.map((p) => (p['title'] ?? '').toString().toLowerCase()).toSet();

        final docs = categories.where((cat) {
          return purchasedIds.contains(cat.id) || purchasedTitles.contains(cat.title.toLowerCase());
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: _getSecondaryTextColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No purchased courses yet.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to the ALL BATCHES tab to browse and unlock premium courses.',
                    style: TextStyle(color: _getSecondaryTextColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final cat = docs[index];
            final courseId = cat.id;
            final courseName = cat.title;
            final matchingPurchase = purchases.firstWhere(
              (p) => (p['id'] ?? p['categoryId'] ?? '').toString() == cat.id ||
                     (p['title'] ?? '').toString().toLowerCase() == cat.title.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            final validTill = (matchingPurchase['validTill'] != null && matchingPurchase['validTill'].toString().isNotEmpty)
                ? matchingPurchase['validTill'].toString()
                : '1 Year Validity';
            final purchaseDate = matchingPurchase['date']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _getTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Valid till: $validTill',
                          style: TextStyle(color: _getSecondaryTextColor, fontSize: 12),
                        ),
                        if (purchaseDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Purchased: $purchaseDate',
                              style: TextStyle(color: _getSecondaryTextColor.withValues(alpha: 0.8), fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Color badgeColor = const Color(0xFFC0C0C0);
                      if (cat.badge.toLowerCase().contains('gold')) {
                        badgeColor = const Color(0xFFFFD700);
                      } else if (cat.badge.toLowerCase().contains('free')) {
                        badgeColor = Colors.green;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestSeriesDetailScreen(
                            categoryId: courseId,
                            title: courseName,
                            badge: cat.badge.isNotEmpty ? cat.badge : 'Premium',
                            price: cat.price.toStringAsFixed(0),
                            originalPrice: cat.originalPrice.toStringAsFixed(0),
                            features: cat.features.isEmpty
                                ? const ['Topic Wise', 'Full Tests']
                                : cat.features,
                            badgeColor: badgeColor,
                            imageUrl: cat.iconUrl,
                            isPurchased: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Prepare',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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

  Widget _buildCategoryBatchList(List<TestCategory> courses, String emptyMsg) {
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMsg,
            style: TextStyle(color: _getSecondaryTextColor, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        Color badgeColor = const Color(0xFFC0C0C0);
        if (course.badge.toLowerCase().contains('gold')) {
          badgeColor = const Color(0xFFFFD700);
        } else if (course.badge.toLowerCase().contains('free')) {
          badgeColor = Colors.green;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CourseCardWidget(
            course: course,
            onExplore: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestSeriesDetailScreen(
                    categoryId: course.id,
                    title: course.title,
                    badge: course.badge,
                    price: course.price.toStringAsFixed(0),
                    originalPrice: course.originalPrice.toStringAsFixed(0),
                    features: course.features.isEmpty
                        ? ['Chapter-wise Tests', 'Full Length Mocks']
                        : course.features,
                    badgeColor: badgeColor,
                    imageUrl: course.iconUrl,
                  ),
                ),
              );
            },
            onUnlock: () async {
              if (course.price == 0 || course.price == 0.0) {
                try {
                  await FirestoreService().addPurchase(
                    id: course.id,
                    title: course.title,
                    type: 'Batch',
                    price: 0,
                  );
                  await FirestoreService().addNotification(
                    title: 'Course Unlocked 🎉',
                    subtitle: 'Successfully unlocked ${course.title} for free!',
                  );
                } catch (e) {
                  debugPrint('Error saving free purchase: $e');
                }
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestSeriesDetailScreen(
                      categoryId: course.id,
                      title: course.title,
                      badge: course.badge,
                      price: course.price.toStringAsFixed(0),
                      originalPrice: course.originalPrice.toStringAsFixed(0),
                      features: course.features.isEmpty
                          ? ['Chapter-wise Tests', 'Full Length Mocks']
                          : course.features,
                      badgeColor: badgeColor,
                      imageUrl: course.iconUrl,
                      isPurchased: true,
                    ),
                  ),
                );
              } else {
                PaymentService().payAndUnlock(
                  context: context,
                  title: course.title,
                  price: course.price,
                  itemType: 'Course',
                  subtitle: 'Comprehensive course with live classes, study material, and full mock tests',
                  onSuccess: () {
                    if (mounted) setState(() {});
                  },
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildModernTab(String text, int index) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        return Tab(
          height: 44,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1B2541), Color(0xFF2A3A6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : _getCardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.transparent : _getBorderColor,
                width: 1.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF1B2541).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : _getSecondaryTextColor,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesTab(List<TestCategory> courses) {
    if (courses.isEmpty) {
      return const Center(child: Text('No batches available yet.'));
    }

    final featuredCourse = courses.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          _buildFeaturedBanner(featuredCourse),
          const SizedBox(height: 16),
          _buildCountdownSection(featuredCourse),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Explore ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _getTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Batches',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _isDark ? const Color(0xFF00D2FE) : AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...courses.asMap().entries.map((entry) {
            final index = entry.key;
            final course = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CourseCardWidget(
                course: course,
                onExplore: () {
                  Color badgeColor = const Color(0xFFC0C0C0);
                  if (course.badge.toLowerCase().contains('gold')) {
                    badgeColor = const Color(0xFFFFD700);
                  } else if (course.badge.toLowerCase().contains('free')) {
                    badgeColor = Colors.green;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestSeriesDetailScreen(
                        categoryId: course.id,
                        title: course.title,
                        badge: course.badge,
                        price: course.price.toStringAsFixed(0),
                        originalPrice: course.originalPrice.toStringAsFixed(0),
                        features: course.features.isEmpty
                            ? ['Chapter-wise Tests', 'Full Length Mocks']
                            : course.features,
                        badgeColor: badgeColor,
                        imageUrl: course.iconUrl,
                      ),
                    ),
                  );
                },
                onUnlock: () async {
                  if (course.price == 0 || course.price == 0.0) {
                    try {
                      await FirestoreService().addPurchase(
                        id: course.id,
                        title: course.title,
                        type: 'Batch',
                        price: 0,
                      );
                      await FirestoreService().addNotification(
                        title: 'Course Unlocked 🎉',
                        subtitle: 'Successfully unlocked ${course.title} for free!',
                      );
                    } catch (e) {
                      debugPrint('Error saving free purchase: $e');
                    }
                    Color badgeColor = const Color(0xFFC0C0C0);
                    if (course.badge.toLowerCase().contains('gold')) {
                      badgeColor = const Color(0xFFFFD700);
                    } else if (course.badge.toLowerCase().contains('free')) {
                      badgeColor = Colors.green;
                    }
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestSeriesDetailScreen(
                          categoryId: course.id,
                          title: course.title,
                          badge: course.badge,
                          price: course.price.toStringAsFixed(0),
                          originalPrice: course.originalPrice.toStringAsFixed(0),
                          features: course.features.isEmpty
                              ? ['Chapter-wise Tests', 'Full Length Mocks']
                              : course.features,
                          badgeColor: badgeColor,
                          imageUrl: course.iconUrl,
                          isPurchased: true,
                        ),
                      ),
                    );
                  } else {
                    PaymentService().payAndUnlock(
                      context: context,
                      title: course.title,
                      price: course.price,
                      itemType: 'Course',
                      subtitle: 'Comprehensive course with live classes, study material, and full mock tests',
                      onSuccess: () {
                        if (mounted) setState(() {});
                      },
                    );
                  }
                },
              ),
            ).animate().fade(delay: Duration(milliseconds: 100 * index)).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutQuad,
                  duration: 400.ms,
                );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDark ? AppColors.greyDark : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        style: TextStyle(color: _getTextColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search batches, courses, live classes...',
          hintStyle: TextStyle(
            color: _getSecondaryTextColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _getSecondaryTextColor,
            size: 20,
          ),
          suffixIcon: Icon(
            Icons.tune_rounded,
            color: _getSecondaryTextColor,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(TestCategory? course) {
    final title = course?.title ?? 'Examinantt Super Batch';
    final description = (course?.description.isNotEmpty ?? false)
        ? course!.description
        : 'The ultimate preparation batch for top exam results. Form your study routine, master mock tests, and achieve top ranks.';
    final badgeText = (course?.badge.isNotEmpty ?? false) ? course!.badge.toUpperCase() : 'FEATURED BATCH';
    final priceText = course == null ? 'FREE' : (course.price == 0 ? 'FREE' : '₹${course.price.toInt()}');
    final testsText = course?.testsCount.isNotEmpty == true ? course!.testsCount : 'Full Mock Tests';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0B1E43), const Color(0xFF00122C)]
              : [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDark ? AppColors.accent.withValues(alpha: 0.4) : Colors.white24,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isDark ? AppColors.accent : AppTheme.primaryColor)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF22C55E), size: 6),
                    SizedBox(width: 4),
                    Text(
                      'Registration Open',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          // Stats Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: AppColors.accent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PRICE',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              priceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.blueAccent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'CONTENT',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              testsText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    ).animate().fade(duration: 500.ms).scaleXY(begin: 0.95, end: 1, curve: Curves.easeOutBack);
  }

  Widget _buildCountdownSection(TestCategory? course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark ? AppColors.greyDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            'BATCH STARTS IN',
            style: TextStyle(
              color: _getSecondaryTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimerBox('12', 'DAYS')),
              const SizedBox(width: 6),
              Expanded(child: _buildTimerBox('08', 'HRS')),
              const SizedBox(width: 6),
              Expanded(child: _buildTimerBox('45', 'MIN')),
              const SizedBox(width: 6),
              Expanded(child: _buildTimerBox('22', 'SEC')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (course != null) {
                      Color badgeColor = const Color(0xFFC0C0C0);
                      if (course.badge.toLowerCase().contains('gold')) {
                        badgeColor = const Color(0xFFFFD700);
                      } else if (course.badge.toLowerCase().contains('free')) {
                        badgeColor = Colors.green;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestSeriesDetailScreen(
                            categoryId: course.id,
                            title: course.title,
                            badge: course.badge,
                            price: course.price.toStringAsFixed(0),
                            originalPrice: course.originalPrice.toStringAsFixed(0),
                            features: course.features.isEmpty
                                ? ['Chapter-wise Tests', 'Full Length Mocks']
                                : course.features,
                            badgeColor: badgeColor,
                            imageUrl: course.iconUrl,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Join Featured Batch',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (course != null) {
                      Color badgeColor = const Color(0xFFC0C0C0);
                      if (course.badge.toLowerCase().contains('gold')) {
                        badgeColor = const Color(0xFFFFD700);
                      } else if (course.badge.toLowerCase().contains('free')) {
                        badgeColor = Colors.green;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestSeriesDetailScreen(
                            categoryId: course.id,
                            title: course.title,
                            badge: course.badge,
                            price: course.price.toStringAsFixed(0),
                            originalPrice: course.originalPrice.toStringAsFixed(0),
                            features: course.features.isEmpty
                                ? ['Chapter-wise Tests', 'Full Length Mocks']
                                : course.features,
                            badgeColor: badgeColor,
                            imageUrl: course.iconUrl,
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _getTextColor,
                    side: BorderSide(
                      color: _isDark ? AppColors.greyDark : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.backgroundDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDark ? AppColors.greyDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _getTextColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _getSecondaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
