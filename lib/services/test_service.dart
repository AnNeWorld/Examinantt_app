import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/test_model.dart';
import '../utils/app_logger.dart';

class TestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<TestCategory>> getCourses() async {
    List<TestCategory> items = [];
    try {
      final collections = ['testSeries', 'test_series', 'testseries', 'categories'];
      for (final colName in collections) {
        try {
          final snapshot = await _db.collection(colName).get();
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (data['isActive'] == false) continue;
            final cat = _parseCategory(doc);
            if (cat.title.isNotEmpty) {
              items.add(cat);
            }
          }
        } catch (_) {}
      }

      final Map<String, TestCategory> uniqueMap = {};
      for (final item in items) {
        String cleanTitle = item.title.trim();
        String key = cleanTitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (key.isNotEmpty && !uniqueMap.containsKey(key)) {
          uniqueMap[key] = item;
        }
      }

      items = uniqueMap.values.toList();
    } catch (e, stack) {
      AppLogger.e("Error fetching categories", error: e, stackTrace: stack, tag: "TEST_SERVICE");
      items = [];
    }
    return items;
  }

  Future<List<TestCategory>> getCategories() async {
    return getCourses();
  }

  Stream<List<TestCategory>> getCategoriesStream() {
    AppLogger.firestore("testSeries", "Listening to testSeries & test_series dual real-time stream");
    late StreamController<List<TestCategory>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    List<TestCategory> list1 = [];
    List<TestCategory> list2 = [];

    void emitMerged() {
      final Map<String, TestCategory> uniqueMap = {};
      for (final item in [...list1, ...list2]) {
        String cleanTitle = item.title.trim();
        String key = cleanTitle.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (key.isNotEmpty && !uniqueMap.containsKey(key)) {
          uniqueMap[key] = item;
        } else if (!uniqueMap.containsKey(item.id)) {
          uniqueMap[item.id] = item;
        }
      }
      if (!controller.isClosed) {
        controller.add(uniqueMap.values.toList());
      }
    }

    controller = StreamController<List<TestCategory>>.broadcast(
      onListen: () {
        sub1 = _db.collection('testSeries').snapshots().listen((snapshot) {
          list1 = snapshot.docs
              .where((doc) => doc.data()['isActive'] != false)
              .map((doc) => _parseCategory(doc))
              .where((cat) => cat.title.isNotEmpty)
              .toList();
          emitMerged();
        }, onError: (e) {
          AppLogger.e("testSeries stream error", error: e, tag: "TEST_SERVICE");
        });

        sub2 = _db.collection('test_series').snapshots().listen((snapshot) {
          list2 = snapshot.docs
              .where((doc) => doc.data()['isActive'] != false)
              .map((doc) => _parseCategory(doc))
              .where((cat) => cat.title.isNotEmpty)
              .toList();
          emitMerged();
        }, onError: (e) {
          AppLogger.e("test_series stream error", error: e, tag: "TEST_SERVICE");
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  TestCategory _parseCategory(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TestCategory.fromMap(data, doc.id);
  }

  Future<List<TestItem>> getTestsForCategory(String categoryId) async {
    return getTestsByCategory(categoryId);
  }

  TestItem _parseTestItem(DocumentSnapshot doc, String defaultCategoryId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MockTest.fromMap(data, doc.id);
  }

  Future<TestItem?> getTestById(String testId) async {
    final testCols = ['tests', 'mock_tests', 'mockTests', 'quizzes'];
    for (final colName in testCols) {
      try {
        final doc = await _db.collection(colName).doc(testId).get();
        if (doc.exists) {
          return _parseTestItem(doc, '');
        }
      } catch (_) {}
    }
    return null;
  }

  Stream<List<TestItem>> getLatestTestsStream({int? limit}) {
    late StreamController<List<TestItem>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;
    List<TestItem> tests1 = [];
    List<TestItem> tests2 = [];
    List<TestItem> tests3 = [];

    void emitMergedTests() {
      final Map<String, TestItem> unique = {};
      for (final t in [...tests1, ...tests2, ...tests3]) {
        if (!unique.containsKey(t.id)) {
          unique[t.id] = t;
        }
      }
      final list = unique.values.toList();
      if (!controller.isClosed) {
        controller.add(limit != null && limit < list.length ? list.sublist(0, limit) : list);
      }
    }

    controller = StreamController<List<TestItem>>.broadcast(
      onListen: () {
        sub1 = _db.collection('tests').snapshots().listen((snap) {
          tests1 = snap.docs.map((doc) => _parseTestItem(doc, '')).toList();
          emitMergedTests();
        }, onError: (_) {});

        sub2 = _db.collection('testSeries').snapshots().listen((snap) {
          tests2 = snap.docs.where((doc) {
            final data = doc.data();
            final qs = data['questions'];
            return qs is List && qs.isNotEmpty;
          }).map((doc) {
            final data = doc.data();
            final qs = data['questions'] as List;
            final duration = int.tryParse((data['duration'] ?? data['durationMinutes'] ?? 180).toString()) ?? 180;
            return MockTest(
              id: doc.id,
              categoryId: doc.id,
              title: (data['title'] ?? data['name'] ?? 'Mock Test').toString(),
              description: (data['description'] ?? data['category'] ?? 'Assessment').toString(),
              durationMinutes: duration,
              totalMarks: qs.length * 4,
              totalQuestions: qs.length,
              isPremium: (data['price'] != null && double.tryParse(data['price'].toString()) != null && double.parse(data['price'].toString()) > 0),
            );
          }).toList();
          emitMergedTests();
        }, onError: (_) {});

        sub3 = _db.collection('test_series').snapshots().listen((snap) {
          tests3 = snap.docs.where((doc) {
            final data = doc.data();
            final qs = data['questions'];
            return qs is List && qs.isNotEmpty;
          }).map((doc) {
            final data = doc.data();
            final qs = data['questions'] as List;
            final duration = int.tryParse((data['duration'] ?? data['durationMinutes'] ?? 180).toString()) ?? 180;
            return MockTest(
              id: doc.id,
              categoryId: doc.id,
              title: (data['title'] ?? data['name'] ?? 'Mock Test').toString(),
              description: (data['description'] ?? data['category'] ?? 'Assessment').toString(),
              durationMinutes: duration,
              totalMarks: qs.length * 4,
              totalQuestions: qs.length,
              isPremium: (data['price'] != null && double.tryParse(data['price'].toString()) != null && double.parse(data['price'].toString()) > 0),
            );
          }).toList();
          emitMergedTests();
        }, onError: (_) {});
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
        sub3?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<TestResult>> getRecentTestResults(String userId, {int? limit}) {
    return _db.collection('users').doc(userId).collection('test_results').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => TestResult.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
      return limit != null && limit < list.length ? list.sublist(0, limit) : list;
    }).handleError((e) => <TestResult>[]);
  }

  Future<List<Question>> getQuestionsForTest(String testId) async {
    List<Question> rawQuestions = [];
    try {
      DocumentSnapshot? testDoc;
      final testCols = ['tests', 'testSeries', 'test_series', 'mock_tests', 'mockTests', 'quizzes'];
      for (final colName in testCols) {
        try {
          final doc = await _db.collection(colName).doc(testId).get();
          if (doc.exists) {
            testDoc = doc;
            break;
          }
        } catch (_) {}
      }

      // If not in root collections, search in test series subcollections
      if (testDoc == null || !testDoc.exists) {
        for (final pCol in ['testSeries', 'test_series']) {
          try {
            final seriesSnap = await _db.collection(pCol).get();
            for (final sDoc in seriesSnap.docs) {
              final subDoc = await sDoc.reference.collection('tests').doc(testId).get();
              if (subDoc.exists) {
                testDoc = subDoc;
                break;
              }
            }
            if (testDoc != null && testDoc.exists) break;
          } catch (_) {}
        }
      }

      if (testDoc != null && testDoc.exists) {
        final testData = testDoc.data() as Map<String, dynamic>? ?? {};

        // 1. Direct embedded questions list (List of Maps from AdminTestsPage!)
        final embeddedQs = testData['questions'];
        if (embeddedQs is List && embeddedQs.isNotEmpty) {
          for (int i = 0; i < embeddedQs.length; i++) {
            final item = embeddedQs[i];
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              rawQuestions.add(Question.fromMap(map, map['id']?.toString() ?? 'q_${i + 1}'));
            }
          }
        }

        // 2. Question IDs list (List of Strings from TestSeriesManagement / QuestionBank)
        if (rawQuestions.isEmpty) {
          final rawQIds = (testData['questionIds'] ?? testData['question_ids'] ?? (embeddedQs is List ? embeddedQs.whereType<String>().toList() : null)) as List<dynamic>? ?? [];
          final qIds = rawQIds.map((e) => e.toString()).toList();

          if (qIds.isNotEmpty) {
            for (int i = 0; i < qIds.length; i += 30) {
              final chunk = qIds.sublist(i, i + 30 > qIds.length ? qIds.length : i + 30);
              try {
                final qSnap = await _db.collection('questions').where(FieldPath.documentId, whereIn: chunk).get();
                final chunkQuestions = qSnap.docs.map((doc) => Question.fromMap(doc.data(), doc.id)).toList();
                rawQuestions.addAll(chunkQuestions);
              } catch (e) {
                for (final qId in chunk) {
                  try {
                    final qDoc = await _db.collection('questions').doc(qId).get();
                    if (qDoc.exists && qDoc.data() != null) {
                      rawQuestions.add(Question.fromMap(qDoc.data()!, qDoc.id));
                    }
                  } catch (_) {}
                }
              }
            }
          }
        }

        // 3. Subcollection inside test doc
        if (rawQuestions.isEmpty) {
          try {
            final subSnapshot = await testDoc.reference.collection('questions').get();
            if (subSnapshot.docs.isNotEmpty) {
              rawQuestions = subSnapshot.docs.map((doc) => Question.fromMap(doc.data(), doc.id)).toList();
            }
          } catch (_) {}
        }
      }

      // 4. Root subcollection check across all collections
      if (rawQuestions.isEmpty) {
        for (final colName in testCols) {
          try {
            final subSnapshot = await _db.collection(colName).doc(testId).collection('questions').get();
            if (subSnapshot.docs.isNotEmpty) {
              rawQuestions = subSnapshot.docs.map((doc) => Question.fromMap(doc.data(), doc.id)).toList();
              break;
            }
          } catch (_) {}
        }
      }

      // 5. Root questions collection where testId matches
      if (rawQuestions.isEmpty) {
        for (final field in ['testId', 'test_id', 'seriesId', 'series_id']) {
          try {
            final rootSnapshot = await _db.collection('questions').where(field, isEqualTo: testId).get();
            if (rootSnapshot.docs.isNotEmpty) {
              rawQuestions = rootSnapshot.docs.map((doc) => Question.fromMap(doc.data(), doc.id)).toList();
              break;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    final Map<String, Question> uniqueQuestions = {};
    for (final q in rawQuestions) {
      final key = q.text.trim().toLowerCase();
      if (key.isNotEmpty && !uniqueQuestions.containsKey(key)) {
        uniqueQuestions[key] = q;
      }
    }
    return uniqueQuestions.values.toList();
  }

  Stream<List<TestItem>> getTestsByCategoryStream(String categoryId) {
    late StreamController<List<TestItem>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;

    void updateTests() async {
      try {
        final tests = await getTestsByCategory(categoryId);
        if (!controller.isClosed) {
          controller.add(tests);
        }
      } catch (e) {
        if (!controller.isClosed) controller.add([]);
      }
    }

    controller = StreamController<List<TestItem>>.broadcast(
      onListen: () {
        updateTests();
        sub1 = _db.collection('tests').snapshots().listen((_) => updateTests());
        sub2 = _db.collection('testSeries').snapshots().listen((_) => updateTests());
        sub3 = _db.collection('test_series').snapshots().listen((_) => updateTests());
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
        sub3?.cancel();
      },
    );

    return controller.stream;
  }

  Future<List<TestItem>> getTestsByCategory(String categoryId) async {
    List<TestItem> tests = [];
    final testCols = ['tests', 'mock_tests', 'mockTests', 'quizzes'];
    try {
      final cleanCatId = categoryId.trim();
      if (cleanCatId.isEmpty || cleanCatId.toLowerCase() == 'all') {
        // Return all tests from tests collection + tests from testSeries that have questions
        for (final colName in testCols) {
          try {
            final snap = await _db.collection(colName).get();
            for (final doc in snap.docs) {
              tests.add(_parseTestItem(doc, categoryId));
            }
          } catch (_) {}
        }
        try {
          final sSnap = await _db.collection('testSeries').get();
          for (final doc in sSnap.docs) {
            final data = doc.data();
            final qs = data['questions'];
            if (qs is List && qs.isNotEmpty) {
              final duration = int.tryParse((data['duration'] ?? data['durationMinutes'] ?? 180).toString()) ?? 180;
              tests.add(
                MockTest(
                  id: doc.id,
                  categoryId: doc.id,
                  title: (data['title'] ?? data['name'] ?? 'Mock Test').toString(),
                  description: (data['description'] ?? data['category'] ?? 'Assessment').toString(),
                  durationMinutes: duration,
                  totalMarks: qs.length * 4,
                  totalQuestions: qs.length,
                  isPremium: (data['price'] != null && double.tryParse(data['price'].toString()) != null && double.parse(data['price'].toString()) > 0),
                ),
              );
            }
          }
        } catch (_) {}
      } else {
        // 1. Check if categoryId is a testSeries ID
        DocumentSnapshot? seriesDoc;
        for (final col in ['testSeries', 'test_series']) {
          try {
            final d = await _db.collection(col).doc(cleanCatId).get();
            if (d.exists) {
              seriesDoc = d;
              break;
            }
          } catch (_) {}
        }

        final Set<String> targetSeriesIds = {cleanCatId};

        if (seriesDoc != null && seriesDoc.exists) {
          final sData = seriesDoc.data() as Map<String, dynamic>? ?? {};
          final title = (sData['title'] ?? sData['name'] ?? sData['testSeriesName'] ?? sData['seriesName'] ?? '').toString().trim();
          if (title.isNotEmpty) targetSeriesIds.add(title);
          final badge = (sData['badge'] ?? '').toString().trim();
          if (badge.isNotEmpty) targetSeriesIds.add(badge);

          // IF THIS TEST SERIES HAS EMBEDDED QUESTIONS (from AdminTestsPage on examinantt.com)
          // SYNTHESIZE A DIRECT TEST ITEM FOR IT!
          final embeddedQuestions = sData['questions'];
          if (embeddedQuestions is List && embeddedQuestions.isNotEmpty) {
            final duration = int.tryParse((sData['duration'] ?? sData['durationMinutes'] ?? 180).toString()) ?? 180;
            tests.add(
              MockTest(
                id: seriesDoc.id,
                categoryId: seriesDoc.id,
                title: title.isNotEmpty ? title : 'Full Length Test',
                description: (sData['description'] ?? sData['category'] ?? 'Official Test Series Exam').toString(),
                durationMinutes: duration,
                totalMarks: embeddedQuestions.length * 4,
                totalQuestions: embeddedQuestions.length,
                isPremium: (sData['price'] != null && double.tryParse(sData['price'].toString()) != null && double.parse(sData['price'].toString()) > 0),
              ),
            );
          }
        } else {
          final allSeries = await getCourses();
          final matched = allSeries.where((s) {
            final title = s.title.toLowerCase();
            final badge = s.badge.toLowerCase();
            final id = s.id.toLowerCase();
            final clean = cleanCatId.toLowerCase();
            return id == clean || title.contains(clean) || badge.contains(clean);
          }).map((s) => s.id).toList();
          targetSeriesIds.addAll(matched);
        }

        // 2. Query tests across all collections and field aliases (e.g. from TestSeriesManagement)
        final fieldKeys = ['seriesId', 'series_id', 'testSeriesId', 'test_series_id', 'categoryId', 'category_id', 'category', 'courseId'];
        for (final sId in targetSeriesIds) {
          for (final colName in testCols) {
            for (final fKey in fieldKeys) {
              try {
                final snap = await _db.collection(colName).where(fKey, isEqualTo: sId).get();
                tests.addAll(snap.docs.map((doc) => _parseTestItem(doc, categoryId)));
              } catch (_) {}
            }
          }

          // Check subcollections: testSeries/{sId}/tests or test_series/{sId}/tests
          for (final parentCol in ['testSeries', 'test_series']) {
            for (final subCol in ['tests', 'mock_tests', 'mockTests']) {
              try {
                final subSnap = await _db.collection(parentCol).doc(sId).collection(subCol).get();
                tests.addAll(subSnap.docs.map((doc) => _parseTestItem(doc, categoryId)));
              } catch (_) {}
            }
          }
        }

        // 3. If series has embedded tests / testIds list
        if (seriesDoc != null && seriesDoc.exists) {
          final sData = seriesDoc.data() as Map<String, dynamic>? ?? {};
          final rawTestList = sData['tests'] ?? sData['testList'] ?? sData['testIds'] ?? sData['test_ids'];
          if (rawTestList is List) {
            final List<String> missingIds = [];
            for (int i = 0; i < rawTestList.length; i++) {
              final item = rawTestList[i];
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                tests.add(MockTest.fromMap(map, map['id']?.toString() ?? 't_${i + 1}'));
              } else if (item is String && item.isNotEmpty) {
                missingIds.add(item);
              }
            }

            if (missingIds.isNotEmpty) {
              final existingIds = tests.map((t) => t.id).toSet();
              final toFetch = missingIds.where((id) => !existingIds.contains(id)).toList();
              for (int i = 0; i < toFetch.length; i += 30) {
                final chunk = toFetch.sublist(i, i + 30 > toFetch.length ? toFetch.length : i + 30);
                for (final colName in testCols) {
                  try {
                    final snap = await _db.collection(colName).where(FieldPath.documentId, whereIn: chunk).get();
                    tests.addAll(snap.docs.map((doc) => _parseTestItem(doc, categoryId)));
                  } catch (_) {}
                }
              }
            }
          }
        }

        // 4. Fallback: If no tests matched specifically by seriesId, check all tests
        if (tests.isEmpty) {
          final cleanLower = cleanCatId.toLowerCase();
          for (final colName in testCols) {
            try {
              final snap = await _db.collection(colName).get();
              for (final doc in snap.docs) {
                final data = doc.data();
                final title = (data['name'] ?? data['title'] ?? data['testName'] ?? '').toString().toLowerCase();
                final desc = (data['description'] ?? data['testType'] ?? '').toString().toLowerCase();
                final examCat = (data['examCategory'] ?? data['category'] ?? '').toString().toLowerCase();
                
                if (title.contains(cleanLower) || desc.contains(cleanLower) || examCat.contains(cleanLower) ||
                    cleanLower.contains('jee') && (title.contains('jee') || examCat.contains('jee')) ||
                    cleanLower.contains('neet') && (title.contains('neet') || examCat.contains('neet'))) {
                  tests.add(_parseTestItem(doc, categoryId));
                }
              }
            } catch (_) {}
          }

          // If still empty, return all available tests so admin's tests are always accessible
          if (tests.isEmpty) {
            for (final colName in testCols) {
              try {
                final snap = await _db.collection(colName).limit(15).get();
                for (final doc in snap.docs) {
                  tests.add(_parseTestItem(doc, categoryId));
                }
              } catch (_) {}
            }
          }
        }
      }

      final Map<String, TestItem> uniqueMap = {};
      for (final item in tests) {
        if (item.title.trim().isNotEmpty && !uniqueMap.containsKey(item.id)) {
          uniqueMap[item.id] = item;
        }
      }
      tests = uniqueMap.values.toList();
    } catch (e, st) {
      AppLogger.e("Error fetching tests for category $categoryId", error: e, stackTrace: st, tag: "TEST_SERVICE");
    }
    return tests;
  }

  Future<void> submitTestResult(TestResult result) async {
    try {
      await _db.collection('users').doc(result.userId).collection('test_results').doc(result.id).set(result.toMap());
      await _db.collection('test_results').add(result.toMap());
    } catch (e) {
      debugPrint("Error submitting test result: $e");
    }
  }

  Future<void> updateAttemptCounts(String userId, String testId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'attemptsCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCourseModules(String courseId) async {
    try {
      final snap = await _db.collection('courses').doc(courseId).collection('modules').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (_) {}
    return [];
  }

  // Real Firestore data only - fake questions stub returns empty
  List<Question> getDefaultQuestionsForTest(String testId) => const [];
}