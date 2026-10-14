import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/my_learning_section.dart';

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
  group('Dashboard Topic/Learning Progress Dynamic Verification Tests', () {
    test('DashboardRepositoryImpl queries /parent/children/:studentId/program and attaches course progress', () async {
      final mockClient = MockDioClient({
        '/parent/children/student-sarah/dashboard': {
          'success': true,
          'data': {
            'attendanceRate': 90.0,
            'upcomingClassesCount': 1,
            'enrolledBatches': [
              {
                'id': 'batch-01',
                'batchName': 'Batch 1 — Junior Foundation, Ages 6 to 10',
                'courseName': 'Junior Foundation',
                'instructor': 'Elizabeth Vance',
              },
            ],
          },
        },
        '/parent/children/student-sarah/live-classes': {
          'success': true,
          'data': [],
        },
        '/parent/children/student-sarah/progress': {
          'success': true,
          'data': {'overallCompletion': 0},
        },
        '/parent/children/student-sarah/program': {
          'success': true,
          'data': {
            'courseId': '6a8d4d374349078373f1fd4f',
            'courseName': 'Junior Foundation',
            'batchId': 'batch-01',
            'batchName': 'Batch 1 — Junior Foundation, Ages 6 to 10',
            'progress': 41,
          },
        },
      });

      final repo = DashboardRepositoryImpl(apiClient: mockClient);
      final dashboard = await repo.getChildDashboard(
        childStudentId: 'student-sarah',
      );

      expect(dashboard.enrolledBatches.length, 1);
      final batch = dashboard.enrolledBatches.first;
      expect(batch.batchName, 'Batch 1 — Junior Foundation, Ages 6 to 10');
      expect(batch.progressPercentage, 41.0);
      expect(dashboard.overallProgress, 41.0);
    });

    test('DashboardRepositoryImpl student switching updates progress accurately between children', () async {
      final mockClient = MockDioClient({
        '/parent/children/sarah/dashboard': {
          'success': true,
          'data': {
            'enrolledBatches': [
              {'id': 'b1', 'batchName': 'Sarah Batch'},
            ],
          },
        },
        '/parent/children/sarah/live-classes': {'success': true, 'data': []},
        '/parent/children/sarah/progress': {
          'success': true,
          'data': {'overallCompletion': 0},
        },
        '/parent/children/sarah/program': {
          'success': true,
          'data': {'batchId': 'b1', 'batchName': 'Sarah Batch', 'progress': 41},
        },
        '/parent/children/ram/dashboard': {
          'success': true,
          'data': {
            'enrolledBatches': [
              {'id': 'b2', 'batchName': 'Ram Batch'},
            ],
          },
        },
        '/parent/children/ram/live-classes': {'success': true, 'data': []},
        '/parent/children/ram/progress': {
          'success': true,
          'data': {'overallCompletion': 0},
        },
        '/parent/children/ram/program': {
          'success': true,
          'data': {'batchId': 'b2', 'batchName': 'Ram Batch', 'progress': 10},
        },
      });

      final repo = DashboardRepositoryImpl(apiClient: mockClient);

      final sarahDash = await repo.getChildDashboard(childStudentId: 'sarah');
      expect(sarahDash.enrolledBatches.first.progressPercentage, 41.0);

      final ramDash = await repo.getChildDashboard(childStudentId: 'ram');
      expect(ramDash.enrolledBatches.first.progressPercentage, 10.0);
    });

    testWidgets(
      'MyLearningSection renders real dynamic progress percentages and matching progress bar',
      (tester) async {
        const batches = [
          EnrolledBatchEntity(
            id: 'b1',
            batchName: 'Batch 1 — Junior Foundation',
            courseName: 'Junior Foundation',
            instructor: 'Elizabeth Vance',
            progressPercentage: 82.0,
          ),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MyLearningSection(enrolledBatches: batches),
              ),
            ),
          ),
        );

        // Verify "82%" is displayed dynamically
        expect(find.text('82%'), findsOneWidget);
        expect(find.text('65%'), findsNothing);

        // Verify LinearProgressIndicator has matching value 0.82
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, 0.82);
      },
    );

    testWidgets('MyLearningSection handles 0% progress correctly', (
      tester,
    ) async {
      const batches = [
        EnrolledBatchEntity(
          id: 'b1',
          batchName: 'Batch 1 — Junior Foundation',
          courseName: 'Junior Foundation',
          progressPercentage: 0.0,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MyLearningSection(enrolledBatches: batches),
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('65%'), findsNothing);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.0);
    });

    testWidgets(
      'MyLearningSection handles null progress gracefully without showing fake 65%',
      (tester) async {
        const batches = [
          EnrolledBatchEntity(
            id: 'b1',
            batchName: 'Batch 1 — Junior Foundation',
            courseName: 'Junior Foundation',
            progressPercentage: null,
          ),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MyLearningSection(enrolledBatches: batches),
              ),
            ),
          ),
        );

        // Should display empty state placeholder '--' and NOT 65%
        expect(find.text('--'), findsOneWidget);
        expect(find.text('65%'), findsNothing);

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, 0.0);
      },
    );
  });
}
