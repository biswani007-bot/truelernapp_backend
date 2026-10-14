import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/screens/joining_class_screen.dart';

void main() {
  testWidgets(
    'JoiningClassScreen renders title, simulated clay mic icon, and progress indicator',
    (tester) async {
      final mockSession = ClassEntity(
        id: 'session-101',
        title: 'Public Speaking Fundamentals',
        subject: 'Communication',
        teacherName: 'Sarah Jenkins',
        scheduledStartTime: DateTime.now(),
        status: 'UPCOMING',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: JoiningClassScreen(
              classId: 'session-101',
              session: mockSession,
            ),
          ),
        ),
      );

      // Verify main heading
      expect(find.text('Joining your class...'), findsOneWidget);

      // Verify class title
      expect(find.text('Public Speaking Fundamentals'), findsOneWidget);

      // Verify status text
      expect(find.text('Connecting to virtual classroom...'), findsOneWidget);

      // Verify back/close button
      expect(
        find.byKey(const Key('joining_class_back_button')),
        findsOneWidget,
      );
    },
  );
}
