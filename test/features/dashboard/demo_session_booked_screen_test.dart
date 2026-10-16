import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_session_booked_screen.dart';

void main() {
  group('DemoSessionBookedScreen Tests', () {
    testWidgets('renders verified booking information correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final booking = DemoBookingEntity(
        bookingId: 'demo-987',
        demoCode: 'DEMO-847291',
        courseName: 'ACE Public Speaking',
        studentName: 'Tommy Jenkins',
        startDateTime: DateTime(2026, 10, 20, 16, 0),
        endDateTime: DateTime(2026, 10, 20, 16, 45),
        teacherName: 'Ms. Sarah',
        teacherStatus: 'Assigned',
        status: 'scheduled',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: DemoSessionBookedScreen(booking: booking)),
        ),
      );
      await tester.pump();

      // Heading and Confirmation text
      expect(find.text('Demo Session Booked'), findsOneWidget);
      expect(
        find.textContaining(
          'Your free 1-on-1 demo session has been scheduled successfully',
        ),
        findsOneWidget,
      );

      // Program Name
      expect(find.text('PROGRAM / SESSION'), findsOneWidget);
      expect(find.text('ACE Public Speaking'), findsOneWidget);

      // Date & Time
      expect(find.text('SCHEDULED DATE & TIME'), findsOneWidget);
      expect(find.text(booking.formattedDate), findsOneWidget);
      expect(find.text(booking.formattedTimeRange), findsOneWidget);

      // Student Name
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('Tommy Jenkins'), findsOneWidget);

      // Teacher Name and Badge
      expect(find.text('ASSIGNED TEACHER'), findsOneWidget);
      expect(find.text('Ms. Sarah'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);

      // Booking Reference
      expect(find.text('BOOKING REFERENCE'), findsOneWidget);
      expect(find.text('DEMO-847291'), findsOneWidget);

      // Join Status Note
      expect(
        find.textContaining(
          'Meeting link activates 15 minutes before the session starts',
        ),
        findsOneWidget,
      );

      // CTA Button
      expect(
        find.byKey(const Key('demo_booked_dashboard_button')),
        findsOneWidget,
      );
      expect(find.text('Go to Dashboard'), findsOneWidget);
    });

    testWidgets(
      'truthfully displays pending assignment when teacher is not assigned',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final booking = DemoBookingEntity(
          bookingId: 'demo-unassigned',
          courseName: 'Junior Foundation, Ages 6 to 10',
          studentName: 'Alex Doe',
          startDateTime: DateTime(2026, 10, 22, 10, 30),
          teacherName: null,
          teacherStatus: 'Finalizing',
          status: 'scheduled',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: DemoSessionBookedScreen(booking: booking)),
          ),
        );
        await tester.pump();

        expect(find.text('Junior Foundation, Ages 6 to 10'), findsOneWidget);
        expect(find.text('Pending Assignment (Finalizing)'), findsOneWidget);
        expect(find.text('Finalizing'), findsOneWidget);
        expect(
          find.text(
            'A specialized mentor will be confirmed before your session.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays active classroom indicator when joinEligible and meetingUrl present',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final booking = DemoBookingEntity(
          bookingId: 'demo-live-now',
          courseName: 'Creative Writing',
          startDateTime: DateTime.now().subtract(const Duration(minutes: 5)),
          teacherName: 'Prof. Davis',
          joinEligible: true,
          meetingUrl: '/parent/demo/join',
          status: 'live',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: DemoSessionBookedScreen(booking: booking)),
          ),
        );
        await tester.pump();

        expect(
          find.text('Your classroom is live! You can join the session now.'),
          findsOneWidget,
        );
      },
    );
  });
}
