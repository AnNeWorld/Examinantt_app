import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class DoubtsScreen extends StatelessWidget {
  const DoubtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Doubt Forum', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ask a doubt CTA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_alt, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stuck on a question?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Ask our experts and get solutions quickly.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Ask', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ).animate().fade().slideY(begin: 0.1),
          
          const SizedBox(height: 24),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('My Doubts', false),
                _buildFilterChip('Maths', false),
                _buildFilterChip('Reasoning', false),
                _buildFilterChip('English', false),
              ],
            ),
          ).animate().fade().slideX(),
          
          const SizedBox(height: 24),
          
          // Doubt Feed
          _buildDoubtCard(
            studentName: 'Rahul Verma',
            time: '2 hours ago',
            subject: 'Quantitative Aptitude',
            question: 'Can someone explain the shortcut for compound interest when compounded half-yearly?',
            isAnswered: true,
            answersCount: 3,
          ),
          const SizedBox(height: 16),
          _buildDoubtCard(
            studentName: 'Priya Sharma',
            time: '5 hours ago',
            subject: 'English',
            question: 'What is the difference between "affect" and "effect" in sentence formulation?',
            isAnswered: true,
            answersCount: 1,
            isExpertAnswer: true,
          ),
          const SizedBox(height: 16),
          _buildDoubtCard(
            studentName: 'Amit Kumar',
            time: 'Just now',
            subject: 'Reasoning',
            question: 'I am not able to solve syllogism questions involving "Only a few". Help!',
            isAnswered: false,
            answersCount: 0,
          ),
        ].animate(interval: 50.ms).fade().slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {},
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildDoubtCard({
    required String studentName,
    required String time,
    required String subject,
    required String question,
    required bool isAnswered,
    required int answersCount,
    bool isExpertAnswer = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: Text(studentName[0], style: const TextStyle(color: AppTheme.darkSlate, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(subject, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: const TextStyle(fontSize: 15, color: AppTheme.darkSlate, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAnswered ? Icons.check_circle : Icons.help_outline,
                    color: isAnswered ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAnswered ? '$answersCount Answers' : 'Unanswered',
                    style: TextStyle(
                      color: isAnswered ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isExpertAnswer) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Expert Verified', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(isAnswered ? 'View Answers' : 'Write Answer', style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
