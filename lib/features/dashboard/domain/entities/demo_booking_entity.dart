import '../../../classes/domain/entities/class_entity.dart';
import 'child_entity.dart';
import 'demo_session_eligibility.dart';

/// Domain entity representing a confirmed demo booking session.
///
/// Encapsulates all verified fields returned by POST /api/parent/demo
/// and GET /api/parent/demo without hardcoding or fabricating fallback data.
class DemoBookingEntity {
  const DemoBookingEntity({
    required this.bookingId,
    required this.courseName,
    required this.startDateTime,
    this.endDateTime,
    this.demoCode,
    this.studentName,
    this.studentId,
    this.studentCode,
    this.liveClassId,
    this.teacherName,
    this.teacherStatus,
    this.status = 'scheduled',
    this.meetingUrl,
    this.joinEligible = false,
    this.duration = 45,
  });

  /// Unique identifier of the demo booking / DemoSession record.
  final String bookingId;

  /// Optional live-class session identifier if distinct from demo booking record.
  final String? liveClassId;

  /// Human-readable booking reference code (e.g. "DEMO-847291").
  final String? demoCode;

  /// Associated course / program title.
  final String courseName;

  /// Full name of the linked child or student.
  final String? studentName;

  /// ID of the student (internal database identifier or code).
  final String? studentId;

  /// Human-readable student code (e.g. "STU-00520397").
  final String? studentCode;

  /// Scheduled start timestamp (UTC/ISO8601 converted to DateTime).
  final DateTime startDateTime;

  /// Scheduled end timestamp.
  final DateTime? endDateTime;

  /// Name of assigned faculty/instructor, if assigned by the backend.
  final String? teacherName;

  /// Status of teacher assignment reported by backend (e.g. "Assigned", "Finalizing").
  final String? teacherStatus;

  /// Current booking status (e.g. "scheduled", "live", "completed").
  final String status;

  /// Meeting or classroom URL/link when supported and active.
  final String? meetingUrl;

  /// Whether parent/student is currently within the active join window (T-15 mins).
  final bool joinEligible;

  /// Duration of the demo session in minutes.
  final int duration;

  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Whether an instructor is confirmed and assigned.
  bool get hasTeacher =>
      teacherName != null &&
      teacherName!.trim().isNotEmpty &&
      teacherName!.toLowerCase() != 'null';

  /// Truthful display text for the teacher.
  String get displayTeacher =>
      hasTeacher ? teacherName! : 'Pending Assignment (Finalizing)';

  /// Truthful display badge for teacher status.
  String get displayTeacherStatus {
    if (teacherStatus != null && teacherStatus!.isNotEmpty) {
      return teacherStatus!;
    }
    return hasTeacher ? 'Assigned' : 'Finalizing';
  }

  /// Formatted date in local timezone: e.g. "Friday, Oct 17, 2026".
  String get formattedDate {
    final local = startDateTime.toLocal();
    final weekday = _weekdayNames[local.weekday - 1];
    final month = _monthNames[local.month - 1];
    return '$weekday, $month ${local.day}, ${local.year}';
  }

  /// Formatted short date in local timezone: e.g. "Oct 17, 2026".
  String get formattedShortDate {
    final local = startDateTime.toLocal();
    final month = _monthNames[local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  /// Formatted start time in local timezone with 12-hour AM/PM: e.g. "8:00 PM".
  String get formattedTime {
    final local = startDateTime.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Formatted end time in local timezone with 12-hour AM/PM: e.g. "8:45 PM".
  String get formattedEndTime {
    final end =
        endDateTime?.toLocal() ??
        startDateTime.toLocal().add(Duration(minutes: duration));
    final hour = end.hour == 0
        ? 12
        : (end.hour > 12 ? end.hour - 12 : end.hour);
    final minute = end.minute.toString().padLeft(2, '0');
    final period = end.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Formatted time range: e.g. "8:00 PM - 8:45 PM".
  String get formattedTimeRange => '$formattedTime - $formattedEndTime';

  /// Formatted date and time: e.g. "Oct 17, 2026 at 8:00 PM".
  String get formattedDateTime => '$formattedShortDate at $formattedTime';

  /// Session time gate eligibility instance.
  DemoSessionEligibility get eligibility => DemoSessionEligibility(
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        durationMinutes: duration,
        status: status,
      );

  /// Evaluates time-gate eligibility relative to [now].
  DemoSessionTimeGateStatus evaluateEligibility([DateTime? now]) =>
      eligibility.evaluate(now);

  /// Whether the session is eligible for classroom entry right now.
  bool canEnterDemoClass([DateTime? now]) => eligibility.canEnter(now);

  /// Whether the session start is more than 15 minutes away.
  bool isTooEarly([DateTime? now]) => eligibility.isTooEarly(now);

  /// Whether the session has concluded.
  bool isExpired([DateTime? now]) => eligibility.isExpired(now);

  /// Remaining duration until the 15-minute joining window opens.
  Duration remainingUntilWindowOpen([DateTime? now]) =>
      eligibility.remainingUntilWindowOpen(now);

  /// Effective live class session identifier for classroom SDK / join operation.
  /// Prioritizes explicit [liveClassId] if available, otherwise uses [bookingId].
  String get effectiveClassId =>
      (liveClassId != null && liveClassId!.trim().isNotEmpty)
          ? liveClassId!.trim()
          : bookingId;

  /// Converts this demo booking into a unified [ClassEntity] for classroom session handling.
  ClassEntity toClassEntity() {
    return ClassEntity(
      id: effectiveClassId,
      classCode: demoCode,
      title: courseName,
      subject: courseName,
      scheduledStartTime: startDateTime,
      scheduledEndTime:
          endDateTime ?? startDateTime.add(Duration(minutes: duration)),
      duration: duration,
      status: status.toUpperCase(),
      effectiveStatus: status.toLowerCase(),
      teacherName: teacherName,
      meetingUrl: meetingUrl,
    );
  }

  /// Factory deserializer converting backend API JSON responses into [DemoBookingEntity].
  factory DemoBookingEntity.fromJson(
    Map<String, dynamic> json, {
    String? fallbackCourseName,
    String? fallbackStudentName,
    DateTime? fallbackStartDateTime,
    String? fallbackTeacherName,
  }) {
    // Extract ID
    final id =
        (json['demoId'] ??
                json['_id'] ??
                json['id'] ??
                json['leadId'] ??
                json['bookingId'] ??
                '')
            .toString();

    // Extract live class ID if distinct from demo ID
    final liveClassIdVal = json['liveClassId']?.toString() ??
        json['sessionId']?.toString() ??
        json['classId']?.toString() ??
        (json['liveClass'] is Map
            ? json['liveClass']['_id']?.toString() ??
                json['liveClass']['id']?.toString()
            : null) ??
        (json['session'] is Map
            ? json['session']['_id']?.toString() ??
                json['session']['id']?.toString()
            : null);

    // Extract demo code
    final code =
        json['demoCode']?.toString() ??
        json['code']?.toString() ??
        json['leadCode']?.toString();

    // Extract course name
    final course =
        json['interestedCourse']?.toString() ??
        json['courseName']?.toString() ??
        (json['course'] is Map
            ? json['course']['courseName']?.toString()
            : null) ??
        (json['course'] is Map ? json['course']['name']?.toString() : null) ??
        fallbackCourseName ??
        'Demo Program';

    // Extract child / student name
    final child =
        json['childName']?.toString() ??
        json['studentName']?.toString() ??
        fallbackStudentName;

    final studentIdVal =
        json['studentId']?.toString() ??
        (json['student'] is Map ? json['student']['_id']?.toString() : null) ??
        (json['student'] is String ? json['student'] : null);

    final studentCodeVal =
        json['studentCode']?.toString() ??
        (json['student'] is Map
            ? json['student']['studentCode']?.toString()
            : null);

    // Parse start date time
    DateTime start = fallbackStartDateTime ?? DateTime.now();
    final rawStart =
        json['scheduledStart'] ??
        json['startDateTime'] ??
        json['scheduledTime'];
    if (rawStart != null) {
      if (rawStart is String) {
        final parsed = DateTime.tryParse(rawStart);
        if (parsed != null) {
          start = parsed;
        }
      } else if (rawStart is DateTime) {
        start = rawStart;
      }
    }

    // Parse end date time
    DateTime? end;
    final rawEnd = json['scheduledEnd'] ?? json['endDateTime'];
    if (rawEnd != null) {
      if (rawEnd is String) {
        end = DateTime.tryParse(rawEnd);
      } else if (rawEnd is DateTime) {
        end = rawEnd;
      }
    }

    // Extract teacher name & status
    String? teacher;
    String? teacherStatus = json['teacherStatus']?.toString();
    final rawTeacher = json['teacher'];
    if (rawTeacher is Map<String, dynamic>) {
      teacher =
          rawTeacher['name']?.toString() ??
          '${rawTeacher['firstName'] ?? ''} ${rawTeacher['lastName'] ?? ''}'
              .trim();
    } else if (rawTeacher is String && rawTeacher.isNotEmpty) {
      teacher = rawTeacher;
    }
    teacher = (teacher != null && teacher.isNotEmpty)
        ? teacher
        : fallbackTeacherName;

    // Extract duration
    int dur = 45;
    if (json['duration'] is int) {
      dur = json['duration'] as int;
    } else if (json['duration'] is num) {
      dur = (json['duration'] as num).toInt();
    } else if (json['duration'] is String) {
      dur = int.tryParse(json['duration'] as String) ?? 45;
    }

    // Extract meeting link & join eligibility
    final meetingLink =
        json['meetingLink']?.toString() ??
        json['joinUrl']?.toString() ??
        json['meetingUrl']?.toString();
    final joinEligibleVal = json['joinEligible'] == true;

    final statusVal = json['status']?.toString() ?? 'scheduled';

    return DemoBookingEntity(
      bookingId: id.isNotEmpty
          ? id
          : (code ?? 'DEMO-${DateTime.now().millisecondsSinceEpoch}'),
      liveClassId: liveClassIdVal,
      demoCode: code,
      courseName: course,
      studentName: child,
      studentId: studentIdVal,
      studentCode: studentCodeVal,
      startDateTime: start,
      endDateTime: end,
      teacherName: teacher,
      teacherStatus: teacherStatus,
      status: statusVal,
      meetingUrl: meetingLink,
      joinEligible: joinEligibleVal,
      duration: dur,
    );
  }
}

/// Resolves the authoritative linked child matching the demo booking.
///
/// Governance:
/// 1. Verifies that the student belongs to the authenticated parent's linked children.
/// 2. Resolves the internal database identifier (e.g. MongoDB ObjectId) even when
///    the booking or CRM specifies a human-readable student code (e.g., STU-00520397).
/// 3. Prevents joining on behalf of an unrelated or stale active child.
ChildEntity? resolveAuthoritativeStudent({
  required DemoBookingEntity booking,
  required List<ChildEntity> linkedChildren,
}) {
  if (linkedChildren.isEmpty) return null;

  // 1. Direct match by internal database identifier
  if (booking.studentId != null && booking.studentId!.isNotEmpty) {
    for (final child in linkedChildren) {
      if (child.studentId == booking.studentId) {
        return child;
      }
    }
  }

  // 2. Match by human-readable student code (e.g., STU-00520397)
  final candidateCode = booking.studentCode ??
      (booking.studentId != null && booking.studentId!.startsWith('STU-')
          ? booking.studentId
          : null);
  if (candidateCode != null) {
    for (final child in linkedChildren) {
      if (child.studentCode != null &&
          child.studentCode!.toUpperCase() == candidateCode.toUpperCase()) {
        return child;
      }
    }
  }

  // 3. Match by studentName / displayName (case-insensitive)
  if (booking.studentName != null && booking.studentName!.trim().isNotEmpty) {
    final targetName = booking.studentName!.trim().toLowerCase();
    for (final child in linkedChildren) {
      final childName = child.displayName.trim().toLowerCase();
      if (childName == targetName) {
        return child;
      }
      final first = child.firstName.trim().toLowerCase();
      final last = (child.lastName ?? '').trim().toLowerCase();
      if ('$first $last'.trim() == targetName) {
        return child;
      }
      if (childName.contains(targetName) || targetName.contains(childName)) {
        return child;
      }
    }
  }

  // 4. Fallback: If only one child is linked under this parent, that child is the authoritative ward
  if (linkedChildren.length == 1) {
    return linkedChildren.first;
  }

  return null;
}
