import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../services/firestore_service.dart';

class MyPreparationScreen extends StatelessWidget {
  const MyPreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final appBarBg = isDark ? const Color(0xFF00122C) : Colors.white;

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? null : AppTheme.backgroundLight,
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF001638), Color(0xFF000F29)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Preparation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              ),
            ),
            bottom: TabBar(
              indicatorColor: const Color(0xFFFFA000),
              labelColor: const Color(0xFFFFA000),
              unselectedLabelColor: isDark ? Colors.white54 : Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'My Goals'),
                Tab(text: 'Analytics & Progress'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              GoalsTab(),
              AnalyticsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  String primaryExam = 'JEE Main 2027';
  List<Map<String, String>> otherExams = [];
  String targetYear = '2027';
  String preferredMode = 'Online';
  String prepStatus = 'Active';

  void _showOptionsBottomSheet({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A1E3F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ...options.map((opt) {
                final isSelected = opt == currentValue;
                return ListTile(
                  title: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFFA000) : (isDark ? Colors.white : AppTheme.darkSlate),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFFFFA000))
                      : null,
                  onTap: () {
                    onSelected(opt);
                    Navigator.pop(context);
                  },
                );
              }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _changePrimaryExam() {
    final allExams = ['JEE Main 2027', 'JEE Advanced 2027', 'NEET 2027', 'CUET UG 2027', 'GATE 2027', 'CAT 2027', 'CLAT 2027'];
    _showOptionsBottomSheet(
      title: 'Select Primary Exam',
      options: allExams,
      currentValue: primaryExam,
      onSelected: (val) {
        setState(() {
          primaryExam = val;
          otherExams.removeWhere((element) => element['title'] == val);
        });
      },
    );
  }

  void _addExam() {
    final availableExams = ['NEET 2027', 'CAT 2027', 'CLAT 2027', 'JEE Advanced 2027']
        .where((exam) => exam != primaryExam && !otherExams.any((e) => e['title'] == exam))
        .toList();

    if (availableExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All exams are already added!')),
      );
      return;
    }

    _showOptionsBottomSheet(
      title: 'Add Another Exam',
      options: availableExams,
      currentValue: '',
      onSelected: (val) {
        setState(() {
          otherExams.add({
            'title': val,
            'desc': 'Entrance Exam Prep',
            'badge': 'Added',
          });
        });
      },
    );
  }

  void _showOtherExamActionSheet(int index) {
    final exam = otherExams[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
              Text(
                exam['title'] ?? 'Exam Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star_rounded, color: Color(0xFFFFA000)),
                title: Text('Make Primary', style: TextStyle(color: textColor)),
                onTap: () {
                  setState(() {
                    final oldPrimary = primaryExam;
                    primaryExam = exam['title']!;
                    otherExams[index] = {
                      'title': oldPrimary,
                      'desc': 'Engineering/Previous Primary Prep',
                      'badge': 'Secondary',
                    };
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Remove Exam', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  setState(() {
                    otherExams.removeAt(index);
                  });
                  Navigator.pop(context);
                },
              ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeTargetYear() {
    _showOptionsBottomSheet(
      title: 'Select Target Year',
      options: ['2025', '2026', '2027', '2028', '2029', '2030'],
      currentValue: targetYear,
      onSelected: (val) => setState(() => targetYear = val),
    );
  }

  void _changePreferredMode() {
    _showOptionsBottomSheet(
      title: 'Select Preferred Mode',
      options: ['Online', 'Offline', 'Hybrid'],
      currentValue: preferredMode,
      onSelected: (val) => setState(() => preferredMode = val),
    );
  }

  void _changePrepStatus() {
    _showOptionsBottomSheet(
      title: 'Select Prep Status',
      options: ['Active', 'Paused', 'Completed'],
      currentValue: prepStatus,
      onSelected: (val) => setState(() => prepStatus = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // Primary Exam
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFFFA000), size: 16),
              const SizedBox(width: 6),
              Text(
                'Primary Exam',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _changePrimaryExam,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: Color(0xFFFFA000), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              primaryExam,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(fontSize: 10, color: Color(0xFFFFA000), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Engineering Entrance Exam',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: subColor),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Other Exams
          if (otherExams.isNotEmpty) ...[
            Text(
              'Other Exams',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            ...List.generate(otherExams.length, (index) {
              final exam = otherExams[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => _showOtherExamActionSheet(index),
                  borderRadius: BorderRadius.circular(20),
                  child: _buildExamItem(
                    context,
                    title: exam['title']!,
                    desc: exam['desc']!,
                    icon: exam['title']!.contains('CUET') ? Icons.book_outlined : Icons.settings_outlined,
                    iconBg: (exam['title']!.contains('CUET') ? const Color(0xFF00C6FF) : const Color(0xFF8B5CF6)).withValues(alpha: 0.1),
                    iconColor: exam['title']!.contains('CUET') ? const Color(0xFF00C6FF) : const Color(0xFF8B5CF6),
                    badgeText: exam['badge']!,
                  ),
                ),
              );
            }).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 12),
          ],

          // Add Another Exam
          InkWell(
            onTap: _addExam,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: subColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: textColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Another Exam',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text(
                          'Track multiple exams together',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: subColor),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Side Metrics/Details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildGoalMetaRow(context, Icons.calendar_month_outlined, 'Target Year', targetYear, const Color(0xFFEC4899), onTap: _changeTargetYear),
                Divider(height: 24, color: borderColor),
                _buildGoalMetaRow(context, Icons.computer_rounded, 'Preferred Mode', preferredMode, const Color(0xFF00C6FF), onTap: _changePreferredMode),
                Divider(height: 24, color: borderColor),
                _buildGoalMetaRow(context, Icons.bar_chart_rounded, 'Preparation Status', prepStatus, const Color(0xFF10B981), isStatus: true, onTap: _changePrepStatus),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // Bottom swap button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _changePrimaryExam,
              icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFFA000)),
              label: const Text(
                'Change Primary Exam',
                style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFA000), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildExamItem(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert_rounded, color: subColor),
        ],
      ),
    );
  }

  Widget _buildGoalMetaRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accent, {
    bool isStatus = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (isStatus)
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                ],
              )
            else
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: subColor, size: 16),
          ],
        ),
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getUserTestResultsStream(),
          builder: (context, snapshot) {
            final results = snapshot.data ?? [];
            final summary = FirestoreService().calculateStatsFromResults(results, user);
            final testsCount = summary.testsAttempted;
            final double accuracyVal = summary.accuracy;

            final studyTimeMin = user?.totalStudyTimeMinutes ?? 0;
            final studyTimeStr = '${studyTimeMin ~/ 60}h ${studyTimeMin % 60}m';
            final streakVal = user?.currentStreak ?? 0;
            final double progressFactor = (accuracyVal / 100).clamp(0.05, 1.0);

            return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview title and dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 14, color: subColor),
                        const SizedBox(width: 6),
                        Text('Live Analytics', style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Grid metrics cards with sparklines
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _buildSparklineCard(
                    context,
                    title: 'Tests Attempted',
                    value: '$testsCount',
                    change: testsCount > 0 ? 'Active preparation' : 'No tests yet',
                    color: const Color(0xFF3B82F6),
                    points: [0, testsCount * 0.3, testsCount * 0.6, testsCount.toDouble()],
                  ),
                  _buildSparklineCard(
                    context,
                    title: 'Avg. Accuracy',
                    value: '${accuracyVal.toStringAsFixed(1)}%',
                    change: accuracyVal > 50 ? 'Good performance' : 'Keep practicing',
                    color: const Color(0xFF10B981),
                    points: [0, accuracyVal * 0.5, accuracyVal * 0.8, accuracyVal],
                  ),
                  _buildSparklineCard(
                    context,
                    title: 'Total Study Time',
                    value: studyTimeStr,
                    change: studyTimeMin > 0 ? 'Consistent learning' : 'Start studying',
                    color: const Color(0xFF8B5CF6),
                    points: [0, studyTimeMin * 0.3, studyTimeMin * 0.7, studyTimeMin.toDouble()],
                  ),
                  _buildSparklineCard(
                    context,
                    title: 'Current Streak',
                    value: '$streakVal',
                    change: streakVal > 0 ? 'Keep it up!' : 'Start streak today',
                    color: const Color(0xFFF59E0B),
                    points: [0, streakVal * 0.4, streakVal * 0.8, streakVal.toDouble()],
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // Overall Preparation Progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Preparation Progress',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${accuracyVal.toInt()}%',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Accuracy Level',
                          style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          accuracyVal > 0 ? "Live progress tracked" : "Attempt tests to boost score",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Gradient progress bar
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progressFactor,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFA000), Color(0xFFFFCC00)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  },
);
  }

  Widget _buildSparklineCard(
    BuildContext context, {
    required String title,
    required String value,
    required String change,
    required Color color,
    required List<double> points,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  title.contains('Tests') ? Icons.assignment_rounded : 
                  title.contains('Accuracy') ? Icons.gps_fixed_rounded : 
                  title.contains('Time') ? Icons.access_time_rounded : Icons.local_fire_department_rounded,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.bold, 
                        color: change.contains('Keep') ? const Color(0xFFFFA000) : const Color(0xFF10B981),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sparkline graph
              SizedBox(
                width: 48,
                height: 24,
                child: CustomPaint(
                  painter: SparklinePainter(points, color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    
    double minVal = data[0];
    double maxVal = data[0];
    for (var val in data) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    
    final double diffY = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      // Invert Y because canvas origin is top-left
      final double y = size.height - ((data[i] - minVal) / diffY * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw area gradient under the sparkline
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.15), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}
