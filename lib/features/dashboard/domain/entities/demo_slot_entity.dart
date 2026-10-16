/// Domain entity representing a scheduled demo slot for a course.
class DemoSlotEntity {
  const DemoSlotEntity({
    required this.id,
    required this.courseId,
    required this.startDateTime,
    required this.endDateTime,
    this.instructorName,
    this.dayLabel,
    this.capacity,
    this.timeString,
    this.duration,
    this.isAvailable = true,
  });

  /// Unique identifier of the availability/slot record.
  final String id;

  /// Associated course ID.
  final String courseId;

  /// Start timestamp of the demo slot.
  final DateTime startDateTime;

  /// End timestamp of the demo slot.
  final DateTime endDateTime;

  /// Assigned faculty or instructor name, if available.
  final String? instructorName;

  /// Optional relative day label (e.g. TODAY, TOMORROW).
  final String? dayLabel;

  /// Maximum student capacity.
  final int? capacity;

  /// Explicit formatted time string from backend (e.g. "4:50 PM").
  final String? timeString;

  /// Duration in minutes (e.g. 15, 30, 45).
  final int? duration;

  /// Whether the slot is currently open for booking.
  final bool isAvailable;

  /// Formatted time string (e.g. "4:50" or "10:00").
  String get formattedTime {
    if (timeString != null && timeString!.trim().isNotEmpty) {
      final parts = timeString!.trim().split(' ');
      if (parts.isNotEmpty) return parts[0];
    }
    final localTime = startDateTime.toLocal();
    final hour = localTime.hour;
    final minute = localTime.minute.toString().padLeft(2, '0');
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute';
  }

  /// AM/PM period string.
  String get period {
    if (timeString != null && timeString!.trim().isNotEmpty) {
      final parts = timeString!.trim().split(' ');
      if (parts.length > 1) return parts[1].toUpperCase();
    }
    final localTime = startDateTime.toLocal();
    return localTime.hour >= 12 ? 'PM' : 'AM';
  }

  /// Computed or provided relative day label.
  String get displayDayLabel {
    if (dayLabel != null && dayLabel!.isNotEmpty) {
      return dayLabel!.toUpperCase();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localTime = startDateTime.toLocal();
    final slotDate = DateTime(localTime.year, localTime.month, localTime.day);
    final diffDays = slotDate.difference(today).inDays;

    if (diffDays == 0) return 'TODAY';
    if (diffDays == 1) return 'TOMORROW';

    const weekdayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdayNames[localTime.weekday - 1];
  }

  factory DemoSlotEntity.fromJson(
    Map<String, dynamic> json, {
    String? fallbackCourseId,
    String? fallbackDateKey,
  }) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawStart =
        json['scheduledStart'] ??
        json['startDateTime'] ??
        json['startTime'] ??
        json['start'] ??
        json['scheduledTime'];
    final parsedStart = parseDate(rawStart);

    final rawDuration = json['duration'] as num?;
    final durationMins = rawDuration?.toInt();

    final rawEnd =
        json['scheduledEnd'] ??
        json['endDateTime'] ??
        json['endTime'] ??
        json['end'];
    final parsedEnd = rawEnd != null
        ? parseDate(rawEnd)
        : (durationMins != null
              ? parsedStart.add(Duration(minutes: durationMins))
              : parsedStart.add(const Duration(minutes: 30)));

    final statusStr = json['status']?.toString().toUpperCase();
    final isAvailable =
        json['isAvailable'] as bool? ??
        (statusStr == null || statusStr == 'AVAILABLE' || statusStr == 'OPEN');

    String? resolvedDayLabel = json['dayLabel']?.toString();
    if (resolvedDayLabel == null && fallbackDateKey != null) {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (fallbackDateKey == todayStr) {
        resolvedDayLabel = 'TODAY';
      }
    }

    return DemoSlotEntity(
      id:
          json['id']?.toString() ??
          json['_id']?.toString() ??
          json['availabilityId']?.toString() ??
          json['slotId']?.toString() ??
          '',
      courseId:
          json['courseId']?.toString() ??
          json['course']?.toString() ??
          fallbackCourseId ??
          '',
      startDateTime: parsedStart,
      endDateTime: parsedEnd,
      timeString: json['timeString']?.toString(),
      duration: durationMins,
      instructorName:
          json['instructorName']?.toString() ??
          json['teacherName']?.toString() ??
          (json['teacher'] is Map
              ? json['teacher']['name']?.toString()
              : null) ??
          json['instructor']?.toString(),
      dayLabel: resolvedDayLabel,
      capacity: json['capacity'] as int?,
      isAvailable: isAvailable,
    );
  }
}
