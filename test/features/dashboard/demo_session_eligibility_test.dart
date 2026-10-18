import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_session_eligibility.dart';

void main() {
  group('DemoSessionEligibility Time Gate Unit Tests', () {
    final sessionStart = DateTime.utc(2026, 10, 20, 15, 0); // 3:00 PM UTC
    final sessionEnd = DateTime.utc(2026, 10, 20, 15, 45); // 3:45 PM UTC

    test('Case 3: Session more than 15 minutes away evaluates to tooEarly', () {
      final eligibility = DemoSessionEligibility(
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        durationMinutes: 45,
        status: 'scheduled',
      );

      // Current time is 2:30 PM UTC (30 minutes before start, 15 minutes before window opens)
      final now = DateTime.utc(2026, 10, 20, 14, 30);

      expect(eligibility.isTooEarly(now), isTrue);
      expect(eligibility.canEnter(now), isFalse);
      expect(eligibility.isExpired(now), isFalse);
      expect(eligibility.evaluate(now), DemoSessionTimeGateStatus.tooEarly);
    });

    test('Case 4: Countdown calculates exact time until window opening', () {
      final eligibility = DemoSessionEligibility(
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        durationMinutes: 45,
        status: 'scheduled',
      );

      // Window opens at 2:45 PM UTC (15 minutes before 3:00 PM)
      // At 2:30 PM UTC, 15 minutes remain
      final now = DateTime.utc(2026, 10, 20, 14, 30);
      final remaining = eligibility.remainingUntilWindowOpen(now);

      expect(remaining, const Duration(minutes: 15));
      expect(DemoSessionEligibility.formatCountdown(remaining), '15:00');

      // At 2:40 PM UTC (5 minutes remaining until 2:45 PM window open)
      final now5m = DateTime.utc(2026, 10, 20, 14, 40);
      expect(
        eligibility.remainingUntilWindowOpen(now5m),
        const Duration(minutes: 5),
      );
      expect(
        DemoSessionEligibility.formatCountdown(
          eligibility.remainingUntilWindowOpen(now5m),
        ),
        '05:00',
      );
    });

    test('Case 6: At exactly 15 minutes before start, joining window opens', () {
      final eligibility = DemoSessionEligibility(
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        durationMinutes: 45,
        status: 'scheduled',
      );

      // Exactly 2:45 PM UTC (T - 15m)
      final now = DateTime.utc(2026, 10, 20, 14, 45);

      expect(eligibility.isTooEarly(now), isFalse);
      expect(eligibility.canEnter(now), isTrue);
      expect(eligibility.isExpired(now), isFalse);
      expect(eligibility.evaluate(now), DemoSessionTimeGateStatus.eligible);
      expect(eligibility.remainingUntilWindowOpen(now), Duration.zero);
    });

    test('Case 6b: During session (between start and end), entry remains permitted', () {
      final eligibility = DemoSessionEligibility(
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        durationMinutes: 45,
        status: 'scheduled',
      );

      // 3:15 PM UTC (15 minutes after start, 30 minutes before end)
      final now = DateTime.utc(2026, 10, 20, 15, 15);

      expect(eligibility.isTooEarly(now), isFalse);
      expect(eligibility.canEnter(now), isTrue);
      expect(eligibility.isExpired(now), isFalse);
      expect(eligibility.evaluate(now), DemoSessionTimeGateStatus.eligible);
    });

    test('Case 15: At or after scheduled end time, session is expired and entry blocked', () {
      final eligibility = DemoSessionEligibility(
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        durationMinutes: 45,
        status: 'scheduled',
      );

      // Exactly at end time: 3:45 PM UTC
      final nowEnd = DateTime.utc(2026, 10, 20, 15, 45);
      expect(eligibility.canEnter(nowEnd), isFalse);
      expect(eligibility.isExpired(nowEnd), isTrue);
      expect(eligibility.evaluate(nowEnd), DemoSessionTimeGateStatus.expired);

      // After end time: 4:00 PM UTC
      final nowAfter = DateTime.utc(2026, 10, 20, 16, 0);
      expect(eligibility.canEnter(nowAfter), isFalse);
      expect(eligibility.isExpired(nowAfter), isTrue);
      expect(eligibility.evaluate(nowAfter), DemoSessionTimeGateStatus.expired);
    });

    test('Case 11: Cancelled session cannot be entered even during window', () {
      final cancelled = DemoSessionEligibility(
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        durationMinutes: 45,
        status: 'cancelled',
      );

      // Even at 3:00 PM
      final now = DateTime.utc(2026, 10, 20, 15, 0);

      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.canEnter(now), isFalse);
      expect(cancelled.evaluate(now), DemoSessionTimeGateStatus.cancelled);
    });

    test('DemoBookingEntity integration with DemoSessionEligibility', () {
      final booking = DemoBookingEntity(
        bookingId: 'demo-test-123',
        courseName: 'English Communication',
        startDateTime: sessionStart,
        endDateTime: sessionEnd,
        studentName: 'Maya Patel',
        studentId: 'student-maya-001',
        duration: 45,
        status: 'scheduled',
      );

      final tooEarlyTime = DateTime.utc(2026, 10, 20, 14, 0);
      final eligibleTime = DateTime.utc(2026, 10, 20, 14, 50);
      final expiredTime = DateTime.utc(2026, 10, 20, 16, 0);

      expect(booking.isTooEarly(tooEarlyTime), isTrue);
      expect(booking.canEnterDemoClass(tooEarlyTime), isFalse);

      expect(booking.isTooEarly(eligibleTime), isFalse);
      expect(booking.canEnterDemoClass(eligibleTime), isTrue);

      expect(booking.isExpired(expiredTime), isTrue);
      expect(booking.canEnterDemoClass(expiredTime), isFalse);

      final classEntity = booking.toClassEntity();
      expect(classEntity.id, 'demo-test-123');
      expect(classEntity.title, 'English Communication');
      expect(classEntity.scheduledStartTime, sessionStart);
      expect(classEntity.scheduledEndTime, sessionEnd);
    });
  });
}
