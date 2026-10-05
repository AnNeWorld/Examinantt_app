import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/analytics_provider.dart';
import '../models/analytics_model.dart';
import '../models/test_model.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import 'test_series_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Performance Overview',
    'Accuracy Trend',
    'Speed Analysis',
    'Time Management',
    'Consistency',
    'Score Trend',
    'Comparative Analysis',
  ];

  final List<String> _targetExams = [
    'All Exams',
    'Banking',
    'Boards',
    'Defence exams',
    'Engineering entrance',
    'JEE Mains',
    'Medical entrance',
    'NEET',
    'Other',
    'Railways',
    'SSC',
    'SSC CGL Tier 1',
    'SSC CGL Tier 2',
    'State PCS',
    'State govt. Exam',
    'Teaching exams',
    'UPP Constable',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
      analyticsProvider.init(userProvider.user?.uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey.shade600;
    final borderColor = isDark ? AppColors.greyDark.withValues(alpha: 0.3) : Colors.grey.shade200;

    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Performance Analytics',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            actions: [
              // Target Exam Filter dropdown
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.42),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Exam: ',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.w600),
                    ),
                    Flexible(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.selectedExam,
                          isDense: true,
                          dropdownColor: cardColor,
                          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? AppColors.accent : AppTheme.primaryColor),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          selectedItemBuilder: (context) {
                            return _targetExams.map((exam) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  exam,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList();
                          },
                          items: _targetExams.map((exam) {
                            return DropdownMenuItem<String>(
                              value: exam,
                              child: Text(exam, style: TextStyle(color: textColor, fontSize: 12), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              provider.setExam(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Column(
                children: [
                  // Date range pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: DateRangeFilter.values.map((filter) {
                        final isSelected = provider.selectedDateFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => provider.setDateFilter(filter),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.accent : AppTheme.primaryColor)
                                    : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? AppColors.accent : AppTheme.primaryColor)
                                      : borderColor,
                                ),
                              ),
                              child: Text(
                                filter.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                    labelColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                    unselectedLabelColor: secondaryTextColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    dividerColor: borderColor,
                    tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ],
              ),
            ),
          ),
          body: _buildBody(context, provider, isDark, cardColor, textColor, secondaryTextColor, borderColor, userProvider.user?.uid),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    String? userId,
  ) {
    if (provider.status == AnalyticsStatus.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark ? AppColors.accent : AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your performance analytics...',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.status == AnalyticsStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.redAccent.shade200),
              const SizedBox(height: 16),
              Text(
                'Could not load analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.retry(userId),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('RETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = provider.data;
    if (provider.status == AnalyticsStatus.empty || data == null || data.isEmpty) {
      return _buildNoDataView(isDark, textColor, secondaryTextColor, provider.selectedExam);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
        _buildAccuracyTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
        _buildSpeedTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
        _buildTimeTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
        _buildConsistencyTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
        _buildScoreTrendTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
        _buildComparativeTab(data, isDark, cardColor, textColor, secondaryTextColor, borderColor),
      ],
    );
  }

  Widget _buildNoDataView(bool isDark, Color textColor, Color secondaryTextColor, String exam) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: isDark ? AppColors.accent : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Performance Analytics Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Once you start attempting mock tests of $exam, detailed analytics of your scores, speed, accuracy, and consistency will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestSeriesScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'EXPLORE TEST SERIES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PERFORMANCE OVERVIEW
  // ===========================================================================
  Widget _buildOverviewTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric KPI Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Attempted',
                  data.totalTests.toString(),
                  'Tests Completed',
                  Icons.assignment_outlined,
                  const Color(0xFF38BDF8),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Accuracy',
                  '${data.averageAccuracy.toStringAsFixed(1)}%',
                  'Overall Rate',
                  Icons.center_focus_strong,
                  const Color(0xFF10B981),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Score',
                  '${data.averageScore.toStringAsFixed(0)}%',
                  'Peak: ${data.highestScore.toStringAsFixed(0)}%',
                  Icons.military_tech_outlined,
                  const Color(0xFFA855F7),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Study Time',
                  data.formattedTotalStudyTime,
                  'Total Duration',
                  Icons.timer_outlined,
                  const Color(0xFFF59E0B),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Performance Scorecard
          _buildScorecardContainer(data, cardColor, textColor, secondaryTextColor, borderColor),
          const SizedBox(height: 14),

          // Questions Breakdown Pill
          _buildQuestionDistributionCard(data, cardColor, textColor, secondaryTextColor, borderColor),
          const SizedBox(height: 14),

          // Subject-wise Performance
          if (data.subjectAnalytics.isNotEmpty) ...[
            _buildSubjectBreakdownSection(data.subjectAnalytics, cardColor, textColor, secondaryTextColor, borderColor),
            const SizedBox(height: 14),
          ],

          // Recent Activity & Tests List
          if (data.recentActivities.isNotEmpty) ...[
            _buildRecentActivitySection(data.recentActivities, cardColor, textColor, secondaryTextColor, borderColor),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ACCURACY TREND
  // ===========================================================================
  Widget _buildAccuracyTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final spots = data.accuracyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.userValue);
    }).toList();

    final benchmarkSpots = data.accuracyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.top10Benchmark);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Accuracy',
                  '${data.averageAccuracy.toStringAsFixed(1)}%',
                  'Across all tests',
                  Icons.track_changes,
                  const Color(0xFF10B981),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Peak Accuracy',
                  '${data.peakAccuracy.toStringAsFixed(1)}%',
                  'Highest recorded',
                  Icons.stars,
                  const Color(0xFF38BDF8),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Accuracy Chart
          _buildSectionContainer(
            title: 'Accuracy Trend Over Time (%)',
            subtitle: 'Your test accuracy compared to the Top 10% benchmark',
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: borderColor, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < data.accuracyTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                data.accuracyTrend[idx].label,
                                style: TextStyle(color: secondaryTextColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}%',
                          style: TextStyle(color: secondaryTextColor, fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3.5,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      ),
                    ),
                    LineChartBarData(
                      spots: benchmarkSpots.isEmpty ? [const FlSpot(0, 0)] : benchmarkSpots,
                      isCurved: true,
                      color: const Color(0xFFFF7A00),
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildLegendRow([
            _LegendItem('Your Accuracy', const Color(0xFF10B981)),
            _LegendItem('Top 10% Benchmark', const Color(0xFFFF7A00)),
          ], textColor),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: SPEED ANALYSIS
  // ===========================================================================
  Widget _buildSpeedTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final barGroups = data.speedTrend.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.userValue,
            color: const Color(0xFF38BDF8),
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Time / Ques',
                  data.formattedTimeEfficiency,
                  'Target: < 45s',
                  Icons.speed,
                  const Color(0xFF38BDF8),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Pacing Efficiency',
                  '${(data.completionPercentage * 0.9).clamp(50.0, 98.0).toStringAsFixed(1)}%',
                  'Productive answering',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSectionContainer(
            title: 'Average Answering Time per Question (Seconds)',
            subtitle: 'Lower time per question indicates quicker problem-solving speed',
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 120,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: borderColor, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < data.speedTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                data.speedTrend[idx].label,
                                style: TextStyle(color: secondaryTextColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}s',
                          style: TextStyle(color: secondaryTextColor, fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: TIME MANAGEMENT
  // ===========================================================================
  Widget _buildTimeTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final int total = data.totalQuestions;
    final double correctPct = total > 0 ? (data.correctAnswers / total) * 100 : 0.0;
    final double wrongPct = total > 0 ? (data.wrongAnswers / total) * 100 : 0.0;
    final double skippedPct = total > 0 ? (data.skippedAnswers / total) * 100 : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Test Time',
                  data.formattedTotalStudyTime,
                  'Across all attempts',
                  Icons.access_time_filled,
                  const Color(0xFF38BDF8),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Time Utilization',
                  '${data.completionPercentage.toStringAsFixed(1)}%',
                  'Productive test time',
                  Icons.timelapse,
                  const Color(0xFF10B981),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSectionContainer(
            title: 'Answer Distribution Breakdown',
            subtitle: 'Correct vs Incorrect vs Skipped question allocation',
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF10B981),
                          value: correctPct > 0 ? correctPct : 1,
                          title: '${correctPct.toStringAsFixed(0)}%',
                          radius: 46,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFEF4444),
                          value: wrongPct > 0 ? wrongPct : 0.01,
                          title: '${wrongPct.toStringAsFixed(0)}%',
                          radius: 46,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF94A3B8),
                          value: skippedPct > 0 ? skippedPct : 0.01,
                          title: '${skippedPct.toStringAsFixed(0)}%',
                          radius: 46,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegendRow([
                  _LegendItem('Correct (${data.correctAnswers})', const Color(0xFF10B981)),
                  _LegendItem('Wrong (${data.wrongAnswers})', const Color(0xFFEF4444)),
                  _LegendItem('Skipped (${data.skippedAnswers})', const Color(0xFF94A3B8)),
                ], textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: CONSISTENCY
  // ===========================================================================
  Widget _buildConsistencyTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Current Streak',
                  '${data.currentStreakDays} Days',
                  data.currentStreakDays > 0 ? 'Active Practice' : 'Attempt a test today',
                  Icons.local_fire_department,
                  const Color(0xFFFF7A00),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Longest Streak',
                  '${data.longestStreakDays} Days',
                  'Personal record',
                  Icons.emoji_events,
                  const Color(0xFFF59E0B),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSectionContainer(
            title: 'Practice Consistency Heatmap',
            subtitle: 'Daily practice activity over the past 5 weeks',
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...data.consistencyWeeks.map((week) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            week.weekLabel,
                            style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: week.dayColors.map((color) {
                              return Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: borderColor),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Less', style: TextStyle(color: secondaryTextColor, fontSize: 9)),
                    const SizedBox(width: 4),
                    _colorIndicator(const Color(0xFF1E293B)),
                    _colorIndicator(const Color(0xFFEF4444)),
                    _colorIndicator(const Color(0xFFFBBF24)),
                    _colorIndicator(const Color(0xFF1D64D0)),
                    _colorIndicator(const Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text('More', style: TextStyle(color: secondaryTextColor, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorIndicator(Color c) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
    );
  }

  // ===========================================================================
  // TAB 6: SCORE TREND
  // ===========================================================================
  Widget _buildScoreTrendTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final spots = data.scoreTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.userValue);
    }).toList();

    final benchmarkSpots = data.scoreTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.top10Benchmark);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Score',
                  '${data.averageScore.toStringAsFixed(1)}%',
                  'Across all tests',
                  Icons.military_tech,
                  const Color(0xFF38BDF8),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Highest Score',
                  '${data.highestScore.toStringAsFixed(1)}%',
                  'Personal best',
                  Icons.emoji_events_outlined,
                  const Color(0xFF10B981),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSectionContainer(
            title: 'Score Progression (% Score)',
            subtitle: 'Test-by-test score trajectory compared with Top 10% benchmark',
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: borderColor, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < data.scoreTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                data.scoreTrend[idx].label,
                                style: TextStyle(color: secondaryTextColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}%',
                          style: TextStyle(color: secondaryTextColor, fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                      isCurved: true,
                      color: const Color(0xFF38BDF8),
                      barWidth: 3.5,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      ),
                    ),
                    LineChartBarData(
                      spots: benchmarkSpots.isEmpty ? [const FlSpot(0, 0)] : benchmarkSpots,
                      isCurved: true,
                      color: const Color(0xFFFF7A00),
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildLegendRow([
            _LegendItem('Your Score', const Color(0xFF38BDF8)),
            _LegendItem('Top 10% Benchmark', const Color(0xFFFF7A00)),
          ], textColor),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 7: COMPARATIVE ANALYSIS
  // ===========================================================================
  Widget _buildComparativeTab(
    OverallAnalyticsData data,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Percentile',
                  '${data.estimatedPercentile.toStringAsFixed(1)}%',
                  'Top ${(100 - data.estimatedPercentile).toStringAsFixed(1)}% of pool',
                  Icons.insights,
                  const Color(0xFF10B981),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Estimated Rank',
                  data.estimatedRank,
                  'Active Aspirants',
                  Icons.format_list_numbered,
                  const Color(0xFF38BDF8),
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildComparisonCard(
            title: 'Score Comparison',
            items: [
              _CompareBarItem('Your Average Score', data.averageScore, true),
              _CompareBarItem('Top 10% Average', 85.6, false),
              _CompareBarItem('Top 25% Average', 73.2, false),
              _CompareBarItem('Overall Pool Average', 61.4, false),
            ],
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 14),

          _buildComparisonCard(
            title: 'Accuracy Comparison',
            items: [
              _CompareBarItem('Your Average Accuracy', data.averageAccuracy, true),
              _CompareBarItem('Top 10% Accuracy', 88.9, false),
              _CompareBarItem('Top 25% Accuracy', 81.2, false),
              _CompareBarItem('Overall Pool Accuracy', 68.5, false),
            ],
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE SUB-WIDGETS
  // ===========================================================================
  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardContainer(
    OverallAnalyticsData data,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final rows = [
      _ScorecardRow('Average Accuracy', '${data.averageAccuracy.toStringAsFixed(1)}%', const Color(0xFF10B981), Icons.center_focus_strong),
      _ScorecardRow('Average Score', '${data.averageScore.toStringAsFixed(1)} / 100', const Color(0xFF38BDF8), Icons.military_tech_outlined),
      _ScorecardRow('Average Time / Ques', data.formattedTimeEfficiency, const Color(0xFF0EA5E9), Icons.speed),
      _ScorecardRow('Tests Analyzed', '${data.totalTests}', const Color(0xFFA855F7), Icons.assignment_outlined),
      _ScorecardRow('Estimated Percentile', '${data.estimatedPercentile.toStringAsFixed(1)}%', const Color(0xFFFF7A00), Icons.insights),
    ];

    return _buildSectionContainer(
      title: 'Performance Scorecard',
      subtitle: 'Summary metrics across all test attempts',
      cardColor: cardColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      borderColor: borderColor,
      child: Column(
        children: rows.map((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: r.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: r.color.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(r.icon, size: 16, color: r.color),
                    const SizedBox(width: 8),
                    Text(
                      r.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                    ),
                  ],
                ),
                Text(
                  r.value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: r.color),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionDistributionCard(
    OverallAnalyticsData data,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return _buildSectionContainer(
      title: 'Question Allocation Breakdown',
      subtitle: 'Total Questions: ${data.totalQuestions} • Completion Rate: ${data.completionPercentage.toStringAsFixed(0)}%',
      cardColor: cardColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      borderColor: borderColor,
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStatPill('Correct', '${data.correctAnswers}', const Color(0xFF10B981)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMiniStatPill('Wrong', '${data.wrongAnswers}', const Color(0xFFEF4444)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMiniStatPill('Skipped', '${data.skippedAnswers}', const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatPill(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdownSection(
    List<SubjectAnalytics> subjects,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return _buildSectionContainer(
      title: 'Subject-wise Performance',
      subtitle: 'Proficiency across different test subjects',
      cardColor: cardColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      borderColor: borderColor,
      child: Column(
        children: subjects.map((subj) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subj.subjectName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: subj.badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subj.statusBadge,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: subj.badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accuracy: ${subj.accuracy.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Questions: ${subj.correctCount + subj.wrongCount}/${subj.totalQuestions}',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (subj.accuracy / 100.0).clamp(0.0, 1.0),
                    backgroundColor: borderColor,
                    color: subj.badgeColor,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivitySection(
    List<RecentActivityItem> activities,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return _buildSectionContainer(
      title: 'Recent Test Attempts',
      subtitle: 'Detailed record of your latest tests and scores',
      cardColor: cardColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      borderColor: borderColor,
      child: Column(
        children: activities.take(8).map((act) {
          final dateStr = '${act.timestamp.day}/${act.timestamp.month}/${act.timestamp.year}';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_turned_in, size: 20, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act.testTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateStr • Correct: ${act.correctAnswers} • Wrong: ${act.wrongAnswers}',
                        style: TextStyle(fontSize: 10, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${act.score}/${act.totalMarks}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor),
                    ),
                    Text(
                      '${act.accuracy.toStringAsFixed(0)}% Acc',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required List<_CompareBarItem> items,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return _buildSectionContainer(
      title: title,
      subtitle: 'Your performance benchmarked against test-takers',
      cardColor: cardColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      borderColor: borderColor,
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: item.isYou ? FontWeight.bold : FontWeight.w500,
                        color: item.isYou ? (Theme.of(context).brightness == Brightness.dark ? AppColors.accent : AppTheme.primaryColor) : secondaryTextColor,
                      ),
                    ),
                    Text(
                      '${item.value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.isYou ? (Theme.of(context).brightness == Brightness.dark ? AppColors.accent : AppTheme.primaryColor) : textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.value / 100.0).clamp(0.0, 1.0),
                    backgroundColor: borderColor,
                    color: item.isYou ? const Color(0xFFFF7A00) : const Color(0xFF38BDF8),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required Widget child,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendRow(List<_LegendItem> items, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: i.color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(i.label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}

class _ScorecardRow {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  _ScorecardRow(this.label, this.value, this.color, this.icon);
}

class _CompareBarItem {
  final String label;
  final double value;
  final bool isYou;
  _CompareBarItem(this.label, this.value, this.isYou);
}
