import 'package:flutter/material.dart';
import 'test_model.dart';

enum DateRangeFilter {
  allTime('All Time'),
  today('Today'),
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  thisMonth('This Month');

  final String label;
  const DateRangeFilter(this.label);
}

class SubjectAnalytics {
  final String subjectName;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int score;
  final int maxScore;
  final double scorePercentage;
  final double accuracy;
  final int totalTimeSeconds;
  final double avgTimePerQuestionSeconds;
  final String statusBadge;
  final Color badgeColor;

  SubjectAnalytics({
    required this.subjectName,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.score,
    required this.maxScore,
    required this.scorePercentage,
    required this.accuracy,
    required this.totalTimeSeconds,
    required this.avgTimePerQuestionSeconds,
    required this.statusBadge,
    required this.badgeColor,
  });
}

class AnalyticsChartPoint {
  final String label;
  final double userValue;
  final double top10Benchmark;
  final DateTime? date;
  final String? testTitle;

  AnalyticsChartPoint({
    required this.label,
    required this.userValue,
    required this.top10Benchmark,
    this.date,
    this.testTitle,
  });
}

class RecentActivityItem {
  final String id;
  final String testTitle;
  final DateTime timestamp;
  final int score;
  final int totalMarks;
  final double scorePercentage;
  final double accuracy;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final int durationSeconds;

  RecentActivityItem({
    required this.id,
    required this.testTitle,
    required this.timestamp,
    required this.score,
    required this.totalMarks,
    required this.scorePercentage,
    required this.accuracy,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.durationSeconds,
  });

  factory RecentActivityItem.fromTestResult(TestResult result) {
    final double pct = result.totalMarks > 0
        ? (result.score / result.totalMarks) * 100
        : 0.0;
    return RecentActivityItem(
      id: result.id,
      testTitle: result.testTitle,
      timestamp: result.attemptedAt,
      score: result.score,
      totalMarks: result.totalMarks,
      scorePercentage: pct.clamp(0.0, 100.0),
      accuracy: result.accuracy.clamp(0.0, 100.0),
      correctAnswers: result.correctAnswers,
      wrongAnswers: result.wrongAnswers,
      skippedAnswers: result.skippedAnswers,
      durationSeconds: result.timeTakenSeconds,
    );
  }
}

class WeeklyConsistencyWeek {
  final String weekLabel;
  final List<Color> dayColors;

  WeeklyConsistencyWeek({
    required this.weekLabel,
    required this.dayColors,
  });
}

class OverallAnalyticsData {
  final int totalTests;
  final int testsCompleted;
  final double averageScore;
  final double highestScore;
  final double averageAccuracy;
  final double peakAccuracy;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final int totalQuestions;
  final int attemptedQuestions;
  final double completionPercentage;
  final int totalDurationSeconds;
  final String formattedTotalStudyTime;
  final String formattedTimeEfficiency;
  final double estimatedPercentile;
  final String estimatedRank;
  final int currentStreakDays;
  final int longestStreakDays;
  final double weeklyConsistencyPercentage;
  final List<SubjectAnalytics> subjectAnalytics;
  final List<AnalyticsChartPoint> scoreTrend;
  final List<AnalyticsChartPoint> accuracyTrend;
  final List<AnalyticsChartPoint> speedTrend;
  final List<RecentActivityItem> recentActivities;
  final List<WeeklyConsistencyWeek> consistencyWeeks;

  OverallAnalyticsData({
    required this.totalTests,
    required this.testsCompleted,
    required this.averageScore,
    required this.highestScore,
    required this.averageAccuracy,
    required this.peakAccuracy,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.completionPercentage,
    required this.totalDurationSeconds,
    required this.formattedTotalStudyTime,
    required this.formattedTimeEfficiency,
    required this.estimatedPercentile,
    required this.estimatedRank,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.weeklyConsistencyPercentage,
    required this.subjectAnalytics,
    required this.scoreTrend,
    required this.accuracyTrend,
    required this.speedTrend,
    required this.recentActivities,
    required this.consistencyWeeks,
  });

  bool get isEmpty => totalTests == 0;
}
