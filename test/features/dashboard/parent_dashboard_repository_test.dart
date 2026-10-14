import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';

class MockApiClient extends Fake implements ApiClient {
  Map<String, dynamic>? dashboardResponse;
  bool shouldThrowDashboard = false;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (shouldThrowDashboard) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network failure',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: dashboardResponse as T?,
    );
  }
}

class MockClassesRepository implements ClassesRepository {
  Map<String, List<ClassEntity>> classesByChild = {};
  bool shouldThrow = false;
  int getLiveClassesCalls = 0;
  String? lastQueriedChildId;

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async {
    getLiveClassesCalls++;
    lastQueriedChildId = childStudentId;
    if (shouldThrow) {
      throw Exception('Failed to fetch live classes');
    }
    return classesByChild[childStudentId] ?? [];
  }

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Parent Dashboard "TODAY\'S CLASS" Authoritative Resolution', () {
    late MockApiClient fakeApiClient;
    late MockClassesRepository fakeClassesRepo;
    late DashboardRepositoryImpl repository;

    final sarahId = '6a89117035e1245c12ebf5d6';
    final ramId = '6a884d8adf8b9098fbe99fa9';

    // Standard dashboard API payload (only has future class on Sept 30)
    final standardDashboardJson = {
      'success': true,
      'data': {
        'attendance': {'attendancePercentage': 100},
        'upcomingLiveClasses': [
          {
            'id': '6aa948f9ce253df8ba6cca53',
            'classTitle': 'Junior Foundation first class',
            'startDate': '2026-09-30T04:30:00.000Z',
            'duration': 240,
            'status': 'scheduled',
            'courseName': 'Junior Foundation',
            'instructor': 'Elizabeth Vance',
          },
        ],
        'enrolledBatches': [
          {
            'id': 'b1',
            'batchName': 'Batch 1 — Junior Foundation',
            'courseName': 'Junior Foundation',
          },
        ],
        'assignmentsCount': 0,
        'feeOverview': {'totalDue': 0},
      },
    };

    setUp(() {
      fakeApiClient = MockApiClient();
      fakeApiClient.dashboardResponse = standardDashboardJson;
      fakeClassesRepo = MockClassesRepository();
      repository = DashboardRepositoryImpl(
        apiClient: fakeApiClient,
        classesRepository: fakeClassesRepo,
        nowProvider: () => DateTime(2026, 9, 21, 13, 0),
      );
    });

    test('Test 1: When current date is Sep 21 and class is at 12:45 PM, selects Word Puzzle', () async {
      // 07:15 UTC = 12:45 PM IST (+05:30) on 2026-09-21
      final wordPuzzleClass = ClassEntity(
        id: '6ab0d936aabd606a21c0c72a',
        classCode: 'LVC-0008',
        title: 'Word Puzzle',
        subject: 'Junior Foundation',
        teacherName: 'Elizabeth Vance',
        scheduledStartTime: DateTime.parse('2026-09-21T07:15:00.000Z'),
        scheduledEndTime: DateTime.parse('2026-09-21T09:45:00.000Z'),
        duration: 150,
        status: 'live',
      );
      fakeClassesRepo.classesByChild[sarahId] = [wordPuzzleClass];

      final dashboard = await repository.getChildDashboard(
        childStudentId: sarahId,
      );

      expect(dashboard.featuredClass, isNotNull);
      expect(dashboard.featuredClass!.id, equals('6ab0d936aabd606a21c0c72a'));
      expect(dashboard.featuredClass!.title, equals('Word Puzzle'));
      expect(dashboard.featuredClass!.teacherName, equals('Elizabeth Vance'));
    });

    test('Test 2: Dashboard API does NOT contain Word Puzzle, but Live-classes API contains Word Puzzle -> Dashboard displays Word Puzzle', () async {
      // Confirm dashboard JSON does NOT have Word Puzzle
      final data = standardDashboardJson['data'] as Map<String, dynamic>;
      final list = data['upcomingLiveClasses'] as List;
      expect(list.any((c) => c['classTitle'] == 'Word Puzzle'), isFalse);

      final wordPuzzleClass = ClassEntity(
        id: '6ab0d936aabd606a21c0c72a',
        classCode: 'LVC-0008',
        title: 'Word Puzzle',
        subject: 'Junior Foundation',
        teacherName: 'Elizabeth Vance',
        scheduledStartTime: DateTime.parse('2026-09-21T07:15:00.000Z'),
        scheduledEndTime: DateTime.parse('2026-09-21T09:45:00.000Z'),
        duration: 150,
        status: 'live',
      );
      fakeClassesRepo.classesByChild[sarahId] = [wordPuzzleClass];

      final dashboard = await repository.getChildDashboard(
        childStudentId: sarahId,
      );

      expect(dashboard.featuredClass, isNotNull);
      expect(dashboard.featuredClass!.title, equals('Word Puzzle'));
    });

    test('Test 3: Only Sep 30 class exists, current date is Sep 21 -> featuredClass is null ("No live class today")', () async {
      final sep30Class = ClassEntity(
        id: '6aa948f9ce253df8ba6cca53',
        classCode: 'LVC-0004',
        title: 'Junior Foundation first class',
        scheduledStartTime: DateTime.parse('2026-09-30T04:30:00.000Z'),
        scheduledEndTime: DateTime.parse('2026-09-30T08:30:00.000Z'),
        duration: 240,
        status: 'upcoming',
      );
      fakeClassesRepo.classesByChild[sarahId] = [sep30Class];

      final dashboard = await repository.getChildDashboard(
        childStudentId: sarahId,
      );

      expect(
        dashboard.featuredClass,
        isNull,
        reason: 'Future class on Sep 30 must not be displayed under "TODAY\'S CLASS"',
      );
    });

    test('Test 4: Class is currently live -> selected as today\'s class', () {
      final now = DateTime(2026, 9, 21, 13, 0); // 1:00 PM local
      final liveClass = ClassEntity(
        id: 'live-1',
        title: 'Word Puzzle Live',
        scheduledStartTime: DateTime(2026, 9, 21, 12, 45),
        scheduledEndTime: DateTime(2026, 9, 21, 15, 15),
        status: 'live',
      );

      final selected = DashboardRepositoryImpl.selectTodayClass([
        liveClass,
      ], nowOverride: now);

      expect(selected, isNotNull);
      expect(selected!.id, equals('live-1'));
      expect(selected.isLive, isTrue);
    });

    test('Test 5: Multiple classes today -> Currently LIVE class has priority over UPCOMING class', () {
      final now = DateTime(2026, 9, 21, 13, 0);
      final upcomingClass = ClassEntity(
        id: 'upcoming-1',
        title: 'Afternoon Science',
        scheduledStartTime: DateTime(2026, 9, 21, 16, 0),
        scheduledEndTime: DateTime(2026, 9, 21, 17, 0),
        status: 'upcoming',
      );
      final liveClass = ClassEntity(
        id: 'live-1',
        title: 'Word Puzzle',
        scheduledStartTime: DateTime(2026, 9, 21, 12, 45),
        scheduledEndTime: DateTime(2026, 9, 21, 15, 15),
        status: 'live',
      );

      // Even if upcoming is passed first in the list
      final selected = DashboardRepositoryImpl.selectTodayClass([
        upcomingClass,
        liveClass,
      ], nowOverride: now);

      expect(selected, isNotNull);
      expect(
        selected!.id,
        equals('live-1'),
        reason: 'LIVE class must have priority over UPCOMING class today',
      );
    });

    test('Test 6: Child context switch -> queries that child\'s live classes, no previous child data leaked', () async {
      final sarahWordPuzzle = ClassEntity(
        id: 'sarah-wp',
        title: 'Word Puzzle',
        scheduledStartTime: DateTime.parse('2026-09-21T07:15:00.000Z'),
        status: 'live',
      );
      fakeClassesRepo.classesByChild[sarahId] = [sarahWordPuzzle];
      fakeClassesRepo.classesByChild[ramId] = []; // Ram has no classes today

      // 1. Fetch Sarah
      final sarahDashboard = await repository.getChildDashboard(
        childStudentId: sarahId,
      );
      expect(fakeClassesRepo.lastQueriedChildId, equals(sarahId));
      expect(sarahDashboard.featuredClass?.title, equals('Word Puzzle'));

      // 2. Fetch Ram
      final ramDashboard = await repository.getChildDashboard(
        childStudentId: ramId,
      );
      expect(fakeClassesRepo.lastQueriedChildId, equals(ramId));
      expect(
        ramDashboard.featuredClass,
        isNull,
        reason: 'Ram has no classes today; must not leak Sarah\'s class',
      );
    });

    test('Test 7: Refresh while a class is live -> recalculates and preserves today\'s class cleanly', () async {
      final wordPuzzleClass = ClassEntity(
        id: 'wp-1',
        title: 'Word Puzzle',
        scheduledStartTime: DateTime.parse('2026-09-21T07:15:00.000Z'),
        status: 'live',
      );
      fakeClassesRepo.classesByChild[sarahId] = [wordPuzzleClass];

      // Initial load
      final d1 = await repository.getChildDashboard(childStudentId: sarahId);
      expect(d1.featuredClass?.title, equals('Word Puzzle'));

      // Re-fetch / Refresh
      final d2 = await repository.getChildDashboard(childStudentId: sarahId);
      expect(d2.featuredClass?.title, equals('Word Puzzle'));
      expect(fakeClassesRepo.getLiveClassesCalls, equals(2));
    });

    test('Test 8: No classes today -> featuredClass is null (Empty state preserved)', () async {
      fakeClassesRepo.classesByChild[sarahId] = [];

      final dashboard = await repository.getChildDashboard(
        childStudentId: sarahId,
      );
      expect(dashboard.featuredClass, isNull);
    });

    test('Test 9: Live-classes API failure -> featuredClass is null, does not use dashboard upcomingLiveClasses as fallback', () async {
      fakeClassesRepo.shouldThrow = true;

      final dashboard = await repository.getChildDashboard(
        childStudentId: sarahId,
      );

      expect(dashboard.attendanceRate, equals(100.0));
      expect(
        dashboard.featuredClass,
        isNull,
        reason: 'When live classes fails, do not treat dashboard upcomingLiveClasses as authoritative',
      );
    });
  });
}
