import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/demo_booking_confirmation_popup.dart';

void main() {
  group('DemoBookingConfirmationPopup Tests', () {
    testWidgets('renders all Figma elements from Node 74:624', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DemoBookingConfirmationPopup())),
      );
      await tester.pump();

      // Heading & Subtitle
      expect(find.text('Ready to Start?'), findsOneWidget);
      expect(
        find.text(
          'Confirm your selection for the ACE Public\nSpeaking Program demo.',
        ),
        findsOneWidget,
      );

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
          'Secure meeting link and prep materials will be sent to your email immediately after confirmation.',
        ),
        findsOneWidget,
      );

      // CTA button & Footer
      expect(find.text('Confirm Booking'), findsOneWidget);
      expect(
        find.text('SECURE RESERVATION • 100% FREE SESSION'),
        findsOneWidget,
      );
    });

    testWidgets(
      'clicking Book this demo on dashboard opens confirmation popup and close button dismisses it',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: DemoBookingDashboardScreen()),
        );
        await tester.pump();

        // Ensure button is visible and tap it
        final bookButton = find.byKey(const Key('book_demo_button_today'));
        await tester.ensureVisible(bookButton);
        await tester.tap(bookButton);
        await tester.pumpAndSettle();

        // Popup should be displayed
        expect(find.byType(DemoBookingConfirmationPopup), findsOneWidget);
        expect(find.text('Ready to Start?'), findsOneWidget);

        // Tap close button
        final closeButton = find.byKey(const Key('demo_popup_close_button'));
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Popup should be dismissed
        expect(find.byType(DemoBookingConfirmationPopup), findsNothing);
      },
    );

    testWidgets(
      'confirm booking button dismisses confirmation popup and opens confirmed popup',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: DemoBookingDashboardScreen()),
        );
        await tester.pump();

        // Tap Book this demo
        final bookButton = find.byKey(const Key('book_demo_button_today'));
        await tester.ensureVisible(bookButton);
        await tester.tap(bookButton);
        await tester.pumpAndSettle();

        // Tap Confirm Booking
        final confirmButton = find.byKey(
          const Key('demo_popup_confirm_button'),
        );
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // Confirmation popup dismissed, Confirmed popup displayed
        expect(find.byType(DemoBookingConfirmationPopup), findsNothing);
        expect(find.text('Booking Confirmed..'), findsOneWidget);
        expect(
          find.byKey(const Key('demo_confirmed_popup_close_button')),
          findsOneWidget,
        );
      },
    );
  });
}
