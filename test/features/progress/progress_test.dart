import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_learning_progress_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/my_learning_section.dart';
import 'package:truelearn/features/progress/data/models/progress_dto.dart';
import 'package:truelearn/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:truelearn/features/progress/domain/entities/progress_entity.dart';
import 'package:truelearn/features/progress/domain/repositories/progress_repository.dart';
import 'package:truelearn/features/progress/presentation/controllers/progress_controller.dart';
import 'package:truelearn/features/progress/presentation/controllers/progress_state.dart';

class FakeApiClient extends Fake implements ApiClient {
  FakeApiClient({this.responses = const {}, this.shouldThrow = false});

  final Map<String, dynamic> responses;
  final bool shouldThrow;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network failure',
      );
    }
    if (responses.containsKey(path)) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: responses[path] as T?,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 404,
      ),
    );
  }
}

class MockProgressRepository implements ProgressRepository {
  ProgressEntity? mockChildProgress;
  Exception? shouldThrow;
  int getChildProgressCallCount = 0;
  String? lastChildId;

  @override
  Future<ProgressEntity> getChildProgress({
    required String childStudentId,
    String? studentName,
    String? activeTrack,
  }) async {
    getChildProgressCallCount++;
    lastChildId = childStudentId;
    if (shouldThrow != null) {
      throw shouldThrow!;
    }
    return mockChildProgress ??
        ProgressEntity(
          childStudentId: childStudentId,
          overallCompletion: 42.0,
          studentName: studentName ?? 'Student',
          activeTrack: activeTrack,
          assignmentCompletion: const ProgressMetricEntity(
            total: 4,
            completed: 2,
            percentage: 50.0,
          ),
          attendanceSummary: const ProgressMetricEntity(
            total: 10,
            completed: 8,
            percentage: 80.0,
          ),
          assessmentCompletion: const ProgressMetricEntity(
            total: 2,
            completed: 1,
            percentage: 50.0,
          ),
        );
  }

  @override
  Future<double> getStudentCourseProgress({required String courseId}) async {
    return 100.0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('1. Progress API parsing', () {
    test('parses real backend response correctly', () {
      final json = {
        "success": true,
        "message": "Data retrieved successfully",
        "data": {
          "overallCompletion": 41,
          "assessmentCompletion": {
            "total": 5,
            "completed": 3,
            "percentage": 60,
          },
          "assignmentCompletion": {
            "total": 4,
            "completed": 2,
            "percentage": 50,
          },
          "attendanceSummary": {
            "totalClasses": 12,
            "attended": 11,
            "percentage": 91.6,
          },
        },
      };

      final dto = ProgressDto.fromJson(json);
      expect(dto.overallCompletion, 41.0);
      expect(dto.assessmentCompletion.total, 5);
      expect(dto.assessmentCompletion.completed, 3);
      expect(dto.assessmentCompletion.percentage, 60.0);
      expect(dto.assignmentCompletion.total, 4);
      expect(dto.assignmentCompletion.completed, 2);
      expect(dto.assignmentCompletion.percentage, 50.0);
      expect(dto.attendanceSummary.total, 12);
      expect(dto.attendanceSummary.completed, 11);
      expect(dto.attendanceSummary.percentage, 91.6);
    });

    test('handles fallback and empty data gracefully', () {
      final json = {"data": {}};
      final dto = ProgressDto.fromJson(json);
      expect(dto.overallCompletion, 0.0);
      expect(dto.assessmentCompletion.total, 0);
      expect(dto.assignmentCompletion.total, 0);
      expect(dto.attendanceSummary.total, 0);
    });
  });

  group('2. Progress repository', () {
    test('converts DTO to domain entity correctly', () {
      const dto = ProgressDto(
        overallCompletion: 75.0,
        assignmentCompletion: ProgressMetricDto(
          total: 10,
          completed: 8,
          percentage: 80.0,
        ),
        attendanceSummary: ProgressMetricDto(
          total: 20,
          completed: 18,
          percentage: 90.0,
        ),
        assessmentCompletion: ProgressMetricDto(
          total: 4,
          completed: 3,
          percentage: 75.0,
        ),
      );

      final entity = dto.toEntity(
        childStudentId: 'child_123',
        studentName: 'Sarah',
        activeTrack: 'Junior Foundation',
      );

      expect(entity.childStudentId, 'child_123');
      expect(entity.studentName, 'Sarah');
      expect(entity.activeTrack, 'Junior Foundation');
      expect(entity.overallCompletion, 75.0);
      expect(entity.assignmentCompletion.percentage, 80.0);
      expect(entity.attendanceSummary.attended, 18);
      expect(entity.assessmentCompletion.total, 4);
    });

    test(
      'reconciles inconsistent /progress with authoritative child endpoints',
      () async {
        final fakeApi = FakeApiClient(
          responses: {
            '/parent/children/c1/progress': {
              'data': {
                'overallCompletion': 0,
                'assessmentCompletion': {
                  'total': 3,
                  'completed': 0,
                  'percentage': 0,
                },
                'assignmentCompletion': {
                  'total': 1,
                  'completed': 0,
                  'percentage': 0,
                },
                'attendanceSummary': {
                  'totalClasses': 0,
                  'attended': 0,
                  'percentage': 0,
                },
              },
            },
            '/parent/children/c1/program': {
              'data': {
                'courseName': 'Future-Ready Builders',
                'progress': 4,
                'totalAssignments': 1,
                'completedAssignments': 0,
                'totalAssessments': 3,
                'completedAssessments': 3,
              },
            },
            '/parent/children/c1/attendance': {
              'data': {
                'summary': {
                  'totalSessions': 1,
                  'presentCount': 1,
                  'attendancePercentage': 100,
                },
              },
            },
            '/parent/children/c1/assessments': {
              'data': [
                {
                  'id': 'a1',
                  'status': 'pass',
                  'evaluatedAt': '2026-10-12T10:00:00.000Z',
                },
                {
                  'id': 'a2',
                  'status': 'fail',
                  'evaluatedAt': '2026-10-12T10:00:00.000Z',
                },
                {
                  'id': 'a3',
                  'status': 'fail',
                  'evaluatedAt': '2026-10-12T10:00:00.000Z',
                },
              ],
            },
            '/parent/children/c1/assignments': {
              'data': [
                {'id': 'as1', 'submission': null, 'status': 'published'},
              ],
            },
          },
        );

        final repo = ProgressRepositoryImpl(apiClient: fakeApi);
        final entity = await repo.getChildProgress(childStudentId: 'c1');

        // Overall Mastery correctly shows 4% from program
        expect(entity.overallCompletion, 4.0);
        // Track name correctly resolved from courseName
        expect(entity.activeTrack, 'Future-Ready Builders');
        // Attendance correctly shows 1 of 1 (100%)
        expect(entity.attendanceSummary.totalClasses, 1);
        expect(entity.attendanceSummary.attended, 1);
        expect(entity.attendanceSummary.percentage, 100.0);
        // Assessments correctly shows 3 of 3 (100%)
        expect(entity.assessmentCompletion.total, 3);
        expect(entity.assessmentCompletion.completed, 3);
        expect(entity.assessmentCompletion.percentage, 100.0);
        // Assignments correctly shows 0 of 1 (0%)
        expect(entity.assignmentCompletion.total, 1);
        expect(entity.assignmentCompletion.completed, 0);
        expect(entity.assignmentCompletion.percentage, 0.0);
      },
    );

    test(
      'falls back safely to base /progress when auxiliary endpoints fail',
      () async {
        final fakeApi = FakeApiClient(
          responses: {
            '/parent/children/c1/progress': {
              'data': {
                'overallCompletion': 50,
                'assessmentCompletion': {
                  'total': 2,
                  'completed': 1,
                  'percentage': 50,
                },
                'assignmentCompletion': {
                  'total': 2,
                  'completed': 2,
                  'percentage': 100,
                },
                'attendanceSummary': {
                  'totalClasses': 4,
                  'attended': 4,
                  'percentage': 100,
                },
              },
            },
          },
        );

        final repo = ProgressRepositoryImpl(apiClient: fakeApi);
        final entity = await repo.getChildProgress(childStudentId: 'c1');

        expect(entity.overallCompletion, 50.0);
        expect(entity.attendanceSummary.totalClasses, 4);
        expect(entity.attendanceSummary.attended, 4);
        expect(entity.attendanceSummary.percentage, 100.0);
        expect(entity.assessmentCompletion.total, 2);
        expect(entity.assessmentCompletion.completed, 1);
        expect(entity.assignmentCompletion.completed, 2);
      },
    );

    test('throws when all requests fail', () async {
      final fakeApi = FakeApiClient(shouldThrow: true);
      final repo = ProgressRepositoryImpl(apiClient: fakeApi);

      expect(
        () => repo.getChildProgress(childStudentId: 'c1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('3. Overall progress mapping', () {
    test('maps overallCompletion exactly to entity', () {
      final entity = const ProgressDto(overallCompletion: 42.0)
          .toEntity(childStudentId: 'c1');
      expect(entity.overallCompletion, 42.0);
    });
  });

  group('4. Individual progress mapping', () {
    test(
      'maps individual assignment, attendance, and assessment completion',
      () {
        const dto = ProgressDto(
          overallCompletion: 50.0,
          assignmentCompletion: ProgressMetricDto(
            total: 6,
            completed: 3,
            percentage: 50.0,
          ),
          attendanceSummary: ProgressMetricDto(
            total: 8,
            completed: 8,
            percentage: 100.0,
          ),
          assessmentCompletion: ProgressMetricDto(
            total: 2,
            completed: 1,
            percentage: 50.0,
          ),
        );
        final entity = dto.toEntity(childStudentId: 'c1');
        expect(entity.assignmentCompletion.completed, 3);
        expect(entity.assignmentCompletion.total, 6);
        expect(entity.attendanceSummary.attended, 8);
        expect(entity.attendanceSummary.totalClasses, 8);
        expect(entity.assessmentCompletion.completed, 1);
      },
    );
  });

  group('5-9. Progress Controller lifecycle & states', () {
    test('5. Loading state transitions to Loaded', () async {
      final mockRepo = MockProgressRepository();
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(progressControllerProvider),
        isA<ProgressInitial>(),
      );

      final future = container
          .read(progressControllerProvider.notifier)
          .loadProgress(childStudentId: 'child_sarah', studentName: 'Sarah');
      expect(
        container.read(progressControllerProvider),
        isA<ProgressLoading>(),
      );

      await future;

      final state = container.read(progressControllerProvider);
      expect(state, isA<ProgressLoaded>());
      expect((state as ProgressLoaded).progress.overallCompletion, 42.0);
    });

    test('6. Empty state when child student ID is null or empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(progressControllerProvider.notifier)
          .loadProgress(childStudentId: null);

      expect(container.read(progressControllerProvider), isA<ProgressEmpty>());
    });

    test('7. Error state produces ProgressError on failure', () async {
      final mockRepo = MockProgressRepository();
      mockRepo.shouldThrow = Exception('Network timeout');
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      await container
          .read(progressControllerProvider.notifier)
          .loadProgress(childStudentId: 'child_sarah');

      final state = container.read(progressControllerProvider);
      expect(state, isA<ProgressError>());
      expect((state as ProgressError).message, contains('Network timeout'));
    });

    test('8. Child switching updates active child ID and reloads', () async {
      final mockRepo = MockProgressRepository();
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      await container
          .read(progressControllerProvider.notifier)
          .loadProgress(childStudentId: 'child_sarah');
      expect(mockRepo.lastChildId, 'child_sarah');

      // Switch to Ram
      await container
          .read(progressControllerProvider.notifier)
          .loadProgress(childStudentId: 'child_ram');
      expect(mockRepo.lastChildId, 'child_ram');
      final state =
          container.read(progressControllerProvider) as ProgressLoaded;
      expect(state.activeChildId, 'child_ram');
    });

    test('9. Pull to refresh calls getChildProgress again', () async {
      final mockRepo = MockProgressRepository();
      final container = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      await container
          .read(progressControllerProvider.notifier)
          .loadProgress(childStudentId: 'child_sarah');
      expect(mockRepo.getChildProgressCallCount, 1);

      await container.read(progressControllerProvider.notifier).refresh();
      expect(mockRepo.getChildProgressCallCount, 2);
    });
  });

  group('10. Dashboard Progress Tile Navigation', () {
    testWidgets(
      'MyLearningSection course card renders and navigates to progress',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MyLearningSection(
                enrolledBatches: [
                  EnrolledBatchEntity(
                    id: 'batch_1',
                    batchName: 'Batch 1 — Junior Foundation',
                    courseName: 'Junior Foundation',
                    progressPercentage: 42.0,
                    instructor: 'Elizabeth Vance',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('My Learning'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('42%'), findsOneWidget);
        expect(
          find.byKey(const Key('dashboard_progress_card_0')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'MyLearningSection empty state card is clickable and navigates',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: MyLearningSection(enrolledBatches: [])),
          ),
        );

        expect(
          find.byKey(const Key('dashboard_progress_empty_card')),
          findsOneWidget,
        );
        expect(find.text('No enrolled courses'), findsOneWidget);
      },
    );
  });

  group('11. "My Progress" -> "Progress" Title Change & UI widgets', () {
    const testChild = ChildEntity(
      studentId: 'child_sarah',
      firstName: 'Sarah',
      lastName: 'Connor',
    );

    testWidgets(
      'renders title as "Progress" (not "My Progress") and displays real values',
      (tester) async {
        final mockRepo = MockProgressRepository();
        mockRepo.mockChildProgress = const ProgressEntity(
          childStudentId: 'child_sarah',
          overallCompletion: 42.0,
          studentName: 'Sarah',
          activeTrack: 'Public Speaking & Communication',
          assignmentCompletion: ProgressMetricEntity(
            total: 4,
            completed: 2,
            percentage: 50.0,
          ),
          attendanceSummary: ProgressMetricEntity(
            total: 10,
            completed: 9,
            percentage: 90.0,
          ),
          assessmentCompletion: ProgressMetricEntity(
            total: 2,
            completed: 1,
            percentage: 50.0,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              progressRepositoryProvider.overrideWithValue(mockRepo),
              childrenControllerProvider.overrideWith(
                () => MockChildrenController(
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'child_sarah',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentLearningProgressScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Title must be "Progress", NOT "My Progress"
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('My Progress'), findsNothing);

        // Overall Progress dial card
        expect(find.text('42%'), findsOneWidget);
        expect(find.text('Overall Mastery'), findsOneWidget);

        // Real dynamic metric cards
        expect(
          find.byKey(const Key('metric_card_assignments')),
          findsOneWidget,
        );
        expect(find.text('Assignments'), findsOneWidget);
        expect(find.text('50%'), findsNWidgets(2)); // assignments & assessments
        expect(find.text('2 of 4 submitted'), findsOneWidget);

        expect(find.byKey(const Key('metric_card_attendance')), findsOneWidget);
        expect(find.text('Attendance'), findsOneWidget);
        expect(find.text('90%'), findsOneWidget);
        expect(find.text('9 of 10 classes attended'), findsOneWidget);

        expect(
          find.byKey(const Key('metric_card_assessments')),
          findsOneWidget,
        );
        expect(find.text('Assessments'), findsOneWidget);
        expect(find.text('1 of 2 evaluated'), findsOneWidget);

        // Back button
        expect(find.byKey(const Key('progress_back_button')), findsOneWidget);
      },
    );

    testWidgets('renders empty state when progress is empty', (tester) async {
      final container = ProviderContainer();
      container.read(progressControllerProvider.notifier).state =
          const ProgressEmpty(activeChildId: 'child_sarah');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ParentLearningProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress unavailable'), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      final container = ProviderContainer();
      container.read(progressControllerProvider.notifier).state =
          const ProgressError(message: 'Could not connect to server');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ParentLearningProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load progress'), findsOneWidget);
      expect(find.byKey(const Key('progress_retry_button')), findsOneWidget);
    });
  });
}

class MockChildrenController extends ChildrenController {
  MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;
}
