import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/assignments/data/models/assignment_dto.dart';
import 'package:truelearn/features/assignments/data/repositories/assignments_repository_impl.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/presentation/widgets/assignment_card.dart';

class MockDioClient extends ApiClient {
  MockDioClient(this.responses) : super(dio: Dio());

  final Map<String, dynamic> responses;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (responses.containsKey(path)) {
      final data = responses[path];
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: data as T,
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 404,
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

void main() {
  group('Assignment Grade Dynamic Parsing & Display Tests', () {
    test(
      'AssignmentDto parses marksAwarded and grade from submission correctly',
      () {
        final json = {
          'id': '6ac3836a9cbbb9dada126651',
          'title': 'test3',
          'type': 'homework',
          'totalMarks': 100,
          'status': 'published',
          'submission': {
            'id': '6ac3cacc9cbbb9dada126b87',
            'submissionNumber': 'SUB-00010',
            'status': 'accepted',
            'marksAwarded': 100,
            'grade': 'A',
            'isGraded': true,
          },
        };

        final dto = AssignmentDto.fromJson(json);
        expect(dto.score, 100);
        expect(dto.totalMarks, 100);
        expect(dto.grade, 'A');

        final entity = dto.toEntity(childStudentId: 'student_sarah');
        expect(entity.score, 100);
        expect(entity.totalMarks, 100);
        expect(entity.grade, 'A');
        expect(entity.status, AssignmentStatus.completed);
      },
    );

    test('AssignmentsRepositoryImpl fetches and maps real test3 assignment response', () async {
      final mockClient = MockDioClient({
        '/parent/children/sarah/assignments': {
          'success': true,
          'message': 'Child assignments retrieved successfully',
          'data': [
            {
              'id': '6ac3836a9cbbb9dada126651',
              'title': 'test3',
              'type': 'homework',
              'totalMarks': 100,
              'status': 'published',
              'submission': {
                'id': '6ac3cacc9cbbb9dada126b87',
                'submissionNumber': 'SUB-00010',
                'status': 'accepted',
                'marksAwarded': 100,
                'grade': 'A',
                'isGraded': true,
              },
            },
          ],
        },
      });

      final repo = AssignmentsRepositoryImpl(apiClient: mockClient);
      final items = await repo.getAssignments(childStudentId: 'sarah');

      expect(items.length, 1);
      final test3 = items.first;
      expect(test3.title, 'test3');
      expect(test3.score, 100);
      expect(test3.totalMarks, 100);
      expect(test3.grade, 'A');
      expect(test3.status, AssignmentStatus.completed);
    });

    testWidgets(
      'AssignmentCard renders real dynamic grade 100/100 and no hardcoded 95',
      (tester) async {
        const assignment = AssignmentEntity(
          id: '6ac3836a9cbbb9dada126651',
          title: 'test3',
          topic: 'homework',
          status: AssignmentStatus.completed,
          score: 100,
          totalMarks: 100,
          grade: 'A',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssignmentCard(assignment: assignment),
              ),
            ),
          ),
        );

        // Verify "100/100" is displayed dynamically
        expect(find.text('100/100'), findsOneWidget);
        expect(find.text('95/100'), findsNothing);
      },
    );

    testWidgets(
      'AssignmentCard handles null score gracefully without falling back to 95',
      (tester) async {
        const assignment = AssignmentEntity(
          id: 'asg_null_score',
          title: 'Pending Eval Assignment',
          topic: 'Academics',
          status: AssignmentStatus.completed,
          score: null,
          totalMarks: 100,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssignmentCard(assignment: assignment),
              ),
            ),
          ),
        );

        // Must NOT display 95/100
        expect(find.text('95/100'), findsNothing);
        expect(find.text('--'), findsOneWidget);
      },
    );
  });
}
