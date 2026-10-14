import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_event_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildCard(ClassEntity session) {
    return MaterialApp(
      home: Scaffold(body: ClassesEventCard(session: session)),
    );
  }

  group('SCR-13 ClassesEventCard Timezone & Date Consistency', () {
    testWidgets('1. UTC -> local conversion for scheduledStartTime', (
      tester,
    ) async {
      final utcStart = DateTime.parse('2026-09-21T04:30:00.000Z');
      final localStart = utcStart.toLocal();

      final session = ClassEntity(
        id: 'cls-tz-001',
        title: 'Introduction class',
        subject: 'General',
        scheduledStartTime: utcStart,
        scheduledEndTime: DateTime.parse('2026-09-21T05:30:00.000Z'),
        duration: 60,
      );

      await tester.pumpWidget(buildCard(session));
      await tester.pumpAndSettle();

      // Ensure that raw UTC hour (4:30 AM) is not displayed when local timezone is not UTC
      if (localStart.timeZoneOffset != Duration.zero) {
        expect(find.text('Mon, 21 Sep at 4:30 AM'), findsNothing);
      }

      // If running on a system with IST (UTC+05:30), verify exact '10:00 AM'
      if (localStart.timeZoneOffset == const Duration(hours: 5, minutes: 30)) {
        expect(find.text('Mon, 21 Sep at 10:00 AM'), findsOneWidget);
      }

      // In any timezone, verify it matches localStart formatting
      final hour = localStart.hour;
      final minute = localStart.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      expect(
        find.textContaining('$formattedHour:$minute $ampm'),
        findsOneWidget,
      );
    });

    testWidgets('2. End time verification', (tester) async {
      final utcEnd = DateTime.parse('2026-09-21T05:30:00.000Z');
      final localEnd = utcEnd.toLocal();

      final session = ClassEntity(
        id: 'cls-tz-002',
        title: 'End Time Test Class',
        subject: 'General',
        scheduledStartTime: utcEnd, // test formatting when start is 05:30 UTC
        scheduledEndTime: DateTime.parse('2026-09-21T06:30:00.000Z'),
        duration: 60,
      );

      await tester.pumpWidget(buildCard(session));
      await tester.pumpAndSettle();

      if (localEnd.timeZoneOffset == const Duration(hours: 5, minutes: 30)) {
        expect(find.text('Mon, 21 Sep at 11:00 AM'), findsOneWidget);
      }

      final hour = localEnd.hour;
      final minute = localEnd.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      expect(
        find.textContaining('$formattedHour:$minute $ampm'),
        findsOneWidget,
      );
    });

    testWidgets(
      '3. Date rollover near midnight uses local date, not UTC date',
      (tester) async {
        // 23:30 UTC on 20 Sep
        final midnightUtc = DateTime.parse('2026-09-20T23:30:00.000Z');
        final localStart = midnightUtc.toLocal();

        final session = ClassEntity(
          id: 'cls-tz-003',
          title: 'Midnight Rollover Class',
          subject: 'Science',
          scheduledStartTime: midnightUtc,
          duration: 60,
        );

        await tester.pumpWidget(buildCard(session));
        await tester.pumpAndSettle();

        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const months = [
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

        final expectedDayName = weekdays[localStart.weekday - 1];
        final expectedDayNum = localStart.day;
        final expectedMonthName = months[localStart.month - 1];

        // In IST (+05:30), 2026-09-20 23:30 UTC is 2026-09-21 05:00 AM (Monday, 21 Sep)
        if (localStart.timeZoneOffset ==
            const Duration(hours: 5, minutes: 30)) {
          expect(find.text('Mon, 21 Sep at 5:00 AM'), findsOneWidget);
          expect(find.textContaining('Sun, 20 Sep'), findsNothing);
        }

        // Always matches local calendar date
        expect(
          find.textContaining(
            '$expectedDayName, $expectedDayNum $expectedMonthName',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '4. Verify no hardcoded +05:30 offset is applied to local DateTimes',
      (tester) async {
        // Create a DateTime that is already local
        final alreadyLocal = DateTime(2026, 9, 21, 14, 15);

        final session = ClassEntity(
          id: 'cls-tz-004',
          title: 'Local DateTime Class',
          subject: 'Math',
          scheduledStartTime: alreadyLocal,
          duration: 45,
        );

        await tester.pumpWidget(buildCard(session));
        await tester.pumpAndSettle();

        // Must format as 2:15 PM, not 7:45 PM (which would happen if +05:30 was hardcoded on top of local)
        expect(find.text('Mon, 21 Sep at 2:15 PM'), findsOneWidget);
      },
    );
  });
}
