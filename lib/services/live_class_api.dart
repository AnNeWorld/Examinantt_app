import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/jitsi_live_models.dart';

/// Service for Live Class API integration with web backend.
/// Handles:
/// 1. Fetching live classes from backend (GET /api/live-classes or /api/sessions)
/// 2. Requesting authorized room tokens & JWT (POST /api/live-token)
class LiveClassApi {
  // Configurable base URL. Default auto-detects Android emulator vs Desktop/Web.
  static String? _customBaseUrl;

  static void setBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    // Android emulator routes host machine localhost through 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // 1. Sabhi Live & Upcoming Classes lana
  static Future<List<dynamic>> getLiveClasses() async {
    try {
      final uri = Uri.parse('$baseUrl/api/live-classes');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['classes'] ?? data['sessions'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('[LiveClassApi] Error fetching live classes: $e');
      return [];
    }
  }

  // 2. Live Class me join hone ke liye Room Token lana
  static Future<Map<String, dynamic>?> getLiveToken({
    required String classId,
    required String roomId,
    required String studentName,
    required String studentEmail,
    required String studentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/live-token');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': classId,
              'classId': classId,
              'roomId': roomId,
              'roomName': roomId,
              'userId': studentId,
              'userName': studentName,
              'userEmail': studentEmail,
              'isInstructor': false,
              'user': {
                'id': studentId,
                'name': studentName,
                'email': studentEmail,
                'role': 'student',
              },
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[LiveClassApi] Successfully obtained live token for room: ${data['roomName']}');
        return data;
      } else {
        debugPrint('[LiveClassApi] Token request returned HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[LiveClassApi] Token API unreachable ($e), falling back to direct room connection');
    }

    // Direct classroom room fallback matching examinantt.com website room config
    final fullRoom = JitsiLiveConfig.calculateWebsiteRoomName(
      roomName: roomId,
      classId: classId,
    );
    return {
      'roomName': fullRoom,
      'domain': JitsiLiveConfig.defaultJaasDomain,
      'appId': JitsiLiveConfig.defaultAppId,
      'token': null,
      'status': 'live',
      'isLive': true,
    };
  }
}
