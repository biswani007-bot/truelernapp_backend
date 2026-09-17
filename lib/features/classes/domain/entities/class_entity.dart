/// Domain entity representing a live class session for a student/child.
///
/// Source: GET /api/parent/children/{childStudentId}/live-classes
/// Governance: docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04, Item 7
/// and Folder 08 (Live Classes schema).
class ClassEntity {
  const ClassEntity({
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

  /// Unique identifier of the live class session (_id).
  final String id;

  /// Unique class code (e.g. "LVC-0004").
  final String? classCode;

  /// Title or topic of the class.
  final String title;

  /// Subject name or curriculum domain (e.g. "Mathematics", "Science").
  final String? subject;

  /// Scheduled start timestamp.
  final DateTime? scheduledStartTime;

  /// Scheduled end timestamp.
  final DateTime? scheduledEndTime;

  /// Duration in minutes (e.g. 45, 90, 240).
  final int? duration;

  /// Status string (e.g. "UPCOMING", "LIVE", "COMPLETED", "CANCELLED").
  final String? status;

  /// Instructor / Teacher display name.
  final String? teacherName;

  /// Instructor / Teacher avatar URL.
  final String? teacherAvatar;

  /// Direct meeting URL if exposed.
  final String? meetingUrl;

  /// Jitsi / conferencing room name.
  final String? roomName;

  /// Helper flag to check if the session is currently live.
  bool get isLive => status?.toUpperCase() == 'LIVE';

  /// Helper flag to check if the session is upcoming.
  bool get isUpcoming =>
      status?.toUpperCase() == 'UPCOMING' ||
      status?.toUpperCase() == 'SCHEDULED';

  /// Helper flag to check if the session has completed.
  bool get isCompleted =>
      status?.toUpperCase() == 'COMPLETED' ||
      status?.toUpperCase() == 'ATTENDED';

  /// Helper flag to check if the session was missed.
  bool get isMissed => status?.toUpperCase() == 'MISSED';

  /// Helper flag to check if the session was cancelled.
  bool get isCancelled => status?.toUpperCase() == 'CANCELLED';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ClassEntity && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
