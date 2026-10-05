import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

enum AnalyticsStatus { loading, success, empty, error }

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  AnalyticsStatus _status = AnalyticsStatus.loading;
  AnalyticsStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedExam = 'All Exams';
  String get selectedExam => _selectedExam;

  DateRangeFilter _selectedDateFilter = DateRangeFilter.allTime;
  DateRangeFilter get selectedDateFilter => _selectedDateFilter;

  List<TestResult> _rawResults = [];
  List<TestResult> get rawResults => _rawResults;

  OverallAnalyticsData? _data;
  OverallAnalyticsData? get data => _data;

  StreamSubscription? _resultsSubscription;

  void init(String? userId) {
    _status = AnalyticsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _resultsSubscription?.cancel();
    _resultsSubscription = _analyticsService.getUserTestResultsStream(userId).listen(
      (results) {
        _rawResults = results;
        _recompute();
      },
      onError: (err) {
        _status = AnalyticsStatus.error;
        _errorMessage = 'Failed to load analytics: $err';
        notifyListeners();
      },
    );
  }

  void setExam(String exam) {
    if (_selectedExam == exam) return;
    _selectedExam = exam;
    _recompute();
  }

  void setDateFilter(DateRangeFilter filter) {
    if (_selectedDateFilter == filter) return;
    _selectedDateFilter = filter;
    _recompute();
  }

  void _recompute() {
    try {
      _data = _analyticsService.getOverallAnalytics(
        _rawResults,
        dateFilter: _selectedDateFilter,
        targetExam: _selectedExam,
      );

      if (_data == null || _data!.isEmpty) {
        _status = AnalyticsStatus.empty;
      } else {
        _status = AnalyticsStatus.success;
      }
      _errorMessage = null;
    } catch (e) {
      _status = AnalyticsStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void retry(String? userId) {
    init(userId);
  }

  @override
  void dispose() {
    _resultsSubscription?.cancel();
    super.dispose();
  }
}
