import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/test_model.dart';
import 'solutions_screen.dart';
import '../constants/app_colors.dart';

class QuizResultScreen extends StatelessWidget {
  final String userName;
  final String testName;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unattempted;
  final String timeTaken;
  final List<Question> questions;
  final Map<int, int> userAnswers;

  const QuizResultScreen({
    super.key,
    required this.userName,
    required this.testName,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unattempted,
    required this.timeTaken,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final textColor = isDark ? AppColors.textDark : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey[600]!;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.greyDark : Colors.grey.withOpacity(0.2);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Congratulatory Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, size: 60, color: Colors.green),
                  ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  Text(
                    'Great Job, $userName!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ).animate().fade().slideY(),
                  const SizedBox(height: 8),
                  Text(
                    'You have successfully completed $testName',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  ).animate().fade().slideY(),
                  const SizedBox(height: 6),
                  Text(
                    'Completed on ${DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.accent : AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fade().slideY(),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [AppColors.accent, AppColors.accent.withValues(alpha: 0.8)] 
                      : [AppTheme.primaryColor, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.accent : AppTheme.primaryColor).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildScoreMetric('Score', '$score/${totalQuestions * 2}', Icons.stars)),
                  Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildScoreMetric('Accuracy', '${((score / (totalQuestions * 2)) * 100).clamp(0, 100).toStringAsFixed(0)}%', Icons.check_circle_outline)),
                  Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildScoreMetric('Percentile', '${(score / (totalQuestions * 2) * 100).toStringAsFixed(1)}%', Icons.trending_up)), // Dynamic percentile
                ],
              ),
            ).animate().fade().slideX(),
            const SizedBox(height: 32),

            // Detailed Analytics
            Text(
              'Detailed Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildAnalysisCard('Correct', '$correctAnswers', Colors.green, Icons.check_circle_outline, cardColor, borderColor, textColor, secondaryTextColor),
                _buildAnalysisCard('Incorrect', '$incorrectAnswers', Colors.red, Icons.cancel_outlined, cardColor, borderColor, textColor, secondaryTextColor),
                _buildAnalysisCard('Unattempted', '$unattempted', Colors.orange, Icons.help_outline, cardColor, borderColor, textColor, secondaryTextColor),
                _buildAnalysisCard('Time Taken', timeTaken, Colors.blue, Icons.timer_outlined, cardColor, borderColor, textColor, secondaryTextColor),
              ],
            ).animate().fade().scale(),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SolutionsScreen(
                            questions: questions,
                            userAnswers: userAnswers,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? AppColors.accent : AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                    ),
                    child: const Text('View Solutions', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to dashboard
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(String label, String value, Color color, IconData icon, Color cardColor, Color borderColor, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}
