import 'package:flutter/foundation.dart';

/// Explicit status classifications for a demo session time gate.
enum DemoSessionTimeGateStatus {
  /// Session start is more than 15 minutes in the future (T - 15m > now).
  tooEarly,

  /// Current time is between T - 15m and scheduled end time. Entry is permitted.
  eligible,

  /// Scheduled session end time has passed.
  expired,

  /// Session has been explicitly cancelled.
  cancelled,

  /// Session information is invalid or missing required schedule timestamps.
  invalid,
}

/// Pure domain utility encapsulating the 15-minute early access session time gate.
///
/// Rules:
/// Let T = scheduled session start time.
/// Let W = T - 15 minutes (joining window opens).
/// Let now = current time.
///
/// - now < W: [DemoSessionTimeGateStatus.tooEarly]. Entry prohibited.
/// - W <= now < end: [DemoSessionTimeGateStatus.eligible]. Entry allowed.
/// - now >= end: [DemoSessionTimeGateStatus.expired]. Entry prohibited.
/// - status is CANCELLED: [DemoSessionTimeGateStatus.cancelled]. Entry prohibited.
@immutable
class DemoSessionEligibility {
  const DemoSessionEligibility({
    required this.startDateTime,
    this.endDateTime,
    this.durationMinutes = 45,
    this.status = 'scheduled',
  });

  /// Scheduled start time (T).
  final DateTime startDateTime;

  /// Optional scheduled end time. Defaults to startDateTime + durationMinutes.
  final DateTime? endDateTime;

  /// Duration of session in minutes.
  final int durationMinutes;

  /// Raw backend status string (e.g. 'scheduled', 'live', 'completed', 'cancelled').
  final String status;

  /// Exact timestamp when the 15-minute joining window opens (W = T - 15m).
  DateTime get windowOpenTime =>
      startDateTime.subtract(const Duration(minutes: 15));

  /// Effective end time of the demo session.
  DateTime get effectiveEndTime =>
      endDateTime ?? startDateTime.add(Duration(minutes: durationMinutes));

  /// Whether the session was marked cancelled by the backend.
  bool get isCancelled {
    final s = status.trim().toLowerCase();
    return s == 'cancelled' || s == 'canceled';
  }

  /// Whether the session is currently marked live / in-progress by the backend.
  bool get isLive {
    if (isCancelled) return false;
    final s = status.trim().toLowerCase();
    return s == 'live' || s == 'ongoing' || s == 'in_progress';
  }

  /// Evaluates the session time gate status relative to [currentTime] (defaults to [DateTime.now()]).
  DemoSessionTimeGateStatus evaluate([DateTime? currentTime]) {
    if (isCancelled) {
      return DemoSessionTimeGateStatus.cancelled;
    }

    final now = currentTime ?? DateTime.now();

    // If backend reports LIVE and session has not expired past end time, allow entry
    if (isLive && !now.isAfter(effectiveEndTime)) {
      return DemoSessionTimeGateStatus.eligible;
    }

    // Check expiration: now >= effectiveEndTime
    if (!now.isBefore(effectiveEndTime)) {
      return DemoSessionTimeGateStatus.expired;
    }

    // Check early window: now < windowOpenTime
    if (now.isBefore(windowOpenTime)) {
      return DemoSessionTimeGateStatus.tooEarly;
    }

    // W <= now < effectiveEndTime
    return DemoSessionTimeGateStatus.eligible;
  }

  /// Whether the participant is allowed to enter the classroom.
  bool canEnter([DateTime? currentTime]) {
    return evaluate(currentTime) == DemoSessionTimeGateStatus.eligible;
  }

  /// Whether the participant opened the screen too early (more than 15 mins before start).
  bool isTooEarly([DateTime? currentTime]) {
    return evaluate(currentTime) == DemoSessionTimeGateStatus.tooEarly;
  }

  /// Whether the session has concluded.
  bool isExpired([DateTime? currentTime]) {
    return evaluate(currentTime) == DemoSessionTimeGateStatus.expired;
  }

  /// Duration remaining until the 15-minute joining window opens.
  /// Returns [Duration.zero] if the window is already open or past.
  Duration remainingUntilWindowOpen([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    if (!now.isBefore(windowOpenTime)) {
      return Duration.zero;
    }
    return windowOpenTime.difference(now);
  }

  /// Duration remaining until the session ends.
  /// Returns [Duration.zero] if the session has already ended.
  Duration remainingUntilSessionEnd([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    if (!now.isBefore(effectiveEndTime)) {
      return Duration.zero;
    }
    return effectiveEndTime.difference(now);
  }

  /// Formatted countdown string (e.g. "14:59" or "02:15:30").
  static String formatCountdown(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return '00:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }
}
