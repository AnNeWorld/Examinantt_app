import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../screens/resources_screen.dart';
import '../screens/test_series_screen.dart';
import '../screens/pyqs_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/doubts_screen.dart';

class QuickAccessWidget extends StatelessWidget {
  const QuickAccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Learn',
        'desc': 'Concepts & Notes',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF3B82F6), // Blue
        'destination': const CoursesScreen(),
      },
      {
        'title': 'Practice',
        'desc': 'Topic & MCQs',
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFF10B981), // Green
        'destination': const ResourcesScreen(),
      },
      {
        'title': 'Tests',
        'desc': 'Mocks & Series',
        'icon': Icons.assignment_turned_in_outlined,
        'color': const Color(0xFFFF7A00), // Vivid Orange
        'destination': const TestSeriesScreen(),
      },
      {
        'title': 'PYQs',
        'desc': 'Year-wise Papers',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF8B5CF6), // Purple
        'destination': const PyqsScreen(),
      },
      {
        'title': 'Doubts',
        'desc': 'Expert Answers',
        'icon': Icons.help_outline_rounded,
        'color': const Color(0xFF06B6D4), // Cyan
        'destination': const DoubtsScreen(),
      },
      {
        'title': 'Analytics',
        'desc': 'Rank Insights',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFFEC4899), // Pink
        'destination': const AnalyticsScreen(),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final textScaler = MediaQuery.textScalerOf(context);
        final scaleFactor = textScaler.scale(1.0);

        // Responsive grid configuration
        final int crossAxisCount;
        final double childAspectRatio;
        final double spacing;

        if (availableWidth >= 800) {
          // Large tablets / desktop screens: 6 in 1 row
          crossAxisCount = 6;
          childAspectRatio = 1.05;
          spacing = 12;
        } else if (availableWidth >= 550) {
          // Medium tablets / landscape: 6 in 1 row or 3 in 2 rows
          crossAxisCount = availableWidth > 680 ? 6 : 3;
          childAspectRatio = 1.1;
          spacing = 10;
        } else if (availableWidth <= 340) {
          // Very small mobile screens (e.g. 320px width)
          crossAxisCount = 3;
          childAspectRatio = scaleFactor > 1.1 ? 0.88 : 0.94;
          spacing = 8;
        } else {
          // Standard mobile screens (340px - 550px)
          crossAxisCount = 3;
          childAspectRatio = scaleFactor > 1.15 ? 0.92 : 0.98;
          spacing = 10;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return QuickAccessCard(
              title: item['title'] as String,
              desc: item['desc'] as String,
              icon: item['icon'] as IconData,
              accentColor: item['color'] as Color,
              destination: item['destination'] as Widget,
              index: index,
            );
          },
        );
      },
    );
  }
}

class QuickAccessCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color accentColor;
  final Widget destination;
  final int index;

  const QuickAccessCard({
    super.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.accentColor,
    required this.destination,
    required this.index,
  });

  @override
  State<QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<QuickAccessCard> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    _rotationController.reset();
    _rotationController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget.destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final cardBorderColor = isDark
        ? widget.accentColor.withValues(alpha: 0.3)
        : widget.accentColor.withValues(alpha: 0.2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;

        // Proportional responsive dimensions
        final ringSize = (cardWidth * 0.40).clamp(32.0, 46.0);
        final innerIconSize = (ringSize * 0.42).clamp(14.0, 20.0);
        final titleFontSize = (cardWidth * 0.125).clamp(10.0, 13.0);
        final descFontSize = (cardWidth * 0.082).clamp(7.5, 9.5);
        final vPadding = (cardHeight * 0.06).clamp(4.0, 8.0);
        final hPadding = (cardWidth * 0.05).clamp(4.0, 7.0);

        return GestureDetector(
          onTap: _handleTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(cardWidth < 100 ? 12 : 16),
              border: Border.all(
                color: cardBorderColor,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: isDark ? 0.08 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedGlowingIconRing(
                  icon: widget.icon,
                  accentColor: widget.accentColor,
                  rotationController: _rotationController,
                  size: ringSize,
                  iconSize: innerIconSize,
                ),
                SizedBox(height: (cardHeight * 0.05).clamp(2.0, 6.0)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.text,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.desc,
                    style: TextStyle(
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ).animate().scaleXY(
          begin: 0.94,
          end: 1.0,
          duration: 300.ms,
          delay: Duration(milliseconds: 40 * widget.index),
          curve: Curves.easeOutCubic,
        ).fadeIn();
      },
    );
  }
}

class AnimatedGlowingIconRing extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final AnimationController rotationController;
  final double size;
  final double iconSize;

  const AnimatedGlowingIconRing({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.rotationController,
    this.size = 46.0,
    this.iconSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final innerCircleSize = size * 0.78;
    final dotSize = (size * 0.11).clamp(3.5, 5.5);

    return Stack(
      alignment: Alignment.center,
      children: [
        RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: rotationController, curve: Curves.easeInOutCubic),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: (size * 0.09).clamp(2.0, 5.0),
                  bottom: (size * 0.13).clamp(3.0, 7.0),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor,
                          blurRadius: 5,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: innerCircleSize,
          height: innerCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: iconSize,
          ),
        ),
      ],
    );
  }
}
