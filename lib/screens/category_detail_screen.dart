import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import 'test_series_detail_screen.dart';
import '../constants/app_colors.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final appBarColor = isDark ? AppColors.surfaceDark : Colors.white;
    final appBarTitleColor = isDark ? AppColors.textDark : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: appBarTitleColor,
        title: Text('$categoryName Exams', style: TextStyle(fontWeight: FontWeight.bold, color: appBarTitleColor)),
        elevation: 0,
      ),
      body: FutureBuilder<List<TestCategory>>(
        future: TestService().getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: isDark ? AppColors.textDark : Colors.black)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No test series available for this category.', style: TextStyle(color: isDark ? AppColors.textDark : Colors.black)));
          }

          // Filter by categoryName
          final keyword = categoryName.toLowerCase();
          final filtered = snapshot.data!.where((cat) {
            final title = cat.title.toLowerCase();
            final desc = cat.description.toLowerCase();
            final featuresText = cat.features.join(' ').toLowerCase();

            // Match keywords
            if (keyword == 'banking') {
              return title.contains('bank') || title.contains('ibps') || title.contains('sbi') || desc.contains('bank') || featuresText.contains('bank');
            } else if (keyword == 'ssc cgl') {
              return title.contains('ssc') || title.contains('cgl') || title.contains('chsl') || desc.contains('ssc') || featuresText.contains('ssc');
            } else if (keyword == 'medical') {
              return title.contains('neet') || title.contains('medical') || title.contains('physics') || title.contains('biology') || desc.contains('neet');
            } else if (keyword == 'engineering') {
              return title.contains('gate') || title.contains('jee') || title.contains('engineering') || desc.contains('gate') || desc.contains('jee');
            } else if (keyword == 'boards') {
              return title.contains('board') || title.contains('cbse') || title.contains('class') || desc.contains('board') || desc.contains('class');
            }
            return title.contains(keyword) || desc.contains(keyword);
          }).toList();

          if (filtered.isEmpty) {
            final emptyStateIconColor = isDark ? AppColors.textDarkSecondary : Colors.grey[400];
            final emptyStateTextColor = isDark ? AppColors.textDark : Colors.grey[600];
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_dissatisfied, size: 64, color: emptyStateIconColor),
                    const SizedBox(height: 16),
                    Text(
                      'No test series found under $categoryName category.',
                      style: TextStyle(fontSize: 16, color: emptyStateTextColor, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final category = filtered[index];
              Color badgeColor = const Color(0xFFC0C0C0); // Silver default
              if (category.badge.toLowerCase().contains('gold')) {
                badgeColor = const Color(0xFFFFD700);
              } else if (category.badge.toLowerCase().contains('free')) {
                badgeColor = Colors.green;
              }

              return _buildTestCard(
                context,
                categoryId: category.id,
                title: category.title,
                badge: category.badge,
                badgeColor: badgeColor,
                testsCount: category.testsCount,
                price: category.price.toStringAsFixed(0),
                originalPrice: category.originalPrice.toStringAsFixed(0),
                features: category.features.isEmpty 
                    ? ['Chapter-wise Tests', 'Full Length Mocks'] 
                    : category.features,
                imageUrl: category.iconUrl,
              ).animate().fade(delay: (50 * index).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          );
        },
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String categoryId,
    required String title,
    required String badge,
    required Color badgeColor,
    required String testsCount,
    required String price,
    required String originalPrice,
    required List<String> features,
    required String imageUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey[700];
    final originalPriceColor = isDark ? AppColors.textDarkSecondary : Colors.grey[400];
    final testsCountColor = isDark ? AppColors.accent : AppTheme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor == const Color(0xFFFFD700)
                          ? (isDark ? const Color(0xFFFFE066) : const Color(0xFFB8860B))
                          : badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  testsCount,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: testsCountColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹$price', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? AppColors.accent : AppTheme.secondaryColor)),
                    const SizedBox(width: 8),
                    Text(
                      '₹$originalPrice',
                      style: TextStyle(fontSize: 14, color: originalPriceColor, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature, style: TextStyle(fontSize: 13, color: secondaryTextColor))),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestSeriesDetailScreen(
                            categoryId: categoryId,
                            title: title,
                            badge: badge,
                            price: price,
                            originalPrice: originalPrice,
                            features: features,
                            badgeColor: badgeColor,
                            imageUrl: imageUrl,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Explore Series', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
