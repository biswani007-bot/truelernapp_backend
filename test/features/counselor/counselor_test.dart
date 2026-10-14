import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/counselor/data/models/counseling_request_dto.dart';
import 'package:truelearn/features/counselor/data/models/counselor_dto.dart';
import 'package:truelearn/features/counselor/data/repositories/counselor_repository_impl.dart';
import 'package:truelearn/features/counselor/domain/entities/counseling_request_entity.dart';
import 'package:truelearn/features/counselor/domain/entities/counselor_entity.dart';
import 'package:truelearn/features/counselor/domain/repositories/counselor_repository.dart';
import 'package:truelearn/features/counselor/presentation/controllers/counselor_controller.dart';
import 'package:truelearn/features/counselor/presentation/controllers/counselor_state.dart';
import 'package:truelearn/features/counselor/presentation/screens/counselor_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/bento_snapshot_grid.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic responseData;
  bool shouldThrow = false;
  String? lastPath;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network connection error',
        type: DioExceptionType.connectionError,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responseData as T?,
    );
  }
}

class MockCounselorRepository implements CounselorRepository {
  List<CounselorEntity> mockCounselors = [];
  List<CounselingRequestEntity> mockRequests = [];
  bool shouldThrow = false;
  int getCounselorsCalls = 0;
  int getMyRequestsCalls = 0;

  @override
  Future<List<CounselorEntity>> getCounselors() async {
    getCounselorsCalls++;
    if (shouldThrow) {
      throw Exception('Server error loading counselors');
    }
    return mockCounselors;
  }

  @override
  Future<List<CounselingRequestEntity>> getMyRequests() async {
    getMyRequestsCalls++;
    if (shouldThrow) {
      throw Exception('Server error loading requests');
    }
    return mockRequests;
  }
}

void main() {
  group('1. Counselor DTO & Request DTO Parsing', () {
    test('parses counselor JSON from GET /api/counselling correctly', () {
      final json = {
        'id': 'counselor_001',
        'name': 'Dr. Marcus Vance',
        'email': 'marcus.vance@truelern.com',
        'phone': '+1 (555) 345-6789',
        'avatar': 'https://truelern.visital.in/avatars/marcus.png',
        'designation': 'Senior Academic Counselor',
        'specialization': 'STEM & Early Foundation',
        'status': 'active',
      };

      final dto = CounselorDto.fromJson(json);
      expect(dto.id, 'counselor_001');
      expect(dto.name, 'Dr. Marcus Vance');
      expect(dto.email, 'marcus.vance@truelern.com');
      expect(dto.phone, '+1 (555) 345-6789');
      expect(dto.avatar, 'https://truelern.visital.in/avatars/marcus.png');
      expect(dto.designation, 'Senior Academic Counselor');
      expect(dto.specialization, 'STEM & Early Foundation');

      final entity = dto.toEntity();
      expect(entity.id, 'counselor_001');
      expect(entity.name, 'Dr. Marcus Vance');
      expect(entity.displayDesignation, 'Senior Academic Counselor');
      expect(entity.hasContactInfo, isTrue);
    });

    test('parses firstName and lastName fallback correctly', () {
      final json = {
        '_id': 'counselor_002',
        'firstName': 'Elena',
        'lastName': 'Rostova',
        'role': 'Counselor',
      };

      final dto = CounselorDto.fromJson(json);
      expect(dto.id, 'counselor_002');
      expect(dto.name, 'Elena Rostova');
      expect(dto.designation, 'Counselor');
      expect(dto.toEntity().displayDesignation, 'Counselor');
    });

    test('parses CounselingRequestDto from GET /api/counselling/my-requests', () {
      final json = {
        'requestId': 'req_100',
        'counsellor': {
          'id': 'c_1',
          'name': 'Dr. Marcus',
        },
        'status': 'scheduled',
        'proposedStart': '2026-10-15T10:00:00.000Z',
        'proposedEnd': '2026-10-15T11:00:00.000Z',
        'reason': 'Academic guidance for grade transition',
      };

      final dto = CounselingRequestDto.fromJson(json);
      expect(dto.requestId, 'req_100');
      expect(dto.counsellorId, 'c_1');
      expect(dto.counsellorName, 'Dr. Marcus');
      expect(dto.status, 'scheduled');
      expect(dto.reason, 'Academic guidance for grade transition');
      expect(dto.toEntity().statusLabel, 'SCHEDULED');
    });
  });

  group('2. Counselor Repository', () {
    late MockApiClient mockApiClient;
    late CounselorRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = CounselorRepositoryImpl(apiClient: mockApiClient);
    });

    test('getCounselors fetches and parses response from /counselling', () async {
      mockApiClient.responseData = {
        'success': true,
        'message': 'Active counsellors fetched',
        'data': [
          {
            'id': 'c_test',
            'name': 'Sarah Jenkins',
            'designation': 'Lead Counselor',
          }
        ],
        'meta': {}
      };

      final list = await repository.getCounselors();
      expect(mockApiClient.lastPath, '/counselling');
      expect(list.length, 1);
      expect(list.first.name, 'Sarah Jenkins');
    });

    test('getCounselors returns empty list when backend data is empty array', () async {
      mockApiClient.responseData = {
        'success': true,
        'message': 'Active counsellors fetched',
        'data': [],
        'meta': {}
      };

      final list = await repository.getCounselors();
      expect(list, isEmpty);
    });

    test('throws exception when network fails', () async {
      mockApiClient.shouldThrow = true;
      expect(() => repository.getCounselors(), throwsA(isA<Exception>()));
    });
  });

  group('3-8. Counselor Controller & State Transitions', () {
    late MockCounselorRepository mockRepo;

    setUp(() {
      mockRepo = MockCounselorRepository();
    });

    test('3. initial state is CounselorInitial', () {
      final container = ProviderContainer(
        overrides: [
          counselorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(counselorControllerProvider);
      expect(state, isA<CounselorInitial>());
    });

    test('4-5. transitions to CounselorLoading and then CounselorLoaded with counselor', () async {
      mockRepo.mockCounselors = [
        const CounselorEntity(
          id: 'c1',
          name: 'Dr. Marcus Vance',
          designation: 'Academic Counselor',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          counselorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(counselorControllerProvider.notifier);
      await controller.loadCounselor(childStudentId: 'child_alex');

      final state = container.read(counselorControllerProvider);
      expect(state, isA<CounselorLoaded>());
      final loaded = state as CounselorLoaded;
      expect(loaded.hasCounselor, isTrue);
      expect(loaded.primaryCounselor?.name, 'Dr. Marcus Vance');
      expect(loaded.activeChildId, 'child_alex');
    });

    test('6. empty state produces CounselorLoaded with empty counselors list', () async {
      mockRepo.mockCounselors = [];

      final container = ProviderContainer(
        overrides: [
          counselorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(counselorControllerProvider.notifier);
      await controller.loadCounselor(childStudentId: 'child_sarah');

      final state = container.read(counselorControllerProvider);
      expect(state, isA<CounselorLoaded>());
      final loaded = state as CounselorLoaded;
      expect(loaded.hasCounselor, isFalse);
      expect(loaded.counselors, isEmpty);
      expect(loaded.activeChildId, 'child_sarah');
    });

    test('7. error state produces CounselorError on exception', () async {
      mockRepo.shouldThrow = true;

      final container = ProviderContainer(
        overrides: [
          counselorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(counselorControllerProvider.notifier);
      await controller.loadCounselor(childStudentId: 'child_err');

      final state = container.read(counselorControllerProvider);
      expect(state, isA<CounselorError>());
      final err = state as CounselorError;
      expect(err.message, contains('Unable to load counselor information'));
      expect(err.activeChildId, 'child_err');
    });

    test('8. child switching triggers reload with new active child ID', () async {
      final container = ProviderContainer(
        overrides: [
          counselorRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(counselorControllerProvider.notifier);

      // Child 1: Sarah
      await controller.loadCounselor(childStudentId: 'child_sarah');
      var state = container.read(counselorControllerProvider) as CounselorLoaded;
      expect(state.activeChildId, 'child_sarah');

      // Child 2: Ram
      await controller.loadCounselor(childStudentId: 'child_ram');
      state = container.read(counselorControllerProvider) as CounselorLoaded;
      expect(state.activeChildId, 'child_ram');
    });
  });

  group('9. Dashboard Counselor Tile Navigation', () {
    testWidgets('Dashboard BentoSnapshotGrid renders Counselor tile and responds to tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoSnapshotGrid(
              dashboard: const DashboardEntity(
                attendanceRate: 92.0,
                pendingAssignmentsCount: 2,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('bento_counselor_card')), findsOneWidget);
      expect(find.text('Counselor'), findsOneWidget);
      expect(find.text('Guidance'), findsOneWidget);
      expect(find.text('Academic Support'), findsOneWidget);
    });
  });

  group('10. Counselor Screen Widget & Pull to Refresh Tests', () {
    const testChild = ChildEntity(
      studentId: 'child_alex',
      firstName: 'Alex',
      lastName: 'Mercer',
      grade: 'Grade 5',
    );

    testWidgets('renders counselor card when counselor data is present', (tester) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [
        const CounselorEntity(
          id: 'c_test_1',
          name: 'Dr. Marcus Vance',
          email: 'marcus@truelern.com',
          phone: '+1 234 567 8900',
          designation: 'Senior Academic Counselor',
          specialization: 'STEM Pathways',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(() => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_alex',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ParentCounselorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Counselor'), findsOneWidget);
      expect(find.text('Academic Guidance'), findsOneWidget);
      expect(find.text('Dr. Marcus Vance'), findsOneWidget);
      expect(find.text('Senior Academic Counselor'), findsOneWidget);
      expect(find.text('Assigned Counselor'), findsOneWidget);
      expect(find.text('marcus@truelern.com'), findsOneWidget);
      expect(find.text('+1 234 567 8900'), findsOneWidget);
      expect(find.text('Specialization: STEM Pathways'), findsOneWidget);
    });

    testWidgets('renders empty state when no counselor is assigned', (tester) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(() => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_alex',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ParentCounselorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('counselor_empty_state')), findsOneWidget);
      expect(find.text('No Counselor Assigned'), findsOneWidget);
      expect(find.textContaining('Official academic counselor guidance for Alex'), findsOneWidget);
    });

    testWidgets('renders error card with retry button when error occurs', (tester) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(() => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_alex',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: ParentCounselorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('counselor_error_card')), findsOneWidget);
      expect(find.text('Unable to Load Counselor'), findsOneWidget);
      expect(find.byKey(const Key('counselor_retry_button')), findsOneWidget);
    });
  });
}

class MockChildrenController extends ChildrenController {
  MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;
}
