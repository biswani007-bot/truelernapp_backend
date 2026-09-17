import '../../domain/entities/class_entity.dart';

/// Data Transfer Object representing a live class returned by:
/// GET /api/parent/children/{childStudentId}/live-classes
///
/// Governance:
/// - Envelope: { "success": true, "data": [ ClassDto, ... ], "meta": { ... } }
/// - Defensive null handling for all fields.
/// - Handles `teacher` both as a populated object `{ "name": "...", "avatar": "..." }`
///   or a fallback string ID.
/// - Handles date parsing safely without throwing FormatException.
class ClassDto {
  const ClassDto({
    required this.id,
    required this.title,
    this.classCode,
    this.subject,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.duration,
    this.status,
    this.teacherName,
    this.teacherAvatar,
    this.meetingUrl,
    this.roomName,
  });

  final String id;
  final String? classCode;
  final String title;
  final String? subject;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;
  final int? duration;
  final String? status;
  final String? teacherName;
  final String? teacherAvatar;
  final String? meetingUrl;
  final String? roomName;

  /// Parses JSON payload defensively.
  factory ClassDto.fromJson(Map<String, dynamic> json) {
    // Resolve ID: _id, id
    final id = (json['_id'] ?? json['id'] ?? '').toString();

    // Resolve title / topic
    final title = (json['classTitle'] ?? json['title'] ?? json['topic'] ?? json['name'] ?? '').toString();

    // Resolve subject / course
    String? subject;
    final rawSubject = json['subject'] ?? json['courseName'] ?? json['classCode'];
    if (rawSubject is String) {
      subject = rawSubject;
    } else if (rawSubject is Map<String, dynamic>) {
      subject = rawSubject['name']?.toString() ?? rawSubject['title']?.toString();
    }

    // Resolve start / end times
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final startTime = parseDateTime(json['scheduledStartTime'] ?? json['startTime'] ?? json['startDate']);
    final endTime = parseDateTime(json['scheduledEndTime'] ?? json['endTime'] ?? json['endDate']);

    // Resolve status (prioritize effectiveStatus from live API with status fallback)
    final status = (json['effectiveStatus'] ?? json['status'])?.toString();

    // Resolve teacher (can be nested map, string, or null)
    String? teacherName;
    String? teacherAvatar;
    final rawTeacher = json['teacher'] ?? json['instructor'];
    if (rawTeacher is Map<String, dynamic>) {
      final resolvedName = rawTeacher['name']?.toString() ??
          ([rawTeacher['firstName'], rawTeacher['lastName']]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .join(' '));
      teacherName = resolvedName.isNotEmpty ? resolvedName : null;
      teacherAvatar = rawTeacher['avatar']?.toString() ?? rawTeacher['profilePicture']?.toString();
    } else if (rawTeacher is String && rawTeacher.isNotEmpty) {
      // If it's a raw teacher ID or plain name
      teacherName = rawTeacher;
    }

    // Resolve meeting info
    final meetingUrl = json['meetingUrl']?.toString() ?? json['url']?.toString();
    final roomName = json['roomName']?.toString() ?? json['room']?.toString();

    // Resolve classCode and duration
    final classCode = json['classCode']?.toString();
    final duration = (json['duration'] is num)
        ? (json['duration'] as num).toInt()
        : int.tryParse(json['duration']?.toString() ?? '');

    return ClassDto(
      id: id,
      classCode: classCode,
      title: title,
      subject: subject,
      scheduledStartTime: startTime,
      scheduledEndTime: endTime,
      duration: duration,
      status: status,
      teacherName: teacherName,
      teacherAvatar: teacherAvatar,
      meetingUrl: meetingUrl,
      roomName: roomName,
    );
  }

  /// Maps DTO to domain entity.
  ClassEntity toEntity() => ClassEntity(
        id: id,
        classCode: classCode,
        title: title,
        subject: subject,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        duration: duration,
        status: status,
        teacherName: teacherName,
        teacherAvatar: teacherAvatar,
        meetingUrl: meetingUrl,
        roomName: roomName,
      );
}
