import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_attachment_entity.dart';
import 'package:truelearn/features/assignments/presentation/screens/attachment_viewer_screen.dart';

void main() {
  group('AttachmentViewerScreen Tests', () {
    testWidgets('Displays loading indicator while retrieving attachment', (
      tester,
    ) async {
      const att = AssignmentAttachmentEntity(
        id: 'att_01',
        fileName: 'Sample_Worksheet.pdf',
        fileUrl: '/uploads/sample.pdf',
        fileSize: 102400,
        fileType: 'application/pdf',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AttachmentViewerScreen(
              attachment: att,
              assignmentTitle: 'Mathematics Homework',
            ),
          ),
        ),
      );

      // Verify file title and loading indicator are displayed
      expect(find.text('Sample_Worksheet.pdf'), findsWidgets);
      expect(find.text('Retrieving Attachment...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'Displays error state with diagnostics and go back action on invalid host',
      (tester) async {
        const att = AssignmentAttachmentEntity(
          id: 'att_untrusted',
          fileName: 'Malicious_Document.pdf',
          fileUrl: 'https://untrusted-third-party.com/file.pdf',
          fileSize: 50000,
          fileType: 'application/pdf',
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AttachmentViewerScreen(
                attachment: att,
                assignmentTitle: 'Science Practicum',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should flag untrusted URL
        expect(find.text('Attachment Unavailable'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );
  });
}
