import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_session_booked_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/demo_booking_confirmation_popup.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/demo_booking_confirmed_popup.dart';

import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

void main() {
  group('Demo Booking Complete Flow Integration Tests', () {
    testWidgets(
      'Scenario 1 & 2: Submitting state disables repeated taps, shows loading indicator',
      (WidgetTester tester) async {
        final completer = Completer<DemoBookingEntity?>();
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DemoBookingConfirmationPopup(
                selectedDemo: 'ACE Public Speaking',
                dateTime: 'Tomorrow at 4:00 PM',
                teacher: 'Ms. Sarah',
                onConfirmBooking: () async {
                  callCount++;
                  return await completer.future;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final confirmButton = find.byKey(const Key('demo_popup_confirm_button'));
        expect(confirmButton, findsOneWidget);
        expect(find.text('Confirm Booking'), findsOneWidget);

        // Tap confirm button
        await tester.tap(confirmButton);
        await tester.pump();

        // While request is in-flight:
        expect(callCount, 1);
        expect(find.text('Confirming...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Repeated tap should NOT trigger a second submission
        await tester.tap(confirmButton);
        await tester.pump();
        expect(callCount, 1);

        // Complete the future
        completer.complete(null);
        await tester.pump();

        // After failure / null return, loading indicator disappears
        expect(find.text('Confirm Booking'), findsOneWidget);
        expect(find.byType(DemoBookingConfirmedPopup), findsNothing);
      },
    );

    testWidgets(
      'Scenario 6: Failed API response does not show confirmed popup or navigate',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DemoBookingConfirmationPopup(
                selectedDemo: 'ACE Public Speaking',
                dateTime: 'Tomorrow at 4:00 PM',
                teacher: 'Ms. Sarah',
                onConfirmBooking: () async {
                  return null; // Simulates backend error / validation failure
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final confirmButton = find.byKey(const Key('demo_popup_confirm_button'));
        await tester.tap(confirmButton);
        await tester.pump();

        // Must still be on confirmation popup; confirmed popup not displayed
        expect(find.text('Ready to Start?'), findsOneWidget);
        expect(find.text('Booking Confirmed..'), findsNothing);
        expect(find.byType(DemoBookingConfirmedPopup), findsNothing);
      },
    );

    testWidgets(
      'Scenario 3, 4 & 5: Successful booking shows confirmed popup for 2s then transitions to DemoSessionBookedScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final confirmedBooking = DemoBookingEntity(
          bookingId: 'demo-real-101',
          demoCode: 'DEMO-998877',
          courseName: 'ACE Public Speaking Masterclass',
          studentName: 'Alex Doe',
          startDateTime: DateTime(2026, 10, 25, 14, 0),
          endDateTime: DateTime(2026, 10, 25, 14, 45),
          teacherName: 'Ms. Sarah Jenkins',
          teacherStatus: 'Assigned',
          status: 'scheduled',
        );

        DemoBookingEntity? capturedBooking;

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDemoBookingConfirmationPopup(
                        context,
                        selectedDemo: 'ACE Public Speaking Masterclass',
                        dateTime: 'Oct 25 at 2:00 PM',
                        teacher: 'Ms. Sarah Jenkins',
                        onConfirmBooking: () async => confirmedBooking,
                      );
                    },
                    child: const Text('Book Slot'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutePaths.demoSessionBooked,
              builder: (context, state) {
                capturedBooking = state.extra as DemoBookingEntity?;
                return DemoSessionBookedScreen(booking: capturedBooking);
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(
                () => _FakeAuthController(
                  const Authenticated(
                    accessToken: 'mock_token',
                    destination: AuthDestination.demoBookingDashboard,
                    resolvedTargetDestination:
                        AuthDestination.demoBookingDashboard,
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump();

        // 1. Open confirmation popup
        await tester.tap(find.text('Book Slot'));
        await tester.pumpAndSettle();
        expect(find.text('Ready to Start?'), findsOneWidget);

        // 2. Tap Confirm Booking
        await tester.tap(find.byKey(const Key('demo_popup_confirm_button')));
        await tester.pumpAndSettle();

        // 3. Confirmation popup is dismissed, Confirmed Popup is displayed
        expect(find.text('Ready to Start?'), findsNothing);
        expect(find.text('Booking Confirmed..'), findsOneWidget);
        expect(find.text('ACE Public Speaking Masterclass'), findsOneWidget);
        expect(find.text('Ms. Sarah Jenkins'), findsOneWidget);

        // 4. Advance 1 second: confirmed popup is still visible
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.text('Booking Confirmed..'), findsOneWidget);

        // 5. Advance past 2000ms delay: navigates to DemoSessionBookedScreen
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();

        // Confirmed popup gone, Demo Session Booked screen displayed!
        expect(find.text('Booking Confirmed..'), findsNothing);
        expect(find.text('Demo Session Booked'), findsOneWidget);

        // Verified booking fields populated on final screen
        expect(find.text('ACE Public Speaking Masterclass'), findsOneWidget);
        expect(find.text('Ms. Sarah Jenkins'), findsOneWidget);
        expect(find.text('Alex Doe'), findsOneWidget);
        expect(find.text('DEMO-998877'), findsOneWidget);
        expect(find.text('Assigned'), findsOneWidget);

        // 6. Tap Go to Dashboard
        expect(find.byKey(const Key('demo_booked_dashboard_button')), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 8 & 9: Truthfully displays unassigned teacher and missing meeting link',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final bookingWithoutTeacher = DemoBookingEntity(
          bookingId: 'demo-pending-teacher',
          courseName: 'Critical Thinking & Math',
          startDateTime: DateTime(2026, 11, 1, 11, 0),
          teacherName: null,
          teacherStatus: 'Finalizing',
          meetingUrl: null,
          joinEligible: false,
          status: 'scheduled',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: DemoSessionBookedScreen(booking: bookingWithoutTeacher),
            ),
          ),
        );
        await tester.pump();

        // Missing teacher truthfully shown as Pending Assignment (Finalizing)
        expect(find.text('Pending Assignment (Finalizing)'), findsOneWidget);
        expect(find.text('Finalizing'), findsOneWidget);
        expect(find.text('A specialized mentor will be confirmed before your session.'), findsOneWidget);

        // Missing meeting link truthfully shown as not yet activated
        expect(
          find.text('Meeting link activates 15 minutes before the session starts. All access links are verified and protected.'),
          findsOneWidget,
        );
        expect(find.text('Your classroom is live! You can join the session now.'), findsNothing);
      },
    );
  });
}
