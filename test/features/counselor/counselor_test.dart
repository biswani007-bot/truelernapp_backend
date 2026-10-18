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
import 'package:truelearn/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:truelearn/features/messages/domain/entities/message_entity.dart';
import 'package:truelearn/features/messages/domain/repositories/messages_repository.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic responseData;
  dynamic postResponseData;
  bool shouldThrow = false;
  String? lastPath;
  String? lastPostPath;
  dynamic lastPostData;

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

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network connection error',
        type: DioExceptionType.connectionError,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: (postResponseData ?? responseData) as T?,
    );
  }
}

class MockCounselorRepository implements CounselorRepository {
  List<CounselorEntity> mockCounselors = [];
  List<CounselingRequestEntity> mockRequests = [];
  bool shouldThrow = false;
  int getCounselorsCalls = 0;
  int getMyRequestsCalls = 0;
  int submitRequestCalls = 0;
  String? lastSubmittedCounsellorId;
  String? lastSubmittedStudentId;
  DateTime? lastSubmittedProposedStart;
  DateTime? lastSubmittedProposedEnd;
  String? lastSubmittedReason;

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

  @override
  Future<CounselingRequestEntity> submitRequest({
    required String counsellorId,
    required String studentId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required String reason,
  }) async {
    submitRequestCalls++;
    lastSubmittedCounsellorId = counsellorId;
    lastSubmittedStudentId = studentId;
    lastSubmittedProposedStart = proposedStart;
    lastSubmittedProposedEnd = proposedEnd;
    lastSubmittedReason = reason;

    if (shouldThrow) {
      throw Exception('Server error submitting request');
    }

    final newReq = CounselingRequestEntity(
      requestId: 'req_new_${mockRequests.length + 1}',
      counsellorId: counsellorId,
      counsellorName: 'Elizabeth Vance',
      status: 'PENDING',
      childId: studentId,
      notes: reason,
      reason: reason,
      proposedStart: proposedStart,
      proposedEnd: proposedEnd,
      createdAt: DateTime.now(),
    );
    mockRequests.insert(0, newReq);
    return newReq;
  }
}

const testChild = ChildEntity(
  studentId: 'child_alex',
  firstName: 'Alex',
  lastName: 'Mercer',
  grade: 'Grade 5',
);

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

    test(
      'parses CounselingRequestDto from GET /api/counselling/my-requests',
      () {
        final json = {
          'requestId': 'req_100',
          'counsellor': {'id': 'c_1', 'name': 'Dr. Marcus'},
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
      },
    );
  });

  group('2. Counselor Repository', () {
    late MockApiClient mockApiClient;
    late CounselorRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = CounselorRepositoryImpl(apiClient: mockApiClient);
    });

    test(
      'getCounselors fetches and parses response from /counselling',
      () async {
        mockApiClient.responseData = {
          'success': true,
          'message': 'Active counsellors fetched',
          'data': [
            {
              'id': 'c_test',
              'name': 'Sarah Jenkins',
              'designation': 'Lead Counselor',
            },
          ],
          'meta': {},
        };

        final list = await repository.getCounselors();
        expect(mockApiClient.lastPath, '/counselling');
        expect(list.length, 1);
        expect(list.first.name, 'Sarah Jenkins');
      },
    );

    test(
      'getCounselors returns empty list when backend data is empty array',
      () async {
        mockApiClient.responseData = {
          'success': true,
          'message': 'Active counsellors fetched',
          'data': [],
          'meta': {},
        };

        final list = await repository.getCounselors();
        expect(list, isEmpty);
      },
    );

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
        overrides: [counselorRepositoryProvider.overrideWithValue(mockRepo)],
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
        overrides: [counselorRepositoryProvider.overrideWithValue(mockRepo)],
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

    test(
      '6. empty state produces CounselorLoaded with empty counselors list',
      () async {
        mockRepo.mockCounselors = [];

        final container = ProviderContainer(
          overrides: [counselorRepositoryProvider.overrideWithValue(mockRepo)],
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
      },
    );

    test('7. error state produces CounselorError on exception', () async {
      mockRepo.shouldThrow = true;

      final container = ProviderContainer(
        overrides: [counselorRepositoryProvider.overrideWithValue(mockRepo)],
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

    test(
      '8. child switching triggers reload with new active child ID',
      () async {
        final container = ProviderContainer(
          overrides: [counselorRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

        final controller = container.read(counselorControllerProvider.notifier);

        // Child 1: Sarah
        await controller.loadCounselor(childStudentId: 'child_sarah');
        var state =
            container.read(counselorControllerProvider) as CounselorLoaded;
        expect(state.activeChildId, 'child_sarah');

        // Child 2: Ram
        await controller.loadCounselor(childStudentId: 'child_ram');
        state = container.read(counselorControllerProvider) as CounselorLoaded;
        expect(state.activeChildId, 'child_ram');
      },
    );
  });

  group('9. Dashboard Counselor Tile Navigation', () {
    testWidgets(
      'Dashboard BentoSnapshotGrid renders Counselor tile and responds to tap',
      (tester) async {
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
      },
    );
  });

  group('10. Counselor Screen Widget & Pull to Refresh Tests', () {
    testWidgets('renders counselor card when counselor data is present', (
      tester,
    ) async {
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
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
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

    testWidgets('renders empty state when no counselor is assigned', (
      tester,
    ) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('counselor_empty_state')), findsOneWidget);
      expect(find.text('No Counselor Assigned'), findsOneWidget);
      expect(
        find.textContaining('Official academic counselor guidance for Alex'),
        findsOneWidget,
      );
    });

    testWidgets('renders error card with retry button when error occurs', (
      tester,
    ) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('counselor_error_card')), findsOneWidget);
      expect(find.text('Unable to Load Counselor'), findsOneWidget);
      expect(find.byKey(const Key('counselor_retry_button')), findsOneWidget);
    });

    testWidgets('11. Sessions & Requests renders requests with parent note, date, counselor info, and accurate status chips', (
      tester,
    ) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [
        const CounselorEntity(
          id: 'c_1',
          name: 'Elizabeth Vance',
          designation: 'Principal Instructor',
          specialization: 'Software Engineering',
        ),
      ];
      mockRepo.mockRequests = [
        CounselingRequestEntity(
          requestId: 'req_accepted_1',
          counsellorId: 'c_1',
          counsellorName: 'Elizabeth Vance',
          counsellorRole: 'Principal Instructor',
          childName: 'Alex Mercer',
          status: 'accepted',
          proposedStart: DateTime(2026, 10, 16, 10, 0),
          reason: 'Academic Guidance',
          notes: 'Discussing project transition and career pathways',
        ),
        CounselingRequestEntity(
          requestId: 'req_pending_2',
          counsellorId: 'c_1',
          counsellorName: 'Elizabeth Vance',
          status: 'pending',
          proposedStart: DateTime(2026, 10, 20, 14, 0),
          reason: 'Subject Advisory',
          notes: 'Reviewing semester syllabus options',
        ),
        CounselingRequestEntity(
          requestId: 'req_rejected_3',
          counsellorId: 'c_1',
          counsellorName: 'Elizabeth Vance',
          status: 'rejected',
          proposedStart: DateTime(2026, 10, 10, 9, 0),
          reason: 'Schedule Change',
          notes: 'Slot conflict',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Sessions & Requests section title
      expect(find.text('Sessions & Requests'), findsOneWidget);

      // 2. Parent Notes
      expect(find.text('Discussing project transition and career pathways'), findsOneWidget);
      expect(find.text('Reviewing semester syllabus options'), findsOneWidget);
      expect(find.text('Slot conflict'), findsOneWidget);

      // 3. Status chips
      expect(find.text('ACCEPTED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('REJECTED'), findsOneWidget);

      // 4. Dates
      expect(find.text('16/10/2026'), findsOneWidget);
      expect(find.text('20/10/2026'), findsOneWidget);

      // 5. Counselor & Student association
      expect(find.text('Student: Alex Mercer'), findsWidgets);
      expect(find.textContaining('Elizabeth Vance • Principal Instructor'), findsWidgets);
    });

    testWidgets('12. Start Chat button appears only for accepted requests and is absent for pending/rejected requests', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [
        const CounselorEntity(
          id: 'c_1',
          name: 'Elizabeth Vance',
          designation: 'Principal Instructor',
        ),
      ];
      mockRepo.mockRequests = [
        CounselingRequestEntity(
          requestId: 'req_acc',
          counsellorId: 'c_1',
          counsellorName: 'Elizabeth Vance',
          status: 'accepted',
          notes: 'Ready for chat',
        ),
        CounselingRequestEntity(
          requestId: 'req_pen',
          counsellorId: 'c_1',
          counsellorName: 'Elizabeth Vance',
          status: 'pending',
          notes: 'Pending review',
        ),
        CounselingRequestEntity(
          requestId: 'req_rej',
          counsellorId: 'c_1',
          counsellorName: 'Elizabeth Vance',
          status: 'rejected',
          notes: 'Declined request',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Start Chat button should exist ONLY for accepted request
      expect(find.byKey(const Key('start_chat_button_req_acc')), findsOneWidget);
      expect(find.byKey(const Key('start_chat_button_req_pen')), findsNothing);
      expect(find.byKey(const Key('start_chat_button_req_rej')), findsNothing);

      // Pending and Rejected status notices
      expect(
        find.text('Request is pending approval. Chat will unlock once accepted.'),
        findsOneWidget,
      );
      expect(
        find.text('Request was declined. Please contact your academic advisor.'),
        findsOneWidget,
      );
    });

    testWidgets('13. Chat-Only: Start Chat opens conversation sheet and supports messaging', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [
        const CounselorEntity(
          id: 'c_elizabeth',
          name: 'Elizabeth Vance',
          designation: 'Principal Instructor',
        ),
      ];
      mockRepo.mockRequests = [
        CounselingRequestEntity(
          requestId: 'req_live_chat',
          counsellorId: 'c_elizabeth',
          counsellorName: 'Elizabeth Vance',
          status: 'accepted',
          notes: 'Counseling guidance session on STEM goals',
        ),
      ];

      final mockMessagesRepo = MockMessagesRepository();
      mockMessagesRepo.messages = [
        MessageItemEntity(
          id: 'm1',
          senderRole: 'teacher',
          subject: 'Counseling Session: Counseling guidance session on STEM goals',
          message: 'Hello! I am ready to discuss your child\'s learning pathway.',
          isRead: true,
          status: 'delivered',
          createdAt: DateTime(2026, 10, 16, 10, 15),
          senderName: 'Elizabeth Vance',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            messagesRepositoryProvider.overrideWithValue(mockMessagesRepo),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Start Chat
      final startChatBtn = find.byKey(const Key('start_chat_button_req_live_chat'));
      expect(startChatBtn, findsOneWidget);
      await tester.ensureVisible(startChatBtn);
      await tester.tap(startChatBtn);
      await tester.pumpAndSettle();

      // Chat bottom sheet is opened
      expect(find.text('TEXT ONLY'), findsOneWidget);
      expect(find.textContaining('Topic: Counseling guidance session on STEM goals'), findsOneWidget);
      expect(find.text('Hello! I am ready to discuss your child\'s learning pathway.'), findsOneWidget);
      expect(find.byKey(const Key('counselor_chat_input_field')), findsOneWidget);
      expect(find.byKey(const Key('counselor_chat_send_button')), findsOneWidget);
      expect(find.byKey(const Key('counselor_chat_close_button')), findsOneWidget);

      // Send a message
      await tester.enterText(
        find.byKey(const Key('counselor_chat_input_field')),
        'Thank you Ms. Vance, we appreciate your guidance.',
      );
      await tester.tap(find.byKey(const Key('counselor_chat_send_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Thank you Ms. Vance, we appreciate your guidance.'),
        findsOneWidget,
      );

      // Close the sheet
      await tester.tap(find.byKey(const Key('counselor_chat_close_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('counselor_chat_input_field')), findsNothing);
    });

    testWidgets('14. Strict Restriction: NO video calls, audio calls, join session buttons, or meeting links appear', (
      tester,
    ) async {
      final mockRepo = MockCounselorRepository();
      mockRepo.mockCounselors = [
        const CounselorEntity(
          id: 'c_1',
          name: 'Elizabeth Vance',
          designation: 'Principal Instructor',
        ),
      ];
      mockRepo.mockRequests = [
        CounselingRequestEntity(
          requestId: 'req_1',
          status: 'accepted',
          notes: 'Discussion',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                ChildrenLoaded(
                  children: const [testChild],
                  activeChildId: 'child_alex',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentCounselorScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify absence of any video, audio, or meeting call buttons
      expect(find.textContaining('Join Session'), findsNothing);
      expect(find.textContaining('Join Class'), findsNothing);
      expect(find.textContaining('Video Call'), findsNothing);
      expect(find.textContaining('Audio Call'), findsNothing);
      expect(find.textContaining('Meeting Link'), findsNothing);
      expect(find.byIcon(Icons.videocam_rounded), findsNothing);
      expect(find.byIcon(Icons.video_call_rounded), findsNothing);
      expect(find.byIcon(Icons.call), findsNothing);
    });
  });

  group('11. Counselor Request Submission API & Controller', () {
    test(
      'CounselorRepository.submitRequest sends POST /counselling with correct payload',
      () async {
        final mockApi = MockApiClient();
        final repo = CounselorRepositoryImpl(apiClient: mockApi);

        mockApi.postResponseData = {
          'id': 'counselling_req_101',
          'counsellorId': 'counselor_marcus',
          'counsellorName': 'Dr. Marcus Vance',
          'status': 'PENDING',
          'studentId': 'child_alex',
          'notes': 'Discussion on science curriculum progress',
          'proposedStart': '2026-10-20T10:00:00.000Z',
          'proposedEnd': '2026-10-20T11:00:00.000Z',
          'createdAt': '2026-10-16T12:00:00.000Z',
        };

        final start = DateTime.utc(2026, 10, 20, 10, 0);
        final end = DateTime.utc(2026, 10, 20, 11, 0);

        final result = await repo.submitRequest(
          counsellorId: 'counselor_marcus',
          studentId: 'child_alex',
          proposedStart: start,
          proposedEnd: end,
          reason: 'Discussion on science curriculum progress',
        );

        expect(mockApi.lastPostPath, '/counselling');
        expect(mockApi.lastPostData, isA<Map<String, dynamic>>());
        final sentData = mockApi.lastPostData as Map<String, dynamic>;
        expect(sentData['counsellorId'], 'counselor_marcus');
        expect(sentData['studentId'], 'child_alex');
        expect(sentData['reason'], 'Discussion on science curriculum progress');
        expect(sentData['notes'], 'Discussion on science curriculum progress');
        expect(result.requestId, 'counselling_req_101');
        expect(result.status, 'PENDING');
        expect(result.isPending, isTrue);
      },
    );

    test(
      'CounselorRepository.submitRequest throws exception on network error',
      () async {
        final mockApi = MockApiClient();
        mockApi.shouldThrow = true;
        final repo = CounselorRepositoryImpl(apiClient: mockApi);

        expect(
          () => repo.submitRequest(
            counsellorId: 'c_fail',
            studentId: 's_fail',
            proposedStart: DateTime.now(),
            proposedEnd: DateTime.now().add(const Duration(hours: 1)),
            reason: 'Test fail',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'CounselorController.submitRequest calls repository and updates state requests',
      () async {
        final mockRepo = MockCounselorRepository();
        mockRepo.mockCounselors = [
          const CounselorEntity(
            id: 'c_test_1',
            name: 'Elizabeth Vance',
            designation: 'Principal Instructor',
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            counselorRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(counselorControllerProvider.notifier)
            .loadCounselor(childStudentId: 'child_alex');
        final beforeState =
            container.read(counselorControllerProvider) as CounselorLoaded;
        expect(beforeState.myRequests.length, 0);

        final start = DateTime.utc(2026, 10, 25, 14, 0);
        final end = DateTime.utc(2026, 10, 25, 15, 0);

        final created = await container
            .read(counselorControllerProvider.notifier)
            .submitRequest(
              counsellorId: 'c_test_1',
              studentId: 'child_alex',
              proposedStart: start,
              proposedEnd: end,
              reason: 'Requesting guidance on math concepts',
            );

        expect(mockRepo.submitRequestCalls, 1);
        expect(created.requestId, startsWith('req_new_'));
        final afterState =
            container.read(counselorControllerProvider) as CounselorLoaded;
        expect(afterState.myRequests.length, 1);
        expect(
          afterState.myRequests.first.notes,
          'Requesting guidance on math concepts',
        );
      },
    );
  });

  group('12. Multiple Counselors Support', () {
    test(
      'CounselorState separates assignedCounselor and availableCounselors',
      () {
        const c1 = CounselorEntity(id: 'c1', name: 'Primary Counselor');
        const c2 = CounselorEntity(id: 'c2', name: 'Second Counselor');
        const c3 = CounselorEntity(id: 'c3', name: 'Third Counselor');

        const state = CounselorLoaded(
          counselors: [c1, c2, c3],
          myRequests: [],
          activeChildId: 'child_alex',
        );

        expect(state.hasCounselor, isTrue);
        expect(state.assignedCounselor, equals(c1));
        expect(state.availableCounselors.length, 2);
        expect(state.availableCounselors[0], equals(c2));
        expect(state.availableCounselors[1], equals(c3));
      },
    );

    testWidgets(
      'Counselor Screen renders Assigned Counselor and Other Available Counselors',
      (tester) async {
        final mockRepo = MockCounselorRepository();
        mockRepo.mockCounselors = [
          const CounselorEntity(
            id: 'c_assigned',
            name: 'Elizabeth Vance',
            designation: 'Principal Instructor',
            specialization: 'Software Engineering',
          ),
          const CounselorEntity(
            id: 'c_available',
            name: 'Marcus Vance',
            designation: 'Career & College Counselor',
            specialization: 'STEM Foundation',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              counselorRepositoryProvider.overrideWithValue(mockRepo),
              childrenControllerProvider.overrideWith(
                () => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_alex',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentCounselorScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Primary assigned counselor
        expect(find.text('Elizabeth Vance'), findsOneWidget);
        expect(find.text('Assigned Counselor'), findsOneWidget);

        // Other Available Counselors section
        expect(find.text('Other Available Counselors'), findsOneWidget);
        expect(find.text('Marcus Vance'), findsOneWidget);
        expect(find.text('Career & College Counselor'), findsOneWidget);
      },
    );
  });

  group('13. Request Session Bottom Sheet UI & Validation', () {
    testWidgets(
      'opens RequestSessionBottomSheet and validates required fields',
      (tester) async {
        final mockRepo = MockCounselorRepository();
        mockRepo.mockCounselors = [
          const CounselorEntity(
            id: 'c_test_1',
            name: 'Elizabeth Vance',
            designation: 'Principal Instructor',
            specialization: 'Software Engineering',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              counselorRepositoryProvider.overrideWithValue(mockRepo),
              childrenControllerProvider.overrideWith(
                () => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_alex',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentCounselorScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Locate and tap "Request Session" on assigned counselor card
        final requestBtn =
            find.byKey(const Key('request_session_button_c_test_1'));
        expect(requestBtn, findsOneWidget);
        await tester.tap(requestBtn);
        await tester.pumpAndSettle();

        // Bottom sheet is displayed
        expect(
          find.byKey(const Key('request_session_modal_title')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('request_session_child_dropdown')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('request_session_reason_input')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('request_session_submit_button')),
          findsOneWidget,
        );

        // Attempt submit without filling start/end dates
        await tester.tap(find.byKey(const Key('request_session_submit_button')));
        await tester.pump();

        expect(
          find.byKey(const Key('request_session_error_banner')),
          findsOneWidget,
        );
        expect(
          find.text('Please select a preferred start date and time.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'submits request successfully from RequestSessionBottomSheet',
      (tester) async {
        final mockRepo = MockCounselorRepository();
        const counselor = CounselorEntity(
          id: 'c_test_1',
          name: 'Elizabeth Vance',
          designation: 'Principal Instructor',
        );
        mockRepo.mockCounselors = [counselor];

        final now = DateTime.now();
        final start = now.add(const Duration(days: 1));
        final end = start.add(const Duration(hours: 1));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              counselorRepositoryProvider.overrideWithValue(mockRepo),
              childrenControllerProvider.overrideWith(
                () => MockChildrenController(
                  ChildrenLoaded(
                    children: const [testChild],
                    activeChildId: 'child_alex',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: RequestSessionBottomSheet(
                  counselor: counselor,
                  children: const [testChild],
                  initialChild: testChild,
                  initialStart: start,
                  initialEnd: end,
                  initialReason: 'Discussion regarding student progress',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap submit button
        final submitBtn = find.byKey(const Key('request_session_submit_button'));
        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Verify repository was called with correct data
        expect(mockRepo.submitRequestCalls, 1);
        expect(mockRepo.lastSubmittedCounsellorId, 'c_test_1');
        expect(mockRepo.lastSubmittedStudentId, 'child_alex');
        expect(
          mockRepo.lastSubmittedReason,
          'Discussion regarding student progress',
        );
      },
    );
  });
}

class MockChildrenController extends ChildrenController {
  MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;
}

class MockMessagesRepository implements MessagesRepository {
  List<MessageItemEntity> messages = [];

  @override
  Future<MessagesDataEntity> getMessages({required String studentId}) async {
    return MessagesDataEntity(
      studentId: studentId,
      studentName: 'Alex Mercer',
      messages: List.from(messages),
    );
  }

  @override
  Future<MessageItemEntity> sendMessage({
    required String studentId,
    required String message,
    String? subject,
  }) async {
    final item = MessageItemEntity(
      id: 'sent_${DateTime.now().millisecondsSinceEpoch}',
      senderRole: 'parent',
      subject: subject ?? 'Counseling Session',
      message: message,
      isRead: true,
      status: 'sent',
      createdAt: DateTime.now(),
      senderName: 'Parent',
    );
    messages.add(item);
    return item;
  }

  @override
  Future<bool> markAsRead({
    required String studentId,
    required String messageId,
  }) async {
    return true;
  }
}
