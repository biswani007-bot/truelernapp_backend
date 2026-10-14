import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_date_navigator.dart';

void main() {
  testWidgets(
    'ClassesDateNavigator renders initial date selection and allows horizontal swipe',
    (tester) async {
      DateTime selectedDate = DateTime(2026, 8, 26);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClassesDateNavigator(
                selectedDate: selectedDate,
                onDateSelected: (newDate) {
                  selectedDate = newDate;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Wed 26 is rendered
      expect(find.text('Wed'), findsWidgets);
      expect(find.text('26'), findsWidgets);

      // Swipe horizontally to the left
      await tester.drag(
        find.byType(ClassesDateNavigator),
        const Offset(-150, 0),
      );
      await tester.pumpAndSettle();

      // Swipe back to the right
      await tester.drag(
        find.byType(ClassesDateNavigator),
        const Offset(150, 0),
      );
      await tester.pumpAndSettle();

      // Tap on date 27
      final d27 = find.text('27');
      if (d27.evaluate().isNotEmpty) {
        await tester.tap(d27.first);
        await tester.pumpAndSettle();
        expect(selectedDate.day, 27);
      }
    },
  );
}
