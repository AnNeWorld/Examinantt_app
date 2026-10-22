import 'dart:io';
import 'package:flutter/foundation.dart';
import 'content_models.dart';

/// Lifecycle status for Jitsi Virtual Classrooms
enum JitsiSessionStatus {
  notScheduled,
  scheduled,
  live,
  completed,
}

/// Meeting State in the Flutter App
enum JitsiClassroomState {
  initial,
  scheduledWaiting,
  requestingToken,
  joining,
  live,
  leftLocally,
  classEnded,
  error,
}

/// Jitsi Live Classroom Session metadata (synchronized with Website & Backend)
class JitsiLiveSession {
  final String id;
  final String courseId;
  final String courseTitle;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final String status; // 'scheduled' | 'live' | 'completed' | 'not_scheduled'
  final DateTime? scheduledStartTime;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final String roomName;
  final String recordingUrl;
  final String fallbackProvider;
  final String fallbackUrl;
  final Map<String, dynamic> rawData;

  const JitsiLiveSession({
    required this.id,
    this.courseId = '',
    this.courseTitle = '',
    required this.title,
    this.description = '',
    this.instructorId = '',
    this.instructorName = 'Examinantt Faculty',
    this.status = 'scheduled',
    this.scheduledStartTime,
    this.startedAt,
    this.endedAt,
    this.durationMinutes = 60,
    required this.roomName,
    this.recordingUrl = '',
    this.fallbackProvider = 'jitsi',
    this.fallbackUrl = '',
    this.rawData = const {},
  });

  bool get isLive => status.toLowerCase() == 'live';
  bool get isUpcoming => status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'not_scheduled';
  bool get isCompleted => status.toLowerCase() == 'completed' || recordingUrl.isNotEmpty;

  factory JitsiLiveSession.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = (docId ?? map['id'] ?? map['sessionId'] ?? '').toString();
    final title = (map['title'] ?? map['name'] ?? 'Live Classroom').toString();
    final room = (map['roomName'] ?? map['room'] ?? 'classroom-$id').toString();

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      if (val.runtimeType.toString().contains('Timestamp')) {
        try {
          return (val as dynamic).toDate();
        } catch (_) {}
      }
      return null;
    }

    return JitsiLiveSession(
      id: id,
      courseId: (map['courseId'] ?? map['batchId'] ?? '').toString(),
      courseTitle: (map['courseTitle'] ?? map['batchName'] ?? '').toString(),
      title: title,
      description: (map['description'] ?? '').toString(),
      instructorId: (map['instructorId'] ?? '').toString(),
      instructorName: (map['instructorName'] ?? map['instructor'] ?? map['educatorName'] ?? 'Examinantt Faculty').toString(),
      status: (map['status'] ?? 'scheduled').toString().toLowerCase(),
      scheduledStartTime: parseDate(map['scheduledStartTime'] ?? map['startTime']),
      startedAt: parseDate(map['startedAt']),
      endedAt: parseDate(map['endedAt']),
      durationMinutes: int.tryParse(map['durationMinutes']?.toString() ?? '60') ?? 60,
      roomName: room,
      recordingUrl: (map['recordingUrl'] ?? map['replayUrl'] ?? '').toString(),
      fallbackProvider: (map['fallbackProvider'] ?? 'jitsi').toString(),
      fallbackUrl: (map['fallbackUrl'] ?? '').toString(),
      rawData: map,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'status': status,
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'roomName': roomName,
      'recordingUrl': recordingUrl,
      'fallbackProvider': fallbackProvider,
      'fallbackUrl': fallbackUrl,
    };
  }

  /// Convert to existing LiveClass model for backwards-compatibility with existing widgets
  LiveClass toLiveClass() {
    return LiveClass(
      id: id,
      title: title,
      instructor: instructorName,
      description: description,
      videoUrl: recordingUrl,
      time: isLive ? 'Live Now' : (scheduledStartTime != null ? '${scheduledStartTime!.hour}:${scheduledStartTime!.minute.toString().padLeft(2, '0')}' : 'Scheduled'),
      durationMinutes: durationMinutes,
      status: status,
      isLive: isLive,
      isUpcoming: isUpcoming,
      isRecorded: isCompleted,
      streamServer: 'Jitsi Meet / 8x8 JaaS',
      streamProvider: 'jitsi',
      roomName: roomName,
      recordingUrl: recordingUrl,
      batchId: courseId,
      batchName: courseTitle,
      price: 0.0,
      isFree: true,
    );
  }
}

/// Authorized Room Token & Configuration returned by backend /api/live-token
class JitsiLiveTokenInfo {
  final String token;
  final String roomName;
  final String domain;
  final String appId;
  final String serverUrl;
  final String subject;
  final String status;
  final bool isLive;
  final DateTime? startedAt;

  const JitsiLiveTokenInfo({
    required this.token,
    required this.roomName,
    required this.domain,
    this.appId = '',
    required this.serverUrl,
    this.subject = 'Examinantt Live Lecture',
    this.status = 'live',
    this.isLive = true,
    this.startedAt,
  });

  factory JitsiLiveTokenInfo.fromMap(Map<String, dynamic> map) {
    DateTime? started;
    if (map['startedAt'] is String) {
      started = DateTime.tryParse(map['startedAt']);
    }

    final rawDomain = (map['domain'] ?? '8x8.vc').toString();
    String sUrl = (map['serverUrl'] ?? '').toString();
    if (sUrl.isEmpty) {
      sUrl = rawDomain.startsWith('http') ? rawDomain : 'https://$rawDomain';
    }

    return JitsiLiveTokenInfo(
      token: (map['token'] ?? '').toString(),
      roomName: (map['roomName'] ?? '').toString(),
      domain: rawDomain,
      appId: (map['appId'] ?? '').toString(),
      serverUrl: sUrl,
      subject: (map['subject'] ?? 'Live Classroom').toString(),
      status: (map['status'] ?? 'live').toString(),
      isLive: map['isLive'] == true || map['status'] == 'live',
      startedAt: started,
    );
  }
}

/// Central configuration for Jitsi Classroom Backend connection
class JitsiLiveConfig {
  static String? _customBackendUrl;

  /// Custom Base URL (can be set dynamically in main or settings)
  static void setBackendBaseUrl(String url) {
    _customBackendUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Automatically resolves the correct backend URL depending on platform
  static String get backendBaseUrl {
    if (_customBackendUrl != null && _customBackendUrl!.isNotEmpty) {
      return _customBackendUrl!;
    }

    // Default to Next.js dev server on local machine:
    // Android emulator routes host machine localhost through 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Default public Jitsi fallback domain if JaaS is not configured
  static const String defaultPublicJitsiDomain = 'meet.jit.si';
  static const String defaultJaasDomain = '8x8.vc';
  static const String defaultAppId = 'vpaas-magic-cookie-fe717ca9148443d190318fca9291b5ff';

  static String _defaultDomain = defaultJaasDomain;

  static String get defaultDomain => _defaultDomain;

  static void setDefaultDomain(String domain) {
    _defaultDomain = domain.trim();
  }

  /// Resolve Jitsi domain based on server/provider hints
  static String resolveDomain(String? streamServer) {
    if (streamServer != null && streamServer.isNotEmpty) {
      final s = streamServer.toLowerCase();
      if (s.contains('8x8')) return defaultJaasDomain;
      if (s.contains('meet.jit.si')) return defaultPublicJitsiDomain;
      if (s.contains('.')) {
        // Custom self-hosted domain
        return streamServer.replaceFirst(RegExp(r'^https?://'), '').split('/')[0];
      }
    }
    return defaultJaasDomain;
  }

  /// Exact room name algorithm used by https://www.examinantt.com/dashboard/live/:classId
  /// The website uses:
  ///   const t = "vpaas-magic-cookie-fe717ca9148443d190318fca9291b5ff";
  ///   const s = (n.roomId || n.classId || "classroom").toLowerCase().replace(/[^a-z0-9_-]/g, "_");
  ///   const r = s.startsWith("examinant_") ? s : `examinant_${s}`;
  ///   return `${t}/${r}`;
  /// Host (web admin) and Student (mobile app) MUST join the identical 8x8 JaaS room name.
  static String calculateWebsiteRoomName({String? roomName, required String classId, String? appId}) {
    final effectiveAppId = (appId != null && appId.trim().isNotEmpty) ? appId.trim() : defaultAppId;

    // If roomName already contains the full tenant/appId path, return as-is
    if (roomName != null && roomName.contains('/')) {
      return roomName.trim();
    }

    final raw = (roomName != null && roomName.trim().isNotEmpty) ? roomName.trim() : classId.trim();
    final clean = raw.isNotEmpty ? raw : 'classroom';

    final s = clean.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final r = s.startsWith('examinant_') ? s : 'examinant_$s';

    return '$effectiveAppId/$r';
  }

  /// Sanitize meeting room names to ensure 100% match with website
  static String sanitizeRoomName(String rawName, {String? appId}) {
    final effectiveAppId = (appId != null && appId.trim().isNotEmpty) ? appId.trim() : defaultAppId;
    String clean = rawName.trim();
    if (clean.isEmpty) clean = 'virtual-classroom';

    if (!clean.startsWith('$effectiveAppId/')) {
      return '$effectiveAppId/$clean';
    }
    return clean;
  }
}

