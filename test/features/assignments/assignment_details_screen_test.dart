import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/data/models/assignment_dto.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/presentation/screens/assignment_submission_screen.dart';
import 'package:truelearn/features/assignments/presentation/screens/attachment_viewer_screen.dart';

void main() {
  group('Assignment Details Parsing & UI Tests', () {
    test(
      'AssignmentDto parses real backend API fields and attachments accurately',
      () {
        final json = {
          'id': '6aca2a82b2191b5d3a4d4406',
          'title': 'yest',
          'description': '<p>Complete the aptitude test worksheet and submit your answers.</p>',
          'type': 'homework',
          'difficultyLevel': 'medium',
          'totalMarks': 100,
          'passingMarks': 40,
          'dueDate': '2026-10-14T00:00:00.000Z',
          'status': 'published',
          'maxAttempts': 2,
          'totalAttemptsUsed': 0,
          'canSubmit': true,
          'lateSubmissionAllowed': true,
          'attachments': [
            {
              'id': 'att_01',
              'fileName': 'SAP_Certification_Guide.pdf',
              'fileUrl': '/uploads/guide.pdf',
              'fileSize': 114805,
              'fileType': 'application/pdf',
            },
          ],
          'submission': null,
        };

        final dto = AssignmentDto.fromJson(json);
        final entity = dto.toEntity(childStudentId: 'child_123');

        expect(entity.id, '6aca2a82b2191b5d3a4d4406');
        expect(entity.title, 'yest');
        expect(entity.topic, 'homework');
        expect(
          entity.cleanDescription,
          'Complete the aptitude test worksheet and submit your answers.',
        );
        expect(entity.totalMarks, 100);
        expect(entity.passingMarks, 40);
        expect(entity.difficultyLevel, 'medium');
        expect(entity.maxAttempts, 2);
        expect(entity.isLateSubmissionAllowed, true);
        expect(entity.attachments.length, 1);
        expect(
          entity.attachments.first.fileName,
          'SAP_Certification_Guide.pdf',
        );
        expect(entity.attachments.first.displayFileSize, '112.1 KB');
      },
    );

    testWidgets(
      'renders Assignment Details, Instructions, Teacher Attachments, and Guidelines',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const testAssignment = AssignmentEntity(
          id: 'asg-details-01',
          title: 'Aptitude & Logic Practicum',
          topic: 'Critical Thinking',
          status: AssignmentStatus.pending,
          dueDate: 'Due: Oct 14',
          totalMarks: 100,
          passingMarks: 40,
          difficultyLevel: 'medium',
          maxAttempts: 1,
          isLateSubmissionAllowed: true,
          description: '<p>Solve all 5 questions on the provided worksheet. Show your work clearly.</p>',
          attachments: [
            AssignmentAttachmentEntity(
              id: 'att-1',
              fileName: 'Logic_Worksheet_Aptitude.pdf',
              fileUrl: '/uploads/logic_worksheet.pdf',
              fileSize: 114805, // ~112.1 KB
              fileType: 'application/pdf',
            ),
          ],
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AssignmentSubmissionScreen(
                assignmentId: 'asg-details-01',
                assignment: testAssignment,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top Header
        expect(find.text('Assignment'), findsOneWidget);
        expect(find.byKey(const Key('submission_back_button')), findsOneWidget);

        // Title and category
        expect(find.text('Critical Thinking'), findsOneWidget);
        expect(find.text('Aptitude & Logic Practicum'), findsOneWidget);
        expect(find.text('Due: Oct 14'), findsOneWidget);

        // Key metrics pills
        expect(find.text('Max: 100 pts'), findsOneWidget);
        expect(find.text('Pass: 40 pts'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);

        // Description & Instructions Section
        expect(find.text('Description & Instructions'), findsOneWidget);
        expect(
          find.text(
            'Solve all 5 questions on the provided worksheet. Show your work clearly.',
          ),
          findsOneWidget,
        );

        // Teacher Attachments Section
        expect(find.text('Teacher Attachments'), findsOneWidget);
        expect(find.text('Logic_Worksheet_Aptitude.pdf'), findsOneWidget);
        expect(find.text('112.1 KB'), findsOneWidget);
        expect(find.text('View'), findsOneWidget);

        // Submission Guidelines Section
        expect(find.text('Submission Guidelines'), findsOneWidget);
        expect(find.text('Allowed Formats'), findsOneWidget);
        expect(find.text('PDF, DOCX, JPG'), findsOneWidget);
        expect(find.text('Max File Size'), findsOneWidget);
        expect(find.text('10 MB'), findsOneWidget);

        // Upload Submission Section
        expect(find.text('Upload Submission'), findsOneWidget);
        expect(find.text('Not Started'), findsOneWidget);
        expect(find.byKey(const Key('tap_to_upload_box')), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping View on Teacher Attachment opens AttachmentViewerScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const testAssignment = AssignmentEntity(
          id: 'asg-view-01',
          title: 'Worksheet Practicum',
          topic: 'Mathematics',
          status: AssignmentStatus.pending,
          dueDate: 'Due: Tomorrow',
          attachments: [
            AssignmentAttachmentEntity(
              id: 'att-view-01',
              fileName: 'Math_Worksheet.pdf',
              fileUrl: '/uploads/math_worksheet.pdf',
              fileSize: 102400,
              fileType: 'application/pdf',
            ),
          ],
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AssignmentSubmissionScreen(
                assignmentId: 'asg-view-01',
                assignment: testAssignment,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final viewButton = find.byKey(const Key('view_attachment_att-view-01'));
        expect(viewButton, findsOneWidget);
        await tester.tap(viewButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Verify AttachmentViewerScreen is displayed
        expect(find.byType(AttachmentViewerScreen), findsOneWidget);
      },
    );
  });
}
