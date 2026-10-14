import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/data/repositories/student_dashboard_repository_impl.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  dynamic liveClassesResponse;
  dynamic assignmentsResponse;
  dynamic attendanceResponse;

  Object? liveClassesError;
  Object? assignmentsError;
  Object? attendanceError;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path.contains('/live-classes')) {
      if (liveClassesError != null) throw liveClassesError!;
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: liveClassesResponse as T?,
        statusCode: 200,
      );
    }
    if (path.contains('/assignments')) {
      if (assignmentsError != null) throw assignmentsError!;
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: assignmentsResponse as T?,
        statusCode: 200,
      );
    }
    if (path.contains('/attendance/summary')) {
      if (attendanceError != null) throw attendanceError!;
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: attendanceResponse as T?,
        statusCode: 200,
      );
    }
    throw UnimplementedError('Unhandled GET path: $path');
  }
}

void main() {
  group('StudentDashboardRepositoryImpl Tests', () {
    late FakeApiClient fakeClient;
    late StudentDashboardRepositoryImpl repository;

    setUp(() {
      fakeClient = FakeApiClient();
      repository = StudentDashboardRepositoryImpl(apiClient: fakeClient);
    });

    test('getStudentDashboard maps live classes, assignments, and attendance correctly', () async {
      fakeClient.liveClassesResponse = [
        {
          'id': 'cls_1',
          'classTitle': 'Junior Foundation first class',
          'status': 'scheduled',
          'teacher': {'firstName': 'Elizabeth', 'lastName': 'Vance'},
          'batch': {'name': 'Batch 1 — Junior Foundation, Ages 6 to 10'},
          'course': {'title': 'Junior Foundation'},
          'startDate': '2026-09-30T04:30:00.000Z',
          'endDate': '2026-09-30T08:30:00.000Z',
        },
      ];

      fakeClient.assignmentsResponse = [
        {'id': 'a1', 'title': 'Assignment 1', 'status': 'published'},
        {'id': 'a2', 'title': 'Assignment 2', 'status': 'published'},
      ];

      fakeClient.attendanceResponse = {
        'attendancePercentage': 75.5,
        'student': {'firstName': 'Alex', 'lastName': 'Mercer'},
      };

      final dashboard = await repository.getStudentDashboard();

      expect(dashboard.studentName, 'Alex Mercer');
      expect(dashboard.attendanceRate, 75.5);
      expect(dashboard.pendingAssignmentsCount, 2);
      expect(dashboard.featuredClass?.title, 'Junior Foundation first class');
      expect(dashboard.featuredClass?.teacherName, 'Elizabeth Vance');
      expect(dashboard.upcomingClassesCount, 1);
      expect(
        dashboard.enrolledBatches.map((b) => b.batchName),
        contains('Batch 1 — Junior Foundation, Ages 6 to 10'),
      );
    });

    test('handles empty responses and null values without crashing', () async {
      fakeClient.liveClassesResponse = [];
      fakeClient.assignmentsResponse = [];
      fakeClient.attendanceResponse = null;

      final dashboard = await repository.getStudentDashboard();

      expect(dashboard.studentName, null);
      expect(dashboard.attendanceRate, null);
      expect(dashboard.pendingAssignmentsCount, 0);
      expect(dashboard.featuredClass, null);
      expect(dashboard.upcomingClassesCount, 0);
      expect(dashboard.enrolledBatches, isEmpty);
    });

    test(
      'resilient when attendance or assignments API fails partially',
      () async {
        fakeClient.liveClassesResponse = [
          {
            'id': 'cls_1',
            'classTitle': 'Intro Class',
            'teacher': 'Sarah Teacher',
          },
        ];
        fakeClient.assignmentsError = const ServerFailure(
          'Assignments timeout',
        );
        fakeClient.attendanceError = const ServerFailure(
          'Attendance 500 error',
        );

        final dashboard = await repository.getStudentDashboard();

        expect(dashboard.featuredClass?.title, 'Intro Class');
        expect(dashboard.featuredClass?.teacherName, 'Sarah Teacher');
        expect(dashboard.attendanceRate, null);
        expect(dashboard.pendingAssignmentsCount, null);
      },
    );

    test(
      'throws ServerFailure when all requests fail with failure exception',
      () async {
        fakeClient.liveClassesError = const ServerFailure('Network down');
        fakeClient.assignmentsError = const ServerFailure('Network down');
        fakeClient.attendanceError = const ServerFailure('Network down');

        expect(
          () => repository.getStudentDashboard(),
          throwsA(isA<ServerFailure>()),
        );
      },
    );
  });
}
