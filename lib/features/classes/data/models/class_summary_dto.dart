import '../../domain/entities/class_summary_entity.dart';

/// Data Transfer Object for parsing class summary data from real TrueLern APIs:
/// - GET /api/parent/children/{childStudentId}/live-classes
/// - GET /api/parent/children/{childStudentId}/attendance
/// - GET /api/parent/children/{childStudentId}/assignments
class ClassSummaryDto {
  final String classId;
  final String classTitle;
  final String? teacherName;
  final int? scheduledDurationMinutes;
  final int? attendedDurationMinutes;
  final String? attendanceStatus;
  final bool isAttended;
  final List<SkillPracticed> skillsPracticed;
  final String? nextClassId;
  final String? nextClassTitle;
  final String? nextClassTimeFormatted;
  final String? assignmentId;
  final String? assignmentTitle;
  final String? assignmentDueDate;

  const ClassSummaryDto({
    required this.classId,
    required this.classTitle,
    this.teacherName,
    this.scheduledDurationMinutes,
    this.attendedDurationMinutes,
    this.attendanceStatus,
    this.isAttended = true,
    this.skillsPracticed = const [],
    this.nextClassId,
    this.nextClassTitle,
    this.nextClassTimeFormatted,
    this.assignmentId,
    this.assignmentTitle,
    this.assignmentDueDate,
  });

  /// Factory constructor to parse and compose data safely from real backend responses.
  factory ClassSummaryDto.fromBackend({
    required String targetClassId,
    required Map<String, dynamic>? classJson,
    required Map<String, dynamic>? attendanceRecordJson,
    required Map<String, dynamic>? nextClassJson,
    required Map<String, dynamic>? assignmentJson,
  }) {
    // 1. Class title & ID
    final classId = (classJson?['id'] ?? classJson?['_id'] ?? targetClassId).toString();
    final classTitle = (classJson?['classTitle'] ??
            classJson?['title'] ??
            attendanceRecordJson?['classTitle'] ??
            'Live Class')
        .toString();

    // 2. Instructor / Teacher
    String? teacherName;
    final rawTeacher = classJson?['instructor'] ?? classJson?['teacher'];
    if (rawTeacher is String && rawTeacher.trim().isNotEmpty) {
      teacherName = rawTeacher.trim();
    } else if (rawTeacher is Map<String, dynamic>) {
      final name = rawTeacher['name'] ??
          [rawTeacher['firstName'], rawTeacher['lastName']]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .join(' ');
      if (name.toString().trim().isNotEmpty) {
        teacherName = name.toString().trim();
      }
    }

    // 3. Durations
    int? scheduledDuration;
    final rawDuration = classJson?['duration'];
    if (rawDuration is num) {
      scheduledDuration = rawDuration.toInt();
    } else if (rawDuration is String) {
      scheduledDuration = int.tryParse(rawDuration);
    }

    int? attendedDuration;
    // Check attendance in classJson first
    final classAttendance = classJson?['attendance'];
    if (classAttendance is Map<String, dynamic>) {
      final rawAttended = classAttendance['durationAttended'];
      if (rawAttended is num) {
        final val = rawAttended.toInt();
        attendedDuration = val > 500 ? (val / 60).round() : val;
      }
    }
    // Fallback to attendanceRecordJson
    if (attendedDuration == null && attendanceRecordJson != null) {
      final rawRecordAttended = attendanceRecordJson['durationAttended'];
      if (rawRecordAttended is num) {
        final val = rawRecordAttended.toInt();
        attendedDuration = val > 500 ? (val / 60).round() : val;
      }
    }

    // 4. Attendance status
    String? status;
    if (classAttendance is Map<String, dynamic> && classAttendance['status'] != null) {
      status = classAttendance['status']?.toString();
    } else if (attendanceRecordJson?['status'] != null) {
      status = attendanceRecordJson!['status']?.toString();
    } else if (classJson?['effectiveStatus'] != null) {
      status = classJson!['effectiveStatus']?.toString();
    }

    final isAttended = status == null ||
        status.toLowerCase() == 'present' ||
        status.toLowerCase() == 'attended' ||
        status.toLowerCase() == 'late' ||
        status.toLowerCase() == 'half-day';

    // 5. Skills practiced (only if provided by backend API contract)
    final List<SkillPracticed> skills = [];
    final rawSkills = classJson?['skills'] ?? classJson?['topics'];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map<String, dynamic>) {
          skills.add(SkillPracticed(
            title: s['title']?.toString() ?? s['name']?.toString() ?? '',
            svgPath: s['icon']?.toString() ?? 'assets/icons/voice_mic.svg',
            colorHex: s['colorHex'] is int ? s['colorHex'] : 0xFF22D3EE,
            bgColorHex: s['bgColorHex'] is int ? s['bgColorHex'] : 0x1A22D3EE,
          ));
        } else if (s is String && s.trim().isNotEmpty) {
          skills.add(SkillPracticed(
            title: s.trim(),
            svgPath: 'assets/icons/voice_mic.svg',
            colorHex: 0xFF22D3EE,
            bgColorHex: 0x1A22D3EE,
          ));
        }
      }
    }

    // 6. Next class
    String? nextId;
    String? nextTitle;
    String? nextTimeFormatted;
    if (nextClassJson != null) {
      nextId = (nextClassJson['id'] ?? nextClassJson['_id'])?.toString();
      nextTitle = (nextClassJson['classTitle'] ?? nextClassJson['title'])?.toString();
      final rawDate = nextClassJson['startDate'] ?? nextClassJson['scheduledStartTime'];
      if (rawDate != null) {
        final dt = DateTime.tryParse(rawDate.toString())?.toLocal();
        if (dt != null) {
          nextTimeFormatted = _formatDateTime(dt);
        }
      }
    }

    // 7. Assignment
    String? assignmentId;
    String? assignmentTitle;
    String? assignmentDueDate;
    if (assignmentJson != null) {
      assignmentId = (assignmentJson['id'] ?? assignmentJson['_id'])?.toString();
      assignmentTitle = assignmentJson['title']?.toString();
      final rawDueDate = assignmentJson['dueDate'];
      if (rawDueDate != null) {
        final dt = DateTime.tryParse(rawDueDate.toString())?.toLocal();
        if (dt != null) {
          assignmentDueDate = _formatDueDate(dt);
        } else {
          assignmentDueDate = rawDueDate.toString();
        }
      }
    }

    return ClassSummaryDto(
      classId: classId,
      classTitle: classTitle,
      teacherName: teacherName,
      scheduledDurationMinutes: scheduledDuration,
      attendedDurationMinutes: attendedDuration,
      attendanceStatus: status,
      isAttended: isAttended,
      skillsPracticed: skills,
      nextClassId: nextId,
      nextClassTitle: nextTitle,
      nextClassTimeFormatted: nextTimeFormatted,
      assignmentId: assignmentId,
      assignmentTitle: assignmentTitle,
      assignmentDueDate: assignmentDueDate,
    );
  }

  /// Converts DTO to domain entity.
  ClassSummaryEntity toEntity() => ClassSummaryEntity(
        classId: classId,
        classTitle: classTitle,
        teacherName: teacherName,
        scheduledDurationMinutes: scheduledDurationMinutes,
        attendedDurationMinutes: attendedDurationMinutes,
        attendanceStatus: attendanceStatus,
        isAttended: isAttended,
        skillsPracticed: skillsPracticed,
        nextClassId: nextClassId,
        nextClassTitle: nextClassTitle,
        nextClassTimeFormatted: nextClassTimeFormatted,
        assignmentId: assignmentId,
        assignmentTitle: assignmentTitle,
        assignmentDueDate: assignmentDueDate,
      );

  static String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = targetDay.difference(today).inDays;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute > 0 ? ':${dt.minute.toString().padLeft(2, '0')}' : '';
    final timeStr = '$hour$minuteStr $amPm';

    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Tomorrow, $timeStr';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final weekday = weekdays[dt.weekday - 1];
      final month = months[dt.month - 1];
      return '$weekday, $month ${dt.day}, $timeStr';
    }
  }

  static String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = targetDay.difference(today).inDays;

    if (diffDays == 0) {
      return 'Due Today';
    } else if (diffDays == 1) {
      return 'Due Tomorrow';
    } else if (diffDays > 1 && diffDays <= 6) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return 'Due ${weekdays[dt.weekday - 1]}';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Due ${months[dt.month - 1]} ${dt.day}';
    }
  }
}
