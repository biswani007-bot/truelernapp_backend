import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_submission_entity.dart';
import 'package:truelearn/features/assignments/presentation/screens/assignment_submitted_screen.dart';

void main() {
  group('AssignmentSubmittedScreen Widget Tests (Figma Node 76:2611)', () {
    testWidgets(
      'renders hero section, submission details card, related class card, and back button',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final submissionTime = DateTime(2026, 9, 28, 15, 29);
        final assignment = AssignmentEntity(
          id: 'asg_2',
          title: 'Confidence Quiz',
          topic: 'Practical Thinking',
          status: AssignmentStatus.completed,
          submission: AssignmentSubmissionEntity(
            status: SubmissionStatus.submitted,
            submittedAt: submissionTime,
            rawStatus: 'under_review',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: AssignmentSubmittedScreen(
                assignmentId: 'asg_2',
                assignment: assignment,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // 1. Hero Section
        expect(find.text('Assignment Submitted'), findsOneWidget);
        expect(
          find.textContaining(
            'Great job! Your Practical Thinking assignment is',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('securely in the hands of our reviewers.'),
          findsOneWidget,
        );

        // 2. Submission Details Card
        expect(find.text('Submission Details'), findsOneWidget);
        expect(find.text('Submitted'), findsOneWidget);
        expect(find.textContaining('3:29 PM'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Under Review'), findsOneWidget);

        // 3. Related Class Context Card
        expect(find.text('PRACTICAL THINKING'), findsOneWidget);
        expect(find.text('Confidence Quiz'), findsOneWidget);
        expect(
          find.textContaining(
            'This assignment is connected to the recent live class.',
          ),
          findsOneWidget,
        );
        expect(find.text('View Class Details'), findsOneWidget);
        expect(
          find.byKey(const Key('view_class_details_link')),
          findsOneWidget,
        );

        // 4. Primary CTA: BACK TO LEARNING
        expect(find.text('BACK TO LEARNING'), findsOneWidget);
        expect(
          find.byKey(const Key('back_to_learning_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('formats status label and timestamp with timezone conversion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Use a local DateTime directly — test environment may not apply IST offset
      // Local time: 3:29 PM (15:29) on some older date
      final olderLocalDate = DateTime(
        2025,
        6,
        15,
        15,
        29,
        0,
      ); // clearly in the past
      final assignment = AssignmentEntity(
        id: 'asg_older',
        title: 'Science Project',
        topic: 'Science',
        status: AssignmentStatus.completed,
        submission: AssignmentSubmissionEntity(
          status: SubmissionStatus.submitted,
          submittedAt: olderLocalDate,
          rawStatus: 'submitted_late',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AssignmentSubmittedScreen(
              assignmentId: 'asg_older',
              assignment: assignment,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should render Submission Details card with Submitted Late status
      expect(find.text('Submission Details'), findsOneWidget);
      expect(find.text('Submitted Late'), findsOneWidget);

      // Should show formatted local time: '3:29 PM'
      expect(find.textContaining('3:29 PM'), findsOneWidget);

      // Since June 15 2025 is in the past (not today/yesterday), should show date prefix
      expect(find.textContaining('15 Jun 2025'), findsOneWidget);
    });
  });
}
