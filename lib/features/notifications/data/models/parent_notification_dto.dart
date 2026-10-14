import '../../domain/entities/parent_notification_entity.dart';

class ParentNotificationDto {
  const ParentNotificationDto({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.createdAt,
    this.actionUrl,
    this.studentId,
    this.studentName,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String content;
  final String type;
  final DateTime? createdAt;
  final String? actionUrl;
  final String? studentId;
  final String? studentName;
  final bool isRead;

  factory ParentNotificationDto.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawCreated = json['createdAt'] ?? json['timestamp'] ?? json['date'];
    if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated);
    }

    final contentStr =
        (json['content'] ?? json['message'] ?? json['body'] ?? '').toString();

    // 1. Explicit student ID from payload or nested student object
    String? resolvedStudentId = (json['studentId'] ??
            json['childId'] ??
            (json['student'] is Map ? json['student']['_id'] : null) ??
            (json['student'] is Map ? json['student']['studentId'] : null))
        ?.toString();

    // 2. Explicit student name from payload or nested student object
    String? resolvedStudentName = (json['studentName'] ??
            json['childName'] ??
            (json['student'] is Map ? json['student']['name'] : null) ??
            (json['student'] is Map ? json['student']['firstName'] : null))
        ?.toString();

    // 3. Fallback to authoritative backend message template:
    //    "Instructor <Teacher> replied regarding <StudentName>: "<message>""
    if (resolvedStudentName == null || resolvedStudentName.isEmpty) {
      final regardingMatch = RegExp(
        r'regarding\s+([^:"]+):',
        caseSensitive: false,
      ).firstMatch(contentStr);
      if (regardingMatch != null) {
        resolvedStudentName = regardingMatch.group(1)?.trim();
      }
    }

    final isRead = json['isRead'] == true || json['readAt'] != null;

    return ParentNotificationDto(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: contentStr,
      type: (json['type'] ?? json['eventSource'] ?? 'system').toString(),
      createdAt: parsedDate,
      actionUrl: json['actionUrl']?.toString(),
      studentId: resolvedStudentId,
      studentName: resolvedStudentName,
      isRead: isRead,
    );
  }

  ParentNotificationItemEntity toEntity() {
    return ParentNotificationItemEntity(
      id: id,
      title: title,
      content: content,
      type: type,
      createdAt: createdAt,
      actionUrl: actionUrl,
      studentId: studentId,
      studentName: studentName,
      isRead: isRead,
    );
  }
}
