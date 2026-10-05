import 'package:flutter_test/flutter_test.dart';
import 'package:examinantt_app/models/test_model.dart';
import 'package:examinantt_app/models/analytics_model.dart';
import 'package:examinantt_app/services/analytics_service.dart';

void main() {
  group('AnalyticsService & OverallAnalyticsData Tests', () {
    test('Calculates empty analytics properly without dummy data', () {
      final service = AnalyticsService();
      final stats = service.getOverallAnalytics([]);

      expect(stats.isEmpty, isTrue);
      expect(stats.totalTests, equals(0));
      expect(stats.averageScore, equals(0.0));
      expect(stats.averageAccuracy, equals(0.0));
      expect(stats.correctAnswers, equals(0));
      expect(stats.wrongAnswers, equals(0));
      expect(stats.skippedAnswers, equals(0));
      expect(stats.formattedTimeEfficiency, equals('--'));
    });

    test('Calculates dynamic analytics from real test results', () {
      final service = AnalyticsService();
      final sampleResults = [
        TestResult(
          id: 'test_1',
          userId: 'user_123',
          testId: 't1',
          testTitle: 'SSC General Test 1',
          score: 80,
          totalMarks: 100,
          correctAnswers: 20,
          wrongAnswers: 5,
          skippedAnswers: 0,
          accuracy: 80.0,
          attemptedAt: DateTime.now(),
          timeTakenSeconds: 1200,
        ),
        TestResult(
          id: 'test_2',
          userId: 'user_123',
          testId: 't2',
          testTitle: 'SSC Reasoning Test 2',
          score: 60,
          totalMarks: 100,
          correctAnswers: 15,
          wrongAnswers: 10,
          skippedAnswers: 0,
          accuracy: 60.0,
          attemptedAt: DateTime.now().subtract(const Duration(days: 1)),
          timeTakenSeconds: 1500,
        ),
      ];

      final stats = service.getOverallAnalytics(sampleResults);

      expect(stats.isEmpty, isFalse);
      expect(stats.totalTests, equals(2));
      expect(stats.averageScore, equals(70.0));
      expect(stats.highestScore, equals(80.0));
      expect(stats.correctAnswers, equals(35));
      expect(stats.wrongAnswers, equals(15));
      expect(stats.totalQuestions, equals(50));
      expect(stats.averageAccuracy, equals(70.0));
      expect(stats.currentStreakDays, greaterThanOrEqualTo(1));
    });

    test('Filters results accurately by exam and date range', () {
      final service = AnalyticsService();
      final results = [
        TestResult(
          id: '1',
          userId: 'u1',
          testId: 't1',
          testTitle: 'Banking PO Prelims',
          score: 50,
          totalMarks: 100,
          correctAnswers: 25,
          wrongAnswers: 10,
          skippedAnswers: 5,
          accuracy: 71.4,
          attemptedAt: DateTime.now(),
        ),
        TestResult(
          id: '2',
          userId: 'u1',
          testId: 't2',
          testTitle: 'SSC CGL Tier 1 Full Mock',
          score: 75,
          totalMarks: 100,
          correctAnswers: 35,
          wrongAnswers: 5,
          skippedAnswers: 10,
          accuracy: 87.5,
          attemptedAt: DateTime.now().subtract(const Duration(days: 40)),
        ),
      ];

      final bankingFiltered = service.filterByExam(results, 'Banking');
      expect(bankingFiltered.length, equals(1));
      expect(bankingFiltered.first.testTitle, contains('Banking'));

      final last30Days = service.filterByDate(results, DateRangeFilter.last30Days);
      expect(last30Days.length, equals(1));
      expect(last30Days.first.id, equals('1'));
    });
  });
}
