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

    group('Attachment URL Resolution Unit Tests', () {
      const baseApi = 'https://truelern.visital.in/api';

      test('Resolves relative /uploads/ path against server origin, not /api/', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          '/uploads/sample.pdf',
          baseApi,
        );
        expect(resolved, 'https://truelern.visital.in/uploads/sample.pdf');
      });

      test('Resolves relative uploads/ without leading slash against server origin', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          'uploads/sample.pdf',
          baseApi,
        );
        expect(resolved, 'https://truelern.visital.in/uploads/sample.pdf');
      });

      test('Avoids duplicating /api/ prefix for /api/ paths', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          '/api/assignments/test.pdf',
          baseApi,
        );
        expect(resolved, 'https://truelern.visital.in/api/assignments/test.pdf');
      });

      test('Avoids duplicating api/ prefix without leading slash', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          'api/assignments/test.pdf',
          baseApi,
        );
        expect(resolved, 'https://truelern.visital.in/api/assignments/test.pdf');
      });

      test('Preserves valid remote storage URLs from trusted TrueLern domains', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          'https://storage.truelern.com/uploads/homework_submission_1.pdf',
          baseApi,
        );
        expect(
          resolved,
          'https://storage.truelern.com/uploads/homework_submission_1.pdf',
        );
      });

      test('Rejects untrusted third-party hosts for security', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          'https://untrusted-third-party.com/file.pdf',
          baseApi,
        );
        expect(resolved, isNull);
      });

      test('Encodes spaces in URL paths safely', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          '/uploads/sample doc with spaces.pdf',
          baseApi,
        );
        expect(
          resolved,
          'https://truelern.visital.in/uploads/sample%20doc%20with%20spaces.pdf',
        );
      });

      test('Preserves query parameters and existing percent-encoding', () {
        final resolved = AttachmentViewerScreen.resolveAttachmentUrl(
          '/uploads/already%20encoded.pdf?token=123&name=test%20file',
          baseApi,
        );
        expect(
          resolved,
          'https://truelern.visital.in/uploads/already%20encoded.pdf?token=123&name=test%20file',
        );
      });
    });

    group('AssignmentAttachmentEntity Fallback Tests', () {
      test('Parses fileUrl from path, filePath, or attachmentUrl', () {
        final fromPath = AssignmentAttachmentEntity.fromJson({
          'id': '1',
          'fileName': 'file1.pdf',
          'path': '/uploads/file1.pdf',
        });
        expect(fromPath.fileUrl, '/uploads/file1.pdf');

        final fromFilePath = AssignmentAttachmentEntity.fromJson({
          'id': '2',
          'fileName': 'file2.pdf',
          'filePath': '/uploads/file2.pdf',
        });
        expect(fromFilePath.fileUrl, '/uploads/file2.pdf');

        final fromAttachmentUrl = AssignmentAttachmentEntity.fromJson({
          'id': '3',
          'fileName': 'file3.pdf',
          'attachmentUrl': '/uploads/file3.pdf',
        });
        expect(fromAttachmentUrl.fileUrl, '/uploads/file3.pdf');
      });
    });
  });
}
