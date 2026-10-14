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
    this.effectiveStatus,
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

  /// Status string (e.g. "UPCOMING", "LIVE", "SCHEDULED", "COMPLETED", "CANCELLED").
  final String? status;

  /// Student-specific effective status (e.g. "upcoming", "attended", "missed", "cancelled").
  final String? effectiveStatus;

  /// Instructor / Teacher display name.
  final String? teacherName;

  /// Instructor / Teacher avatar URL.
  final String? teacherAvatar;

  /// Direct meeting URL if exposed.
  final String? meetingUrl;

  /// Jitsi / conferencing room name.
  final String? roomName;

  /// Computed effective end time of the session.
  DateTime? get effectiveEndTime =>
      scheduledEndTime ??
      scheduledStartTime?.add(Duration(minutes: duration ?? 60));

  /// Helper flag to check if the session was cancelled.
  bool get isCancelled {
    final s = status?.toUpperCase();
    final eff = effectiveStatus?.toUpperCase();
    return s == 'CANCELLED' ||
        s == 'CANCELED' ||
        eff == 'CANCELLED' ||
        eff == 'CANCELED';
  }

  /// Helper flag to check if the session is currently live.
  bool get isLive {
    if (isCancelled) return false;
    final s = status?.toUpperCase();
    final eff = effectiveStatus?.toUpperCase();
    return s == 'LIVE' ||
        s == 'ONGOING' ||
        s == 'IN_PROGRESS' ||
        s == 'STARTED' ||
        eff == 'LIVE';
  }

  /// Evaluates whether the session is upcoming at the given [currentTime].
  bool isUpcomingAt([DateTime? currentTime]) {
    if (isCancelled || isLive) return false;
    final eff = effectiveStatus?.toUpperCase();
    final s = status?.toUpperCase();

    // If the class session is explicitly completed or attended, it is not upcoming
    // (unless effectiveStatus explicitly overrides it to UPCOMING, e.g. LVC-0019)
    if ((s == 'COMPLETED' || s == 'ATTENDED') && eff != 'UPCOMING') {
      return false;
    }
    if (s == 'MISSED' && eff != 'UPCOMING') {
      return false;
    }

    // Explicit upcoming status from backend
    if (eff == 'UPCOMING' || s == 'UPCOMING') return true;

    final now = currentTime ?? DateTime.now();

    // If session is scheduled and end time has not passed yet, it is still upcoming/active
    if (s == 'SCHEDULED') {
      final end = effectiveEndTime;
      if (end == null || !end.isBefore(now)) {
        return true;
      }
    }

    if (scheduledStartTime != null && scheduledStartTime!.isAfter(now)) {
      if (eff != 'ATTENDED' && eff != 'MISSED') {
        return true;
      }
    }

    return false;
  }

  /// Helper flag to check if the session is upcoming.
  bool get isUpcoming => isUpcomingAt();

  /// Evaluates whether the session was completed at the given [currentTime].
  bool isCompletedAt([DateTime? currentTime]) {
    if (isCancelled || isLive) return false;
    // A future or ongoing scheduled session cannot be completed
    if (isUpcomingAt(currentTime)) return false;

    final eff = effectiveStatus?.toUpperCase();
    final s = status?.toUpperCase();
    return eff == 'ATTENDED' || s == 'COMPLETED' || s == 'ATTENDED';
  }

  /// Helper flag to check if the session has completed.
  bool get isCompleted => isCompletedAt();

  /// Evaluates whether the session was missed at the given [currentTime].
  bool isMissedAt([DateTime? currentTime]) {
    if (isCancelled || isLive) return false;
    // A future or ongoing scheduled session cannot be missed
    if (isUpcomingAt(currentTime)) return false;

    final eff = effectiveStatus?.toUpperCase();
    final s = status?.toUpperCase();
    if (eff == 'MISSED' || s == 'MISSED') return true;

    final now = currentTime ?? DateTime.now();
    final end = effectiveEndTime;
    if (end != null && end.isBefore(now) && !isCompletedAt(now)) {
      return true;
    }
    return false;
  }

  /// Helper flag to check if the session was missed.
  bool get isMissed => isMissedAt();

  /// Earliest permitted entry time (15 minutes prior to scheduled start time).
  DateTime? get earliestEntryTime =>
      scheduledStartTime?.subtract(const Duration(minutes: 15));

  /// Returns true if [currentTime] (or [DateTime.now()]) has reached or passed
  /// [earliestEntryTime]. Returns false if [scheduledStartTime] is null or
  /// [currentTime] is before [earliestEntryTime].
  bool isWithinEntryWindow([DateTime? currentTime]) {
    if (scheduledStartTime == null) return false;
    final now = currentTime ?? DateTime.now();
    final entryTime = earliestEntryTime!;
    return !now.isBefore(entryTime);
  }

  /// Determines whether the user is permitted to enter the live class session.
  ///
  /// Criteria:
  /// - Class must not be completed, missed, or cancelled.
  /// - If the backend status is already LIVE / ONGOING, entry is permitted.
  /// - Otherwise, [scheduledStartTime] must be non-null and [isWithinEntryWindow] must be true.
  /// - If [scheduledEndTime] is specified and has passed, entry is blocked unless session is live.
  bool canEnterLiveClass([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    if (isCompletedAt(now) || isMissedAt(now) || isCancelled) return false;
    if (isLive) return true;
    if (scheduledStartTime == null) return false;

    if (!isWithinEntryWindow(now)) return false;

    if (scheduledEndTime != null && now.isAfter(scheduledEndTime!)) {
      return false;
    }

    return true;
  }

  /// Formats the remaining countdown text until [scheduledStartTime].
  ///
  /// Examples:
  /// - 90 minutes away: "Class is starting in 1 hour 30 minutes"
  /// - 30 minutes away: "Class is starting in 30 minutes"
  /// - 15 minutes away: "Class is starting in 15 minutes"
  /// - 1 minute away: "Class is starting in 1 minute"
  /// - 1 hour away: "Class is starting in 1 hour"
  /// - 24+ hours away: "Class is scheduled in 2 days" / "Class is scheduled in 1 day"
  /// - At or after scheduled start: returns null (no positive countdown).
  String? formatCountdown([DateTime? currentTime]) {
    if (scheduledStartTime == null) return null;
    final now = currentTime ?? DateTime.now();
    final diff = scheduledStartTime!.difference(now);

    // At or after scheduled start: no positive countdown
    if (diff.isNegative || diff.inSeconds <= 0) {
      return null;
    }

    if (diff.inHours >= 24) {
      final days = diff.inDays <= 0 ? 1 : diff.inDays;
      final unit = days == 1 ? 'day' : 'days';
      return 'Class is scheduled in $days $unit';
    }

    // Accurately compute hours and minutes remaining using ceil of minutes
    final totalMinutes = (diff.inSeconds + 59) ~/ 60;
    if (totalMinutes <= 0) return null;

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      final hourStr = '$hours ${hours == 1 ? "hour" : "hours"}';
      final minStr = '$minutes ${minutes == 1 ? "minute" : "minutes"}';
      return 'Class is starting in $hourStr $minStr';
    } else if (hours > 0) {
      final hourStr = '$hours ${hours == 1 ? "hour" : "hours"}';
      return 'Class is starting in $hourStr';
    } else {
      final minStr = '$minutes ${minutes == 1 ? "minute" : "minutes"}';
      return 'Class is starting in $minStr';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ClassEntity && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
