import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/test_model.dart';
import '../constants/app_colors.dart';

class CourseCardWidget extends StatelessWidget {
  final TestCategory course;
  final VoidCallback? onExplore;
  final VoidCallback? onUnlock;

  const CourseCardWidget({
    super.key,
    required this.course,
    this.onExplore,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final getCardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final getBorderColor = isDark ? AppColors.greyDark : Colors.grey.shade200;
    final getTextColor = isDark ? AppColors.textDark : AppColors.text;
    final getSecondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLight;

    int price = course.price.toInt();
    bool isFree = price == 0;
    int originalPrice = course.originalPrice > course.price ? course.originalPrice.toInt() : (isFree ? 0 : (price * 4).toInt());
    int savings = originalPrice - price;
    int savePercentage = originalPrice > 0 ? ((savings / originalPrice) * 100).round() : 0;
    String categoryName = course.features.isNotEmpty ? course.features.first.toUpperCase() : 'GENERAL BATCH';
    String testsCountText = course.testsCount.isNotEmpty ? course.testsCount : '108 Full Tests';

    final themeAccentColor = AppColors.accent;
    final themeSecondaryColor = isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: getBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeAccentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: themeAccentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {},
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.bookmark_border_rounded,
                  color: getSecondaryTextColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            course.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: getTextColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.description.isNotEmpty 
                ? course.description 
                : '${course.title} is a complete exam preparation system designed for your success.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: getSecondaryTextColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.greyDark : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Starts Soon',
                        isDark: isDark,
                        iconColor: getSecondaryTextColor,
                        textColor: getTextColor,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.monetization_on_outlined,
                        label: isFree ? 'FREE' : '₹$price',
                        isDark: isDark,
                        iconColor: themeAccentColor,
                        textColor: themeAccentColor,
                        isBoldText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.assignment_outlined,
                        label: testsCountText,
                        isDark: isDark,
                        iconColor: getSecondaryTextColor,
                        textColor: getTextColor,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Slots Open',
                        isDark: isDark,
                        iconColor: themeSecondaryColor,
                        textColor: getTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Original: ₹$originalPrice',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: getSecondaryTextColor.withValues(alpha: 0.7),
                      decoration: TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Save $savePercentage%',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onExplore ?? () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: getTextColor,
                    side: BorderSide(color: getBorderColor, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'EXPLORE BATCH',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onUnlock ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.accent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isFree ? 'JOIN FREE >' : 'JOIN BATCH >',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color iconColor,
    required Color textColor,
    bool isBoldText = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: isBoldText ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
