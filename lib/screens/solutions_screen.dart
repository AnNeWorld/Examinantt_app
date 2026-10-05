import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../models/test_model.dart';
import '../constants/app_colors.dart';

class SolutionsScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, int> userAnswers;

  const SolutionsScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];
    final selectedOption = widget.userAnswers[currentIndex];
    final isUnattempted = selectedOption == null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final appBarBg = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? AppColors.textDarkSecondary : Colors.grey[600];
    final barBg = isDark ? AppColors.surfaceDark : Colors.white;
    final barBorder = isDark ? AppColors.greyDark : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('Test Solutions', style: TextStyle(fontSize: 16, color: textColor)),
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (currentIndex + 1) / widget.questions.length,
              backgroundColor: isDark ? AppColors.greyDark : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.accent : AppTheme.primaryColor,
              ),
              minHeight: 4,
            ),

            // Question Overview Bar (Quick Jump)
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: barBg,
                border: Border(bottom: BorderSide(color: barBorder)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final isSelected = currentIndex == index;
                  final option = widget.userAnswers[index];
                  final isUnattempted = option == null;
                  final isCorrect =
                      !isUnattempted &&
                      option == widget.questions[index].correctOptionIndex;

                  Color bgColor;
                  Color qTextColor;
                  if (isUnattempted) {
                    bgColor = isDark ? AppColors.greyDark : Colors.grey[200]!;
                    qTextColor = isDark ? Colors.white70 : Colors.grey[700]!;
                  } else if (isCorrect) {
                    bgColor = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green[100]!;
                    qTextColor = isDark ? Colors.greenAccent : Colors.green[800]!;
                  } else {
                    bgColor = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red[100]!;
                    qTextColor = isDark ? Colors.redAccent : Colors.red[800]!;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    child: Container(
                      width: 44,
                      margin: const EdgeInsets.only(right: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: isDark ? Colors.white : AppTheme.darkSlate, width: 2)
                            : null,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: qTextColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentIndex + 1} of ${widget.questions.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subtextColor,
                          ),
                        ),
                        if (isUnattempted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Unattempted',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Question Text
                    Text(
                          question.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.5,
                          ),
                        )
                        .animate(key: ValueKey(currentIndex))
                        .fade()
                        .slideX(begin: 0.05),
                    const SizedBox(height: 32),

                    // Options
                    ...List.generate(
                      question.options.length,
                      (index) => _buildOption(index, question, selectedOption),
                    ),

                    const SizedBox(height: 24),
                    // Explanation Box
                    if (question.explanation.isNotEmpty)
                      Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.accent.withValues(alpha: 0.1)
                                  : AppTheme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.accent.withValues(alpha: 0.2)
                                    : AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: isDark ? AppColors.accent : AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.accent : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  question.explanation,
                                  style: TextStyle(
                                    height: 1.5,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate(key: ValueKey('exp_$currentIndex'))
                          .fade(delay: 300.ms)
                          .slideY(begin: 0.1),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: barBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: currentIndex > 0
                        ? () {
                            setState(() => currentIndex--);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      side: isDark ? BorderSide(color: AppColors.greyDark) : null,
                      foregroundColor: isDark ? Colors.white70 : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                  ElevatedButton(
                    onPressed: currentIndex < widget.questions.length - 1
                        ? () {
                            setState(() => currentIndex++);
                          }
                        : () {
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentIndex < widget.questions.length - 1
                          ? 'Next'
                          : 'Finish Review',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index, Question question, int? selectedOption) {
    bool isCorrectOption = index == question.correctOptionIndex;
    bool isUserSelected = index == selectedOption;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;

    Color borderColor = isDark ? AppColors.greyDark : Colors.grey.shade300;
    Color bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    IconData? icon;
    Color iconColor = Colors.transparent;

    if (isCorrectOption) {
      borderColor = Colors.green;
      bgColor = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.05);
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isUserSelected && !isCorrectOption) {
      borderColor = Colors.red;
      bgColor = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.05);
      icon = Icons.cancel;
      iconColor = Colors.red;
    }

    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: (isCorrectOption || isUserSelected) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (icon == null)
                        ? (isDark ? AppColors.greyDark : Colors.grey.shade400)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: icon != null
                    ? Icon(icon, size: 24, color: iconColor)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.options[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: (isCorrectOption || isUserSelected)
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: (isCorrectOption)
                            ? (isDark ? Colors.greenAccent : Colors.green[800])
                            : (isUserSelected
                                  ? (isDark ? Colors.redAccent : Colors.red[800])
                                  : textColor),
                      ),
                    ),
                    if (isCorrectOption || isUserSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          isCorrectOption && isUserSelected
                              ? 'Your Correct Answer'
                              : (isCorrectOption
                                    ? 'Correct Answer'
                                    : 'Wrong Answer'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCorrectOption
                                ? (isDark ? Colors.greenAccent : Colors.green[700])
                                : (isDark ? Colors.redAccent : Colors.red[700]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(key: ValueKey('opt_${currentIndex}_$index'))
        .fade(delay: (50 * index).ms)
        .slideX(begin: 0.1);
  }
}
