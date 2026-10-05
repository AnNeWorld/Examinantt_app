import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../models/analytics_model.dart';
import 'firestore_service.dart';

class AnalyticsService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Resolves the effective user ID reliably
  Future<String> resolveUserId([String? explicitUid]) async {
    if (explicitUid != null && explicitUid.isNotEmpty && explicitUid != 'guest') {
      return explicitUid;
    }
    return await FirestoreService.getResolvedUid();
  }

  /// Streams all real test results for the user from Firestore
  /// Merges `users/{uid}/test_results`, `users/{uid}/attempts`, and root `test_results`
  Stream<List<TestResult>> getUserTestResultsStream(String? userId) {
    if (userId == null || userId.isEmpty || userId == 'guest') {
      return Stream.fromFuture(resolveUserId(userId)).asyncExpand((resolvedUid) {
        if (resolvedUid.isEmpty) return Stream.value(<TestResult>[]);
        return _buildMergedStream(resolvedUid);
      });
    }
    return _buildMergedStream(userId);
  }

  Stream<List<TestResult>> _buildMergedStream(String uid) {
    final controller = StreamController<List<TestResult>>.broadcast();

    List<TestResult> fromUserSubcoll = [];
    List<TestResult> fromAttemptsSubcoll = [];
    List<TestResult> fromRootColl = [];

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, TestResult> mergedMap = {};

      for (final r in fromUserSubcoll) {
        mergedMap[r.id] = r;
      }
      for (final r in fromAttemptsSubcoll) {
        mergedMap[r.id] = r;
      }
      for (final r in fromRootColl) {
        mergedMap[r.id] = r;
      }

      final list = mergedMap.values.toList();
      list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
      controller.add(list);
    }

    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;

    try {
      sub1 = _db
          .collection('users')
          .doc(uid)
          .collection('test_results')
          .snapshots()
          .listen(
        (snap) {
          fromUserSubcoll = snap.docs
              .map((doc) => TestResult.fromMap(doc.data(), doc.id))
              .toList();
          emitMerged();
        },
        onError: (_) {},
      );
    } catch (_) {}

    try {
      sub2 = _db
          .collection('users')
          .doc(uid)
          .collection('attempts')
          .snapshots()
          .listen(
        (snap) {
          fromAttemptsSubcoll = snap.docs
              .map((doc) => TestResult.fromMap(doc.data(), doc.id))
              .toList();
          emitMerged();
        },
        onError: (_) {},
      );
    } catch (_) {}

    try {
      sub3 = _db
          .collection('test_results')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .listen(
        (snap) {
          fromRootColl = snap.docs
              .map((doc) => TestResult.fromMap(doc.data(), doc.id))
              .toList();
          emitMerged();
        },
        onError: (_) {},
      );
    } catch (_) {}

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
      sub3?.cancel();
    };

    return controller.stream;
  }

  /// Filters test results by exam category/name
  List<TestResult> filterByExam(List<TestResult> results, String exam) {
    if (exam.isEmpty || exam.toLowerCase() == 'all exams' || exam.toLowerCase() == 'all') {
      return results;
    }
    final examLower = exam.toLowerCase();
    if (examLower == 'other') {
      return results;
    }

    return results.where((result) {
      final titleLower = result.testTitle.toLowerCase();
      if (examLower == 'ssc') {
        return titleLower.contains('ssc');
      } else if (examLower == 'ssc cgl tier 1') {
        return titleLower.contains('ssc cgl') && (titleLower.contains('tier 1') || titleLower.contains('tier-1'));
      } else if (examLower == 'ssc cgl tier 2') {
        return titleLower.contains('ssc cgl') && (titleLower.contains('tier 2') || titleLower.contains('tier-2'));
      } else if (examLower == 'banking') {
        return titleLower.contains('bank') || titleLower.contains('sbi') || titleLower.contains('ibps') || titleLower.contains('clerk') || titleLower.contains('po');
      } else if (examLower == 'railways') {
        return titleLower.contains('railway') || titleLower.contains('rrb') || titleLower.contains('ntpc') || titleLower.contains('alp');
      } else if (examLower == 'upp constable') {
        return titleLower.contains('upp') || titleLower.contains('constable') || titleLower.contains('police');
      } else if (examLower == 'jee mains' || examLower == 'jee') {
        return titleLower.contains('jee') || titleLower.contains('iit');
      } else if (examLower == 'neet') {
        return titleLower.contains('neet') || titleLower.contains('medical');
      } else {
        final words = examLower.split(' ');
        return words.any((word) => word.length > 2 && titleLower.contains(word));
      }
    }).toList();
  }

  /// Filters test results by date range
  List<TestResult> filterByDate(List<TestResult> results, DateRangeFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case DateRangeFilter.allTime:
        return results;
      case DateRangeFilter.today:
        return results.where((r) {
          final d = r.attemptedAt;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
      case DateRangeFilter.last7Days:
        final limit = now.subtract(const Duration(days: 7));
        return results.where((r) => r.attemptedAt.isAfter(limit)).toList();
      case DateRangeFilter.last30Days:
        final limit = now.subtract(const Duration(days: 30));
        return results.where((r) => r.attemptedAt.isAfter(limit)).toList();
      case DateRangeFilter.thisMonth:
        return results.where((r) {
          final d = r.attemptedAt;
          return d.year == now.year && d.month == now.month;
        }).toList();
    }
  }

  /// Calculates dynamic Overall Analytics directly from real Firebase records
  OverallAnalyticsData getOverallAnalytics(
    List<TestResult> allResults, {
    DateRangeFilter dateFilter = DateRangeFilter.allTime,
    String targetExam = 'All Exams',
  }) {
    final examFiltered = filterByExam(allResults, targetExam);
    final results = filterByDate(examFiltered, dateFilter);

    if (results.isEmpty) {
      return OverallAnalyticsData(
        totalTests: 0,
        testsCompleted: 0,
        averageScore: 0.0,
        highestScore: 0.0,
        averageAccuracy: 0.0,
        peakAccuracy: 0.0,
        correctAnswers: 0,
        wrongAnswers: 0,
        skippedAnswers: 0,
        totalQuestions: 0,
        attemptedQuestions: 0,
        completionPercentage: 0.0,
        totalDurationSeconds: 0,
        formattedTotalStudyTime: '0 mins',
        formattedTimeEfficiency: '--',
        estimatedPercentile: 0.0,
        estimatedRank: '--',
        currentStreakDays: 0,
        longestStreakDays: 0,
        weeklyConsistencyPercentage: 0.0,
        subjectAnalytics: [],
        scoreTrend: [],
        accuracyTrend: [],
        speedTrend: [],
        recentActivities: [],
        consistencyWeeks: [],
      );
    }

    final int totalTests = results.length;
    final int testsCompleted = totalTests;

    int totalScore = 0;
    int totalMaxScore = 0;
    int totalCorrect = 0;
    int totalWrong = 0;
    int totalSkipped = 0;
    int totalDuration = 0;
    double highestScorePct = 0.0;
    double peakAccuracy = 0.0;

    for (final r in results) {
      totalScore += r.score;
      totalMaxScore += r.totalMarks;
      totalCorrect += r.correctAnswers;
      totalWrong += r.wrongAnswers;
      totalSkipped += r.skippedAnswers;
      totalDuration += r.timeTakenSeconds;

      final double pct = r.totalMarks > 0 ? (r.score / r.totalMarks) * 100 : 0.0;
      if (pct > highestScorePct) highestScorePct = pct;
      if (r.accuracy > peakAccuracy) peakAccuracy = r.accuracy;
    }

    final int totalQ = totalCorrect + totalWrong + totalSkipped;
    final int attemptedQ = totalCorrect + totalWrong;
    final double avgScore = totalMaxScore > 0 ? (totalScore / totalMaxScore) * 100 : 0.0;
    final double avgAccuracy = attemptedQ > 0 ? (totalCorrect / attemptedQ) * 100 : (totalQ > 0 ? (totalCorrect / totalQ) * 100 : 0.0);
    final double completionPct = totalQ > 0 ? (attemptedQ / totalQ) * 100 : 100.0;

    // Study time formatting
    String studyTimeFormatted = '0 mins';
    if (totalDuration > 0) {
      final hours = totalDuration ~/ 3600;
      final minutes = (totalDuration % 3600) ~/ 60;
      if (hours > 0) {
        studyTimeFormatted = '${hours}h ${minutes}m';
      } else {
        studyTimeFormatted = '$minutes mins';
      }
    }

    // Time efficiency formatting
    String timeEfficiencyFormatted = '--';
    if (attemptedQ > 0 && totalDuration > 0) {
      final double secPerQ = totalDuration / attemptedQ;
      if (secPerQ < 60) {
        timeEfficiencyFormatted = '${secPerQ.round()}s/q';
      } else {
        final m = secPerQ ~/ 60;
        final s = (secPerQ % 60).round();
        timeEfficiencyFormatted = '${m}m ${s}s/q';
      }
    }

    // Percentile & Rank estimations derived dynamically from score
    final double clampedScore = avgScore.clamp(0.0, 100.0);
    final double percentile = (clampedScore * 0.9 + 10.0).clamp(1.0, 99.9);
    final int poolSize = 25842;
    final int estimatedRankNum = ((1 - (percentile / 100.0)) * poolSize).round().clamp(1, poolSize);
    final String estimatedRankStr = '${_formatNumber(estimatedRankNum)} / ${_formatNumber(poolSize)}';

    // Streak and consistency
    final streakInfo = _calculateStreaks(results);

    // Subject breakdown
    final subjectAnalyticsList = getSubjectPerformance(results);

    // Charts
    final scoreTrendList = getScoreTrend(results);
    final accuracyTrendList = _getAccuracyTrend(results);
    final speedTrendList = _getSpeedTrend(results);

    // Recent activity
    final recentActivitiesList = results.map((r) => RecentActivityItem.fromTestResult(r)).toList();

    // 5-week heatmap
    final consistencyWeeksList = _generateConsistencyHeatmap(results);

    return OverallAnalyticsData(
      totalTests: totalTests,
      testsCompleted: testsCompleted,
      averageScore: double.parse(avgScore.toStringAsFixed(1)),
      highestScore: double.parse(highestScorePct.toStringAsFixed(1)),
      averageAccuracy: double.parse(avgAccuracy.toStringAsFixed(1)),
      peakAccuracy: double.parse(peakAccuracy.toStringAsFixed(1)),
      correctAnswers: totalCorrect,
      wrongAnswers: totalWrong,
      skippedAnswers: totalSkipped,
      totalQuestions: totalQ,
      attemptedQuestions: attemptedQ,
      completionPercentage: double.parse(completionPct.toStringAsFixed(1)),
      totalDurationSeconds: totalDuration,
      formattedTotalStudyTime: studyTimeFormatted,
      formattedTimeEfficiency: timeEfficiencyFormatted,
      estimatedPercentile: double.parse(percentile.toStringAsFixed(1)),
      estimatedRank: estimatedRankStr,
      currentStreakDays: streakInfo.currentStreak,
      longestStreakDays: streakInfo.longestStreak,
      weeklyConsistencyPercentage: streakInfo.weeklyConsistency,
      subjectAnalytics: subjectAnalyticsList,
      scoreTrend: scoreTrendList,
      accuracyTrend: accuracyTrendList,
      speedTrend: speedTrendList,
      recentActivities: recentActivitiesList,
      consistencyWeeks: consistencyWeeksList,
    );
  }

  int _safeInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
    }
    return fallback;
  }

  /// Calculates dynamic Subject-wise Performance from test results
  List<SubjectAnalytics> getSubjectPerformance(List<TestResult> results) {
    if (results.isEmpty) return [];

    final Map<String, _SubjectAccumulator> accumulators = {};

    for (final r in results) {
      if (r.subjectBreakdown.isNotEmpty) {
        r.subjectBreakdown.forEach((subjKey, rawVal) {
          final subjName = subjKey.toString().trim();
          if (subjName.isEmpty) return;

          accumulators.putIfAbsent(subjName, () => _SubjectAccumulator(subjName));
          final acc = accumulators[subjName]!;

          if (rawVal is Map) {
            final dynamic rawTotal = rawVal['total'] ?? rawVal['totalQuestions'] ?? rawVal['questions'];
            final dynamic rawCorrect = rawVal['correct'] ?? rawVal['correctAnswers'];
            final dynamic rawWrong = rawVal['wrong'] ?? rawVal['wrongAnswers'];
            final dynamic rawSkipped = rawVal['skipped'] ?? rawVal['unattempted'];
            final dynamic rawScore = rawVal['score'];
            final dynamic rawMax = rawVal['maxScore'];
            final dynamic rawTime = rawVal['timeSpent'] ?? rawVal['duration'];

            final int t = _safeInt(rawTotal, 0);
            final int c = _safeInt(rawCorrect, 0);
            final int w = _safeInt(rawWrong, 0);
            final int s = _safeInt(rawSkipped, (t > (c + w)) ? (t - (c + w)) : 0);
            final int sc = _safeInt(rawScore, c * 2);
            final int m = _safeInt(rawMax, t > 0 ? t * 2 : 100);
            final int time = _safeInt(rawTime, 0);

            acc.totalQuestions += t > 0 ? t : (c + w + s);
            acc.correctCount += c;
            acc.wrongCount += w;
            acc.skippedCount += s;
            acc.score += sc;
            acc.maxScore += m > 0 ? m : (t > 0 ? t * 2 : 100);
            acc.totalTimeSeconds += time;
          } else if (rawVal is num) {
            acc.score += rawVal.toInt();
            acc.maxScore += 100;
            acc.totalQuestions += 25;
            acc.correctCount += (rawVal.toDouble() / 4).round();
          } else if (rawVal != null) {
            final n = num.tryParse(rawVal.toString());
            if (n != null) {
              acc.score += n.toInt();
              acc.maxScore += 100;
              acc.totalQuestions += 25;
              acc.correctCount += (n.toDouble() / 4).round();
            }
          }
        });
      }
    }

    if (accumulators.isEmpty) {
      // Derive default standard breakdown if test results lack subject breakdowns
      final Map<String, double> defaultWeights = {
        'Quantitative Aptitude': 0.30,
        'Reasoning Ability': 0.30,
        'General Awareness': 0.20,
        'English Language': 0.20,
      };

      int allCorrect = results.fold(0, (total, r) => total + r.correctAnswers);
      int allWrong = results.fold(0, (total, r) => total + r.wrongAnswers);
      int allSkipped = results.fold(0, (total, r) => total + r.skippedAnswers);
      int allScore = results.fold(0, (total, r) => total + r.score);
      int allMax = results.fold(0, (total, r) => total + r.totalMarks);
      int allTime = results.fold(0, (total, r) => total + r.timeTakenSeconds);

      return defaultWeights.entries.map((e) {
        final w = e.value;
        final c = (allCorrect * w).round();
        final wr = (allWrong * w).round();
        final sk = (allSkipped * w).round();
        final t = c + wr + sk;
        final sc = (allScore * w).round();
        final mx = (allMax * w).round();
        final tm = (allTime * w).round();
        final acc = (c + wr) > 0 ? (c / (c + wr)) * 100 : 0.0;
        final pct = mx > 0 ? (sc / mx) * 100 : 0.0;

        return _buildSubjectAnalytics(
          subjectName: e.key,
          totalQuestions: t,
          correctCount: c,
          wrongCount: wr,
          skippedCount: sk,
          score: sc,
          maxScore: mx,
          scorePercentage: pct,
          accuracy: acc,
          totalTimeSeconds: tm,
        );
      }).toList();
    }

    return accumulators.values.map((a) {
      final double acc = (a.correctCount + a.wrongCount) > 0
          ? (a.correctCount / (a.correctCount + a.wrongCount)) * 100
          : 0.0;
      final double pct = a.maxScore > 0 ? (a.score / a.maxScore) * 100 : 0.0;
      return _buildSubjectAnalytics(
        subjectName: a.subjectName,
        totalQuestions: a.totalQuestions,
        correctCount: a.correctCount,
        wrongCount: a.wrongCount,
        skippedCount: a.skippedCount,
        score: a.score,
        maxScore: a.maxScore,
        scorePercentage: pct,
        accuracy: acc,
        totalTimeSeconds: a.totalTimeSeconds,
      );
    }).toList();
  }

  SubjectAnalytics _buildSubjectAnalytics({
    required String subjectName,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int skippedCount,
    required int score,
    required int maxScore,
    required double scorePercentage,
    required double accuracy,
    required int totalTimeSeconds,
  }) {
    final double avgTime = totalQuestions > 0 ? totalTimeSeconds / totalQuestions : 0.0;

    String badge;
    Color color;
    if (accuracy >= 80.0) {
      badge = 'Strong';
      color = const Color(0xFF10B981);
    } else if (accuracy >= 65.0) {
      badge = 'Good';
      color = const Color(0xFF38BDF8);
    } else if (accuracy >= 50.0) {
      badge = 'Average';
      color = const Color(0xFFF59E0B);
    } else {
      badge = 'Needs Improvement';
      color = const Color(0xFFEF4444);
    }

    return SubjectAnalytics(
      subjectName: subjectName,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      skippedCount: skippedCount,
      score: score,
      maxScore: maxScore,
      scorePercentage: scorePercentage.clamp(0.0, 100.0),
      accuracy: accuracy.clamp(0.0, 100.0),
      totalTimeSeconds: totalTimeSeconds,
      avgTimePerQuestionSeconds: avgTime,
      statusBadge: badge,
      badgeColor: color,
    );
  }

  /// Chronological Score Trend points matching website trajectory
  List<AnalyticsChartPoint> getScoreTrend(List<TestResult> results) {
    final chronological = results.reversed.toList();
    final slice = chronological.length > 12
        ? chronological.sublist(chronological.length - 12)
        : chronological;

    return slice.asMap().entries.map((entry) {
      final index = entry.key;
      final r = entry.value;
      final pct = r.totalMarks > 0 ? (r.score / r.totalMarks) * 100 : 0.0;
      final top10 = (pct + 14.0).clamp(0.0, 98.0);

      return AnalyticsChartPoint(
        label: 'T${index + 1}',
        userValue: pct.clamp(0.0, 100.0),
        top10Benchmark: top10,
        date: r.attemptedAt,
        testTitle: r.testTitle,
      );
    }).toList();
  }

  List<AnalyticsChartPoint> _getAccuracyTrend(List<TestResult> results) {
    final chronological = results.reversed.toList();
    final slice = chronological.length > 11
        ? chronological.sublist(chronological.length - 11)
        : chronological;

    return slice.asMap().entries.map((entry) {
      final r = entry.value;
      final top10 = (r.accuracy + 15.0).clamp(0.0, 96.0);
      final monthStr = _formatShortDate(r.attemptedAt);

      return AnalyticsChartPoint(
        label: monthStr,
        userValue: r.accuracy.clamp(0.0, 100.0),
        top10Benchmark: top10,
        date: r.attemptedAt,
        testTitle: r.testTitle,
      );
    }).toList();
  }

  List<AnalyticsChartPoint> _getSpeedTrend(List<TestResult> results) {
    final chronological = results.reversed.toList();
    final slice = chronological.length > 10
        ? chronological.sublist(chronological.length - 10)
        : chronological;

    return slice.asMap().entries.map((entry) {
      final index = entry.key;
      final r = entry.value;
      final totalQ = r.correctAnswers + r.wrongAnswers + r.skippedAnswers;
      final double secPerQ = totalQ > 0 ? (r.timeTakenSeconds / totalQ) : 45.0;

      return AnalyticsChartPoint(
        label: 'Test ${index + 1}',
        userValue: secPerQ.clamp(0.0, 150.0),
        top10Benchmark: 38.0,
        date: r.attemptedAt,
        testTitle: r.testTitle,
      );
    }).toList();
  }

  _StreakInfo _calculateStreaks(List<TestResult> results) {
    if (results.isEmpty) {
      return _StreakInfo(currentStreak: 0, longestStreak: 0, weeklyConsistency: 0.0);
    }

    final Set<String> activeDateStrings = {};
    for (final r in results) {
      final d = r.attemptedAt;
      activeDateStrings.add('${d.year}-${d.month}-${d.day}');
    }

    int currentStreak = 0;
    DateTime cursor = DateTime.now();

    // Check if practiced today or yesterday
    final todayStr = '${cursor.year}-${cursor.month}-${cursor.day}';
    final yesterday = cursor.subtract(const Duration(days: 1));
    final yestStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    if (activeDateStrings.contains(todayStr)) {
      currentStreak = 1;
      cursor = yesterday;
    } else if (activeDateStrings.contains(yestStr)) {
      currentStreak = 1;
      cursor = yesterday.subtract(const Duration(days: 1));
    }

    if (currentStreak > 0) {
      while (true) {
        final dStr = '${cursor.year}-${cursor.month}-${cursor.day}';
        if (activeDateStrings.contains(dStr)) {
          currentStreak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Longest streak
    final List<DateTime> sortedDates = results
        .map((r) => DateTime(r.attemptedAt.year, r.attemptedAt.month, r.attemptedAt.day))
        .toSet()
        .toList()
      ..sort();

    int longestStreak = currentStreak;
    int tempStreak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i].difference(sortedDates[i - 1]).inDays == 1) {
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 1;
      }
    }

    // Weekly consistency (% of last 7 days active)
    int daysActiveInLast7 = 0;
    for (int i = 0; i < 7; i++) {
      final checkDate = DateTime.now().subtract(Duration(days: i));
      final dStr = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (activeDateStrings.contains(dStr)) daysActiveInLast7++;
    }
    final double weeklyConsistency = (daysActiveInLast7 / 7.0) * 100.0;

    return _StreakInfo(
      currentStreak: currentStreak,
      longestStreak: longestStreak > 0 ? longestStreak : currentStreak,
      weeklyConsistency: double.parse(weeklyConsistency.toStringAsFixed(1)),
    );
  }

  List<WeeklyConsistencyWeek> _generateConsistencyHeatmap(List<TestResult> results) {
    final Set<String> activeDateStrings = {};
    final Map<String, int> dailySeconds = {};

    for (final r in results) {
      final d = r.attemptedAt;
      final k = '${d.year}-${d.month}-${d.day}';
      activeDateStrings.add(k);
      dailySeconds[k] = (dailySeconds[k] ?? 0) + r.timeTakenSeconds;
    }

    final List<WeeklyConsistencyWeek> weeks = [];
    final now = DateTime.now();
    // Monday of current week
    final currentMonday = now.subtract(Duration(days: (now.weekday - 1)));

    for (int w = 4; w >= 0; w--) {
      final weekStart = currentMonday.subtract(Duration(days: w * 7));
      final List<Color> dayColors = [];

      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        final k = '${day.year}-${day.month}-${day.day}';
        final int secs = dailySeconds[k] ?? 0;

        if (secs >= 5400) {
          dayColors.add(const Color(0xFF10B981)); // > 90m
        } else if (secs >= 3600) {
          dayColors.add(const Color(0xFF1D64D0)); // 60-90m
        } else if (secs >= 1800) {
          dayColors.add(const Color(0xFFFBBF24)); // 30-60m
        } else if (secs > 0) {
          dayColors.add(const Color(0xFFEF4444)); // < 30m
        } else {
          dayColors.add(const Color(0xFF1E293B)); // Inactive
        }
      }

      final label = _formatShortDate(weekStart);
      weeks.add(WeeklyConsistencyWeek(weekLabel: label, dayColors: dayColors));
    }

    return weeks;
  }

  String _formatShortDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class _SubjectAccumulator {
  final String subjectName;
  int totalQuestions = 0;
  int correctCount = 0;
  int wrongCount = 0;
  int skippedCount = 0;
  int score = 0;
  int maxScore = 0;
  int totalTimeSeconds = 0;

  _SubjectAccumulator(this.subjectName);
}

class _StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final double weeklyConsistency;

  _StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyConsistency,
  });
}
