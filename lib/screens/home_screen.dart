import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';  
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/quick_access_widget.dart';
import '../widgets/locked_home_sections.dart';
import '../widgets/unlocked_home_sections.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'notifications_screen.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import 'courses_screen.dart';
import '../constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _getCardColor => _isDark ? AppColors.surfaceDark : Colors.white;
  Color get _getBorderColor => _isDark ? AppColors.greyDark : Colors.grey.shade200;
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
              appBar: AppBar(
                backgroundColor: bgColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 52,
                title: Row(
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
                          Row(
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  StreamBuilder<List<NotificationModel>>(
                    stream: FirestoreService().getNotificationsStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: _getCardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: _getBorderColor),
                        ),
                        child: Badge(
                          label: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          isLabelVisible: count > 0,
                          backgroundColor: AppColors.accent,
                          offset: const Offset(-1, 1),
                          child: IconButton(
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: _getTextColor,
                              size: 18,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getUserPurchasesStream(explicitUid: user?.uid),
                  builder: (context, purchaseSnap) {
                    final purchases = purchaseSnap.data ?? [];
                    final bool hasEnrolledBatch = purchases.any((p) {
                      final type = (p['type'] ?? '').toString().toLowerCase();
                      final title = (p['title'] ?? '').toString().toLowerCase();
                      final id = (p['id'] ?? '').toString().toLowerCase();
                      return type == 'batch' || title.contains('batch') || id.contains('batch');
                    });
                    final bool hasPurchasedBatch = hasEnrolledBatch;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // Target Exam Header Banner
                        _buildTargetExamHeader(userProvider.selectedExam),
                        const SizedBox(height: 6),

                        // 1. Poster Banner Slider ALWAYS at the very top
                        _buildHeroSlider().animate().fadeIn(duration: 350.ms),
                        const SizedBox(height: 10),

                        // Quick Access 6 cards (Learn, Practice, Tests, PYQs, Doubts, Analytics)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: QuickAccessWidget(),
                        ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
                        const SizedBox(height: 10),

                        // 2. If student has NOT purchased batch: show ALL pages of locked home.pdf
                        if (!hasPurchasedBatch) ...[
                          LockedHomeSections(
                            onExploreBatches: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CoursesScreen()),
                              );
                            },
                          ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
                        ] else ...[
                          // 3. If student HAS purchased batch: show ALL pages of unlocked home.pdf
                          const UnlockedHomeSections().animate().fadeIn(delay: 50.ms, duration: 400.ms),
                        ],
                        const SizedBox(height: 36),
                      ],
                    );
                  },
                ),
              ),
            );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TARGET EXAM HEADER & DIALOG (Home Page)
  // ---------------------------------------------------------------------------

  Widget _buildTargetExamHeader(String selectedExam) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showChangeExamDialog(selectedExam),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Preparing for: ',
                      style: TextStyle(
                        color: _isDark ? Colors.white60 : Colors.black54,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        selectedExam,
                        style: const TextStyle(
                          color: Color(0xFFFFA000),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFFFA000),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => _showChangeExamDialog(selectedExam),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'Change ⇄',
                  style: TextStyle(
                    color: Color(0xFFFFA000),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeExamDialog(String currentExam) {
    final exams = [
      'JEE Main 2027',
      'NEET UG 2027',
      'JEE Advanced',
      'CUET UG 2027',
      'GATE 2027',
      'SSC CGL 2027',
      'Defence Exams',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Target Exam',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose your target competitive exam to personalize your preparation.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...exams.map((exam) {
                  final isSel = currentExam == exam;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.accent.withValues(alpha: 0.2) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSel ? Icons.check_circle : Icons.school_outlined,
                        color: isSel ? AppColors.accent : Colors.white70,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      exam,
                      style: TextStyle(
                        color: isSel ? AppColors.accent : Colors.white,
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
                }),
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
                final imgUrl = (banner['imageUrl'] ?? banner['bannerUrl'] ?? banner['image'] ?? banner['url'] ?? '').toString().trim();
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.fill,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: _isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: _isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 28),
                              ),
                            ),
                          ),
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
}
