import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../models/live_class_session_models.dart';
import '../utils/app_logger.dart';

/// Service responsible for managing Live Class Join Authorization,
/// Amazon IVS stream access tokens, student attendance tracking,
/// and backend API communication.
class IvsLiveService {
  static final IvsLiveService _instance = IvsLiveService._internal();
  factory IvsLiveService() => _instance;
  IvsLiveService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-flight join tracker to prevent duplicate join requests
  final Set<String> _inFlightJoins = <String>{};

  /// Requests access to an Amazon IVS Live Class session from the backend.
  /// 
  /// 1. Verifies student authentication and retrieves fresh Bearer ID token.
  /// 2. Verifies student batch enrollment / class purchase permissions.
  /// 3. Communicates with backend Join API endpoint (or isolated Firestore adapter).
  /// 4. Logs real-time student attendance on the backend.
  /// 5. Returns authorized [LiveClassAccessSession] with verified playback and chat tokens.
  Future<LiveClassAccessSession> requestJoinAccess({
    required LiveClass liveClass,
    String? currentUid,
    String? currentUserName,
    Set<String> purchasedBatchIds = const {},
    Set<String> purchasedItemIds = const {},
  }) async {
    final classId = liveClass.id;

    // 1. Prevent duplicate simultaneous join requests
    if (_inFlightJoins.contains(classId)) {
      AppLogger.w("Join request already in progress for class: $classId", tag: "IVS_SERVICE");
      return LiveClassAccessSession(
        liveClassId: classId,
        isAuthorized: false,
        playbackUrl: '',
        message: 'A join request is already in progress. Please wait...',
      );
    }

    _inFlightJoins.add(classId);

    try {
      // 2. Authenticate user
      final user = _auth.currentUser;
      final effectiveUid = currentUid ?? user?.uid;
      final effectiveName = currentUserName ?? user?.displayName ?? 'Student';

      if (effectiveUid == null || effectiveUid.isEmpty) {
        return LiveClassAccessSession(
          liveClassId: classId,
          isAuthorized: false,
          playbackUrl: '',
          message: 'Please sign in to join this live classroom session.',
        );
      }

      // Fetch fresh Firebase ID token for authorized Bearer header
      String? bearerToken;
      try {
        bearerToken = await user?.getIdToken(false);
      } catch (e) {
        AppLogger.w("Failed to fetch fresh Bearer token: $e", tag: "IVS_SERVICE");
      }

      // 3. Permission & Enrollment check
      final bool hasAccess = liveClass.isUserEnrolled(
        uid: effectiveUid,
        purchasedBatchIds: purchasedBatchIds,
        purchasedItemIds: purchasedItemIds,
      );

      if (!hasAccess && !liveClass.isFree && liveClass.price > 0) {
        AppLogger.w("Access denied: Student $effectiveUid not enrolled in class $classId", tag: "IVS_SERVICE");
        return LiveClassAccessSession(
          liveClassId: classId,
          isAuthorized: false,
          playbackUrl: '',
          message: 'You are not enrolled in this live class. Please purchase or unlock the batch to join.',
        );
      }

      // 4. Backend Join Flow:
      // If a custom HTTP backend API URL is configured (e.g. Node/Express, AWS API Gateway),
      // we make an authorized HTTP POST call with the Bearer token.
      if (IvsLiveConfig.customJoinEndpointUrl != null &&
          IvsLiveConfig.customJoinEndpointUrl!.isNotEmpty) {
        try {
          final session = await _callCustomJoinApi(
            endpointUrl: IvsLiveConfig.customJoinEndpointUrl!,
            classId: classId,
            bearerToken: bearerToken,
            userId: effectiveUid,
          );
          if (session != null) {
            _recordAttendance(classId: classId, uid: effectiveUid, userName: effectiveName);
            return session;
          }
        } catch (e) {
          AppLogger.e("Custom Join API failed, falling back to Firestore adapter: $e", tag: "IVS_SERVICE");
        }
      }

      // Isolated Firestore/Backend Adapter Flow:
      // Fetches the authoritative, fresh live class document directly from Firestore
      final docSnap = await _db.collection('live_classes').doc(classId).get();
      final data = docSnap.exists ? (docSnap.data() ?? {}) : <String, dynamic>{};

      // Extract playback URL with highest resolution priority
      String playbackUrl = (data['playbackUrl'] ??
              data['streamUrl'] ??
              data['videoUrl'] ??
              liveClass.videoUrl)
          .toString()
          .trim();

      // Check if class is ended/recorded
      final isRecorded = data['status'] == 'completed' ||
          data['isRecorded'] == true ||
          liveClass.isRecorded;

      String fallbackRecordingUrl = '';
      if (playbackUrl.isEmpty || (isRecorded && data['recordingUrl'] != null)) {
        fallbackRecordingUrl = (data['recordingUrl'] ?? liveClass.recordingUrl).toString().trim();
        if (fallbackRecordingUrl.isNotEmpty) {
          playbackUrl = fallbackRecordingUrl;
        }
      }

      final streamServer = (data['streamServer'] ?? liveClass.streamServer).toString();
      final awsRegion = (data['awsRegion'] ??
              data['region'] ??
              liveClass.awsRegion.isNotEmpty
                  ? liveClass.awsRegion
                  : IvsLiveConfig.extractRegionFromUrl(playbackUrl))
          .toString();

      final channelArn = (data['awsChannelArn'] ?? data['channelArn'] ?? liveClass.awsChannelArn).toString();
      final chatRoomArn = (data['chatRoomArn'] ?? data['roomArn'] ?? liveClass.chatRoomArn).toString();
      final chatToken = (data['chatToken'] ?? liveClass.chatToken).toString();

      DateTime? chatExpiration;
      if (data['chatTokenExpiration'] != null) {
        final rawExp = data['chatTokenExpiration'];
        if (rawExp is Timestamp) {
          chatExpiration = rawExp.toDate();
        } else if (rawExp is String) {
          chatExpiration = DateTime.tryParse(rawExp);
        }
      }

      // Record student attendance asynchronously
      _recordAttendance(classId: classId, uid: effectiveUid, userName: effectiveName);

      AppLogger.s("Successfully authorized Amazon IVS live stream for class: $classId", tag: "IVS_SERVICE");

      return LiveClassAccessSession(
        liveClassId: classId,
        isAuthorized: true,
        playbackUrl: playbackUrl,
        streamServer: streamServer,
        awsRegion: awsRegion.isNotEmpty ? awsRegion : IvsLiveConfig.defaultAwsRegion,
        channelArn: channelArn,
        chatRoomArn: chatRoomArn,
        chatToken: chatToken,
        chatTokenExpiration: chatExpiration,
        isRecordedFallback: isRecorded,
        rawResponse: data,
      );
    } catch (e, stack) {
      AppLogger.e("Error requesting live class join access: $e", error: e, tag: "IVS_SERVICE");
      debugPrintStack(stackTrace: stack);
      return LiveClassAccessSession(
        liveClassId: classId,
        isAuthorized: false,
        playbackUrl: '',
        message: 'Failed to connect to class server: $e',
      );
    } finally {
      _inFlightJoins.remove(classId);
    }
  }

  /// Requests a fresh Amazon IVS Chat token for the room when current token is expiring or refreshed.
  Future<String?> refreshChatToken({
    required String classId,
    required String chatRoomArn,
    String? currentUid,
  }) async {
    try {
      final user = _auth.currentUser;
      final uid = currentUid ?? user?.uid;
      final idToken = await user?.getIdToken(false);

      if (IvsLiveConfig.customChatTokenRefreshUrl != null &&
          IvsLiveConfig.customChatTokenRefreshUrl!.isNotEmpty) {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse(IvsLiveConfig.customChatTokenRefreshUrl!));
        request.headers.set('Content-Type', 'application/json');
        if (idToken != null) {
          request.headers.set('Authorization', 'Bearer $idToken');
        }
        request.write(jsonEncode({
          'liveClassId': classId,
          'chatRoomArn': chatRoomArn,
          'userId': uid,
        }));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        client.close();

        if (response.statusCode == 200) {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final token = json['token'] ?? json['chatToken'];
          if (token != null) return token.toString();
        }
      }

      // Check Firestore document for updated chatToken
      final doc = await _db.collection('live_classes').doc(classId).get();
      if (doc.exists && doc.data() != null) {
        final token = doc.data()?['chatToken'];
        if (token != null && token.toString().isNotEmpty) {
          return token.toString();
        }
      }
    } catch (e) {
      AppLogger.w("Failed to refresh Amazon IVS Chat token: $e", tag: "IVS_SERVICE");
    }
    return null;
  }

  /// Records verified student attendance in the live classroom
  void _recordAttendance({
    required String classId,
    required String uid,
    required String userName,
  }) {
    try {
      _db
          .collection('live_classes')
          .doc(classId)
          .collection('attendance')
          .doc(uid)
          .set({
        'uid': uid,
        'studentName': userName,
        'name': userName,
        'joinedAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'status': 'online',
        'role': 'student',
      }, SetOptions(merge: true)).catchError((_) {});

      _db
          .collection('live_classes')
          .doc(classId)
          .collection('participants')
          .doc(uid)
          .set({
        'uid': uid,
        'name': userName,
        'studentName': userName,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'role': 'student',
      }, SetOptions(merge: true)).catchError((_) {});

      _db.collection('live_classes').doc(classId).set({
        'activeViewers': FieldValue.increment(1),
        'enrolledStudentIds': FieldValue.arrayUnion([uid]),
        'activeParticipants': FieldValue.arrayUnion([userName]),
        'lastStudentJoined': userName,
        'lastStudentJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {});
    } catch (_) {}
  }

  /// Helper to call custom HTTP backend endpoint with standard Bearer authorization
  Future<LiveClassAccessSession?> _callCustomJoinApi({
    required String endpointUrl,
    required String classId,
    required String? bearerToken,
    required String userId,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(endpointUrl));
      request.headers.set('Content-Type', 'application/json');
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $bearerToken');
      }
      request.write(jsonEncode({
        'liveClassId': classId,
        'userId': userId,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return LiveClassAccessSession.fromMap(json, classId);
      } else {
        AppLogger.w("Custom Join API responded with HTTP ${response.statusCode}: $body", tag: "IVS_SERVICE");
      }
    } catch (e) {
      client.close();
      rethrow;
    }
    return null;
  }
}
