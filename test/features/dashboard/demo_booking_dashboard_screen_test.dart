import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';

void main() {
  group('DemoBookingDashboardScreen Tests', () {
    testWidgets('renders all Figma elements: hero, slots, benefits, footer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: DemoBookingDashboardScreen()),
      );
      await tester.pump();

      // TopAppBar
      expect(find.text('Dashboard'), findsOneWidget);

      // Hero Card
      expect(find.text('FREE DEMO'), findsOneWidget);
      expect(find.text('ACE Public Speaking Program'), findsOneWidget);
      expect(find.text('Free Demo • Age 5-8 Years'), findsOneWidget);

      // Slots Section
      expect(find.text('Next Available Slots'), findsOneWidget);
      expect(find.text('TC'), findsOneWidget);
      expect(find.text('Pps son'), findsOneWidget);

      // Slot Cards
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('TOMORROW'), findsOneWidget);
      expect(find.text('7:00'), findsOneWidget);
      expect(find.text('Book this demo'), findsNWidgets(2));

      // Custom date
      expect(find.text("Can't find a suitable slot?"), findsOneWidget);
      expect(find.text('Choose Preferred Date & Time'), findsOneWidget);

      // Benefits Section
      expect(find.text('Free live demo'), findsOneWidget);
      expect(find.text('Expert faculty'), findsOneWidget);
      expect(find.text('45-minute session'), findsOneWidget);

      // Footer
      expect(
        find.text('FREE DEMO • 45 MINS • EXPERT INSTRUCTOR\n• NO COMMITMENT'),
        findsOneWidget,
      );
    });
  });
}
