import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import 'test_series_screen.dart';
import 'resources_screen.dart';
import 'bookmarks_screen.dart';
import 'my_purchases_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'subscription_screen.dart';
import 'current_affairs_screen.dart';
import 'live_classes_screen.dart';
import 'doubts_screen.dart';
import 'job_alerts_screen.dart';
import 'syllabus_screen.dart';
import 'leaderboard_screen.dart';
import 'mentorship_screen.dart';
import 'community_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    _buildStatsScroll(),
                    const SizedBox(height: 24),
                    _buildDailyGoalCard(context),
                    const SizedBox(height: 24),
                    _buildPerformanceOverview(),
                    const SizedBox(height: 24),
                    _buildSubjectWisePerformance(context),
                    const SizedBox(height: 24),
                    _buildContinuePreparation(context),
                    const SizedBox(height: 24),
                    _buildRecentActivity(context),
                    const SizedBox(height: 24),
                    _buildQuickAccess(context),
                    const SizedBox(height: 16),
                    _buildGoldPromoBanner(context),
                    const SizedBox(height: 24),
                    _buildFooterFeatures(),
                    const SizedBox(height: 40),
                  ]
                  .animate(interval: 50.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Welcome back, ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        TextSpan(
                          text: 'Ankur! 👋 ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: '(SSC)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Track your progress and continue your learning journey.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '17 July 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsScroll() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildStatCard(
            'TESTS ATTEMPTED',
            '3',
            'Total Tests',
            Icons.assignment_outlined,
            AppTheme.primaryColor,
          ),
          _buildStatCard(
            'AVERAGE SCORE',
            '68/100',
            'Across all tests',
            Icons.score,
            AppTheme.secondaryColor,
          ),
          _buildStatCard(
            'ACCURACY',
            '86%',
            'Correct questions %',
            Icons.track_changes,
            Colors.red,
          ),
          _buildStatCard(
            'TOTAL STUDY TIME',
            '4h 15m',
            'Time spent in test',
            Icons.timer_outlined,
            Colors.purple,
          ),
          _buildStatCard(
            'CURRENT STREAK',
            '5 Days',
            'Keep it up! 🔥',
            Icons.local_fire_department,
            AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Builder(
      builder: (context) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const Spacer(),
                  Text(
                    'No attempts yet',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate blue
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestSeriesScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reset daily at midnight',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 0.5,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: AppTheme.secondaryColor,
                ),
              ),
              const Text(
                '50%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '1 / 2 Tests Completed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const QuizScreen(testName: 'Daily Mock Test'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'START TEST NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    String selectedPeriod = 'This Week';
    return StatefulBuilder(
      builder: (context, setState) {
        return _buildContainerCard(
          title: 'Performance Overview',
          subtitle: 'Weekly metrics analysis',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  selectedPeriod = value;
                });
              },
              offset: const Offset(0, 30),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedPeriod, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'This Week',
                  child: Text('This Week', style: TextStyle(fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 'Last Week',
                  child: Text('Last Week', style: TextStyle(fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 'This Month',
                  child: Text('This Month', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Chart Mockup
              SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: ChartGridPainter(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: selectedPeriod == 'This Month'
                        ? [
                            _buildChartBar(0.7, 0.8, 'Wk 1'),
                            _buildChartBar(0.6, 0.75, 'Wk 2'),
                            _buildChartBar(0.85, 0.82, 'Wk 3'),
                            _buildChartBar(0.9, 0.88, 'Wk 4'),
                          ]
                        : selectedPeriod == 'Last Week'
                        ? [
                            _buildChartBar(0.5, 0.6, 'Mon'),
                            _buildChartBar(0.6, 0.55, 'Tue'),
                            _buildChartBar(0.7, 0.8, 'Wed'),
                            _buildChartBar(0.65, 0.7, 'Thu'),
                            _buildChartBar(0.8, 0.75, 'Fri'),
                            _buildChartBar(0.9, 0.85, 'Sat'),
                            _buildChartBar(0.85, 0.9, 'Sun'),
                          ]
                        : [
                            _buildChartBar(0.6, 0.75, 'Mon'),
                            _buildChartBar(0.8, 0.65, 'Tue'),
                            _buildChartBar(0.5, 0.85, 'Wed'),
                            _buildChartBar(0.9, 0.80, 'Thu'),
                            _buildChartBar(0.7, 0.70, 'Fri'),
                            _buildChartBar(0.85, 0.90, 'Sat'),
                            _buildChartBar(0.65, 0.75, 'Sun'),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Score (%)', Colors.blue),
                  const SizedBox(width: 20),
                  _buildLegendItem('Accuracy (%)', Colors.orange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectWisePerformance(BuildContext context) {
    return _buildContainerCard(
      title: 'Subject Wise Performance',
      subtitle: 'Average accuracy per subject',
      trailing: GestureDetector(
        onTap: () => _showAllSubjectsPerformance(context),
        child: const Text(
          'View All',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: 0.72,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                  color: AppTheme.secondaryColor,
                ),
              ),
              const Text(
                '72%\nOverall',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubjectRow('Quantitative Aptitude', Colors.blue, '65%'),
                const SizedBox(height: 8),
                _buildSubjectRow('Reasoning Ability', Colors.orange, '80%'),
                const SizedBox(height: 8),
                _buildSubjectRow('English Language', Colors.green, '71%'),
                const SizedBox(height: 8),
                _buildSubjectRow('General Awareness', Colors.red, '0%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String subject, Color color, String percent) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subject,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          percent,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildContinuePreparation(BuildContext context) {
    return _buildContainerCard(
      title: 'Continue Your Preparation',
      subtitle: 'Resume where you left off',
      trailing: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TestSeriesScreen()),
          );
        },
        child: const Text(
          'View All',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SSC CGL Mock Test 4',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '25 Questions • 60 Mins',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'In Progress',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.4, // 40% completed
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const QuizScreen(testName: 'SSC CGL Mock Test 4'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Resume Test',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return _buildContainerCard(
      title: 'Recent Test Activity',
      subtitle: 'Your recent test performance',
      trailing: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TestSeriesScreen()),
          );
        },
        child: const Text(
          'View All',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            _buildRecentTestItem('SSC CGL Mock Test 3', '24/80', '85.4%'),
            const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
            _buildRecentTestItem('Banking PO Prelims', '65/100', '92.1%'),
            const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
            _buildRecentTestItem('Railway NTPC Mini Mock', '30/40', '88.5%'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTestItem(String title, String score, String percentile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Score: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    score,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Percentile: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    percentile,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ],
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildQuickAccessIcon(
                context,
                Icons.assignment,
                'Test Series',
                Colors.orange,
                const TestSeriesScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.play_circle_fill,
                'Live Classes',
                Colors.red,
                const LiveClassesScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.public,
                'News & CA',
                Colors.blue,
                const CurrentAffairsScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.psychology_alt,
                'Doubts',
                Colors.purple,
                const DoubtsScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.file_copy,
                'PDFs / PYQs',
                Colors.green,
                const ResourcesScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.bookmark,
                'Bookmarks',
                Colors.pink,
                const BookmarksScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.work,
                'Job Alerts',
                Colors.teal,
                const JobAlertsScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.menu_book,
                'Syllabus',
                Colors.indigo,
                const SyllabusScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.emoji_events,
                'Leaderboard',
                Colors.amber,
                const LeaderboardScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.people_alt,
                'Mentorship',
                Colors.cyan,
                const MentorshipScreen(),
              ),
              _buildQuickAccessIcon(
                context,
                Icons.forum,
                'Community',
                Colors.deepOrange,
                const CommunityScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Widget destination,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldPromoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Examinantt Gold Test Series',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium access. Detailed analysis. Top rank. Your success.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'EXPLORE NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.workspace_premium,
            color: AppTheme.secondaryColor,
            size: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterFeatures() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureBadge(
                  context,
                  Icons.quiz,
                  '1500+',
                  'Tests Available',
                ),
                const SizedBox(width: 24),
                _buildFeatureBadge(
                  context,
                  Icons.school,
                  '50+',
                  'Exams Covered',
                ),
                const SizedBox(width: 24),
                _buildFeatureBadge(
                  context,
                  Icons.analytics,
                  'Detailed',
                  'Performance Analysis',
                ),
                const SizedBox(width: 24),
                _buildFeatureBadge(
                  context,
                  Icons.auto_awesome,
                  'AI-Powered',
                  'Smart Recommendations',
                ),
                const SizedBox(width: 24),
                _buildFeatureBadge(
                  context,
                  Icons.headset_mic,
                  '24x7',
                  'Student Support',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureBadge(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.secondaryColor, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildContainerCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildChartBar(double scoreRatio, double accuracyRatio, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: 120 * scoreRatio,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
            Container(
              width: 8,
              height: 120 * accuracyRatio,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showAllSubjectsPerformance(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Subjects Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSubjectDetailRow(
                    'Quantitative Aptitude',
                    Colors.blue,
                    '65%',
                    'Good',
                  ),
                  _buildSubjectDetailRow(
                    'Reasoning Ability',
                    Colors.orange,
                    '80%',
                    'Excellent',
                  ),
                  _buildSubjectDetailRow(
                    'English Language',
                    Colors.green,
                    '71%',
                    'Very Good',
                  ),
                  _buildSubjectDetailRow(
                    'General Awareness',
                    Colors.red,
                    '45%',
                    'Needs Improvement',
                  ),
                  _buildSubjectDetailRow(
                    'Computer Knowledge',
                    Colors.purple,
                    '85%',
                    'Excellent',
                  ),
                  _buildSubjectDetailRow(
                    'Data Interpretation',
                    Colors.teal,
                    '60%',
                    'Good',
                  ),
                  _buildSubjectDetailRow(
                    'Current Affairs',
                    Colors.indigo,
                    '55%',
                    'Average',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDetailRow(
    String name,
    Color color,
    String accuracy,
    String remark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                accuracy,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remark,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * (size.height / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
