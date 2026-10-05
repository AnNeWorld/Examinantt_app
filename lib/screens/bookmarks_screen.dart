import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('Bookmarks', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: scaffoldBg,
        elevation: 0,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: !isLoggedIn
          ? Center(
              child: Text(
                'Please sign in to view your bookmarks.',
                style: TextStyle(fontSize: 16, color: isDark ? AppColors.textDarkSecondary : Colors.grey),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getBookmarksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 80, color: isDark ? AppColors.greyDark : Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No Bookmarks Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can bookmark questions during your mock tests to review them later.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.textDarkSecondary : Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final bookmarks = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookmarks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    final questionId = bookmark['questionId']?.toString() ?? '';
                    final questionText = bookmark['questionText']?.toString() ?? 'No Question';
                    final subject = bookmark['subject']?.toString() ?? 'General';
                    final testName = bookmark['testName']?.toString() ?? 'Mock Test';
                    final correctAnswer = bookmark['correctAnswer']?.toString() ?? 'N/A';

                    return _buildBookmarkItem(
                      context,
                      questionId: questionId,
                      question: questionText,
                      subject: subject,
                      testName: testName,
                      answer: correctAnswer,
                    ).animate(delay: (50 * index).ms).fade().slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                  },
                );
              },
            ),
    );
  }

  Widget _buildBookmarkItem(
    BuildContext context, {
    required String questionId,
    required String question,
    required String subject,
    required String testName,
    required String answer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.greyDark : Colors.grey.shade200;
    final tagBg = isDark ? AppColors.greyDark : const Color(0xFFF1F5F9);
    final tagTextColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final questionColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final answerBg = isDark ? AppColors.backgroundDark : const Color(0xFFEFF6FF);
    final answerLabelColor = isDark ? AppColors.accent : const Color(0xFF2563EB);
    final answerTextColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tagTextColor,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.bookmark, color: isDark ? AppColors.accent : const Color(0xFF2563EB), size: 22),
                onPressed: () async {
                  await FirestoreService().removeBookmark(questionId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed bookmark'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: questionColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: answerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: answerLabelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: answerTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  testName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
