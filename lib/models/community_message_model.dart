import 'package:cloud_firestore/cloud_firestore.dart';

enum UserCommunityRole {
  student,
  teacher,
  mentor,
  admin,
}

class CommunityMessage {
  final String id;
  final String channel; // e.g. 'general', 'physics', 'chemistry', 'maths', 'faculty'
  final String senderId;
  final String senderName;
  final String senderRole; // 'student', 'teacher', 'mentor', 'admin'
  final String senderTag; // e.g. 'Class 12 • JEE Aspirant', 'Physics Faculty • IIT-D'
  final String text;
  final DateTime timestamp;
  final String? replyToId;
  final String? replyToName;
  final String? replyToText;
  final bool isTeacherReply;
  final Map<String, int> reactions; // emoji -> count
  final List<String> userLikedEmojis; // emojis selected by current user
  final String? attachmentType; // 'image', 'formula', 'pdf'
  final String? attachmentUrl;

  CommunityMessage({
    required this.id,
    this.channel = 'general',
    required this.senderId,
    required this.senderName,
    this.senderRole = 'student',
    this.senderTag = 'Student',
    required this.text,
    required this.timestamp,
    this.replyToId,
    this.replyToName,
    this.replyToText,
    this.isTeacherReply = false,
    this.reactions = const {},
    this.userLikedEmojis = const [],
    this.attachmentType,
    this.attachmentUrl,
  });

  bool get isFaculty => senderRole.toLowerCase() == 'teacher' || senderRole.toLowerCase() == 'faculty' || isTeacherReply;

  factory CommunityMessage.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime ts;
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    Map<String, int> rxn = {};
    if (data['reactions'] is Map) {
      (data['reactions'] as Map).forEach((k, v) {
        if (v is num) {
          rxn[k.toString()] = v.toInt();
        }
      });
    }

    return CommunityMessage(
      id: documentId,
      channel: data['channel']?.toString() ?? 'general',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Student',
      senderRole: data['senderRole']?.toString() ?? 'student',
      senderTag: data['senderTag']?.toString() ?? 'Student',
      text: data['text']?.toString() ?? '',
      timestamp: ts,
      replyToId: data['replyToId']?.toString(),
      replyToName: data['replyToName']?.toString(),
      replyToText: data['replyToText']?.toString(),
      isTeacherReply: data['isTeacherReply'] == true || (data['senderRole']?.toString().toLowerCase() == 'teacher'),
      reactions: rxn,
      userLikedEmojis: (data['userLikedEmojis'] as List?)?.map((e) => e.toString()).toList() ?? [],
      attachmentType: data['attachmentType']?.toString(),
      attachmentUrl: data['attachmentUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'channel': channel,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderTag': senderTag,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToName != null) 'replyToName': replyToName,
      if (replyToText != null) 'replyToText': replyToText,
      'isTeacherReply': isTeacherReply,
      'reactions': reactions,
      'userLikedEmojis': userLikedEmojis,
      if (attachmentType != null) 'attachmentType': attachmentType,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    };
  }

  CommunityMessage copyWith({
    String? id,
    String? channel,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderTag,
    String? text,
    DateTime? timestamp,
    String? replyToId,
    String? replyToName,
    String? replyToText,
    bool? isTeacherReply,
    Map<String, int>? reactions,
    List<String>? userLikedEmojis,
    String? attachmentType,
    String? attachmentUrl,
  }) {
    return CommunityMessage(
      id: id ?? this.id,
      channel: channel ?? this.channel,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderTag: senderTag ?? this.senderTag,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      replyToName: replyToName ?? this.replyToName,
      replyToText: replyToText ?? this.replyToText,
      isTeacherReply: isTeacherReply ?? this.isTeacherReply,
      reactions: reactions ?? this.reactions,
      userLikedEmojis: userLikedEmojis ?? this.userLikedEmojis,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}
