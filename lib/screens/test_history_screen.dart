import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../providers/user_provider.dart';
import '../constants/app_colors.dart';
import 'test_results_screen.dart';

class TestHistoryScreen extends StatelessWidget {
  const TestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final appBarBg = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? AppColors.greyDark : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('Test History', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final userId = userProvider.user?.uid;
          if (userId == null) {
            return Center(
              child: Text(
                'Login to see your test history.',
                style: TextStyle(color: isDark ? AppColors.textDarkSecondary : Colors.black87),
              ),
            );
          }

          return StreamBuilder<List<TestResult>>(
            // Pass limit: null to fetch all test results
            stream: TestService().getRecentTestResults(userId, limit: null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: isDark ? Colors.redAccent : Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No test history available.',
                    style: TextStyle(color: isDark ? AppColors.textDarkSecondary : Colors.grey, fontSize: 16),
                  ),
                );
              }

              final results = snapshot.data!;
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: results.length,
                separatorBuilder: (context, index) => Divider(height: 32, color: dividerColor),
                itemBuilder: (context, index) {
                  final result = results[index];
                  final formattedDate = DateFormat(
                    'MMM d, yyyy - h:mm a',
                  ).format(result.attemptedAt);

                  return _buildHistoryItem(context, result, formattedDate);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    TestResult result,
    String formattedDate,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subtextColor = isDark ? AppColors.textDarkSecondary : Colors.grey[600];
    final scoreColor = isDark ? AppColors.accent : AppTheme.primaryColor;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestResultsScreen(result: result),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in,
                color: isDark ? AppColors.accent : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.testTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: subtextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 12,
                        color: subtextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Accuracy: ${result.accuracy.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.score}/${result.totalMarks}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
