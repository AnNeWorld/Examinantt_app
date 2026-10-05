class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String targetExam;
  final int testsAttempted;
  final double averageScore;
  final double accuracy;
  final int totalStudyTimeMinutes;
  final int currentStreak;

  final String? profileImage;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.targetExam = 'Banking',
    this.testsAttempted = 0,
    this.averageScore = 0.0,
    this.accuracy = 0.0,
    this.totalStudyTimeMinutes = 0,
    this.currentStreak = 0,
    this.profileImage,
  });

  String get id => uid;

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? targetExam,
    int? testsAttempted,
    double? averageScore,
    double? accuracy,
    int? totalStudyTimeMinutes,
    int? currentStreak,
    String? profileImage,
    bool clearProfileImage = false,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      targetExam: targetExam ?? this.targetExam,
      testsAttempted: testsAttempted ?? this.testsAttempted,
      averageScore: averageScore ?? this.averageScore,
      accuracy: accuracy ?? this.accuracy,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      profileImage: clearProfileImage ? null : (profileImage ?? this.profileImage),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      targetExam: data['targetExam'] ?? 'Banking',
      testsAttempted: data['testsAttempted'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
      totalStudyTimeMinutes: data['totalStudyTimeMinutes'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      profileImage: data['profileImage'] ?? data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'targetExam': targetExam,
      'testsAttempted': testsAttempted,
      'averageScore': averageScore,
      'accuracy': accuracy,
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
      'currentStreak': currentStreak,
      'profileImage': profileImage,
    };
  }
}
