import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  
import '../utils/app_navigator.dart';  
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/quick_access_widget.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/notification_bell_action.dart';
import '../services/firestore_service.dart';
import 'courses_screen.dart';
import '../constants/app_colors.dart';
import '../models/content_models.dart';
import '../utils/app_theme.dart';
import 'test_series_screen.dart';
import 'resources_screen.dart';
import 'doubts_screen.dart';
import 'pyqs_screen.dart';
import 'batch_details_screen.dart';

import 'profile_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/safe_app_image.dart';
import '../widgets/home_live_classes_section.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index)? onSelectTab;
  const HomeScreen({super.key, this.onSelectTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _getTextColor => _isDark ? AppColors.textDark : AppColors.text;
  Color get _getSecondaryTextColor => _isDark ? AppColors.textDarkSecondary : AppColors.textLight;

  int _currentCarouselIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  // Fallback banners matching https://www.examinantt.com/ exactly if Firestore stream is offline
  static const List<Map<String, dynamic>> _fallbackBanners = [
    {
      'imageUrl': 'https://www.examinantt.com/assets/slider11-BF0Iauqj.png',
      'title': 'Examinantt - Education Redefined',
      'order': 1,
    },
    {
      'imageUrl': 'https://www.examinantt.com/assets/slider3-CgqkNE7j.png',
      'title': 'Live Interactive Classes',
      'order': 2,
    },
    {
      'imageUrl': 'https://www.examinantt.com/assets/slioder4-BhKXNWYL.png',
      'title': 'Comprehensive Mock Tests & Test Series',
      'order': 3,
    },
    {
      'imageUrl': 'https://www.examinantt.com/assets/slider5-K9I7QbE8.png',
      'title': 'Expert Guidance & Doubt Support',
      'order': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final user = userProvider.user;
        final name = user?.name ?? 'Student';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
        final isDark = themeProvider.isDarkMode;
        final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);

        return Scaffold(
              backgroundColor: bgColor,
              drawer: AppDrawer(
                currentIndex: 0,
                onSelectTab: widget.onSelectTab,
              ),
              appBar: AppBar(
                backgroundColor: bgColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 52,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: _getTextColor,
                      size: 25,
                    ),
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                titleSpacing: 0,
                title: InkWell(
                  onTap: () {
                    if (widget.onSelectTab != null) {
                      widget.onSelectTab!(4);
                    } else {
                      AppNavigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.accent, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: _isDark ? AppColors.surfaceDark : Colors.white,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hi, $name 👋',
                                style: TextStyle(
                                  color: _getTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              InkWell(
                                onTap: () => _showChangeExamDialog(userProvider.selectedExam),
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Target: ${userProvider.selectedExam}',
                                        style: TextStyle(
                                          color: _getSecondaryTextColor,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _getSecondaryTextColor,
                                      size: 13,
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
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: NotificationBellAction(color: _getTextColor),
                  ),
                ],
              ),
              body: RefreshIndicator(
                color: const Color(0xFFFFA000),
                backgroundColor: isDark ? const Color(0xFF0F1E36) : Colors.white,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 650));
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getUserPurchasesStream(explicitUid: user?.uid),
                    initialData: FirestoreService.cachedPurchases,
                    builder: (context, purchaseSnap) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // 1. Poster Banner Slider ALWAYS at the very top
                          _buildHeroSlider(),
                          const SizedBox(height: 10),

                          // Quick Access 6 cards (Learn, Practice, Tests, PYQs, Doubts, Analytics)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: QuickAccessWidget(),
                          ),
                          const SizedBox(height: 10),

                          // 2. Unified Sections for both Dark and Light Mode (same functions and features)
                          _buildHomeSections(context, userProvider.selectedExam, isDark),
                          const SizedBox(height: 36),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
      },
    );
  }


  void _showChangeExamDialog(String currentExam) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final handleColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final unselectedChipBg = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    final unselectedChipText = isDark ? Colors.white : AppTheme.darkSlate;
    final unselectedIconColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Target Exam',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your target competitive exam to personalize your preparation.',
                  style: TextStyle(color: subColor, fontSize: 12),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<String>>(
                  stream: FirestoreService().getExamsStream(),
                  initialData: FirestoreService.fallbackExams,
                  builder: (context, examSnap) {
                    final liveExams = examSnap.data ?? FirestoreService.fallbackExams;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: liveExams.map((exam) {
                        final isSel = currentExam.toLowerCase().trim() == exam.toLowerCase().trim();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.accent.withValues(alpha: 0.2) : unselectedChipBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSel ? Icons.check_circle : Icons.school_outlined,
                              color: isSel ? AppColors.accent : unselectedIconColor,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            exam,
                            style: TextStyle(
                              color: isSel ? AppColors.accent : unselectedChipText,
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
                            Provider.of<UserProvider>(context, listen: false).updateTargetExam(exam);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Target exam switched to $exam!'),
                                  ],
                                ),
                                backgroundColor: AppColors.accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }


  Widget _buildHeroSlider() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getBannersStream(),
      initialData: FirestoreService.cachedBanners.isNotEmpty ? FirestoreService.cachedBanners : _fallbackBanners,
      builder: (context, snapshot) {
        List<Map<String, dynamic>> banners = snapshot.data ?? [];
        if (banners.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 140);
        }
        if (banners.isEmpty) {
          banners = _fallbackBanners;
        }
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        final safeIndex = _currentCarouselIndex.clamp(0, banners.length - 1);
        return Column(
          children: [
            CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                aspectRatio: 2.15,
                autoPlay: banners.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: banners.length > 1,
                enableInfiniteScroll: banners.length > 1,
                viewportFraction: banners.length > 1 ? 0.94 : 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              items: banners.map((banner) {
                final imgUrl = (banner['resolvedImageUrl'] ?? banner['imageUrl'] ?? banner['desktopUrl'] ?? banner['bannerUrl'] ?? banner['image'] ?? banner['url'] ?? '').toString().trim();
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        AppNavigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CoursesScreen()),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SafeAppImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.fill,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: banners.asMap().entries.map((entry) {
                  final isSelected = safeIndex == entry.key;
                  return GestureDetector(
                    onTap: () => _carouselController.animateToPage(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 14.0 : 5.0,
                      height: 5.0,
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.5),
                        color: isSelected
                            ? AppColors.accent
                            : (_isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  // ===========================================================================
  // UNIFIED HOME SECTIONS (Identical functions in both Dark & Light modes)
  // ===========================================================================
  Widget _buildHomeSections(BuildContext context, String selectedExam, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dedicated Live Classes & Video Lectures Section (Synced real-time with website)
          HomeLiveClassesSection(
            selectedExam: selectedExam,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // 2. Featured Batches Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Batches ($selectedExam)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () {
                  AppNavigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoursesScreen()),
                  );
                },
                child: const Text('View All →', style: TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<CourseModel>>(
            stream: FirestoreService().getBatchesStream(),
            initialData: FirestoreService.cachedBatches,
            builder: (context, snapshot) {
              final batches = snapshot.data ?? [];
              final matchingBatches = batches.where((b) {
                if (selectedExam.isEmpty || selectedExam == 'All') return true;
                final cat = b.examCategory.toLowerCase();
                final sel = selectedExam.toLowerCase();
                return cat.contains(sel) || sel.contains(cat) || b.title.toLowerCase().contains(sel);
              }).toList();
              final displayBatches = matchingBatches.isNotEmpty ? matchingBatches : batches;
              final topCourses = displayBatches.take(3).toList();
              if (topCourses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Center(
                    child: Text('Explore latest batches in the Batches tab', style: TextStyle(color: subtitleColor, fontSize: 13)),
                  ),
                );
              }

              return Column(
                children: topCourses.map((c) {
                  final isFree = c.price <= 0;
                  final categoryTag = c.examCategory.isNotEmpty ? c.examCategory.toUpperCase() : 'BATCH';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (c.thumbnailUrl.trim().isNotEmpty)
                          SafeAppImage(
                            imageUrl: c.thumbnailUrl.trim(),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                            fallbackIcon: Icons.school_rounded,
                            errorWidget: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0070F3).withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.school_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0070F3), size: 24),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0070F3).withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.school_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0070F3), size: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: titleColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFree ? 'FREE BATCH • $categoryTag' : categoryTag,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isFree ? const Color(0xFF10B981) : const Color(0xFFFF7A00)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFree ? 'FREE ACCESS' : '₹${c.price.toInt()} Complete Batch',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isFree ? const Color(0xFF10B981) : (isDark ? Colors.white70 : AppColors.text)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AppNavigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BatchDetailsScreen(batch: c),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFree ? const Color(0xFF10B981) : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isFree ? 'Start Free' : 'View Batch',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),

          // 3. Practice & Test Series Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF0F1E36), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All-India Mock Test Series',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Practice chapter tests with instant percentile analytics',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.blue.shade900.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TestSeriesScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Quick Study Tools Grid (PYQs & Notes)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PyqsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE),
                          child: const Icon(Icons.history_edu_rounded, color: Color(0xFF8B5CF6), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('15+ Yrs PYQs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: titleColor)),
                              Text('Solved Papers', style: TextStyle(fontSize: 12, color: subtitleColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ResourcesScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Formula PDFs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: titleColor)),
                              Text('Revision Sheets', style: TextStyle(fontSize: 12, color: subtitleColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Ask Doubts & Community Banner
          InkWell(
            onTap: () {
              AppNavigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoubtsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFFF7ED),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFFFF7A00), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Have a Doubt in any Question?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: titleColor)),
                        const SizedBox(height: 2),
                        Text('Ask expert faculty & get step-by-step solutions under 15 mins', style: TextStyle(fontSize: 12.5, color: subtitleColor)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF7A00), size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
