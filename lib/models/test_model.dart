import 'package:cloud_firestore/cloud_firestore.dart';

typedef TestItem = MockTest;

double _parseDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  final s = val.toString().replaceAll(RegExp(r'[^0-9.]'), '').trim();
  return double.tryParse(s) ?? defaultVal;
}

int _parseInt(dynamic val, [int defaultVal = 0]) {
  if (val == null) return defaultVal;
  if (val is int) return val;
  if (val is num) return val.toInt();
  final s = val.toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
  return int.tryParse(s) ?? defaultVal;
}

class TestCategory {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final double price;
  final double originalPrice;
  final String badge;
  final String testsCount;
  final List<String> features;
  final String examCategory;
  final String examSubCategory;
  final bool isPublished;

  TestCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    this.price = 0.0,
    this.originalPrice = 0.0,
    this.badge = 'Free',
    this.testsCount = '0 Tests',
    this.features = const [],
    this.examCategory = 'General',
    this.examSubCategory = '',
    this.isPublished = true,
  });

  factory TestCategory.fromMap(Map<String, dynamic> data, String documentId) {
    final pricing = data['pricing'] as Map<String, dynamic>?;
    final isFree = pricing?['type'] == 'free' || data['accessType'] == 'free';
    
    // Parse price safely whether it's in pricing object or root
    double amount = 0.0;
    if (data.containsKey('price')) {
      amount = _parseDouble(data['price']);
    } else if (pricing != null && pricing.containsKey('amount')) {
      amount = _parseDouble(pricing['amount']);
    } else if (data.containsKey('amount')) {
      amount = _parseDouble(data['amount']);
    }

    String badgeText = data['badge']?.toString() ?? '';
    bool isEffectivelyFree = isFree || amount == 0 || badgeText.toLowerCase().contains('free');

    // Parse original price safely
    double origPrice = 0.0;
    if (data.containsKey('originalPrice')) {
      origPrice = _parseDouble(data['originalPrice']);
    } else if (pricing != null && pricing.containsKey('originalPrice')) {
      origPrice = _parseDouble(pricing['originalPrice']);
    }
    if (origPrice <= 0 && amount > 0) {
      origPrice = amount * 4.0;
    }

    if (isEffectivelyFree) {
      amount = 0.0;
      origPrice = 0.0;
    }

    final totalModules = data['totalModules'];
    final totalLessons = data['totalLessons'];
    String parsedTestsCount = '0 Tests';
    if (data['testsCount'] != null && data['testsCount'].toString().isNotEmpty) {
      parsedTestsCount = data['testsCount'].toString();
    } else if (data['questions'] != null && data['questions'] is List && (data['questions'] as List).isNotEmpty) {
      parsedTestsCount = '1 Full Test • ${(data['questions'] as List).length} Qs';
    } else if (data['stats'] is Map && (data['stats'] as Map)['totalTests'] != null) {
      parsedTestsCount = '${(data['stats'] as Map)['totalTests']} Tests';
    } else if (data['testIds'] != null && data['testIds'] is List && (data['testIds'] as List).isNotEmpty) {
      parsedTestsCount = '${(data['testIds'] as List).length} Tests';
    } else if (data['totalTests'] != null) {
      parsedTestsCount = '${data['totalTests']} Tests';
    } else if (totalModules != null || totalLessons != null) {
      parsedTestsCount = '${totalModules ?? 0} Modules • ${totalLessons ?? 0} Lessons';
    }

    final rawTitle = data['name'] ?? 
        data['title'] ?? 
        data['testSeriesName'] ?? 
        data['seriesName'] ?? 
        data['test_series_name'] ?? 
        data['testName'] ?? 
        data['courseName'] ?? 
        data['batchName'] ?? 
        data['label'] ?? 
        data['heading'] ?? 
        data['displayName'] ?? 
        data['examCategory'];

    final seriesTitle = (rawTitle != null && rawTitle.toString().trim().isNotEmpty)
        ? rawTitle.toString().trim()
        : 'Test Series ${documentId.length > 6 ? documentId.substring(0, 6) : documentId}';

    final examCategory = data['examCategory']?.toString() ?? data['category']?.toString() ?? 'General';
    final examSubCategory = data['examSubCategory']?.toString() ?? data['subCategory']?.toString() ?? '';
    final bool isPublished = data['isActive'] != false;

    if (badgeText.isEmpty) {
      final nameLower = seriesTitle.toLowerCase();
      if (nameLower.contains('gold')) {
        badgeText = 'GOLD';
      } else if (nameLower.contains('silver')) {
        badgeText = 'SILVER';
      } else if (nameLower.contains('mock')) {
        badgeText = 'MOCK';
      } else if (isEffectivelyFree) {
        badgeText = 'FREE';
      } else {
        badgeText = 'PREMIUM';
      }
    }

    List<String> parsedFeatures = [];
    if (data['features'] != null && data['features'] is List && (data['features'] as List).isNotEmpty) {
      parsedFeatures = (data['features'] as List).map((e) => e.toString()).toList();
    } else {
      parsedFeatures = [];
    }

    return TestCategory(
      id: documentId,
      title: seriesTitle,
      description: (data['description'] != null && data['description'].toString().isNotEmpty)
          ? data['description'].toString()
          : (data['shortDescription'] ?? data['details'] ?? data['subtitle'] ?? data['about'] ?? ''),
      iconUrl: data['thumbnailUrl'] ?? data['iconUrl'] ?? data['image'] ?? data['imageUrl'] ?? data['bannerUrl'] ?? data['img'] ?? '',
      price: amount,
      originalPrice: origPrice,
      badge: isEffectivelyFree ? 'Free' : (badgeText.isNotEmpty ? badgeText : 'Premium'),
      testsCount: parsedTestsCount, 
      features: parsedFeatures,
      examCategory: examCategory,
      examSubCategory: examSubCategory,
      isPublished: isPublished,
    );
  }
}

class MockTest {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final int durationMinutes;
  final int totalMarks;
  final int totalQuestions;
  final bool isPremium;
  final List<String> questionIds;

  MockTest({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.totalMarks,
    required this.totalQuestions,
    required this.isPremium,
    this.questionIds = const [],
  });

  factory MockTest.fromMap(Map<String, dynamic> data, String documentId) {
    final settings = data['settings'] as Map<String, dynamic>?;
    final duration = _parseInt(settings?['duration'] ?? data['duration'], 60);
    
    final omrTemplate = data['omrTemplate'] as Map<String, dynamic>?;
    final rawQIds = data['questionIds'] as List<dynamic>? ?? [];
    final questionIds = rawQIds.map((e) => e.toString()).toList();
    final questionConfig = data['questionConfig'] as Map<String, dynamic>?;
    final totalQ = questionIds.isNotEmpty 
        ? questionIds.length 
        : _parseInt(questionConfig?['totalQuestions'] ?? omrTemplate?['totalQuestions'] ?? data['totalQuestions'], 25);

    final marksPerQ = _parseInt(settings?['marksPerQuestion'] ?? data['marksPerQuestion'] ?? data['marks_per_question'], 2);
    final totalMarks = _parseInt(data['totalMarks'] ?? settings?['totalMarks'] ?? data['marks'], totalQ * marksPerQ);

    return MockTest(
      id: documentId,
      categoryId: data['seriesId'] ?? data['series_id'] ?? data['testSeriesId'] ?? data['test_series_id'] ?? data['categoryId'] ?? data['category_id'] ?? data['category'] ?? data['courseId'] ?? data['testSeries'] ?? data['series'] ?? '',
      title: data['name'] ?? data['title'] ?? data['testName'] ?? data['test_name'] ?? data['heading'] ?? 'Test $documentId',
      description: data['testType'] ?? data['test_type'] ?? data['description'] ?? data['subtitle'] ?? 'Mock Test',
      durationMinutes: duration,
      totalMarks: totalMarks,
      totalQuestions: totalQ,
      isPremium: data['isPremium'] == true || data['premium'] == true || settings?['isPremium'] == true,
      questionIds: questionIds,
    );
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final int marks;
  final String subject;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.marks,
    this.subject = 'General',
  });

  factory Question.fromMap(Map<String, dynamic> data, String documentId) {
    final ans = data['correctAnswer'] ?? data['correct_answer'] ?? data['correctOption'] ?? data['answer'] ?? data['correct'];
    int correctIndex = 0;

    final rawOptions = data['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else if (rawOptions is Map) {
      // Sort by keys if A, B, C, D
      final sortedKeys = rawOptions.keys.toList()..sort();
      for (final k in sortedKeys) {
        parsedOptions.add(rawOptions[k].toString());
      }
    }

    if (parsedOptions.isEmpty) {
      for (final key in ['option1', 'option2', 'option3', 'option4']) {
        if (data[key] != null) parsedOptions.add(data[key].toString());
      }
    }
    if (parsedOptions.isEmpty) {
      for (final key in ['optionA', 'optionB', 'optionC', 'optionD']) {
        if (data[key] != null) parsedOptions.add(data[key].toString());
      }
    }
    if (parsedOptions.isEmpty) {
      for (final key in ['optA', 'optB', 'optC', 'optD']) {
        if (data[key] != null) parsedOptions.add(data[key].toString());
      }
    }

    if (ans is int) {
      correctIndex = ans;
    } else if (ans is String) {
      final strAns = ans.trim();
      final upperAns = strAns.toUpperCase();
      if (upperAns == 'A' || upperAns == 'OPTION A' || upperAns == 'OPTIONA') {
        correctIndex = 0;
      } else if (upperAns == 'B' || upperAns == 'OPTION B' || upperAns == 'OPTIONB') {
        correctIndex = 1;
      } else if (upperAns == 'C' || upperAns == 'OPTION C' || upperAns == 'OPTIONC') {
        correctIndex = 2;
      } else if (upperAns == 'D' || upperAns == 'OPTION D' || upperAns == 'OPTIOND') {
        correctIndex = 3;
      } else {
        final parsed = int.tryParse(strAns);
        if (parsed != null) {
          // If 1-indexed (1, 2, 3, 4), adjust to 0-indexed if out of bounds for 0-based
          correctIndex = (parsed >= 1 && parsed <= parsedOptions.length && parsedOptions.length == 4 && !strAns.startsWith('0'))
              ? parsed - 1
              : parsed;
        } else {
          // If it's the actual text of the option
          final foundIndex = parsedOptions.indexWhere((opt) => opt.trim().toLowerCase() == strAns.toLowerCase());
          if (foundIndex != -1) {
            correctIndex = foundIndex;
          }
        }
      }
    }

    String explanationText = (data['explanation'] ?? data['solution'] ?? data['rationale'] ?? data['detail'] ?? '').toString().trim();
    if (explanationText.isEmpty && data['explanationHindi'] != null) {
      explanationText = data['explanationHindi'].toString().trim();
    }
    if (explanationText.isEmpty && data['subject'] != null) {
      explanationText = 'Subject: ${data['subject']} • Difficulty: ${data['difficulty'] ?? "Standard"}';
    }

    int marks = 2;
    if (data['marks'] != null) {
      marks = int.tryParse(data['marks'].toString()) ?? (data['difficulty'] == 'Hard' ? 4 : 2);
    }

    final qText = (data['text'] ?? data['question'] ?? data['questionText'] ?? data['title'] ?? data['q'] ?? '').toString();

    return Question(
      id: documentId,
      text: qText.isNotEmpty ? qText : 'Question $documentId',
      options: parsedOptions,
      correctOptionIndex: correctIndex,
      explanation: explanationText,
      marks: marks,
      subject: (data['subject'] ?? data['subjectName'] ?? data['chapter'] ?? data['topic'] ?? 'General').toString(),
    );
  }
}

class TestResult {
  final String id;
  final String userId;
  final String testId;
  final String testTitle;
  final int score;
  final int totalMarks;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final double accuracy;
  final DateTime attemptedAt;
  final Map<String, dynamic> subjectBreakdown;
  final Map<int, int> userAnswers;
  final int timeTakenSeconds;

  TestResult({
    required this.id,
    required this.userId,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.totalMarks,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.accuracy,
    required this.attemptedAt,
    this.subjectBreakdown = const {},
    this.userAnswers = const {},
    this.timeTakenSeconds = 0,
  });

  int get totalQuestions => correctAnswers + wrongAnswers + skippedAnswers;

  factory TestResult.fromMap(Map<String, dynamic> data, String documentId) {
    Map<int, int> parsedAnswers = {};
    if (data['userAnswers'] != null) {
      final Map<String, dynamic> rawAnswers = Map<String, dynamic>.from(data['userAnswers']);
      rawAnswers.forEach((key, value) {
        final intKey = int.tryParse(key);
        final intValue = value is int ? value : int.tryParse(value.toString());
        if (intKey != null && intValue != null) {
          parsedAnswers[intKey] = intValue;
        }
      });
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = data['attemptedAt'] ?? data['attemptDate'] ?? data['completedAt'] ?? data['createdAt'] ?? data['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    final correct = _parseInt(data['correctAnswers'] ?? data['correctCount'] ?? data['correct'], 0);
    final wrong = _parseInt(data['wrongAnswers'] ?? data['wrongCount'] ?? data['wrong'], 0);
    final skipped = _parseInt(data['skippedAnswers'] ?? data['unattemptedCount'] ?? data['unattempted'] ?? data['skipped'], 0);
    final totalQ = correct + wrong + skipped;

    double calculatedAccuracy = _parseDouble(data['accuracy'], -1.0);
    if (calculatedAccuracy < 0) {
      final attempted = correct + wrong;
      calculatedAccuracy = attempted > 0 ? (correct / attempted) * 100 : (totalQ > 0 ? (correct / totalQ) * 100 : 0.0);
    }

    return TestResult(
      id: documentId,
      userId: (data['userId'] ?? data['uid'] ?? '').toString(),
      testId: (data['testId'] ?? data['id'] ?? '').toString(),
      testTitle: (data['testTitle'] ?? data['testName'] ?? data['title'] ?? 'Mock Test').toString(),
      score: _parseInt(data['score'], 0),
      totalMarks: _parseInt(data['totalMarks'] ?? data['maxScore'] ?? data['total_marks'], totalQ > 0 ? totalQ * 2 : 100),
      correctAnswers: correct,
      wrongAnswers: wrong,
      skippedAnswers: skipped,
      accuracy: calculatedAccuracy,
      attemptedAt: parsedDate,
      subjectBreakdown: (data['subjectBreakdown'] ?? data['sectionWiseScore'] ?? data['subjects']) is Map
          ? Map<String, dynamic>.from(data['subjectBreakdown'] ?? data['sectionWiseScore'] ?? data['subjects'] as Map)
          : {},
      userAnswers: parsedAnswers,
      timeTakenSeconds: _parseInt(data['timeTakenSeconds'] ?? data['duration'] ?? data['timeSpent'], 0),
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, int> answersForFirestore = {};
    userAnswers.forEach((key, value) {
      answersForFirestore[key.toString()] = value;
    });

    return {
      'userId': userId,
      'testId': testId,
      'testTitle': testTitle,
      'score': score,
      'totalMarks': totalMarks,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'skippedAnswers': skippedAnswers,
      'accuracy': accuracy,
      'attemptedAt': attemptedAt.toIso8601String(),
      'completedAt': Timestamp.fromDate(attemptedAt),
      'subjectBreakdown': subjectBreakdown,
      'userAnswers': answersForFirestore,
      'timeTakenSeconds': timeTakenSeconds,
    };
  }
}
