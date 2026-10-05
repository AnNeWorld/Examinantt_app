import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../constants/app_colors.dart';
import 'solutions_screen.dart';

class TestResultsScreen extends StatelessWidget {
  final TestResult result;

  const TestResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subtextColor = isDark ? AppColors.textDarkSecondary : Colors.grey;
    final summaryBg = isDark ? AppColors.surfaceDark : const Color(0xFF0F172A);
    final bottomBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Test Results',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    // Trophy Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.green,
                        size: 60,
                      ),
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 24),

                    // Greeting
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final name = userProvider.user?.name ?? 'Student';
                        return Text(
                          'Great Job, $name!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have successfully completed ${result.testTitle}',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: 6),
                    Text(
                      'Attempted on ${DateFormat('dd MMM yyyy • hh:mm a').format(result.attemptedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.accent : AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                    const SizedBox(height: 28),

                    // Summary Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: summaryBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: summaryBg.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildSummaryItem(
                              Icons.stars_rounded,
                              '${result.score}/${result.totalMarks}',
                              'Score',
                            ),
                            VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                            _buildSummaryItem(
                              Icons.bar_chart_rounded,
                              '-',
                              'Rank',
                            ), // Rank is not in TestResult yet
                            VerticalDivider(
                              color: Colors.white.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                            _buildSummaryItem(
                              Icons.trending_up_rounded,
                              '${(result.accuracy > 1.0 ? result.accuracy : result.accuracy * 100).toStringAsFixed(1)}%',
                              'Accuracy',
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 40),

                    // Detailed Analysis
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Detailed Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 16),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildAnalysisCard(
                          context,
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: Colors.green,
                          title: 'Correct',
                          value: '${result.correctAnswers}',
                          index: 0,
                        ),
                        _buildAnalysisCard(
                          context,
                          icon: Icons.cancel_outlined,
                          iconColor: Colors.red,
                          title: 'Incorrect',
                          value: '${result.wrongAnswers}',
                          index: 1,
                        ),
                        _buildAnalysisCard(
                          context,
                          icon: Icons.help_outline_rounded,
                          iconColor: Colors.orange,
                          title: 'Unattempted',
                          value: '${result.skippedAnswers}',
                          index: 2,
                        ),
                        _buildAnalysisCard(
                          context,
                          icon: Icons.timer_outlined,
                          iconColor: Colors.blue,
                          title: 'Time Taken',
                          value: result.timeTakenSeconds > 0 
                              ? '${result.timeTakenSeconds ~/ 60}:${(result.timeTakenSeconds % 60).toString().padLeft(2, '0')}' 
                              : '-',
                          index: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bottomBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openTestSolutions(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: isDark ? Colors.white70 : AppTheme.darkSlate),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Solutions',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.darkSlate,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isDark ? AppColors.accent : const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(
              begin: 1,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final titleColor = isDark ? AppColors.textDarkSecondary : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final borderColor = isDark ? AppColors.greyDark : Colors.grey.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ).animate().scale(
      delay: Duration(milliseconds: 600 + (100 * index)),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }

  void _openTestSolutions(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final questions = await TestService().getQuestionsForTest(result.testId);
      if (context.mounted) {
        Navigator.pop(context); // close dialog
        if (questions.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SolutionsScreen(
                questions: questions,
                userAnswers: result.userAnswers,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load questions for this test.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading solutions: $e')));
      }
    }
  }
}
