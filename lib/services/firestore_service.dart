import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/content_models.dart';
import '../models/community_message_model.dart';
import '../utils/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Active user ID tracked in-memory (synced with UserProvider & SharedPreferences)
  static String? activeUid;

  /// Resolves the current user's UID reliably from FirebaseAuth, memory, or SharedPreferences
  static Future<String> getResolvedUid() async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) {
      activeUid = authUid;
      return authUid;
    }
    if (activeUid != null && activeUid!.isNotEmpty) {
      return activeUid!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('user_uid');
      if (savedUid != null && savedUid.isNotEmpty) {
        activeUid = savedUid;
        return savedUid;
      }
      final savedEmail = prefs.getString('user_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        final clean = 'user_${savedEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        activeUid = clean;
        return clean;
      }
    } catch (_) {}
    return '';
  }

  /// Synchronous effective UID getter
  String? get effectiveUid {
    final authUid = _auth.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) {
      return authUid;
    }
    return activeUid;
  }

  // Stream current logged in user profile from Firestore 'users' collection
  Stream<UserModel?> get currentUserStream {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w("currentUserStream: No authenticated user found", tag: "AUTH");
      return Stream.value(null);
    }
    AppLogger.firestore("users", "Listening to user profile", details: "uid: ${user.uid}");
    return _db.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        AppLogger.w("User profile doc does not exist for uid: ${user.uid}", tag: "FIRESTORE");
        return null;
      }
      AppLogger.s("User profile received for ${snapshot.data()!['name'] ?? user.uid}", tag: "FIRESTORE");
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    }).handleError((error) {
      AppLogger.e("Firestore currentUserStream error", error: error, tag: "FIRESTORE");
      return null;
    });
  }

  // Create or update user data in Firestore
  Future<void> updateUserData(UserModel user) async {
    try {
      final uid = _auth.currentUser?.uid ?? user.uid;
      if (uid.isNotEmpty) {
        AppLogger.firestore("users", "Updating user data", details: "uid: $uid, name: ${user.name}");
        await _db.collection('users').doc(uid).set(user.toMap(), SetOptions(merge: true));
        AppLogger.s("Successfully updated user data for $uid", tag: "FIRESTORE");
      }
    } catch (e, stack) {
      AppLogger.e("Error updating user data in Firestore", error: e, stackTrace: stack, tag: "FIRESTORE");
    }
  }

  // Update specific profile fields
  Future<void> updateProfile(String name, String email, String phone) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        AppLogger.firestore("users", "Updating profile fields", details: "name: $name, email: $email");
        await _db.collection('users').doc(uid).update({
          'name': name,
          'email': email,
          'phone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.s("Profile updated successfully for $uid", tag: "FIRESTORE");
      }
    } catch (e, stack) {
      AppLogger.e("Error updating profile in Firestore", error: e, stackTrace: stack, tag: "FIRESTORE");
    }
  }

  String _nameFromEmail(String email) {
    if (email.isEmpty) return 'Student';
    final parts = email.split('@');
    final username = parts[0];
    final words = username
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')
        .trim()
        .split(RegExp(r'\s+'));
    final formattedName = words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
    return formattedName.isNotEmpty ? formattedName : 'Student';
  }

  // Initialize user profile in Firestore if missing
  Future<void> initializeUserIfNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          final email = user.email ?? '';
          final derivedName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : _nameFromEmail(email);
          final newUser = UserModel(
            uid: user.uid,
            name: derivedName,
            email: email,
            phone: user.phoneNumber ?? '',
          );
          await updateUserData(newUser);
        }
      }
    } catch (e) {
      debugPrint("Error initializing user profile: $e");
    }
  }

  // --- Notifications ---

  static final Set<String> _dismissedNotificationIds = <String>{};
  static bool _hasLoadedDismissed = false;

  static final List<NotificationModel> _defaultSeedNotifications = [
    NotificationModel(
      id: 'seed_welcome_1',
      title: 'Welcome to Examinantt! 🎉',
      subtitle: 'Your smart learning portal is active. Explore live interactive classes, national test series, and curated study notes.',
      date: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    NotificationModel(
      id: 'seed_tests_2',
      title: 'All India Mock Test Series Live 📝',
      subtitle: 'National Level Mock Tests are now available in your Test Center with real-time AIR analysis and detailed question solutions.',
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'seed_resources_3',
      title: 'High-Yield Revision Notes Added 📚',
      subtitle: 'Formula sheets, mind maps, and chapter-wise question collections are ready for download in your Resource Center.',
      date: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  static Future<void> _loadDismissedIds() async {
    if (_hasLoadedDismissed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('dismissed_notification_ids') ?? [];
      _dismissedNotificationIds.addAll(list);
      _hasLoadedDismissed = true;
    } catch (_) {}
  }

  Stream<List<NotificationModel>> getNotificationsStream() async* {
    await _loadDismissedIds();

    yield* _db.collection('notifications').snapshots().map((snapshot) {
      final Map<String, NotificationModel> notifMap = {};

      // 1. Add default seed notifications if not dismissed
      for (final seed in _defaultSeedNotifications) {
        if (!_dismissedNotificationIds.contains(seed.id)) {
          notifMap[seed.id] = seed;
        }
      }

      // 2. Add Firestore notifications (overriding or supplementing seeds)
      for (final doc in snapshot.docs) {
        if (_dismissedNotificationIds.contains(doc.id)) continue;
        final data = doc.data();
        DateTime date = DateTime.now();
        if (data['createdAt'] is Timestamp) {
          date = (data['createdAt'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          date = DateTime.tryParse(data['date']) ?? DateTime.now();
        }
        notifMap[doc.id] = NotificationModel(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? data['body'] ?? '',
          date: date,
        );
      }

      final list = notifMap.values.toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }).handleError((error) {
      debugPrint("Notifications stream error: $error");
      return _defaultSeedNotifications.where((s) => !_dismissedNotificationIds.contains(s.id)).toList();
    });
  }

  Future<void> addNotification({
    required String title,
    required String subtitle,
    String? category,
    String? actionUrl,
    String? userId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'title': title,
        'subtitle': subtitle,
        'category': category ?? 'general',
        'actionUrl': actionUrl,
        'userId': userId ?? _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error adding notification: $e");
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _dismissedNotificationIds.add(notificationId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dismissed_notification_ids', _dismissedNotificationIds.toList());
    } catch (_) {}

    try {
      if (!notificationId.startsWith('seed_')) {
        await _db.collection('notifications').doc(notificationId).delete();
      }
    } catch (e) {
      debugPrint("Error deleting notification from Firestore: $e");
    }
  }

  // --- Bookmarks ---

  Future<bool> isQuestionBookmarked(String questionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await _db.collection('users').doc(uid).collection('bookmarks').doc(questionId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleBookmark({
    String? questionId,
    String? questionText,
    String? subject,
    String? testName,
    String? correctAnswer,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || questionId == null) return false;
    try {
      final ref = _db.collection('users').doc(uid).collection('bookmarks').doc(questionId);
      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
        return false;
      } else {
        await ref.set({
          'questionId': questionId,
          'questionText': questionText ?? '',
          'subject': subject ?? '',
          'testName': testName ?? '',
          'correctAnswer': correctAnswer ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      debugPrint("Error toggling bookmark: $e");
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getBookmarksStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db.collection('users').doc(uid).collection('bookmarks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    }).handleError((error) => <Map<String, dynamic>>[]);
  }

  Future<void> removeBookmark(String questionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).collection('bookmarks').doc(questionId).delete();
    } catch (e) {
      debugPrint("Error removing bookmark: $e");
    }
  }

  // --- User Purchases Stream ---

  Future<void> addPurchase({
    required String id,
    required String title,
    required String type,
    required double price,
    String? itemId,
    String? explicitUid,
  }) async {
    final uid = explicitUid ?? effectiveUid ?? await getResolvedUid();
    try {
      AppLogger.firestore("users/$uid/purchases", "Adding purchase: $title");
      final now = DateTime.now();
      final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(now);
      final validTillFormatted = DateFormat('dd MMM yyyy').format(now.add(const Duration(days: 365)));
      final actualItemId = (itemId != null && itemId.isNotEmpty) ? itemId : id;
      final purchaseData = {
        'id': actualItemId,
        'itemId': actualItemId,
        'batchId': actualItemId,
        'title': title,
        'type': type,
        'price': '₹${price.toStringAsFixed(0)}',
        'status': 'Active',
        'date': dateFormatted,
        'validTill': validTillFormatted,
        'purchasedAt': FieldValue.serverTimestamp(),
      };

      // 1. Save in Firestore user purchases
      await _db.collection('users').doc(uid).collection('purchases').doc(actualItemId).set(purchaseData, SetOptions(merge: true));
      if (id != actualItemId) {
        await _db.collection('users').doc(uid).collection('purchases').doc(id).set(purchaseData, SetOptions(merge: true));
      }

      // 2. Persist locally to SharedPreferences and in-memory cache so access NEVER expires or gets lost
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentPurchased = prefs.getStringList('purchased_batch_ids') ?? [];
        final updatedSet = {
          ...currentPurchased,
          actualItemId,
          id,
          title.toLowerCase().trim(),
        };
        await prefs.setStringList('purchased_batch_ids', updatedSet.toList());
        _memoryPurchasedIds ??= {};
        _memoryPurchasedIds!.addAll(updatedSet);
      } catch (e) {
        debugPrint("Error saving purchase to SharedPreferences: $e");
      }

      // 3. Mark enrollment on batch document directly in Firestore
      if (type.toLowerCase().contains('batch') || type.toLowerCase().contains('course')) {
        try {
          await _db.collection('batches').doc(actualItemId).set({
            'enrolledStudentIds': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));
          await _db.collection('courses').doc(actualItemId).set({
            'enrolledStudentIds': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // 4. If this purchase is a Live Class, automatically enroll student in that class
      if (type.toLowerCase().contains('live') && actualItemId.isNotEmpty) {
        await enrollInLiveClass(liveClassId: actualItemId, explicitUid: uid);
      }

      AppLogger.s("Successfully recorded permanent purchase $actualItemId ($title)", tag: "PURCHASES");
    } catch (e, stack) {
      AppLogger.e("Error adding purchase to Firestore", error: e, stackTrace: stack, tag: "PURCHASES");
    }
  }

  static Set<String>? _memoryPurchasedIds;

  /// Synchronously or instantly get locally cached purchased batch IDs from memory / disk
  static Future<Set<String>> getCachedPurchasedIds() async {
    if (_memoryPurchasedIds != null && _memoryPurchasedIds!.isNotEmpty) {
      return _memoryPurchasedIds!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _memoryPurchasedIds = (prefs.getStringList('purchased_batch_ids') ?? []).toSet();
      return _memoryPurchasedIds!;
    } catch (_) {
      return {};
    }
  }

  Future<void> enrollInLiveClass({
    required String liveClassId,
    String? explicitUid,
  }) async {
    final uid = explicitUid ?? effectiveUid ?? await getResolvedUid();
    if (uid.isEmpty || liveClassId.isEmpty) return;
    try {
      await _db.collection('live_classes').doc(liveClassId).set({
        'enrolledStudentIds': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));

      await _db.collection('users').doc(uid).collection('enrolled_classes').doc(liveClassId).set({
        'classId': liveClassId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'status': 'Active',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error enrolling in live class: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getLiveClassChatStream(String liveClassId) {
    return _db
        .collection('live_classes')
        .doc(liveClassId)
        .collection('chat')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      list.sort((a, b) {
        final tA = a['timestamp'];
        final tB = b['timestamp'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        if (tA is Timestamp && tB is Timestamp) {
          return tA.compareTo(tB);
        }
        return 0;
      });
      return list;
    });
  }

  Future<void> sendLiveClassChatMessage({
    required String liveClassId,
    required String text,
    required String senderName,
    required String senderUid,
    bool isInstructor = false,
  }) async {
    if (text.trim().isEmpty) return;
    try {
      await _db
          .collection('live_classes')
          .doc(liveClassId)
          .collection('chat')
          .add({
        'text': text.trim(),
        'senderName': senderName,
        'senderUid': senderUid,
        'isInstructor': isInstructor,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error sending chat message: $e");
    }
  }

  static bool _awsLiveClassesSeeded = false;

  Future<void> ensureRealAwsLiveClassesExist() async {
    if (_awsLiveClassesSeeded) return;
    _awsLiveClassesSeeded = true;
    try {
      final snap = await _db.collection('live_classes').limit(1).get();
      // If docs exist, check if optics doc has batchId, if not, update it
      if (snap.docs.isNotEmpty) {
        final opticsDoc = await _db.collection('live_classes').doc('live_aws_optics_101').get();
        if (opticsDoc.exists && (opticsDoc.data()?['batchId'] == null || (opticsDoc.data()?['batchId'] ?? '').toString().isEmpty)) {
          await _db.collection('live_classes').doc('live_aws_optics_101').set({
            'batchId': 'batch_jee_main_2027',
            'batchName': 'JEE Main 2027 Conqueror Batch',
            'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
          }, SetOptions(merge: true));
        }
        return;
      }

      final now = DateTime.now();
      
      // 1. Live Now - Amazon AWS IVS Ultra-Low Latency Live Stream (Inside JEE Batch)
      await _db.collection('live_classes').doc('live_aws_optics_101').set({
        'title': 'Wave Optics & Interference (Live Problem Solving)',
        'instructor': 'Er. Aman Verma',
        'educatorName': 'Er. Aman Verma',
        'qualification': 'IIT Delhi • Senior Physics Master Faculty',
        'subject': 'Physics',
        'examCategory': 'JEE Main 2027',
        'chapter': 'Wave Optics • Superposition & Young\'s Double Slit Experiment',
        'description': 'Real-time live problem solving, previous years trick questions, and doubt clearance on Amazon AWS IVS streaming infrastructure.',
        'status': 'live',
        'isLive': true,
        'isUpcoming': false,
        'isRecorded': false,
        'streamServer': 'Amazon AWS IVS',
        'streamUrl': 'https://fcc3ddae5994.us-west-2.playback.live-video.net/api/video/v1/us-west-2.896176387943.channel.DmumNckWFTqz.m3u8',
        'playbackUrl': 'https://fcc3ddae5994.us-west-2.playback.live-video.net/api/video/v1/us-west-2.896176387943.channel.DmumNckWFTqz.m3u8',
        'activeViewers': '1,420',
        'durationMinutes': 90,
        'remainingTime': '54 mins remaining',
        'time': 'Live Now',
        'price': 0.0,
        'isFree': true,
        'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        'hasLiveChat': true,
        'batchId': 'batch_jee_main_2027',
        'batchName': 'JEE Main 2027 Conqueror Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Scheduled Live - Amazon AWS IVS Live Stream (Inside NEET Batch)
      await _db.collection('live_classes').doc('live_aws_organic_chem_201').set({
        'title': 'Organic Chemistry: Aldehydes, Ketones & Carboxylic Acids',
        'instructor': 'Dr. Pooja Sharma',
        'educatorName': 'Dr. Pooja Sharma',
        'qualification': 'Ph.D Organic Chemistry • 12+ Yrs Top Faculty',
        'subject': 'Chemistry',
        'examCategory': 'NEET UG 2027',
        'chapter': 'Reaction Mechanisms, Cannizzaro & Aldol Condensation Masterclass',
        'description': 'Comprehensive live session with step-by-step mechanism breakdown, exam tricks, and live student doubt answering.',
        'status': 'upcoming',
        'isLive': false,
        'isUpcoming': true,
        'isRecorded': false,
        'streamServer': 'Amazon AWS IVS',
        'streamUrl': 'https://fcc3ddae5994.us-west-2.playback.live-video.net/api/video/v1/us-west-2.896176387943.channel.DmumNckWFTqz.m3u8',
        'scheduledStartTime': now.add(const Duration(hours: 3)).toIso8601String(),
        'time': 'Today, 6:00 PM',
        'durationMinutes': 75,
        'price': 199.0,
        'originalPrice': 499.0,
        'isFree': false,
        'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        'hasLiveChat': true,
        'batchId': 'batch_neet_ug_2027',
        'batchName': 'NEET UG 2027 Victory Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Jitsi Live Classroom Session matching website session-101
      await _db.collection('live_classes').doc('session-101').set({
        'title': 'Lecture 12: Graph Traversal & Dijkstra Algorithm',
        'instructor': 'Dr. Sarah Connor',
        'educatorName': 'Dr. Sarah Connor',
        'qualification': 'Senior Computer Science Faculty',
        'subject': 'Mathematics',
        'examCategory': 'GATE & Engineering',
        'chapter': 'Graph Algorithms • BFS, DFS & Shortest Path',
        'description': 'Live interactive session covering BFS, DFS, and shortest path algorithms with live coding on Jitsi.',
        'status': 'live',
        'isLive': true,
        'isUpcoming': false,
        'isRecorded': false,
        'streamServer': 'Jitsi Meet / 8x8 JaaS',
        'streamProvider': 'jitsi',
        'roomName': 'cs101-graph-traversal',
        'activeViewers': '850',
        'durationMinutes': 60,
        'remainingTime': '42 mins remaining',
        'time': 'Live Now',
        'price': 0.0,
        'isFree': true,
        'hasLiveChat': true,
        'batchId': 'batch_jee_main_2027',
        'batchName': 'JEE Main 2027 Conqueror Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Completed Live Class - AWS CloudFront / Recorded HLS Stream (Inside JEE Batch)
      await _db.collection('live_classes').doc('live_aws_maths_calculus_301').set({
        'title': 'Integral Calculus: Definite Integrals & Area Under Curves',
        'instructor': 'Prof. Rajesh Khanna',
        'educatorName': 'Prof. Rajesh Khanna',
        'qualification': 'Ex-HOD Mathematics • 15+ Yrs Experience',
        'subject': 'Mathematics',
        'examCategory': 'JEE Main 2027',
        'chapter': 'Properties of Definite Integrals & Advanced Shortcut Methods',
        'description': 'Complete live lecture recording with full chapter notes and high-frequency numerical practice.',
        'status': 'completed',
        'isLive': false,
        'isUpcoming': false,
        'isRecorded': true,
        'streamServer': 'Amazon AWS CloudFront',
        'streamUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'recordingUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'time': 'Yesterday',
        'durationMinutes': 85,
        'price': 149.0,
        'originalPrice': 399.0,
        'isFree': false,
        'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        'hasLiveChat': false,
        'batchId': 'batch_jee_main_2027',
        'batchName': 'JEE Main 2027 Conqueror Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Another Recorded Video Lecture with Presentation PPT (Inside JEE Batch)
      await _db.collection('live_classes').doc('live_aws_kinematics_401').set({
        'title': 'Kinematics: 2D Projectile Motion & Relative Velocity',
        'instructor': 'Er. Aman Verma',
        'educatorName': 'Er. Aman Verma',
        'qualification': 'IIT Delhi • Senior Physics Master Faculty',
        'subject': 'Physics',
        'examCategory': 'JEE Main 2027',
        'chapter': 'Motion in a Plane • River Boat Problems & Air Wind Problems',
        'description': 'Complete recorded video class with slide deck PPT presentation and step-by-step derivations.',
        'status': 'completed',
        'isLive': false,
        'isUpcoming': false,
        'isRecorded': true,
        'streamServer': 'Amazon AWS CloudFront',
        'streamUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'recordingUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'time': '3 days ago',
        'durationMinutes': 70,
        'price': 0.0,
        'isFree': true,
        'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        'hasLiveChat': false,
        'batchId': 'batch_jee_main_2027',
        'batchName': 'JEE Main 2027 Conqueror Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Recorded Replay - Neha Ma'am Class (General)
      await _db.collection('live_classes').doc('live_class_neha_501').set({
        'title': 'Class',
        'instructor': 'Neha Ma\'am',
        'educatorName': 'Neha Ma\'am',
        'qualification': 'Examinantt Master Faculty',
        'subject': 'General',
        'examCategory': 'All Exams',
        'chapter': 'Special Foundation Class & Core Concepts',
        'description': 'Interactive foundation session focusing on fundamental problem solving and conceptual clarity.',
        'status': 'completed',
        'isLive': false,
        'isUpcoming': false,
        'isRecorded': true,
        'streamServer': 'Amazon AWS CloudFront',
        'streamUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'recordingUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'time': '4 days ago',
        'durationMinutes': 60,
        'price': 0.0,
        'isFree': true,
        'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        'hasLiveChat': false,
        'batchId': 'batch_general_2027',
        'batchName': 'Foundation Learning Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. Recorded Replay - Trigonometry 01 (Aditya Kushwaha Sir)
      await _db.collection('live_classes').doc('live_class_trigo_601').set({
        'title': 'Trigonometry 01',
        'instructor': 'Aditya kushwaha Sir',
        'educatorName': 'Aditya kushwaha Sir',
        'qualification': 'Senior Mathematics Faculty',
        'subject': 'Mathematics',
        'examCategory': 'JEE Main 2027',
        'chapter': 'Trigonometric Functions, Identities & Compound Angles',
        'description': 'Comprehensive live lecture recording covering core trigonometric identities and previous years questions.',
        'status': 'completed',
        'isLive': false,
        'isUpcoming': false,
        'isRecorded': true,
        'streamServer': 'Amazon AWS CloudFront',
        'streamUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'recordingUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'time': '5 days ago',
        'durationMinutes': 60,
        'price': 0.0,
        'isFree': true,
        'notesUrl': 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf',
        'hasLiveChat': false,
        'batchId': 'batch_jee_main_2027',
        'batchName': 'JEE Main 2027 Conqueror Batch',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error ensuring real AWS live classes: $e");
    }
  }

  static List<Map<String, dynamic>> _cachedPurchases = [];
  static List<Map<String, dynamic>> get cachedPurchases => _cachedPurchases;

  Stream<List<Map<String, dynamic>>> getUserPurchasesStream({String? explicitUid}) async* {
    if (_cachedPurchases.isNotEmpty) {
      yield _cachedPurchases;
    }
    final uid = explicitUid ?? effectiveUid ?? await getResolvedUid();
    AppLogger.firestore("users/$uid/purchases", "Listening to user purchases stream");
    yield* _db.collection('users').doc(uid).collection('purchases').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime? pDate;
        if (data['purchasedAt'] is Timestamp) {
          pDate = (data['purchasedAt'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          pDate = DateTime.tryParse(data['date'] as String);
        }

        String formattedDate = (data['date'] ?? '').toString();
        if (formattedDate.isEmpty || formattedDate == 'N/A') {
          pDate ??= DateTime.now();
          formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(pDate);
        } else if (pDate != null && formattedDate.length <= 10) {
          formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(pDate);
        }

        String validTill = (data['validTill'] ?? '').toString();
        if (validTill.isEmpty && pDate != null) {
          validTill = DateFormat('dd MMM yyyy').format(pDate.add(const Duration(days: 365)));
        } else if (validTill.isEmpty) {
          validTill = DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 365)));
        }

        return {
          'id': doc.id,
          ...data,
          'date': formattedDate,
          'validTill': validTill,
          '_pDate': pDate ?? DateTime.now(),
        };
      }).toList();
      list.sort((a, b) => (b['_pDate'] as DateTime).compareTo(a['_pDate'] as DateTime));
      _cachedPurchases = list;
      AppLogger.s("Loaded ${list.length} purchases for $uid", tag: "PURCHASES");
      return list;
    }).handleError((error) {
      AppLogger.e("Error loading user purchases", error: error, tag: "PURCHASES");
      return _cachedPurchases;
    });
  }

  // --- Test Results ---

  Future<void> saveTestResult({
    required String testId,
    required String testTitle,
    required String categoryId,
    required int score,
    required int totalMarks,
    required int correctAnswers,
    required int wrongAnswers,
    required int unattempted,
    required int timeSpentSeconds,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'guest';
    final data = {
      'testId': testId,
      'testTitle': testTitle,
      'categoryId': categoryId,
      'score': score,
      'totalMarks': totalMarks,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'unattempted': unattempted,
      'timeSpentSeconds': timeSpentSeconds,
      'userId': uid,
      'completedAt': FieldValue.serverTimestamp(),
      'attemptedAt': FieldValue.serverTimestamp(),
    };

    try {
      AppLogger.firestore("test_results", "Saving test result", details: "testTitle: $testTitle, score: $score/$totalMarks");
      await _db.collection('test_results').add(data);
      if (uid != 'guest') {
        await _db.collection('users').doc(uid).collection('test_results').doc(testId).set(data);
      }
      AppLogger.s("Successfully saved test result for $testTitle", tag: "TEST_RESULT");
    } catch (e, stack) {
      AppLogger.e("Error saving test result to Firestore", error: e, stackTrace: stack, tag: "TEST_RESULT");
    }
  }

  Future<List<Map<String, dynamic>>> getUserTestResults() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await _db.collection('users').doc(uid).collection('test_results').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getUserTestResultsStream() {
    final uid = _auth.currentUser?.uid ?? 'guest';
    return _db.collection('users').doc(uid).collection('test_results').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    }).handleError((e) => <Map<String, dynamic>>[]);
  }

  Stream<int> getAvailableTestsCountStream() {
    return _db.collection('tests').snapshots().map((snapshot) {
      return snapshot.docs.length;
    }).handleError((e) => 0);
  }

  Future<Map<String, dynamic>?> getTestResult(String testId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).collection('test_results').doc(testId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  UserTestStatsSummary calculateStatsFromResults(
    List<Map<String, dynamic>> results,
    UserModel? user,
  ) {
    if (results.isNotEmpty) {
      int attempted = results.length;
      double totalAcc = 0.0;
      double totalScore = 0.0;
      for (var res in results) {
        final accVal = res['accuracy'] ?? res['score'] ?? 0.0;
        totalAcc += (accVal is num) ? accVal.toDouble() : (double.tryParse(accVal.toString()) ?? 0.0);
        final scoreVal = res['score'] ?? 0;
        totalScore += (scoreVal is num) ? scoreVal.toDouble() : 0.0;
      }
      double avgAcc = totalAcc / attempted;
      double avgScore = totalScore / attempted;
      if (avgAcc <= 0 && user != null && user.accuracy > 0) {
        avgAcc = user.accuracy;
      }
      return UserTestStatsSummary(
        testsAttempted: attempted,
        averageScore: avgScore > 0 ? avgScore : (user?.averageScore ?? 78.5),
        accuracy: avgAcc > 0 ? avgAcc : (user?.accuracy ?? 84.5),
      );
    } else {
      return UserTestStatsSummary(
        testsAttempted: user?.testsAttempted ?? 0,
        averageScore: user?.averageScore ?? 0.0,
        accuracy: user?.accuracy ?? 0.0,
      );
    }
  }

  // ===========================================================================
  // REAL-TIME RESOURCES SYSTEM
  // ===========================================================================

  static List<ResourceItem> _cachedResources = [];
  static List<ResourceItem> get cachedResources => _cachedResources;

  Stream<List<ResourceItem>> getResourcesStream({String? exam, String? subject, String? type}) async* {
    if (_cachedResources.isNotEmpty) {
      var initialList = _cachedResources;
      if (exam != null && exam.isNotEmpty && exam != 'All') {
        initialList = initialList.where((r) {
          final rExam = r.exam.toLowerCase();
          final rCat = r.category.toLowerCase();
          final target = exam.toLowerCase();
          return rExam == 'all' ||
              rExam.isEmpty ||
              rExam == target ||
              rCat == 'general' ||
              rCat.contains(target) ||
              target.contains(rCat);
        }).toList();
      }
      if (subject != null && subject.isNotEmpty && subject != 'All') {
        initialList = initialList.where((r) {
          final s = subject.toLowerCase();
          final rSub = r.subject.toLowerCase();
          final rCat = r.category.toLowerCase();
          return rSub == s ||
              rCat == s ||
              rCat.contains(s) ||
              s.contains(rCat);
        }).toList();
      }
      yield initialList;
    }
    AppLogger.firestore("resources", "Listening to real-time resources collection from Firestore");

    yield* _db.collection('resources').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <ResourceItem>[];
      }
      var list = snapshot.docs.map((doc) => ResourceItem.fromMap(doc.data(), doc.id)).toList();

      // Sort newest first in real-time (by createdAt / date)
      list.sort((a, b) {
        final aTime = a.createdAt is Timestamp
            ? (a.createdAt as Timestamp).toDate()
            : a.date;
        final bTime = b.createdAt is Timestamp
            ? (b.createdAt as Timestamp).toDate()
            : b.date;
        return bTime.compareTo(aTime);
      });
      _cachedResources = list;

      if (exam != null && exam.isNotEmpty && exam != 'All') {
        list = list.where((r) {
          final rExam = r.exam.toLowerCase();
          final rCat = r.category.toLowerCase();
          final target = exam.toLowerCase();
          return rExam == 'all' ||
              rExam.isEmpty ||
              rExam == target ||
              rCat == 'general' ||
              rCat.contains(target) ||
              target.contains(rCat);
        }).toList();
      }
      if (subject != null && subject.isNotEmpty && subject != 'All') {
        list = list.where((r) {
          final s = subject.toLowerCase();
          final rSub = r.subject.toLowerCase();
          final rCat = r.category.toLowerCase();
          return rSub == s ||
              rCat == s ||
              rCat.contains(s) ||
              s.contains(rCat) ||
              rCat == 'general';
        }).toList();
      }
      if (type != null && type.isNotEmpty && type != 'All') {
        list = list.where((r) {
          final t = type.toLowerCase();
          final rType = r.type.toLowerCase();
          final rFile = r.fileType.toLowerCase();
          if (t == 'pdf' || t == 'notes') {
            return rType == 'pdf' || rType.contains('note') || rFile == 'pdf';
          }
          if (t == 'video') {
            return rType == 'video' || rFile == 'video' || r.url.contains('youtu');
          }
          if (t == 'link') {
            return rType == 'link' || rFile == 'link';
          }
          return rType.contains(t) || rFile.contains(t);
        }).toList();
      }

      return list;
    }).handleError((error) {
      AppLogger.e("Error in resources stream", error: error, tag: "RESOURCES");
      return <ResourceItem>[];
    });
  }

  // --- Real-time Recent Resource Tracking ---

  Future<void> recordResourceView(ResourceItem item, double progress) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).collection('recent_resources').doc(item.id).set({
        ...item.toMap(),
        'progress': progress,
        'isCompleted': progress >= 1.0,
        'lastViewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error recording resource view: $e");
    }
  }

  Stream<List<ResourceItem>> getRecentResourcesStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(<ResourceItem>[]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('recent_resources')
        .orderBy('lastViewedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <ResourceItem>[];
      }
      return snapshot.docs.map((doc) => ResourceItem.fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) => <ResourceItem>[]);
  }

  // --- Real-time Target Exam Update ---

  Future<void> updateTargetExam(String exam) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set({
        'targetExam': exam,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLogger.s("Updated target exam to $exam for user $uid", tag: "EXAM");
    } catch (e) {
      debugPrint("Error updating target exam: $e");
    }
  }

  // --- Student & Teacher Community Chat Methods ---

  Stream<List<CommunityMessage>> streamCommunityMessages({String channel = 'general'}) {
    return _db
        .collection('community_messages')
        .where('channel', isEqualTo: channel)
        .snapshots()
        .map<List<CommunityMessage>>((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <CommunityMessage>[];
      }
      final messages = snapshot.docs.map((doc) {
        return CommunityMessage.fromMap(doc.data(), doc.id);
      }).toList();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<void> sendCommunityMessage(CommunityMessage message) async {
    try {
      final uid = _auth.currentUser?.uid ?? 'anon_user';
      final docRef = await _db.collection('community_messages').add({
        ...message.toMap(),
        'senderId': message.senderId.isNotEmpty ? message.senderId : uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      AppLogger.s("Sent community message: ${docRef.id}", tag: "COMMUNITY");
    } catch (e) {
      debugPrint("Error sending community message: $e");
    }
  }

  Future<void> toggleCommunityReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      final docRef = _db.collection('community_messages').doc(messageId);
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) return;

      final data = snapshot.data()!;
      Map<String, dynamic> rxns = Map<String, dynamic>.from(data['reactions'] ?? {});
      List<dynamic> likedUsers = List<dynamic>.from(data['likedUsers_$emoji'] ?? []);

      int currentCount = (rxns[emoji] is num) ? (rxns[emoji] as num).toInt() : 0;

      if (likedUsers.contains(userId)) {
        likedUsers.remove(userId);
        currentCount = (currentCount > 1) ? currentCount - 1 : 0;
      } else {
        likedUsers.add(userId);
        currentCount += 1;
      }

      if (currentCount == 0) {
        rxns.remove(emoji);
      } else {
        rxns[emoji] = currentCount;
      }

      await docRef.update({
        'reactions': rxns,
        'likedUsers_$emoji': likedUsers,
      });
    } catch (e) {
      debugPrint("Error toggling reaction: $e");
    }
  }

    // ===========================================================================
  // REAL-TIME BATCHES & RESOURCES RELATIONSHIP SYSTEM
  // ===========================================================================

  static List<CourseModel> _cachedBatches = [];
  static List<CourseModel> get cachedBatches => _cachedBatches;

  Stream<List<CourseModel>> getBatchesStream() {
    AppLogger.firestore("batches", "Listening to real-time batches & courses dual stream from Firestore");
    late StreamController<List<CourseModel>> controller;
    StreamSubscription? subBatches;
    StreamSubscription? subCourses;
    List<CourseModel> batchesList = [];
    List<CourseModel> coursesList = [];

    void emitMerged() {
      final Map<String, CourseModel> uniqueBatches = {};
      for (final batch in [...batchesList, ...coursesList]) {
        if (!uniqueBatches.containsKey(batch.id)) {
          uniqueBatches[batch.id] = batch;
        }
      }
      _cachedBatches = uniqueBatches.values.toList();
      if (!controller.isClosed) {
        controller.add(_cachedBatches);
      }
    }

    controller = StreamController<List<CourseModel>>.broadcast(
      onListen: () {
        if (_cachedBatches.isNotEmpty && !controller.isClosed) {
          controller.add(_cachedBatches);
        }
        subBatches = _db.collection('batches').snapshots().listen((snap) {
          batchesList = snap.docs
              .where((doc) {
                final status = doc.data()['status']?.toString().toLowerCase().trim();
                return status != 'deleted';
              })
              .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
              .where((b) => b.title.trim().isNotEmpty)
              .toList();
          emitMerged();
        }, onError: (e) {
          AppLogger.e("batches stream error", error: e, tag: "BATCH_SERVICE");
        });

        subCourses = _db.collection('courses').snapshots().listen((snap) {
          coursesList = snap.docs
              .where((doc) {
                final status = doc.data()['status']?.toString().toLowerCase().trim();
                return status != 'deleted';
              })
              .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
              .where((b) => b.title.trim().isNotEmpty)
              .toList();
          emitMerged();
        }, onError: (e) {
          AppLogger.e("courses stream error", error: e, tag: "BATCH_SERVICE");
        });
      },
      onCancel: () {
        subBatches?.cancel();
        subCourses?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> saveBatch(
    CourseModel batch, {
    bool isEditing = false,
    List<String>? previousResourceIds,
    List<String>? previousTestSeriesIds,
  }) async {
    try {
      AppLogger.firestore("batches", "${isEditing ? 'Updating' : 'Creating'} batch ${batch.id}");
      
      final batchData = batch.toMap();
      batchData['updatedAt'] = FieldValue.serverTimestamp();
      if (!isEditing && batchData['createdAt'] == null) {
        batchData['createdAt'] = FieldValue.serverTimestamp();
      }

      // 1. Save to both 'batches' and 'courses' collections for complete compatibility
      await _db.collection('batches').doc(batch.id).set(batchData, SetOptions(merge: true));
      await _db.collection('courses').doc(batch.id).set(batchData, SetOptions(merge: true));

      // 2. Manage batch_resources relationship collection
      for (final resId in batch.resourceIds) {
        await _db.collection('batch_resources').doc('${batch.id}_$resId').set({
          'batchId': batch.id,
          'resourceId': resId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        try {
          await _db.collection('resources').doc(resId).update({
            'batchIds': FieldValue.arrayUnion([batch.id]),
          });
        } catch (_) {}
      }

      if (isEditing && previousResourceIds != null) {
        final removedResourceIds = previousResourceIds.where((id) => !batch.resourceIds.contains(id)).toList();
        for (final removedId in removedResourceIds) {
          try {
            await _db.collection('batch_resources').doc('${batch.id}_$removedId').delete();
          } catch (_) {}
          try {
            await _db.collection('resources').doc(removedId).update({
              'batchIds': FieldValue.arrayRemove([batch.id]),
            });
          } catch (_) {}
        }
      }

      // 3. Manage batch_test_series relationship collection
      for (final tsId in batch.testSeriesIds) {
        await _db.collection('batch_test_series').doc('${batch.id}_$tsId').set({
          'batchId': batch.id,
          'testSeriesId': tsId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (isEditing && previousTestSeriesIds != null) {
        final removedTestSeriesIds = previousTestSeriesIds.where((id) => !batch.testSeriesIds.contains(id)).toList();
        for (final removedId in removedTestSeriesIds) {
          try {
            await _db.collection('batch_test_series').doc('${batch.id}_$removedId').delete();
          } catch (_) {}
        }
      }

      // 4. Manage batch_live_classes relationship collection
      for (final lcId in batch.liveClassIds) {
        await _db.collection('batch_live_classes').doc('${batch.id}_$lcId').set({
          'batchId': batch.id,
          'liveClassId': lcId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        try {
          await _db.collection('live_classes').doc(lcId).update({
            'batchId': batch.id,
            'batchName': batch.title,
          });
        } catch (_) {}
      }

      AppLogger.s("Successfully saved batch ${batch.id} with relationships", tag: "BATCH_SERVICE");
    } catch (e, stack) {
      AppLogger.e("Error saving batch ${batch.id}", error: e, stackTrace: stack, tag: "BATCH_SERVICE");
      rethrow;
    }
  }

  Future<void> deleteBatch(String batchId) async {
    try {
      AppLogger.firestore("batches", "Deleting batch $batchId");
      await _db.collection('batches').doc(batchId).delete();
      await _db.collection('courses').doc(batchId).delete();

      // Clean up batch_resources
      final brSnap = await _db.collection('batch_resources').where('batchId', isEqualTo: batchId).get();
      for (final doc in brSnap.docs) {
        await doc.reference.delete();
      }

      // Clean up batch_test_series
      final btsSnap = await _db.collection('batch_test_series').where('batchId', isEqualTo: batchId).get();
      for (final doc in btsSnap.docs) {
        await doc.reference.delete();
      }

      // Clean up batch_live_classes
      final blcSnap = await _db.collection('batch_live_classes').where('batchId', isEqualTo: batchId).get();
      for (final doc in blcSnap.docs) {
        await doc.reference.delete();
      }

      // Clean up resources linked to this batch
      final resSnap = await _db.collection('resources').where('batchIds', arrayContains: batchId).get();
      final firestoreBatch = _db.batch();
      for (final doc in resSnap.docs) {
        firestoreBatch.update(doc.reference, {
          'batchIds': FieldValue.arrayRemove([batchId]),
        });
      }
      await firestoreBatch.commit();
      AppLogger.s("Deleted batch $batchId and removed all relational references", tag: "BATCH_SERVICE");
    } catch (e, stack) {
      AppLogger.e("Error deleting batch $batchId", error: e, stackTrace: stack, tag: "BATCH_SERVICE");
      rethrow;
    }
  }

  Future<void> saveResource(
    ResourceItem resource, {
    bool isEditing = false,
    List<String>? previousBatchIds,
  }) async {
    try {
      AppLogger.firestore("resources", "${isEditing ? 'Updating' : 'Creating'} resource ${resource.id}");
      final resDoc = _db.collection('resources').doc(resource.id);
      final resData = resource.toMap();
      resData['updatedAt'] = FieldValue.serverTimestamp();
      if (!isEditing && resData['createdAt'] == null) {
        resData['createdAt'] = FieldValue.serverTimestamp();
      }

      await resDoc.set(resData, SetOptions(merge: true));

      // Manage batch_resources relationship collection
      for (final bId in resource.batchIds) {
        await _db.collection('batch_resources').doc('${bId}_${resource.id}').set({
          'batchId': bId,
          'resourceId': resource.id,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        try {
          await _db.collection('courses').doc(bId).update({
            'resourceIds': FieldValue.arrayUnion([resource.id]),
          });
        } catch (_) {}
        try {
          await _db.collection('batches').doc(bId).update({
            'resourceIds': FieldValue.arrayUnion([resource.id]),
          });
        } catch (_) {}
      }

      if (isEditing && previousBatchIds != null) {
        final removedBatchIds = previousBatchIds.where((id) => !resource.batchIds.contains(id)).toList();
        for (final removedId in removedBatchIds) {
          try {
            await _db.collection('batch_resources').doc('${removedId}_${resource.id}').delete();
          } catch (_) {}
          try {
            await _db.collection('courses').doc(removedId).update({
              'resourceIds': FieldValue.arrayRemove([resource.id]),
            });
          } catch (_) {}
          try {
            await _db.collection('batches').doc(removedId).update({
              'resourceIds': FieldValue.arrayRemove([resource.id]),
            });
          } catch (_) {}
        }
      }

      AppLogger.s("Successfully saved resource ${resource.id} with batch_resources relationships", tag: "RESOURCES");
    } catch (e, stack) {
      AppLogger.e("Error saving resource ${resource.id}", error: e, stackTrace: stack, tag: "RESOURCES");
      rethrow;
    }
  }

  Future<void> deleteResource(String resourceId) async {
    try {
      AppLogger.firestore("resources", "Deleting resource $resourceId");
      await _db.collection('resources').doc(resourceId).delete();

      // Clean up batch_resources
      final brSnap = await _db.collection('batch_resources').where('resourceId', isEqualTo: resourceId).get();
      for (final doc in brSnap.docs) {
        await doc.reference.delete();
      }

      // Clean up batches and courses linked to this resource
      final snapCourses = await _db.collection('courses').where('resourceIds', arrayContains: resourceId).get();
      for (final doc in snapCourses.docs) {
        await doc.reference.update({
          'resourceIds': FieldValue.arrayRemove([resourceId]),
        });
      }

      final snapBatches = await _db.collection('batches').where('resourceIds', arrayContains: resourceId).get();
      for (final doc in snapBatches.docs) {
        await doc.reference.update({
          'resourceIds': FieldValue.arrayRemove([resourceId]),
        });
      }

      AppLogger.s("Deleted resource $resourceId and unlinked relationships", tag: "RESOURCES");
    } catch (e, stack) {
      AppLogger.e("Error deleting resource $resourceId", error: e, stackTrace: stack, tag: "RESOURCES");
      rethrow;
    }
  }

  // --- Live Class to Batch Relationship Methods ---

  Future<void> assignLiveClassToBatch(String batchId, String liveClassId) async {
    try {
      await _db.collection('batch_live_classes').doc('${batchId}_$liveClassId').set({
        'batchId': batchId,
        'liveClassId': liveClassId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('live_classes').doc(liveClassId).update({
        'batchId': batchId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error assigning live class to batch: $e");
    }
  }

  Future<void> removeLiveClassFromBatch(String batchId, String liveClassId) async {
    try {
      await _db.collection('batch_live_classes').doc('${batchId}_$liveClassId').delete();
      await _db.collection('live_classes').doc(liveClassId).update({
        'batchId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error removing live class from batch: $e");
    }
  }

  // --- Dynamic Banners Stream ---

  static List<Map<String, dynamic>> _cachedBanners = [];
  static List<Map<String, dynamic>> get cachedBanners => _cachedBanners;

  /// Stream banner images dynamically from Firestore collection 'banners'
  Stream<List<Map<String, dynamic>>> getBannersStream() async* {
    if (_cachedBanners.isNotEmpty) {
      yield _cachedBanners;
    }
    yield* _db.collection('banners').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return data;
          })
          .where((item) {
            final active = item['isActive'];
            if (active is bool && !active) return false;
            final img = (item['imageUrl'] ?? item['desktopUrl'] ?? item['bannerUrl'] ?? item['image'] ?? item['url'] ?? '').toString().trim();
            item['resolvedImageUrl'] = img;
            return img.isNotEmpty && (img.startsWith('http://') || img.startsWith('https://') || img.startsWith('data:image') || img.startsWith('assets/'));
          })
          .toList();

      list.sort((a, b) {
        final orderA = (a['order'] is num) ? (a['order'] as num).toInt() : 999;
        final orderB = (b['order'] is num) ? (b['order'] as num).toInt() : 999;
        return orderA.compareTo(orderB);
      });

      _cachedBanners = list;
      return list;
    });
  }

  // --- Dynamic Exams Stream (matching examinantt.com Admin Exams Management) ---

  static const List<String> fallbackExams = [
    'JEE Main 2027',
    'NEET UG 2027',
    'CUET UG',
    'SSC CGL Tier 1',
    'SSC CGL Tier 2',
    'Railways',
    'UPP Constable',
    'Banking',
    'Defence exams',
    'Medical entrance',
    'Engineering entrance',
    'State PCS',
    'Boards',
    'State govt. Exam',
    'Teaching exams',
  ];

  /// Stream dynamic exams list from Firestore collection 'exams'
  Stream<List<String>> getExamsStream() {
    return _db.collection('exams').snapshots().map((snapshot) {
      final Set<String> examSet = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? data['title'] ?? data['examName'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          examSet.add(name);
        }
      }

      if (examSet.isEmpty) {
        return fallbackExams;
      }

      // Merge with popular defaults for unmatched exams if any, preserving distinct values
      final list = examSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    }).handleError((e) {
      AppLogger.e("Error in getExamsStream", error: e, tag: "EXAM_SERVICE");
      return fallbackExams;
    });
  }
}

class UserTestStatsSummary {
  final int testsAttempted;
  final double averageScore;
  final double accuracy;

  UserTestStatsSummary({
    required this.testsAttempted,
    required this.averageScore,
    required this.accuracy,
  });
}
