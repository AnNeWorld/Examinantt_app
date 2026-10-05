import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../utils/app_theme.dart';
import 'pdf_viewer_screen.dart';
import 'quiz_screen.dart';

class PyqsScreen extends StatefulWidget {
  const PyqsScreen({super.key});

  @override
  State<PyqsScreen> createState() => _PyqsScreenState();
}

class _PyqsScreenState extends State<PyqsScreen> {
  String _selectedExamFilter = 'All';
  String _searchQuery = '';

    Stream<List<Map<String, dynamic>>> _getPyqsStream() {
    return FirebaseFirestore.instance.collection('resources').snapshots().map((snapshot) {
      final list = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = (data['type'] ?? '').toString().toUpperCase();
        if (type == 'PYQ' || type.contains('PYQ')) {
          final exam = (data['exam'] ?? data['examCategory'] ?? 'General').toString();
          list.add({
            'id': doc.id,
            'exam': exam,
            'year': (data['year'] ?? '').toString(),
            'title': (data['title'] ?? '').toString(),
            'shift': (data['shift'] ?? data['subtitle'] ?? 'Official Shift').toString(),
            'questions': data['questions'] ?? data['totalQuestions'] ?? 90,
            'marks': data['marks'] ?? data['totalMarks'] ?? 300,
            'duration': (data['duration'] ?? data['time'] ?? '180 Mins').toString(),
            'subjects': (data['subject'] ?? data['subjects'] ?? data['category'] ?? '').toString(),
            'pdfUrl': (data['url'] ?? data['pdfUrl'] ?? '').toString(),
            'attempts': (data['downloads'] != null ? '${data['downloads']} Attempts' : 'Official Paper'),
            'color': const Color(0xFF0070F3),
          });
        }
      }
      return list;
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF050F1E) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF0D1D38) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A68) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;

    

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history_edu_rounded, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text(
              'Previous Year Papers (PYQs)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF071428) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF071428) : Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by exam, shift, or year (e.g. 2024)...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F2448) : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Exam Filter Horizontal Chips
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: ['All', 'JEE Main', 'NEET UG', 'SSC CGL', 'CUET UG', 'NDA'].map((exam) {
                      final isSel = _selectedExamFilter == exam;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedExamFilter = exam),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0070F3) : (isDark ? const Color(0xFF0D2244) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? const Color(0xFF38BDF8) : (isDark ? const Color(0xFF1B3864) : Colors.grey.shade300),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              exam,
                              style: TextStyle(
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // PYQs List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getPyqsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading PYQs',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  );
                }
                final allPapers = snapshot.data ?? [];
                final filteredPapers = allPapers.where((paper) {
                  final exam = (paper['exam'] as String?) ?? '';
                  final matchesExam = _selectedExamFilter == 'All' ||
                      exam.toLowerCase() == _selectedExamFilter.toLowerCase();
                  final title = (paper['title'] as String?) ?? '';
                  final shift = (paper['shift'] as String?) ?? '';
                  final year = (paper['year'] as String?) ?? '';
                  final matchesQuery = _searchQuery.isEmpty ||
                      title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      shift.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exam.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      year.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesExam && matchesQuery;
                }).toList();

                if (filteredPapers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('No PYQ papers matching your filter', style: TextStyle(color: textColor, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: filteredPapers.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final paper = filteredPapers[index];
                      final Color examColor = paper['color'] as Color;

                      return Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: examColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: examColor.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        paper['exam'] as String,
                                        style: TextStyle(
                                          color: examColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        paper['year'] as String,
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  paper['attempts'] as String,
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              paper['title'] as String,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${paper['shift']} • ${paper['subjects']}',
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 10.5),
                            ),
                            const SizedBox(height: 10),

                            // Metrics Badges
                            Row(
                              children: [
                                _buildMetricChip(Icons.quiz_outlined, '${paper['questions']} Questions', isDark),
                                const SizedBox(width: 8),
                                _buildMetricChip(Icons.military_tech_outlined, '${paper['marks']} Marks', isDark),
                                const SizedBox(width: 8),
                                _buildMetricChip(Icons.timer_outlined, paper['duration'] as String, isDark),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Action Buttons
                            Row(
                              children: [
                                // View PDF Button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final item = ResourceItem(
                                        id: paper['id'] as String,
                                        title: paper['title'] as String,
                                        subtitle: paper['shift'] as String,
                                        category: paper['exam'] as String,
                                        subject: paper['subjects'] as String,
                                        type: 'PYQ Paper',
                                        fileType: 'PDF',
                                        fileSize: '4.5 MB',
                                        badge: 'OFFICIAL',
                                        badgeColorHex: '#38BDF8',
                                        downloads: paper['attempts'] as String,
                                        rating: 4.9,
                                        exam: paper['exam'] as String,
                                        price: 0.0,
                                        isPublic: true,
                                        description: 'Official ${paper['exam']} question paper.',
                                        url: paper['pdfUrl'] as String,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfViewerScreen(pdfData: item),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                                    label: const Text('View PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF38BDF8),
                                      side: const BorderSide(color: Color(0xFF1E4378)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Attempt Live Test Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QuizScreen(
                                            testName: paper['title'] as String,
                                            testId: paper['id'] as String,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                    label: const Text('Attempt CBT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0070F3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06152E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0xFF142E54) : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
