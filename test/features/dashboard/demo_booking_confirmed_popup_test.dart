import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/demo_booking_confirmed_popup.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/parent_hamburger_drawer.dart';

void main() {
  group('DemoBookingConfirmedPopup Tests', () {
    testWidgets('renders all Figma elements from Node 75:793', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoBookingConfirmedPopup(
              selectedDemo: 'ACE Public Speaking',
              dateTime: 'Today at 8:00 PM',
              teacher: 'Ms. Sarah',
            ),
          ),
        ),
      );
      await tester.pump();

      // Heading
      expect(find.text('Booking Confirmed..'), findsOneWidget);

      // Summary Details
      expect(find.text('SELECTED DEMO'), findsOneWidget);
      expect(find.text('ACE Public Speaking'), findsOneWidget);
      expect(find.text('DATE & TIME'), findsOneWidget);
      expect(find.text('Today at 8:00 PM'), findsOneWidget);
      expect(find.text('TEACHER'), findsOneWidget);
      expect(find.text('Ms. Sarah'), findsOneWidget);

      // Info message
      expect(
        find.text(
          'Booking details and meeting link will be sent to your email or WhatsApp immediately after confirmation.',
        ),
        findsOneWidget,
      );

      // Footer
      expect(
        find.text('SECURE RESERVATION • 100% FREE SESSION'),
        findsOneWidget,
      );

      // Close button
      expect(
        find.byKey(const Key('demo_confirmed_popup_close_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'dismissing confirmed popup triggers callback to dashboard navigation',
      (WidgetTester tester) async {
        bool navigatedToDashboard = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDemoBookingConfirmedPopup(
                      context,
                      onDismissToDashboard: () {
                        navigatedToDashboard = true;
                      },
                    );
                  },
                  child: const Text('Open Popup'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Open popup
        await tester.tap(find.text('Open Popup'));
        await tester.pumpAndSettle();

        expect(find.byType(DemoBookingConfirmedPopup), findsOneWidget);

        // Tap close button
        await tester.tap(
          find.byKey(const Key('demo_confirmed_popup_close_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DemoBookingConfirmedPopup), findsNothing);
        expect(navigatedToDashboard, isTrue);
      },
    );

    testWidgets(
      'automatically redirects to dashboard after confirmation delay without pressing close button',
      (WidgetTester tester) async {
        int navigationCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDemoBookingConfirmedPopup(
                      context,
                      redirectDelay: const Duration(milliseconds: 1500),
                      onDismissToDashboard: () {
                        navigationCount++;
                      },
                    );
                  },
                  child: const Text('Open Popup'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Open popup
        await tester.tap(find.text('Open Popup'));
        await tester.pumpAndSettle();

        expect(find.byType(DemoBookingConfirmedPopup), findsOneWidget);
        expect(navigationCount, 0);

        // Advance time past the redirect delay without touching close button
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();

        // Popup dismissed and automatically redirected to dashboard
        expect(find.byType(DemoBookingConfirmedPopup), findsNothing);
        expect(navigationCount, 1);
      },
    );

    testWidgets(
      'prevents duplicate navigation if user presses close button while timer is active',
      (WidgetTester tester) async {
        int navigationCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDemoBookingConfirmedPopup(
                      context,
                      redirectDelay: const Duration(milliseconds: 2000),
                      onDismissToDashboard: () {
                        navigationCount++;
                      },
                    );
                  },
                  child: const Text('Open Popup'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Open popup
        await tester.tap(find.text('Open Popup'));
        await tester.pumpAndSettle();

        expect(find.byType(DemoBookingConfirmedPopup), findsOneWidget);

        // User manually taps close button before 2000ms timer expires
        await tester.tap(
          find.byKey(const Key('demo_confirmed_popup_close_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DemoBookingConfirmedPopup), findsNothing);
        expect(navigationCount, 1);

        // Advance time past where timer would have fired
        await tester.pump(const Duration(milliseconds: 3000));
        await tester.pumpAndSettle();

        // Still exactly 1 navigation invocation
        expect(navigationCount, 1);
      },
    );

    testWidgets(
      'hamburger button on DemoBookingDashboard opens ParentHamburgerDrawer',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: DemoBookingDashboardScreen()),
        );
        await tester.pump();

        // Ensure drawer is initially closed
        expect(find.byType(ParentHamburgerDrawer), findsNothing);

        // Tap hamburger menu button
        final hamburgerButton = find.byKey(
          const Key('demo_dashboard_hamburger_button'),
        );
        expect(hamburgerButton, findsOneWidget);
        await tester.tap(hamburgerButton);
        await tester.pumpAndSettle();

        // Drawer is open with exact Figma elements
        expect(find.byType(ParentHamburgerDrawer), findsOneWidget);
        expect(find.text('Hi, PPs'), findsOneWidget);
        expect(find.text('LEARNING'), findsOneWidget);
        expect(find.text('MY GROWTH'), findsOneWidget);
        expect(find.text('COMMUNICATION'), findsOneWidget);
        expect(find.text('ACCOUNT'), findsOneWidget);
      },
    );
  });
}
