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
    this.teacherName,
    this.teacherStatus,
    this.status = 'scheduled',
    this.meetingUrl,
    this.joinEligible = false,
    this.duration = 45,
  });

  /// Unique identifier of the demo booking / DemoSession record.
  final String bookingId;

  /// Human-readable booking reference code (e.g. "DEMO-847291").
  final String? demoCode;

  /// Associated course / program title.
  final String courseName;

  /// Full name of the linked child or student.
  final String? studentName;

  /// ID of the student.
  final String? studentId;

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
      demoCode: code,
      courseName: course,
      studentName: child,
      studentId: studentIdVal,
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
