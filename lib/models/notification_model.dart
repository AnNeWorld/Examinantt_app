class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;

  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parsedDate = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is DateTime) {
        parsedDate = data['date'] as DateTime;
      } else if (data['date'] is String) {
        parsedDate = DateTime.tryParse(data['date'] as String) ?? DateTime.now();
      } else if (data['date'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(data['date'] as int);
      }
    }
    return NotificationModel(
      id: documentId,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      date: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'date': date.toIso8601String(),
    };
  }
}
