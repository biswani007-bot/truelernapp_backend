import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_class_waiting_screen.dart';

class _FakeChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  _FakeChildrenController(this._initial);
  final ChildrenState _initial;

  @override
  ChildrenState build() => _initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {}

  @override
  void reset() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testChild = ChildEntity(
    studentId: 'child-student-001',
    firstName: 'Tommy',
    lastName: 'Jenkins',
    grade: 'Grade 4',
  );

  Widget createSubject({
    required DemoBookingEntity booking,
  }) {
    return ProviderScope(
      overrides: [
        childrenControllerProvider.overrideWith(
          () => _FakeChildrenController(
            const ChildrenLoaded(
              children: [testChild],
              activeChildId: 'child-student-001',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: DemoClassWaitingScreen(booking: booking),
      ),
    );
  }

  group('DemoClassWaitingScreen Widget Tests', () {
    testWidgets(
      'Case 3, 4, 5: Displays waiting screen, required messages, countdown, and disabled Join button when too early',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Starts in 40 minutes (25 minutes until window opens)
        final futureStart = DateTime.now().add(const Duration(minutes: 40));
        final booking = DemoBookingEntity(
          bookingId: 'demo-booking-001',
          demoCode: 'DEMO-123456',
          courseName: 'Junior Robotics & Coding',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: futureStart,
          duration: 45,
          teacherName: 'Dr. Alan Grant',
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking));
        await tester.pump();

        // 1. Heading and required rule text
        expect(find.byKey(const Key('demo_waiting_heading')), findsOneWidget);
        expect(find.text("Your demo class isn't open yet."), findsOneWidget);
        expect(
          find.text('You can join 15 minutes before your scheduled session starts.'),
          findsOneWidget,
        );

        // 2. Program details and participant info
        expect(find.text('Junior Robotics & Coding'), findsOneWidget);
        expect(find.text('Tommy Jenkins'), findsOneWidget);
        expect(find.text('Dr. Alan Grant'), findsOneWidget);

        // 3. Countdown container and formatted timer
        expect(
          find.byKey(const Key('demo_waiting_countdown_container')),
          findsOneWidget,
        );
        expect(find.text('Classroom opens in'), findsOneWidget);
        expect(
          find.byKey(const Key('demo_waiting_countdown_text')),
          findsOneWidget,
        );

        // 4. Case 5: Join Classroom button remains disabled
        final joinButtonFinder = find.byKey(const Key('demo_waiting_join_button'));
        expect(joinButtonFinder, findsOneWidget);
        final elevatedButton = tester.widget<ElevatedButton>(joinButtonFinder);
        expect(elevatedButton.onPressed, isNull);
        expect(
          find.text('Join Classroom (Opens 15m Before)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Case 11: Cancelled session displays Cancelled header and explanatory text',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final booking = DemoBookingEntity(
          bookingId: 'demo-cancelled',
          courseName: 'Public Speaking',
          studentName: 'Tommy Jenkins',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          status: 'cancelled',
        );

        await tester.pumpWidget(createSubject(booking: booking));
        await tester.pump();

        expect(find.text('Demo Session Cancelled'), findsOneWidget);
        expect(
          find.text(
            'This demo session has been cancelled. Please book another available slot.',
          ),
          findsOneWidget,
        );

        // Join button is disabled
        final joinButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('demo_waiting_join_button')),
        );
        expect(joinButton.onPressed, isNull);
      },
    );

    testWidgets(
      'Case 15: Expired session displays Ended header and blocks entry',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final pastBooking = DemoBookingEntity(
          bookingId: 'demo-past',
          courseName: 'Public Speaking',
          studentName: 'Tommy Jenkins',
          startDateTime: DateTime.now().subtract(const Duration(hours: 3)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: pastBooking));
        await tester.pump();

        expect(find.text('Demo Session Ended'), findsOneWidget);
        expect(
          find.text(
            'This scheduled demo session has already concluded and is no longer accessible.',
          ),
          findsOneWidget,
        );

        // Join button is disabled
        final joinButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('demo_waiting_join_button')),
        );
        expect(joinButton.onPressed, isNull);
      },
    );

    testWidgets(
      'Case 14: App lifecycle resume triggers re-evaluation',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final booking = DemoBookingEntity(
          bookingId: 'demo-lifecycle',
          courseName: 'Junior Robotics',
          studentName: 'Tommy Jenkins',
          startDateTime: DateTime.now().add(const Duration(minutes: 30)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking));
        await tester.pump();

        // Simulate returning from background
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        // Should still render and evaluate without crashes
        expect(find.byKey(const Key('demo_waiting_heading')), findsOneWidget);
      },
    );
  });
}
