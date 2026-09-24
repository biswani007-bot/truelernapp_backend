import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:truelearn/features/classes/data/repositories/class_summary_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';

class MockClassesRepository implements ClassesRepository {
  List<ClassEntity> classes = [];

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async {
    return classes;
  }

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    throw UnimplementedError();
  }
}

class MockAssignmentsRepository implements AssignmentsRepository {
  List<AssignmentEntity> assignments = [];

  @override
  Future<List<AssignmentEntity>> getAssignments({required String childStudentId}) async {
    return assignments;
  }
}

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  Map<String, dynamic> responses = {};

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final data = responses[path] as T?;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );
  }
}

void main() {
  group('ClassSummaryRepositoryImpl', () {
    late ClassSummaryRepositoryImpl repository;
    late FakeApiClient fakeApiClient;
    late MockClassesRepository mockClassesRepo;
    late MockAssignmentsRepository mockAssignmentsRepo;

    setUp(() {
      fakeApiClient = FakeApiClient();
      mockClassesRepo = MockClassesRepository();
      mockAssignmentsRepo = MockAssignmentsRepository();
      repository = ClassSummaryRepositoryImpl(
        apiClient: fakeApiClient,
        classesRepository: mockClassesRepo,
        assignmentsRepository: mockAssignmentsRepo,
      );
    });

    test('composes session details, next scheduled class, and upcoming assignment from real API endpoints', () async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      fakeApiClient.responses['/api/parent/children/child-123/live-classes'] = {
        'success': true,
        'data': [
          {
            'id': 'class-01',
            'classTitle': 'Junior Foundation first class',
            'duration': 90,
            'instructor': 'Elizabeth Vance',
            'startDate': now.toIso8601String(),
            'status': 'scheduled',
            'effectiveStatus': 'attended',
            'attendance': {
              'status': 'present',
              'durationAttended': 85,
            },
          },
          {
            'id': 'class-02',
            'classTitle': 'Advanced Public Speaking',
            'duration': 60,
            'startDate': tomorrow.toIso8601String(),
            'scheduledStartTime': tomorrow.toIso8601String(),
            'status': 'scheduled',
          },
        ],
      };

      fakeApiClient.responses['/api/parent/children/child-123/attendance'] = {
        'success': true,
        'data': {
          'records': [
            {
              'id': 'att-01',
              'classTitle': 'Junior Foundation first class',
              'status': 'present',
              'durationAttended': 85,
            },
          ],
        },
      };

      fakeApiClient.responses['/api/parent/children/child-123/assignments'] = {
        'success': true,
        'data': [
          {
            'id': 'asg-01',
            'title': 'Speech Draft',
            'dueDate': tomorrow.toIso8601String(),
            'status': 'published',
          },
        ],
      };

      final summary = await repository.getClassSummary(
        childStudentId: 'child-123',
        classId: 'class-01',
      );

      expect(summary.classId, 'class-01');
      expect(summary.classTitle, 'Junior Foundation first class');
      expect(summary.teacherName, 'Elizabeth Vance');
      expect(summary.scheduledDurationMinutes, 90);
      expect(summary.attendedDurationMinutes, 85);
      expect(summary.attendanceStatus, 'present');
      expect(summary.isAttended, true);
      expect(summary.nextClassTitle, 'Advanced Public Speaking');
      expect(summary.nextClassTimeFormatted, contains('Tomorrow'));
      expect(summary.assignmentTitle, 'Speech Draft');
      expect(summary.assignmentDueDate, contains('Due'));
    });

    test('gracefully resolves defensive values when remote endpoints return empty', () async {
      fakeApiClient.responses['/api/parent/children/child-123/live-classes'] = {
        'success': true,
        'data': [],
      };
      fakeApiClient.responses['/api/parent/children/child-123/attendance'] = {
        'success': true,
        'data': {'records': []},
      };
      fakeApiClient.responses['/api/parent/children/child-123/assignments'] = {
        'success': true,
        'data': [],
      };

      final summary = await repository.getClassSummary(
        childStudentId: 'child-123',
        classId: 'class-fallback',
      );

      expect(summary.classId, 'class-fallback');
      expect(summary.classTitle, 'Live Class');
      expect(summary.teacherName, isNull);
      expect(summary.scheduledDurationMinutes, isNull);
      expect(summary.skillsPracticed, isEmpty);
      expect(summary.nextClassTitle, isNull);
      expect(summary.assignmentId, isNull);
    });
  });
}
