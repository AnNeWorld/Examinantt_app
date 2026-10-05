import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../services/firestore_service.dart';
import '../constants/app_colors.dart';
import 'test_series_detail_screen.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('My Purchases', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: scaffoldBg,
        elevation: 0,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserPurchasesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: isDark ? AppColors.greyDark : Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No purchases yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock premium courses and test packages to see them here.',
                      style: TextStyle(
                        color: isDark ? AppColors.textDarkSecondary : Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              final title = (purchase['title'] ?? 'Course Package').toString();
              final validTill = (purchase['validTill'] ?? '1 Year Validity').toString();
              final purchaseDate = (purchase['date'] ?? '').toString();
              final price = (purchase['price'] ?? '').toString();
              final id = (purchase['id'] ?? purchase['categoryId'] ?? '').toString();

              final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
              final borderColor = isDark ? AppColors.greyDark : Colors.grey.withValues(alpha: 0.2);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestSeriesDetailScreen(
                        categoryId: id,
                        title: title,
                        badge: 'Active',
                        price: price.replaceAll('₹', ''),
                        originalPrice: price.replaceAll('₹', ''),
                        features: const ['Topic Wise Tests', 'Full Mock Tests', 'Detailed Solutions'],
                        badgeColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                        imageUrl: '',
                        isPurchased: true,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                          color: isDark
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          color: isDark ? AppColors.accent : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Valid till: $validTill',
                              style: TextStyle(
                                color: isDark ? AppColors.textDarkSecondary : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (purchaseDate.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Purchased: $purchaseDate',
                                  style: TextStyle(
                                    color: isDark ? AppColors.textDarkSecondary.withValues(alpha: 0.8) : Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (price.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? AppColors.accent : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}
