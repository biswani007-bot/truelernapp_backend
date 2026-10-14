import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_submission_entity.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignment_submission_controller.dart';
import 'package:truelearn/features/assignments/presentation/screens/assignment_submission_screen.dart';

void main() {
  group('AssignmentSubmissionScreen Widget Tests', () {
    testWidgets(
      'renders Not Started state initially without hardcoded draft/submission strings',
      (tester) async {
        const assignment = AssignmentEntity(
          id: 'asg-test-1',
          title: 'Design a Rube Goldberg Machine',
          topic: 'Practical Thinking',
          status: AssignmentStatus.pending,
          dueDate: 'Due: Friday, 11:59 PM',
        );

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AssignmentSubmissionScreen(
                assignmentId: 'asg-test-1',
                assignment: assignment,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top Header
        expect(find.text('Assignment'), findsOneWidget);
        expect(find.byKey(const Key('submission_back_button')), findsOneWidget);

        // Header Section with actual assignment details
        expect(find.text('Practical Thinking'), findsOneWidget);
        expect(find.text('Design a Rube Goldberg Machine'), findsOneWidget);
        expect(find.text('Due: Friday, 11:59 PM'), findsOneWidget);

        // State A: Not Started
        expect(find.text('Not Started'), findsOneWidget);
        expect(find.text('Tap to upload file'), findsOneWidget);
        expect(find.byKey(const Key('tap_to_upload_box')), findsOneWidget);

        // Static values must NOT be present
        expect(find.text('my_rube_goldberg_plan.pdf'), findsNothing);
        expect(find.text('2.4 MB'), findsNothing);
        expect(find.text('Draft Saved'), findsNothing);
        expect(find.byKey(const Key('submit_now_button')), findsNothing);
      },
    );

    testWidgets('renders real selected file when controller sets local file', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const assignment = AssignmentEntity(
        id: 'asg-test-2',
        title: 'Physics Experiment',
        topic: 'Science',
        status: AssignmentStatus.pending,
        dueDate: 'Due: Monday, 5:00 PM',
      );

      // Simulate real user selecting a file
      container
          .read(assignmentSubmissionControllerProvider.notifier)
          .init(
            assignmentId: 'asg-test-2',
            childStudentId: 'child_1',
            initialAssignment: assignment,
          );

      container
          .read(assignmentSubmissionControllerProvider.notifier)
          .setLocalFile(
            assignmentId: 'asg-test-2',
            path: '/storage/emulated/0/Download/assignment_final.pdf',
            name: 'assignment_final.pdf',
            size: 3355443, // ~3.2 MB
            type: 'application/pdf',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AssignmentSubmissionScreen(
              assignmentId: 'asg-test-2',
              assignment: assignment,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify REAL file info appears
      expect(find.text('assignment_final.pdf'), findsOneWidget);
      expect(find.text('3.2 MB'), findsOneWidget);
      expect(find.text('File Selected'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(find.text('Submit Now'), findsOneWidget);

      // Delete file removes it
      await tester.ensureVisible(
        find.byKey(const Key('delete_draft_file_button')),
      );
      await tester.tap(find.byKey(const Key('delete_draft_file_button')));
      await tester.pumpAndSettle();

      expect(find.text('assignment_final.pdf'), findsNothing);
      expect(find.text('Not Started'), findsOneWidget);
      expect(find.text('Tap to upload file'), findsOneWidget);
    });

    testWidgets(
      'renders Submitted state if assignment already has real backend submission',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final submittedAssignment = AssignmentEntity(
          id: 'asg-test-3',
          title: 'Module 1 Practicum',
          topic: 'Coding',
          status: AssignmentStatus.completed,
          dueDate: 'Due: Aug 22',
          submission: AssignmentSubmissionEntity(
            id: 'sub_123',
            submittedAt: DateTime(2026, 9, 28, 10, 30),
            status: SubmissionStatus.submitted,
            files: const [
              SubmissionFileEntity(
                fileName: 'router_implementation.pdf',
                fileSize: 1048576, // 1 MB
                fileType: 'application/pdf',
              ),
            ],
          ),
        );

        container
            .read(assignmentSubmissionControllerProvider.notifier)
            .init(
              assignmentId: 'asg-test-3',
              childStudentId: 'child_1',
              initialAssignment: submittedAssignment,
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: AssignmentSubmissionScreen(
                assignmentId: 'asg-test-3',
                assignment: submittedAssignment,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Submission Status'), findsOneWidget);
        expect(find.text('Submitted'), findsOneWidget);
        expect(find.text('Great job!'), findsOneWidget);
        expect(find.text('router_implementation.pdf'), findsOneWidget);
        expect(find.text('View'), findsOneWidget);
      },
    );
  });
}
