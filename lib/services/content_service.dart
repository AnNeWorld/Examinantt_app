import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_models.dart';
import '../utils/app_logger.dart';

class ContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static List<LiveClass>? _cachedLiveClasses;
  static List<CourseModel>? _cachedCourses;
  static List<ResourceItem>? _cachedResources;

  // Live Classes Real-Time Stream (Direct from Firestore live_classes collection)
  Stream<List<LiveClass>> getLiveClasses({String? batchId}) async* {
    if (_cachedLiveClasses != null && _cachedLiveClasses!.isNotEmpty) {
      var cached = _cachedLiveClasses!;
      if (batchId != null && batchId.isNotEmpty) {
        cached = cached.where((c) => c.batchId == batchId).toList();
      }
      yield cached;
    }
    AppLogger.firestore("live_classes", "Listening to real-time live_classes stream from Firestore");
    yield* _db.collection('live_classes').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <LiveClass>[];
      }

      var list = snapshot.docs.map((doc) {
        return LiveClass.fromMap(doc.data(), doc.id);
      }).toList();

      _cachedLiveClasses = list;

      if (batchId != null && batchId.isNotEmpty) {
        list = list.where((c) => c.batchId == batchId).toList();
      }

      // Sort: Live Now first, then Upcoming by start time, then Completed
      list.sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        if (a.isUpcoming && !b.isUpcoming) return -1;
        if (!a.isUpcoming && b.isUpcoming) return 1;
        final aTime = a.scheduledStartTime?.millisecondsSinceEpoch ?? 0;
        final bTime = b.scheduledStartTime?.millisecondsSinceEpoch ?? 0;
        return aTime.compareTo(bTime);
      });

      return list;
    }).handleError((e) {
      AppLogger.e("Error in getLiveClasses stream", error: e, tag: "CONTENT_SERVICE");
      return _cachedLiveClasses ?? <LiveClass>[];
    });
  }

  // Real Courses / Batches Stream from Firestore
  Stream<List<CourseModel>> getCoursesStream() async* {
    if (_cachedCourses != null && _cachedCourses!.isNotEmpty) {
      yield _cachedCourses!;
    }
    AppLogger.firestore("courses", "Listening to real-time courses stream from Firestore");
    yield* _db.collection('courses').snapshots().map((snapshot) {
      final list = snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['status'] == null || data['status'] == 'published';
          })
          .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
          .toList();
      _cachedCourses = list;
      AppLogger.s("Real-time courses stream updated: ${list.length} courses direct from Firestore", tag: "CONTENT_SERVICE");
      return list;
    }).handleError((e) {
      AppLogger.e("Error in getCoursesStream", error: e, tag: "CONTENT_SERVICE");
      return _cachedCourses ?? <CourseModel>[];
    });
  }

  // Active Live Now Stream
  Stream<List<LiveClass>> getLiveNowClasses() {
    return getLiveClasses().map((classes) => classes.where((c) => c.isLive).toList());
  }

  // Upcoming Scheduled Classes Stream
  Stream<List<LiveClass>> getUpcomingClasses() {
    return getLiveClasses().map((classes) => classes.where((c) => c.isUpcoming).toList());
  }

  // Past Recorded Classes Stream
  Stream<List<LiveClass>> getRecordedClasses() {
    return getLiveClasses().map((classes) => classes.where((c) => c.isRecorded).toList());
  }

  // News & Current Affairs
  Stream<List<NewsArticle>> getNewsArticles() {
    return _db.collection('news').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => NewsArticle.fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) {
      AppLogger.e("Error in getNewsArticles stream", error: e, tag: "CONTENT_SERVICE");
      return <NewsArticle>[];
    });
  }

  // Resources & PDFs
  Stream<List<ResourceItem>> getResources() async* {
    if (_cachedResources != null && _cachedResources!.isNotEmpty) {
      yield _cachedResources!;
    }
    AppLogger.firestore("resources", "Listening to resources collection stream");
    yield* _db.collection('resources').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ResourceItem.fromMap(doc.data(), doc.id)).toList();
      _cachedResources = list;
      AppLogger.s("Resources stream updated: ${list.length} items from Firestore", tag: "RESOURCES");
      return list;
    }).handleError((e) {
      AppLogger.e("Resources stream error", error: e, tag: "RESOURCES");
      return _cachedResources ?? <ResourceItem>[];
    });
  }

  // Job Alerts
  Stream<List<JobAlert>> getJobAlerts() {
    return _db.collection('job_alerts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return JobAlert(
          id: doc.id,
          title: data['title'] ?? '',
          organization: data['organization'] ?? data['dept'] ?? '',
          lastDate: data['lastDate'] ?? '',
          applyUrl: data['applyUrl'] ?? data['link'] ?? '',
          tag: data['tag'] ?? '',
        );
      }).toList();
    }).handleError((e) => <JobAlert>[]);
  }
}
