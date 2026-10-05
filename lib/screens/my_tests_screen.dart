import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import '../services/firestore_service.dart';
import 'test_series_screen.dart';

class MyTestsScreen extends StatelessWidget {
  const MyTestsScreen({super.key});

  Stream<Map<String, dynamic>> _getAllStatsStream() {
    return FirestoreService().getUserTestResultsStream().map((results) {
      final summary = FirestoreService().calculateStatsFromResults(results, null);
      return {
        'purchasedCount': 2,
        'availableCount': 610,
        'attemptedCount': summary.testsAttempted,
        'avgScore': summary.accuracy,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final getBackgroundColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final getTextColor = isDark ? AppColors.textDark : AppColors.text;

    return Scaffold(
      backgroundColor: getBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header area
              Text(
                'Your Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: getTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TestSeriesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'BROWSE MARKETPLACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Stats Grid
              StreamBuilder<Map<String, dynamic>>(
                stream: _getAllStatsStream(),
                builder: (context, statsSnapshot) {
                  if (statsSnapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }

                  final stats = statsSnapshot.data ?? {
                    'purchasedCount': 2,
                    'availableCount': 610,
                    'attemptedCount': 14,
                    'avgScore': 84.5
                  };
                  final purchasedCount = stats['purchasedCount'] ?? 2;
                  final availableCount = stats['availableCount'] ?? 610;
                  final testsAttempted = stats['attemptedCount'].toString();
                  final avgScore = '${(stats['avgScore'] as double).toStringAsFixed(0)}%';
                  
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        context: context,
                        title: 'TOTAL TEST SERIES',
                        value: '$purchasedCount',
                        subtitle: 'Purchased',
                        icon: Icons.menu_book,
                        iconColor: Colors.blue,
                        bgColor: Colors.blue.withValues(alpha: 0.05),
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'TESTS AVAILABLE',
                        value: '$availableCount',
                        subtitle: 'All Series',
                        icon: Icons.description_outlined,
                        iconColor: Colors.green,
                        bgColor: Colors.green.withValues(alpha: 0.05),
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'TESTS ATTEMPTED',
                        value: testsAttempted,
                        subtitle: 'Keep it up!',
                        icon: Icons.trending_up,
                        iconColor: Colors.orange,
                        bgColor: Colors.orange.withValues(alpha: 0.05),
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'AVERAGE SCORE',
                        value: avgScore,
                        subtitle: 'Across all tests',
                        icon: Icons.workspace_premium,
                        iconColor: Colors.orange,
                        bgColor: Colors.orange.withValues(alpha: 0.05),
                      ),
                    ],
                  ).animate().fade().slideY(begin: 0.1);
                }
              ),
              
              const SizedBox(height: 24),
              // Bottom Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEEP PUSHING FORWARD! 🔥',
                          style: TextStyle(
                            color: isDark ? Colors.orangeAccent : Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You\'re on the right path.\nConsistency is the key to\nsuccess.',
                          style: TextStyle(
                            color: getTextColor.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.local_fire_department,
                        size: 80,
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final getTextColor = isDark ? AppColors.textDark : AppColors.text;
    final getSecondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLight;
    final finalBgColor = isDark ? AppColors.surfaceDark : bgColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: finalBgColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColors.greyDark) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? iconColor.withValues(alpha: 0.8) : iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? iconColor.withValues(alpha: 0.8) : iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: getTextColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: getSecondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
