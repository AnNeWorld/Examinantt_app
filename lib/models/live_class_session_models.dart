/// Status of the Amazon IVS Chat connection.
enum IvsChatConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Authorized access session returned when requesting access to a live class.
/// Contains verified playback authorization and short-lived Amazon IVS Chat tokens.
class LiveClassAccessSession {
  final String liveClassId;
  final bool isAuthorized;
  final String playbackUrl;
  final String streamServer;
  final String awsRegion;
  final String channelArn;
  final String chatRoomArn;
  final String chatToken;
  final DateTime? chatTokenExpiration;
  final String? chatSessionId;
  final String? message;
  final bool isRecordedFallback;
  final Map<String, dynamic> rawResponse;

  const LiveClassAccessSession({
    required this.liveClassId,
    required this.isAuthorized,
    required this.playbackUrl,
    this.streamServer = 'Amazon AWS IVS',
    this.awsRegion = 'us-west-2',
    this.channelArn = '',
    this.chatRoomArn = '',
    this.chatToken = '',
    this.chatTokenExpiration,
    this.chatSessionId,
    this.message,
    this.isRecordedFallback = false,
    this.rawResponse = const {},
  });

  bool get hasValidChatToken =>
      chatToken.isNotEmpty &&
      (chatTokenExpiration == null || chatTokenExpiration!.isAfter(DateTime.now()));

  bool get isIvsStream {
    final lower = playbackUrl.toLowerCase();
    return streamServer.toLowerCase().contains('ivs') ||
        lower.contains('live-video.net') ||
        channelArn.isNotEmpty;
  }

  factory LiveClassAccessSession.fromMap(Map<String, dynamic> map, String classId) {
    DateTime? exp;
    final expRaw = map['chatTokenExpiration'] ?? map['sessionExpiration'] ?? map['tokenExpiration'];
    if (expRaw is String && expRaw.isNotEmpty) {
      exp = DateTime.tryParse(expRaw);
    } else if (expRaw is int) {
      exp = DateTime.fromMillisecondsSinceEpoch(expRaw);
    }

    return LiveClassAccessSession(
      liveClassId: classId,
      isAuthorized: map['isAuthorized'] == true || map['authorized'] == true || map['success'] == true,
      playbackUrl: (map['playbackUrl'] ?? map['streamUrl'] ?? map['videoUrl'] ?? '').toString().trim(),
      streamServer: (map['streamServer'] ?? map['server'] ?? 'Amazon AWS IVS').toString(),
      awsRegion: (map['awsRegion'] ?? map['region'] ?? 'us-west-2').toString(),
      channelArn: (map['channelArn'] ?? map['awsChannelArn'] ?? '').toString(),
      chatRoomArn: (map['chatRoomArn'] ?? map['roomArn'] ?? '').toString(),
      chatToken: (map['chatToken'] ?? map['token'] ?? '').toString(),
      chatTokenExpiration: exp,
      chatSessionId: map['chatSessionId']?.toString(),
      message: map['message']?.toString(),
      isRecordedFallback: map['isRecordedFallback'] == true,
      rawResponse: map,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'liveClassId': liveClassId,
      'isAuthorized': isAuthorized,
      'playbackUrl': playbackUrl,
      'streamServer': streamServer,
      'awsRegion': awsRegion,
      'channelArn': channelArn,
      'chatRoomArn': chatRoomArn,
      'chatToken': chatToken,
      'chatTokenExpiration': chatTokenExpiration?.toIso8601String(),
      'chatSessionId': chatSessionId,
      'message': message,
      'isRecordedFallback': isRecordedFallback,
    };
  }
}

/// Amazon IVS Chat Message Model (conforming to AWS IVS Chat WebSocket protocol).
class IvsChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime timestamp;
  final bool isInstructor;
  final bool isSystem;
  final bool isSelf;
  final Map<String, dynamic> rawPayload;

  const IvsChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.text,
    required this.timestamp,
    this.isInstructor = false,
    this.isSystem = false,
    this.isSelf = false,
    this.rawPayload = const {},
  });

  factory IvsChatMessage.fromIvsPayload(Map<String, dynamic> data, {String? currentUserId}) {
    final type = (data['Type'] ?? 'MESSAGE').toString().toUpperCase();
    final id = (data['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();
    final content = (data['Content'] ?? data['content'] ?? data['text'] ?? '').toString();

    DateTime time = DateTime.now();
    final sendTime = data['SendTime'] ?? data['sendTime'] ?? data['timestamp'];
    if (sendTime is String) {
      time = DateTime.tryParse(sendTime) ?? DateTime.now();
    } else if (sendTime is int) {
      time = DateTime.fromMillisecondsSinceEpoch(sendTime);
    }

    final senderObj = data['Sender'] is Map<String, dynamic>
        ? data['Sender'] as Map<String, dynamic>
        : (data['sender'] is Map<String, dynamic> ? data['sender'] as Map<String, dynamic> : {});

    final senderId = (senderObj['UserId'] ?? senderObj['userId'] ?? data['senderUid'] ?? '').toString();
    final senderAttrs = senderObj['Attributes'] is Map
        ? senderObj['Attributes'] as Map
        : (data['attributes'] is Map ? data['attributes'] as Map : {});

    final senderName = (senderAttrs['name'] ??
            senderAttrs['displayName'] ??
            data['senderName'] ??
            (senderId.isNotEmpty ? 'Student ${senderId.substring(0, senderId.length > 4 ? 4 : senderId.length)}' : 'Student'))
        .toString();

    final senderAvatar = (senderAttrs['avatar'] ?? data['senderAvatar'] ?? '').toString();
    final role = (senderAttrs['role'] ?? data['role'] ?? '').toString().toLowerCase();
    final isInstructor = role == 'instructor' ||
        role == 'teacher' ||
        role == 'faculty' ||
        data['isInstructor'] == true;
    final isSystem = type == 'EVENT' || type == 'SYSTEM_MESSAGE' || data['isSystem'] == true;
    final isSelf = currentUserId != null && currentUserId.isNotEmpty && senderId == currentUserId;

    return IvsChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      text: content,
      timestamp: time,
      isInstructor: isInstructor,
      isSystem: isSystem,
      isSelf: isSelf,
      rawPayload: data,
    );
  }

  factory IvsChatMessage.fromFirestore(Map<String, dynamic> data, String docId, {String? currentUserId}) {
    final text = (data['text'] ?? data['message'] ?? '').toString();
    final senderName = (data['senderName'] ?? 'Student').toString();
    final senderUid = (data['senderUid'] ?? data['senderId'] ?? '').toString();
    final isInstructor = data['isInstructor'] == true;

    DateTime time = DateTime.now();
    final ts = data['timestamp'];
    if (ts != null) {
      try {
        time = (ts as dynamic).toDate();
      } catch (_) {
        if (ts is String) {
          time = DateTime.tryParse(ts) ?? DateTime.now();
        }
      }
    }

    return IvsChatMessage(
      id: docId,
      senderId: senderUid,
      senderName: senderName,
      senderAvatar: (data['senderAvatar'] ?? '').toString(),
      text: text,
      timestamp: time,
      isInstructor: isInstructor,
      isSystem: data['isSystem'] == true,
      isSelf: currentUserId != null && currentUserId.isNotEmpty && senderUid == currentUserId,
      rawPayload: data,
    );
  }
}

/// Isolated Backend/AWS Configuration point for Amazon IVS endpoints.
/// If custom backend HTTP routes or AWS Lambda functions are deployed, they can be configured here.
class IvsLiveConfig {
  /// Optional custom backend join endpoint (e.g., https://api.examinantt.com/live-classes/join)
  static String? customJoinEndpointUrl;

  /// Optional custom chat token refresh endpoint
  static String? customChatTokenRefreshUrl;

  /// Default AWS Region for Amazon IVS streaming & chat rooms
  static String defaultAwsRegion = 'us-west-2';

  /// Whether to use real AWS IVS Chat WebSocket protocol
  static bool enableIvsWebSocketChat = true;

  /// Helper to extract AWS region from an IVS playback URL (e.g. https://xxxx.us-west-2.playback.live-video.net/...)
  static String extractRegionFromUrl(String url) {
    if (url.isEmpty) return defaultAwsRegion;
    final regExp = RegExp(r'\.([a-z]{2}-[a-z]+-\d+)\.playback\.live-video\.net', caseSensitive: false);
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? defaultAwsRegion;
    }
    return defaultAwsRegion;
  }
}
