import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveClass {
  final String id;
  final String title;
  final String instructor;
  final String educatorAvatar;
  final String qualification;
  final String videoUrl;
  final String thumbnailUrl;
  final String subject;
  final String examCategory;
  final String description;
  final String chapter;
  final String time;
  final DateTime? scheduledStartTime;
  final int durationMinutes;
  final String status; // 'live' | 'upcoming' | 'completed'
  final bool isLive;
  final bool isUpcoming;
  final bool isRecorded;
  final String activeViewers;
  final String remainingTime;
  final String notesUrl;
  final bool hasLiveChat;
  final String batchId;
  final String batchName;
  final double price;
  final double? originalPrice;
  final bool isFree;
  final List<String> enrolledStudentIds;
  final String streamServer; // 'Amazon AWS IVS' / 'AWS MediaLive'
  final String awsChannelArn;
  final String awsRegion;
  final String chatRoomArn;
  final String chatToken;
  final String recordingUrl;
  final String streamProvider;
  final String roomName;
  final Color color;

  LiveClass({
    required this.id,
    required this.title,
    required this.instructor,
    this.educatorAvatar = '',
    this.qualification = 'Examinantt Master Faculty',
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.subject = 'General',
    this.examCategory = 'All Exams',
    this.description = '',
    this.chapter = '',
    required this.time,
    this.scheduledStartTime,
    this.durationMinutes = 60,
    this.status = 'upcoming',
    required this.isLive,
    this.isUpcoming = false,
    required this.isRecorded,
    this.activeViewers = '0',
    this.remainingTime = '',
    this.notesUrl = '',
    this.hasLiveChat = true,
    this.batchId = '',
    this.batchName = '',
    this.price = 0.0,
    this.originalPrice,
    this.isFree = true,
    this.enrolledStudentIds = const [],
    this.streamServer = 'Amazon AWS IVS',
    this.awsChannelArn = '',
    this.awsRegion = 'us-west-2',
    this.chatRoomArn = '',
    this.chatToken = '',
    this.recordingUrl = '',
    this.streamProvider = '',
    this.roomName = '',
    Color? color,
  }) : color = color ?? _getColorForSubject(subject);

  bool get isIvsStream {
    final s = streamServer.toLowerCase();
    final v = videoUrl.toLowerCase();
    return awsChannelArn.isNotEmpty ||
        v.contains('live-video.net') ||
        (s.contains('ivs') && (v.contains('.m3u8') || awsChannelArn.isNotEmpty));
  }

  bool get isJitsi {
    final p = streamProvider.toLowerCase().trim();
    final s = streamServer.toLowerCase().trim();
    final v = videoUrl.toLowerCase().trim();
    final r = roomName.toLowerCase().trim();

    // 1. Explicit Jitsi indicators
    if (p.contains('jitsi') || s.contains('jitsi') || s.contains('8x8')) return true;
    if (v.contains('meet.jit.si') || v.contains('8x8.vc')) return true;
    if (r.isNotEmpty) return true;

    // 2. External third-party or dedicated stream
    if (isYoutube || isGoogleMeet || isZoom) return false;
    if (isIvsStream) return false;
    if (v.endsWith('.mp4')) return false;

    // 3. Default: Website examinantt.com live classes run via Jitsi Meet
    return true;
  }

  bool get isYoutube {
    final p = streamProvider.toLowerCase();
    final u = videoUrl.toLowerCase();
    return p.contains('youtube') || u.contains('youtube.com') || u.contains('youtu.be');
  }

  bool get isGoogleMeet {
    final p = streamProvider.toLowerCase().trim();
    final u = videoUrl.toLowerCase().trim();
    if (p.contains('jitsi') || u.contains('jit.si') || u.contains('8x8')) return false;
    return p.contains('google') || p == 'gmeet' || u.contains('meet.google.com');
  }

  bool get isZoom {
    final p = streamProvider.toLowerCase();
    final u = videoUrl.toLowerCase();
    return p.contains('zoom') || u.contains('zoom.us');
  }

  bool isUserEnrolled({
    required String? uid,
    Set<String> purchasedBatchIds = const {},
    Set<String> purchasedItemIds = const {},
  }) {
    if (isFree || price <= 0) return true;
    if (uid != null && uid.isNotEmpty) {
      if (enrolledStudentIds.contains(uid)) return true;
    }
    if (purchasedItemIds.contains(id)) return true;
    if (batchId.isNotEmpty && (purchasedBatchIds.contains(batchId) || purchasedItemIds.contains(batchId))) return true;
    if (batchName.isNotEmpty) {
      final bNameLower = batchName.toLowerCase().trim();
      if (purchasedBatchIds.any((b) => b.toLowerCase().trim() == bNameLower) ||
          purchasedItemIds.any((b) => b.toLowerCase().trim() == bNameLower)) {
        return true;
      }
    }
    return false;
  }

  static Color _getColorForSubject(String subj) {
    final s = subj.toLowerCase();
    if (s.contains('physic')) return const Color(0xFF38BDF8);
    if (s.contains('chem')) return const Color(0xFF10B981);
    if (s.contains('math') || s.contains('quant')) return const Color(0xFFF59E0B);
    if (s.contains('bio')) return const Color(0xFFEC4899);
    if (s.contains('english')) return const Color(0xFF8B5CF6);
    if (s.contains('gk') || s.contains('aware') || s.contains('general')) return const Color(0xFF06B6D4);
    if (s.contains('reason')) return const Color(0xFFF97316);
    return const Color(0xFF38BDF8);
  }

  factory LiveClass.fromFirestore(Map<String, dynamic> data, String documentId) =>
      LiveClass.fromMap(data, documentId);

  factory LiveClass.fromMap(Map<String, dynamic> data, String documentId) {
    final title = (data['title'] ?? data['name'] ?? 'Examinantt Live Lecture').toString();
    final instructor = (data['educatorName'] ?? data['instructor'] ?? data['teacher'] ?? 'Examinantt Faculty').toString();
    final educatorAvatar = (data['educatorAvatar'] ?? data['avatar'] ?? '').toString();
    final qualification = (data['qualification'] ?? data['facultyRole'] ?? 'Master Faculty • Top Educator').toString();

    String thumb = (data['thumbnailUrl'] ?? data['thumbnail'] ?? data['imageUrl'] ?? data['poster'] ?? data['desktopUrl'] ?? data['image'] ?? data['banner'] ?? '').toString();
    final notes = (data['notesUrl'] ?? data['notesPdf'] ?? data['pdfUrl'] ?? '').toString();
    final subject = (data['subject'] ?? data['category'] ?? 'General').toString();
    final examCategory = (data['examCategory'] ?? data['exam'] ?? 'All Exams').toString();
    final desc = (data['description'] ?? data['details'] ?? '').toString();
    final chapter = (data['chapter'] ?? (desc.isNotEmpty ? desc : 'Interactive Session & Doubts')).toString();

    // High quality subject-specific study posters matching examinantt.com website fallbacks
    if (thumb.trim().isEmpty) {
      final s = subject.toLowerCase();
      if (s.contains('physic')) {
        thumb = 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?q=80&w=800&auto=format&fit=crop';
      } else if (s.contains('chem')) {
        thumb = 'https://images.unsplash.com/photo-1603126857599-f6e157fa2fe6?q=80&w=800&auto=format&fit=crop';
      } else if (s.contains('math') || s.contains('calculus')) {
        thumb = 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?q=80&w=800&auto=format&fit=crop';
      } else if (s.contains('english')) {
        thumb = 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=800&auto=format&fit=crop';
      } else {
        thumb = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=800&auto=format&fit=crop';
      }
    }

    final batchId = (data['batchId'] ?? '').toString();
    final batchName = (data['batchName'] ?? '').toString();
    final provider = (data['streamProvider'] ?? data['provider'] ?? '').toString().toLowerCase();
    String roomName = (data['roomName'] ?? data['room'] ?? data['roomId'] ?? '').toString().trim();
    if (roomName.isEmpty) {
      final possibleUrl = (data['streamUrl'] ?? data['playbackUrl'] ?? data['videoUrl'] ?? data['url'] ?? '').toString();
      if (possibleUrl.contains('meet.jit.si/') || possibleUrl.contains('8x8.vc/')) {
        final uri = Uri.tryParse(possibleUrl);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          roomName = uri.pathSegments.last;
        }
      }
    }

    final rawStatus = (data['status'] ?? data['streamStatus'] ?? data['state'] ?? '').toString().toLowerCase().trim();
    bool rawIsLive = data['isLive'] == true ||
        data['isLive'] == 'true' ||
        data['isLive'] == 1 ||
        rawStatus == 'live' ||
        rawStatus == 'ongoing' ||
        rawStatus == 'active' ||
        rawStatus == 'started' ||
        rawStatus == 'in_progress';

    bool rawIsCompleted = data['isRecorded'] == true ||
        data['isRecorded'] == 'true' ||
        rawStatus == 'completed' ||
        rawStatus == 'recorded' ||
        rawStatus == 'ended' ||
        rawStatus == 'finished' ||
        (data['recordingUrl'] != null && data['recordingUrl'].toString().trim().isNotEmpty);

    bool rawIsUpcoming = rawStatus == 'upcoming' ||
        rawStatus == 'scheduled' ||
        rawStatus == 'pending' ||
        rawStatus == 'not_started' ||
        rawStatus == 'cancelled';

    // Comprehensive video link detection (streamUrl, playbackUrl, recordingUrl, videoUrl, url, video, youtubeUrl, link, hlsUrl)
    String streamUrl = '';
    final List<String> priorityKeys;
    if (rawIsLive) {
      priorityKeys = ['streamUrl', 'playbackUrl', 'videoUrl', 'url', 'recordingUrl', 'video', 'youtubeUrl', 'link', 'hlsUrl'];
    } else if (rawIsCompleted) {
      priorityKeys = ['recordingUrl', 'playbackUrl', 'streamUrl', 'videoUrl', 'url', 'video', 'youtubeUrl', 'link', 'hlsUrl'];
    } else {
      priorityKeys = ['streamUrl', 'playbackUrl', 'videoUrl', 'recordingUrl', 'url', 'video', 'youtubeUrl', 'link', 'hlsUrl'];
    }

    for (final key in priorityKeys) {
      final val = data[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        streamUrl = val.toString().trim();
        break;
      }
    }

    DateTime? startTime;
    final scheduledRaw = data['scheduledStartTime'] ?? data['startTime'] ?? data['date'];
    if (scheduledRaw is String && scheduledRaw.isNotEmpty) {
      startTime = DateTime.tryParse(scheduledRaw);
    } else if (scheduledRaw != null && scheduledRaw.runtimeType.toString().contains('Timestamp')) {
      try {
        startTime = (scheduledRaw as dynamic).toDate();
      } catch (_) {}
    }

    // Auto-resolve live vs upcoming vs recorded if status is ambiguous
    if (!rawIsLive && !rawIsCompleted && !rawIsUpcoming) {
      if (startTime != null) {
        if (startTime.isAfter(DateTime.now())) {
          rawIsUpcoming = true;
        } else {
          rawIsCompleted = true;
        }
      } else {
        if (streamUrl.isNotEmpty) {
          rawIsCompleted = true;
        } else {
          rawIsUpcoming = true;
        }
      }
    }

    final resolvedStatus = rawIsLive
        ? 'live'
        : (rawIsCompleted ? 'completed' : 'upcoming');

    String formattedTime = (data['time'] ?? '').toString();
    if (formattedTime.isEmpty) {
      if (startTime != null) {
        final now = DateTime.now();
        final isToday = startTime.year == now.year && startTime.month == now.month && startTime.day == now.day;
        final hourNum = startTime.hour > 12 ? startTime.hour - 12 : (startTime.hour == 0 ? 12 : startTime.hour);
        final hour = hourNum.toString().padLeft(2, '0');
        final minute = startTime.minute.toString().padLeft(2, '0');
        final ampm = startTime.hour >= 12 ? 'PM' : 'AM';
        if (isToday) {
          formattedTime = 'Today at $hour:$minute $ampm';
        } else {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final m = months[startTime.month - 1];
          formattedTime = '$m ${startTime.day} at $hour:$minute $ampm';
        }
      } else {
        formattedTime = rawIsLive ? 'Live Now' : 'Scheduled soon';
      }
    }

    int duration = 60;
    if (data['durationMinutes'] != null) {
      duration = int.tryParse(data['durationMinutes'].toString()) ?? 60;
    } else if (data['duration'] != null) {
      duration = int.tryParse(data['duration'].toString()) ?? 60;
    }

    String viewers = '0';
    if (data['activeViewers'] != null) {
      viewers = data['activeViewers'].toString();
    } else if (data['watching'] != null) {
      viewers = data['watching'].toString();
    }

    String remaining = '';
    if (data['remainingTime'] != null && data['remainingTime'].toString().isNotEmpty) {
      remaining = data['remainingTime'].toString();
    } else if (data['duration'] != null || data['durationMinutes'] != null) {
      remaining = '$duration min';
    } else {
      remaining = 'Live';
    }

    final hasChat = data['hasLiveChat'] != false;

    final double price = double.tryParse((data['price'] ?? 0).toString()) ?? 0.0;
    final double? origPrice = data['originalPrice'] != null
        ? double.tryParse(data['originalPrice'].toString())
        : null;
    final bool isFree = data['isFree'] == true || (price <= 0);

    List<String> enrolledIds = [];
    if (data['enrolledStudentIds'] is List) {
      enrolledIds = (data['enrolledStudentIds'] as List).map((e) => e.toString()).toList();
    } else if (data['enrolledStudents'] is List) {
      enrolledIds = (data['enrolledStudents'] as List).map((e) => e.toString()).toList();
    }

    final server = (data['streamServer'] ?? data['server'] ?? 'Amazon AWS IVS').toString();
    final awsArn = (data['awsChannelArn'] ?? data['channelArn'] ?? '').toString();
    final awsRegion = (data['awsRegion'] ?? data['region'] ?? 'us-west-2').toString();
    final chatRoomArn = (data['chatRoomArn'] ?? data['roomArn'] ?? '').toString();
    final chatToken = (data['chatToken'] ?? '').toString();
    String recording = (data['recordingUrl'] ?? data['recording'] ?? '').toString();
    if (recording.trim().isEmpty) {
      if (streamUrl.endsWith('.mp4') || streamUrl.contains('storage.googleapis.com')) {
        recording = streamUrl;
      } else if (rawIsCompleted || streamUrl.contains('live-video.net')) {
        recording = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      }
    }

    final effectiveVideoUrl = (rawIsCompleted && recording.trim().isNotEmpty && !streamUrl.contains('youtube') && !streamUrl.contains('meet.google.com'))
        ? recording.trim()
        : (streamUrl.isNotEmpty ? streamUrl : recording.trim());

    return LiveClass(
      id: documentId,
      title: title,
      instructor: instructor,
      educatorAvatar: educatorAvatar,
      qualification: qualification,
      videoUrl: effectiveVideoUrl,
      thumbnailUrl: thumb,
      subject: subject,
      examCategory: examCategory,
      description: desc,
      chapter: chapter,
      time: formattedTime,
      scheduledStartTime: startTime,
      durationMinutes: duration,
      status: resolvedStatus,
      isLive: rawIsLive,
      isUpcoming: rawIsUpcoming,
      isRecorded: rawIsCompleted,
      activeViewers: viewers,
      remainingTime: remaining,
      notesUrl: notes,
      hasLiveChat: hasChat,
      batchId: batchId,
      batchName: batchName,
      price: price,
      originalPrice: origPrice,
      isFree: isFree,
      enrolledStudentIds: enrolledIds,
      streamServer: server,
      awsChannelArn: awsArn,
      awsRegion: awsRegion,
      chatRoomArn: chatRoomArn,
      chatToken: chatToken,
      recordingUrl: recording,
      streamProvider: provider,
      roomName: roomName,
      color: _getColorForSubject(subject),
    );
  }

  // Official dynamic real-time live classes (no static/mock fallback data)
  
}

class CourseModel {
  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final String examCategory;
  final double price;
  final double originalPrice;
  final String instructorName;
  final String instructorTitle;
  final int totalModules;
  final int totalLessons;
  final String status;
  final String thumbnailUrl;
  final String bannerUrl;
  final List<String> resourceIds;
  final List<String> testSeriesIds;
  final List<String> liveClassIds;
  final List<String> enrolledStudentIds;
  final List<String> features;
  final String validity;
  final String startDate;
  final String endDate;
  final String createdBy;
  final dynamic createdAt;
  final dynamic updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    this.shortDescription = '',
    this.description = '',
    this.examCategory = '',
    this.price = 0.0,
    this.originalPrice = 0.0,
    this.instructorName = '',
    this.instructorTitle = '',
    this.totalModules = 0,
    this.totalLessons = 0,
    this.status = 'published',
    this.thumbnailUrl = '',
    this.bannerUrl = '',
    this.resourceIds = const [],
    this.testSeriesIds = const [],
    this.liveClassIds = const [],
    this.enrolledStudentIds = const [],
    this.features = const [],
    this.validity = 'Till Exam Day',
    this.startDate = '',
    this.endDate = '',
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  String get imageUrl => thumbnailUrl.isNotEmpty ? thumbnailUrl : bannerUrl;

  factory CourseModel.fromMap(Map<String, dynamic> data, String docId) {
    final pricing = data['pricing'] as Map<String, dynamic>?;
    final accessType = (data['accessType'] ?? pricing?['type'] ?? '').toString().toLowerCase().trim();
    final isExplicitlyFree = accessType == 'free' || data['isFree'] == true || data['isFree'] == 'true';

    double amount = 0.0;
    if (isExplicitlyFree) {
      amount = 0.0;
    } else if (data.containsKey('price')) {
      amount = (data['price'] ?? 0).toDouble();
    } else if (pricing != null) {
      amount = (pricing['amount'] ?? 0).toDouble();
    }

    double origPrice = 0.0;
    if (data.containsKey('originalPrice')) {
      origPrice = (data['originalPrice'] ?? 0).toDouble();
    } else if (pricing != null && pricing.containsKey('originalPrice')) {
      origPrice = (pricing['originalPrice'] ?? 0).toDouble();
    }

    final instructor = data['instructor'] as Map<String, dynamic>?;

    List<String> parsedResourceIds = [];
    if (data['resourceIds'] is List) {
      parsedResourceIds = (data['resourceIds'] as List).map((e) => e.toString()).toList();
    } else if (data['resources'] is List) {
      parsedResourceIds = (data['resources'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedTestSeriesIds = [];
    if (data['testSeriesIds'] is List) {
      parsedTestSeriesIds = (data['testSeriesIds'] as List).map((e) => e.toString()).toList();
    } else if (data['testSeries'] is List) {
      parsedTestSeriesIds = (data['testSeries'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedLiveClassIds = [];
    if (data['liveClassIds'] is List) {
      parsedLiveClassIds = (data['liveClassIds'] as List).map((e) => e.toString()).toList();
    } else if (data['liveClasses'] is List) {
      parsedLiveClassIds = (data['liveClasses'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedEnrolledStudentIds = [];
    if (data['enrolledStudentIds'] is List) {
      parsedEnrolledStudentIds = (data['enrolledStudentIds'] as List).map((e) => e.toString()).toList();
    } else if (data['students'] is List) {
      parsedEnrolledStudentIds = (data['students'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedFeatures = [];
    if (data['features'] is List) {
      parsedFeatures = (data['features'] as List).map((e) => e.toString()).toList();
    }

    return CourseModel(
      id: docId,
      title: (data['title'] ?? data['name'] ?? 'Batch Course').toString(),
      shortDescription: (data['shortDescription'] ?? data['subtitle'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      examCategory: (data['examCategory'] ?? data['category'] ?? '').toString(),
      price: amount,
      originalPrice: origPrice > 0 ? origPrice : (amount * 3),
      instructorName: (instructor?['name'] ?? data['educatorName'] ?? 'Examinant Expert Team').toString(),
      instructorTitle: (instructor?['title'] ?? 'Senior Educator').toString(),
      totalModules: int.tryParse(data['totalModules']?.toString() ?? '') ?? 0,
      totalLessons: int.tryParse(data['totalLessons']?.toString() ?? '') ?? 0,
      status: (data['status'] ?? 'published').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? data['thumbnail'] ?? data['imageUrl'] ?? data['image'] ?? data['bannerUrl'] ?? data['iconUrl'] ?? '').toString(),
      bannerUrl: (data['bannerUrl'] ?? data['banner'] ?? data['thumbnailUrl'] ?? data['imageUrl'] ?? '').toString(),
      resourceIds: parsedResourceIds,
      testSeriesIds: parsedTestSeriesIds,
      liveClassIds: parsedLiveClassIds,
      enrolledStudentIds: parsedEnrolledStudentIds,
      features: parsedFeatures,
      validity: (data['validity'] ?? 'Till Exam Day').toString(),
      startDate: (data['startDate'] ?? '').toString(),
      endDate: (data['endDate'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'name': title,
      'shortDescription': shortDescription,
      'description': description,
      'examCategory': examCategory,
      'price': price,
      'originalPrice': originalPrice,
      'instructorName': instructorName,
      'instructorTitle': instructorTitle,
      'instructor': {
        'name': instructorName,
        'title': instructorTitle,
      },
      'totalModules': totalModules,
      'totalLessons': totalLessons,
      'status': status,
      'thumbnailUrl': thumbnailUrl,
      'bannerUrl': bannerUrl,
      'resourceIds': resourceIds,
      'testSeriesIds': testSeriesIds,
      'liveClassIds': liveClassIds,
      'enrolledStudentIds': enrolledStudentIds,
      'features': features,
      'validity': validity,
      'startDate': startDate,
      'endDate': endDate,
      'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? shortDescription,
    String? description,
    String? examCategory,
    double? price,
    double? originalPrice,
    String? instructorName,
    String? instructorTitle,
    int? totalModules,
    int? totalLessons,
    String? status,
    String? thumbnailUrl,
    String? bannerUrl,
    List<String>? resourceIds,
    List<String>? testSeriesIds,
    List<String>? liveClassIds,
    List<String>? enrolledStudentIds,
    List<String>? features,
    String? validity,
    String? startDate,
    String? endDate,
    String? createdBy,
    dynamic createdAt,
    dynamic updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      examCategory: examCategory ?? this.examCategory,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      instructorName: instructorName ?? this.instructorName,
      instructorTitle: instructorTitle ?? this.instructorTitle,
      totalModules: totalModules ?? this.totalModules,
      totalLessons: totalLessons ?? this.totalLessons,
      status: status ?? this.status,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      resourceIds: resourceIds ?? this.resourceIds,
      testSeriesIds: testSeriesIds ?? this.testSeriesIds,
      liveClassIds: liveClassIds ?? this.liveClassIds,
      enrolledStudentIds: enrolledStudentIds ?? this.enrolledStudentIds,
      features: features ?? this.features,
      validity: validity ?? this.validity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

typedef BatchModel = CourseModel;

class ResourceItem {
  final String id;
  final String title;
  final String category; // e.g., 'Mathematics', 'Physics', 'Chemistry', 'General'
  final String type; // e.g., 'Notes', 'PYQ', 'Formula Sheet', 'Mind Map', 'Lecture'
  final String url;
  final double price;
  final bool isPublic;
  final String description;
  final DateTime date;
  // Enhanced fields for rich UI & real-time sync
  final String subtitle;
  final String subject;
  final String fileType;
  final String fileSize;
  final String badge;
  final String badgeColorHex;
  final String downloads;
  final double rating;
  final String exam;
  final double progress;
  final bool isCompleted;
  final String chapter;
  final String chapterNum;
  final List<String> batchIds;
  final String status;
  final String createdBy;
  final dynamic createdAt;
  final dynamic updatedAt;
  final String thumbnailUrl;

  final bool isFreeField;

  bool get isFree => (isFreeField && price == 0.0) || price == 0.0 || badge.toUpperCase().contains('FREE');
  bool get isBatchIncluded => badge.toUpperCase().contains('INCLUDED');

  ResourceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.url,
    required this.price,
    required this.isPublic,
    required this.description,
    DateTime? date,
    this.subtitle = '',
    this.subject = 'Physics',
    this.fileType = 'PDF',
    this.fileSize = '2.4 MB',
    this.badge = 'FREE',
    this.badgeColorHex = '#34D399',
    this.downloads = '24.5k',
    this.rating = 4.8,
    this.exam = 'All',
    this.progress = 0.0,
    this.isCompleted = false,
    this.chapter = '',
    String? chapterNum,
    String? num,
    this.batchIds = const [],
    this.status = 'published',
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
    this.thumbnailUrl = '',
    this.isFreeField = true,
  })  : chapterNum = chapterNum ?? num ?? '01',
        date = date ?? DateTime.now();

  factory ResourceItem.fromMap(Map<String, dynamic> data, String documentId) {
    double parsedPrice = 0.0;
    if (data['price'] != null) {
      if (data['price'] is int || data['price'] is double) {
        parsedPrice = (data['price'] as dynamic).toDouble();
      } else if (data['price'] is String) {
        parsedPrice = double.tryParse(data['price'].toString().replaceAll('₹', '').trim()) ?? 0.0;
      }
    }

    bool parsedIsFree = true;
    if (data['isFree'] != null) {
      if (data['isFree'] is bool) {
        parsedIsFree = data['isFree'];
      } else if (data['isFree'] is String) {
        parsedIsFree = data['isFree'].toString().toLowerCase() == 'true';
      }
    } else {
      parsedIsFree = parsedPrice == 0.0;
    }

    bool parsedPublic = true;
    if (data['isPublic'] != null) {
      if (data['isPublic'] is bool) {
        parsedPublic = data['isPublic'];
      } else if (data['isPublic'] is String) {
        parsedPublic = data['isPublic'].toString().toLowerCase() == 'true';
      }
    } else {
      parsedPublic = parsedIsFree || parsedPrice == 0.0;
    }

    double parsedProgress = 0.0;
    if (data['progress'] != null) {
      if (data['progress'] is int || data['progress'] is double) {
        parsedProgress = (data['progress'] as dynamic).toDouble();
      } else if (data['progress'] is String) {
        parsedProgress = double.tryParse(data['progress'].toString().replaceAll('%', '').trim()) ?? 0.0;
        if (parsedProgress > 1.0) parsedProgress = parsedProgress / 100.0;
      }
    }

    double parsedRating = 4.8;
    if (data['rating'] != null) {
      if (data['rating'] is int || data['rating'] is double) {
        parsedRating = (data['rating'] as dynamic).toDouble();
      } else if (data['rating'] is String) {
        parsedRating = double.tryParse(data['rating']) ?? 4.8;
      }
    }

    final cat = (data['category'] ?? data['subject'] ?? 'General').toString();

    // Smart exam mapping: if not specified on website, default to 'All' so all students see it!
    String parsedExam = (data['exam'] ?? '').toString();
    if (parsedExam.isEmpty) {
      final catLower = cat.toLowerCase();
      if (catLower.contains('cuet')) {
        parsedExam = 'CUET UG';
      } else if (catLower.contains('neet')) {
        parsedExam = 'NEET';
      } else if (catLower.contains('jee')) {
        parsedExam = 'JEE Main 2027';
      } else {
        parsedExam = 'All'; // Visible to all students!
      }
    }

    // Normalizing URL for relative paths uploaded on examinantt.com
    String rawUrl = (data['url'] ?? data['pdfUrl'] ?? '').toString().trim();
    if (rawUrl.startsWith('/')) {
      rawUrl = 'https://www.examinantt.com$rawUrl';
    }

    final rawType = (data['type'] ?? 'Notes').toString();
    String detectedFileType = (data['fileType'] ?? '').toString();
    if (detectedFileType.isEmpty) {
      final lower = rawType.toLowerCase();
      if (lower == 'pdf') {
        detectedFileType = 'PDF';
      } else if (lower == 'video') {
        detectedFileType = 'VIDEO';
      } else if (lower == 'link') {
        detectedFileType = 'LINK';
      } else {
        detectedFileType = 'PDF';
      }
    }

    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    } else if (data['date'] != null) {
      if (data['date'] is String) {
        parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
      } else if (data['date'] is Timestamp) {
        parsedDate = (data['date'] as Timestamp).toDate();
      }
    }

    List<String> parsedBatchIds = [];
    if (data['batchIds'] is List) {
      parsedBatchIds = (data['batchIds'] as List).map((e) => e.toString()).toList();
    } else if (data['batches'] is List) {
      parsedBatchIds = (data['batches'] as List).map((e) => e.toString()).toList();
    } else if (data['batchId'] != null && data['batchId'].toString().isNotEmpty) {
      parsedBatchIds = [data['batchId'].toString()];
    }

    return ResourceItem(
      id: documentId,
      title: data['title']?.toString() ?? '',
      category: cat,
      subject: data['subject']?.toString() ?? cat,
      type: rawType,
      url: rawUrl,
      price: parsedPrice,
      isPublic: parsedPublic,
      isFreeField: parsedIsFree,
      description: data['description']?.toString() ?? '',
      date: parsedDate,
      subtitle: data['subtitle']?.toString() ?? data['description']?.toString() ?? '',
      fileType: detectedFileType,
      fileSize: data['fileSize']?.toString() ?? data['size']?.toString() ?? (rawType.toLowerCase() == 'video' ? 'Video Stream' : rawType.toLowerCase() == 'link' ? 'Web Link' : '2.4 MB'),
      badge: data['badge']?.toString() ?? (parsedIsFree || parsedPrice == 0 ? 'FREE' : 'PREMIUM'),
      badgeColorHex: data['badgeColorHex']?.toString() ?? (parsedIsFree || parsedPrice == 0 ? '#34D399' : '#FFA000'),
      downloads: data['downloads']?.toString() ?? '18.2k',
      rating: parsedRating,
      exam: parsedExam,
      progress: parsedProgress,
      isCompleted: data['isCompleted'] == true || parsedProgress >= 1.0,
      chapter: data['chapter']?.toString() ?? '',
      chapterNum: data['chapterNum']?.toString() ?? data['num']?.toString() ?? '01',
      batchIds: parsedBatchIds,
      status: (data['status'] ?? 'published').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      thumbnailUrl: (data['thumbnailUrl'] ?? data['thumbnail'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'subject': subject,
      'type': type,
      'fileType': fileType,
      'fileSize': fileSize,
      'badge': badge,
      'badgeColorHex': badgeColorHex,
      'downloads': downloads,
      'rating': rating,
      'exam': exam,
      'price': price,
      'isPublic': isPublic,
      'isFree': isFree,
      'description': description,
      'progress': progress,
      'isCompleted': isCompleted,
      'chapter': chapter,
      'chapterNum': chapterNum,
      'num': chapterNum,
      'url': url,
      'thumbnailUrl': thumbnailUrl.isNotEmpty ? thumbnailUrl : url,
      'date': date.toIso8601String(),
      'batchIds': batchIds,
      'status': status,
      'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  ResourceItem copyWith({
    String? id,
    String? title,
    String? category,
    String? type,
    String? url,
    double? price,
    bool? isPublic,
    String? description,
    DateTime? date,
    String? subtitle,
    String? subject,
    String? fileType,
    String? fileSize,
    String? badge,
    String? badgeColorHex,
    String? downloads,
    double? rating,
    String? exam,
    double? progress,
    bool? isCompleted,
    String? chapter,
    String? chapterNum,
    List<String>? batchIds,
    bool? isFreeField,
    dynamic createdAt,
    dynamic updatedAt,
    String? thumbnailUrl,
  }) {
    return ResourceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      url: url ?? this.url,
      price: price ?? this.price,
      isPublic: isPublic ?? this.isPublic,
      description: description ?? this.description,
      date: date ?? this.date,
      subtitle: subtitle ?? this.subtitle,
      subject: subject ?? this.subject,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      badge: badge ?? this.badge,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
      downloads: downloads ?? this.downloads,
      rating: rating ?? this.rating,
      exam: exam ?? this.exam,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      chapter: chapter ?? this.chapter,
      chapterNum: chapterNum ?? this.chapterNum,
      batchIds: batchIds ?? this.batchIds,
      status: status,
      createdBy: createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFreeField: isFreeField ?? this.isFreeField,
    );
  }
}

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final DateTime date;
  final String source;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl = '',
    DateTime? date,
    this.source = 'Examinantt',
  }) : date = date ?? DateTime.now();

  factory NewsArticle.fromMap(Map<String, dynamic> data, String documentId) {
    return NewsArticle(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      date: data['date'] is String ? (DateTime.tryParse(data['date']) ?? DateTime.now()) : DateTime.now(),
      source: data['source'] ?? 'Examinantt',
    );
  }
}

class JobAlert {
  final String id;
  final String title;
  final String organization;
  final String lastDate;
  final String applyUrl;
  final String tag;

  JobAlert({
    required this.id,
    required this.title,
    this.organization = 'Examinantt',
    required this.lastDate,
    required this.applyUrl,
    this.tag = 'New',
  });

  factory JobAlert.fromMap(Map<String, dynamic> data, String documentId) {
    return JobAlert(
      id: documentId,
      title: data['title'] ?? '',
      organization: data['organization'] ?? '',
      lastDate: data['lastDate'] ?? '',
      applyUrl: data['applyUrl'] ?? '',
      tag: data['tag'] ?? '',
    );
  }
}
