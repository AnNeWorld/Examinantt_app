import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBookmarkItem(
            'Q. What is the capital of Australia?',
            'Geography',
            'SSC CGL Mock Test 3',
            'Canberra',
          ),
          const SizedBox(height: 12),
          _buildBookmarkItem(
            'Q. If x + 1/x = 5, then find the value of x^2 + 1/x^2',
            'Algebra',
            'SSC CHSL Previous Year',
            '23',
          ),
          const SizedBox(height: 12),
          _buildBookmarkItem(
            'Q. Who is known as the Missile Man of India?',
            'General Knowledge',
            'RRB NTPC Set 1',
            'Dr. A.P.J. Abdul Kalam',
          ),
          const SizedBox(height: 12),
          _buildBookmarkItem(
            'Q. A train running at the speed of 60 km/hr crosses a pole in 9 seconds. What is the length of the train?',
            'Time & Distance',
            'Banking IBPS PO Mock',
            '150 metres',
          ),
        ].animate(interval: 50.ms).fade().slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildBookmarkItem(String question, String subject, String testName, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // slate-100
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569), // slate-600
                  ),
                ),
              ),
              const Icon(Icons.bookmark, color: Color(0xFF2563EB), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B), // slate-800
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correct Answer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB), // primary color
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B), // dark slate
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
              Text(
                testName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
