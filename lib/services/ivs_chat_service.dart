import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/live_class_session_models.dart';
import '../utils/app_logger.dart';

/// Amazon IVS Chat Service implementing the official AWS IVS Chat WebSocket protocol
/// with automatic token refresh, reconnection backoff, error handling,
/// and fallback to Firestore real-time messaging if tokens are pending backend deployment.
class IvsChatService extends ChangeNotifier {
  final String liveClassId;
  final String awsRegion;
  final String? chatRoomArn;
  String? chatToken;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;
  final bool isInstructor;
  final Future<String?> Function()? onRefreshToken;

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _firestoreSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  IvsChatConnectionStatus _status = IvsChatConnectionStatus.disconnected;
  final List<IvsChatMessage> _messages = [];
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  IvsChatConnectionStatus get status => _status;
  List<IvsChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _status == IvsChatConnectionStatus.connected;
  bool get isConnecting => _status == IvsChatConnectionStatus.connecting || _status == IvsChatConnectionStatus.reconnecting;
  bool get isUsingWebSocket => _channel != null;

  IvsChatService({
    required this.liveClassId,
    required this.awsRegion,
    this.chatRoomArn,
    this.chatToken,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar = '',
    this.isInstructor = false,
    this.onRefreshToken,
  });

  /// Connects to Amazon IVS Chat Room.
  Future<void> connect() async {
    if (_isDisposed) return;

    // Check if we already have an active connection
    if (_status == IvsChatConnectionStatus.connected ||
        _status == IvsChatConnectionStatus.connecting) {
      return;
    }

    _updateStatus(IvsChatConnectionStatus.connecting);

    // If chatToken is provided and valid, connect via official AWS IVS WebSocket
    if (chatToken != null && chatToken!.isNotEmpty && IvsLiveConfig.enableIvsWebSocketChat) {
      await _connectIvsWebSocket();
    } else {
      // If chatToken is empty, connect via resilient Firestore real-time adapter
      AppLogger.i("No Amazon IVS chat token provided; connecting via Firestore chat adapter", tag: "IVS_CHAT");
      _connectFirestoreChat();
    }
  }

  /// Official Amazon IVS Chat WebSocket Connection
  Future<void> _connectIvsWebSocket() async {
    try {
      _cleanupSocket();

      final region = awsRegion.isNotEmpty ? awsRegion : IvsLiveConfig.defaultAwsRegion;
      final uri = Uri.parse('wss://edge.ivschat.$region.amazonaws.com');

      AppLogger.i("Connecting to Amazon IVS Chat at $uri with token (length: ${chatToken?.length})", tag: "IVS_CHAT");

      // Connect with chatToken in the subprotocol list as required by AWS IVS Chat protocol
      _channel = WebSocketChannel.connect(
        uri,
        protocols: [chatToken!],
      );

      // Wait for handshake
      await _channel!.ready;

      if (_isDisposed) {
        _cleanupSocket();
        return;
      }

      _reconnectAttempts = 0;
      _updateStatus(IvsChatConnectionStatus.connected);
      _startHeartbeat();

      // Listen to incoming messages & events
      _socketSubscription = _channel!.stream.listen(
        (data) {
          _handleIncomingSocketMessage(data);
        },
        onError: (error) {
          AppLogger.w("Amazon IVS Chat socket error: $error", tag: "IVS_CHAT");
          _handleSocketDisconnect(error: error.toString());
        },
        onDone: () {
          AppLogger.i("Amazon IVS Chat connection closed by server", tag: "IVS_CHAT");
          _handleSocketDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      AppLogger.e("Failed to connect to Amazon IVS Chat WebSocket: $e", tag: "IVS_CHAT");
      _handleSocketDisconnect(error: e.toString());
    }
  }

  /// Parses incoming Amazon IVS Chat events and messages
  void _handleIncomingSocketMessage(dynamic rawData) {
    if (_isDisposed) return;
    try {
      final json = jsonDecode(rawData.toString()) as Map<String, dynamic>;
      final type = (json['Type'] ?? 'MESSAGE').toString().toUpperCase();

      if (type == 'MESSAGE') {
        final msg = IvsChatMessage.fromIvsPayload(json, currentUserId: currentUserId);
        // Avoid duplicate message IDs
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
          notifyListeners();
        }
      } else if (type == 'EVENT' || type == 'SYSTEM_MESSAGE') {
        final sysMsg = IvsChatMessage.fromIvsPayload(json, currentUserId: currentUserId);
        _messages.add(sysMsg);
        notifyListeners();
      } else if (type == 'DELETE_MESSAGE') {
        final delId = (json['Id'] ?? json['MessageId'] ?? '').toString();
        if (delId.isNotEmpty) {
          _messages.removeWhere((m) => m.id == delId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error parsing IVS chat message: $e");
    }
  }

  /// Sends a message using Amazon IVS Chat protocol or Firestore fallback
  Future<bool> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return false;

    // Mode 1: Amazon IVS WebSocket
    if (_channel != null && _status == IvsChatConnectionStatus.connected) {
      try {
        final payload = {
          'action': 'SEND_MESSAGE',
          'content': clean,
          'attributes': {
            'name': currentUserName,
            'avatar': currentUserAvatar,
            'role': isInstructor ? 'instructor' : 'student',
          },
        };
        _channel!.sink.add(jsonEncode(payload));
        return true;
      } catch (e) {
        AppLogger.w("Failed to send message via IVS WebSocket: $e", tag: "IVS_CHAT");
      }
    }

    // Mode 2: Firestore Real-Time Chat Fallback
    try {
      await FirebaseFirestore.instance
          .collection('live_classes')
          .doc(liveClassId)
          .collection('chat')
          .add({
        'text': clean,
        'senderName': currentUserName,
        'senderUid': currentUserId,
        'senderAvatar': currentUserAvatar,
        'isInstructor': isInstructor,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.e("Error sending chat message via Firestore fallback: $e", tag: "IVS_CHAT");
      return false;
    }
  }

  /// Fallback: Connects to Firestore real-time subcollection `live_classes/{id}/chat`
  void _connectFirestoreChat() {
    _firestoreSubscription?.cancel();
    _updateStatus(IvsChatConnectionStatus.connected);

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('live_classes')
        .doc(liveClassId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .limit(200)
        .snapshots()
        .listen(
      (snapshot) {
        if (_isDisposed) return;
        _messages.clear();
        for (final doc in snapshot.docs) {
          _messages.add(
            IvsChatMessage.fromFirestore(doc.data(), doc.id, currentUserId: currentUserId),
          );
        }
        notifyListeners();
      },
      onError: (e) {
        AppLogger.e("Firestore chat stream error: $e", tag: "IVS_CHAT");
        _updateStatus(IvsChatConnectionStatus.error);
      },
    );
  }

  /// Handles disconnection with exponential backoff and token refresh
  void _handleSocketDisconnect({String? error}) async {
    if (_isDisposed) return;
    _cleanupSocket();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _updateStatus(IvsChatConnectionStatus.reconnecting);

      final delaySec = (1 << (_reconnectAttempts - 1)).clamp(1, 10);
      AppLogger.w("Amazon IVS Chat reconnecting in ${delaySec}s (Attempt $_reconnectAttempts/$_maxReconnectAttempts)", tag: "IVS_CHAT");

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySec), () async {
        if (_isDisposed) return;

        // Attempt to request a fresh token if callback provided
        if (onRefreshToken != null) {
          try {
            final freshToken = await onRefreshToken!();
            if (freshToken != null && freshToken.isNotEmpty) {
              chatToken = freshToken;
            }
          } catch (_) {}
        }

        connect();
      });
    } else {
      AppLogger.e("Amazon IVS Chat max reconnect attempts reached. Falling back to Firestore.", tag: "IVS_CHAT");
      _updateStatus(IvsChatConnectionStatus.error);
      // Seamlessly fall back to Firestore listener so students never lose chat
      _connectFirestoreChat();
    }
  }

  /// Starts a light heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_channel != null && _status == IvsChatConnectionStatus.connected) {
        try {
          // AWS IVS Chat keeps connection open on message activity
          _channel!.sink.add(jsonEncode({'action': 'PING'}));
        } catch (_) {}
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStatus(IvsChatConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  void _cleanupSocket() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    try {
      _channel?.sink.close(1000, 'Screen closed');
    } catch (_) {}
    _channel = null;
  }

  /// Manually retry connection
  void retry() {
    _reconnectAttempts = 0;
    connect();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _cleanupSocket();
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    super.dispose();
  }
}
