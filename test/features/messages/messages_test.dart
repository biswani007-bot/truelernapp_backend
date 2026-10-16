import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_messages_screen.dart';
import 'package:truelearn/features/messages/data/models/message_dto.dart';
import 'package:truelearn/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:truelearn/features/messages/domain/entities/message_entity.dart';
import 'package:truelearn/features/messages/domain/repositories/messages_repository.dart';
import 'package:truelearn/features/messages/presentation/controllers/messages_controller.dart';
import 'package:truelearn/features/messages/presentation/controllers/messages_state.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic responseData;
  bool shouldThrow = false;
  String? lastPath;
  dynamic lastPayload;

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
    lastPath = path;
    lastPayload = data;
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
      data: responseData as T?,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastPayload = data;
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

class FakeMessagesRepository implements MessagesRepository {
  MessagesDataEntity? mockData;
  bool shouldThrow = false;
  int getMessagesCalls = 0;
  int sendMessageCalls = 0;
  int markAsReadCalls = 0;

  @override
  Future<MessagesDataEntity> getMessages({required String studentId}) async {
    getMessagesCalls++;
    if (shouldThrow) throw Exception('API Error');
    return mockData ??
        MessagesDataEntity(
          studentId: studentId,
          studentName: 'Ram Pearson',
          messages: [],
        );
  }

  @override
  Future<MessageItemEntity> sendMessage({
    required String studentId,
    required String message,
    String? subject,
  }) async {
    sendMessageCalls++;
    if (shouldThrow) throw Exception('Send failed');
    return MessageItemEntity(
      id: 'new_msg_1',
      senderRole: 'parent',
      subject: subject ?? 'Inquiry regarding Ram',
      message: message,
      isRead: false,
      status: 'sent',
      createdAt: DateTime.now(),
      senderName: 'You',
    );
  }

  @override
  Future<bool> markAsRead({
    required String studentId,
    required String messageId,
  }) async {
    markAsReadCalls++;
    if (shouldThrow) throw Exception('Mark read failed');
    return true;
  }
}

class FakeChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  FakeChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> setActiveChild(String childStudentId) async {}

  @override
  Future<void> retry() async {}

  @override
  void reset() {}
}

void main() {
  group('Messages DTO & Entity tests', () {
    test('MessageItemDto correctly parses json', () {
      final json = {
        '_id': 'msg_123',
        'senderRole': 'teacher',
        'subject': 'Update from Instructor',
        'message': 'Great work today!',
        'isRead': false,
        'status': 'sent',
        'createdAt': '2026-10-05T10:11:43.005Z',
      };

      final dto = MessageItemDto.fromJson(json);
      expect(dto.id, 'msg_123');
      expect(dto.senderRole, 'teacher');
      expect(dto.isRead, false);
      expect(dto.message, 'Great work today!');

      final entity = dto.toEntity(resolvedSenderName: 'Ms. Elizabeth');
      expect(entity.isTeacher, true);
      expect(entity.isParent, false);
      expect(entity.senderName, 'Ms. Elizabeth');
    });

    test('MessagesDataDto parses student, teachers, and messages lists', () {
      final json = {
        'student': {
          '_id': 'student_ram',
          'firstName': 'Ram',
          'lastName': 'Pearson',
        },
        'activeTeacher': {
          '_id': 'teacher_liz',
          'firstName': 'Elizabeth',
          'lastName': 'Vance',
          'designation': 'Principal Instructor',
          'department': 'Software Engineering',
        },
        'teachers': [
          {'_id': 'teacher_liz', 'firstName': 'Elizabeth', 'lastName': 'Vance'},
        ],
        'messages': [
          {
            '_id': 'm1',
            'senderRole': 'teacher',
            'subject': 'Inquiry',
            'message': 'Hello Ram',
            'isRead': false,
          },
          {
            '_id': 'm2',
            'senderRole': 'parent',
            'subject': 'Reply',
            'message': 'Thank you',
            'isRead': true,
          },
        ],
      };

      final dto = MessagesDataDto.fromJson(json);
      expect(dto.studentId, 'student_ram');
      expect(dto.studentName, 'Ram Pearson');
      expect(dto.activeTeacher?.firstName, 'Elizabeth');
      expect(dto.messages.length, 2);

      final entity = dto.toEntity();
      expect(entity.unreadCount, 1);
      expect(entity.messages[0].senderName, 'Elizabeth Vance');
      expect(entity.messages[1].senderName, 'You');
    });
  });

  group('MessagesRepositoryImpl tests', () {
    test(
      'getMessages makes GET request to correct path and maps data',
      () async {
        final mockApi = MockApiClient();
        mockApi.responseData = {
          'success': true,
          'message': 'Messages retrieved successfully',
          'data': {
            'student': {'_id': 'stud_1', 'firstName': 'Sarah'},
            'messages': [
              {
                '_id': 'm_001',
                'senderRole': 'teacher',
                'subject': 'Update',
                'message': 'Hello Sarah',
                'isRead': true,
              },
            ],
          },
        };

        final repo = MessagesRepositoryImpl(apiClient: mockApi);
        final result = await repo.getMessages(studentId: 'stud_1');

        expect(mockApi.lastPath, '/parent/children/stud_1/messages');
        expect(result.studentId, 'stud_1');
        expect(result.messages.length, 1);
        expect(result.messages.first.message, 'Hello Sarah');
      },
    );

    test('sendMessage makes POST request with payload', () async {
      final mockApi = MockApiClient();
      mockApi.responseData = {
        'success': true,
        'data': {
          '_id': 'm_new',
          'senderRole': 'parent',
          'subject': 'Inquiry',
          'message': 'Can we discuss grades?',
          'isRead': false,
          'status': 'sent',
        },
      };

      final repo = MessagesRepositoryImpl(apiClient: mockApi);
      final sent = await repo.sendMessage(
        studentId: 'stud_1',
        message: 'Can we discuss grades?',
        subject: 'Inquiry',
      );

      expect(mockApi.lastPath, '/parent/children/stud_1/messages');
      expect(mockApi.lastPayload, {
        'message': 'Can we discuss grades?',
        'subject': 'Inquiry',
      });
      expect(sent.id, 'm_new');
    });

    test('markAsRead makes PATCH request to correct path', () async {
      final mockApi = MockApiClient();
      mockApi.responseData = {'success': true};

      final repo = MessagesRepositoryImpl(apiClient: mockApi);
      final success = await repo.markAsRead(
        studentId: 'stud_1',
        messageId: 'm_123',
      );

      expect(mockApi.lastPath, '/parent/children/stud_1/messages/m_123/read');
      expect(success, true);
    });
  });

  group('MessagesController tests', () {
    test('loadMessages transitions state to MessagesLoaded', () async {
      final fakeRepo = FakeMessagesRepository();
      fakeRepo.mockData = MessagesDataEntity(
        studentId: 'stud_1',
        studentName: 'Ram',
        messages: [
          MessageItemEntity(
            id: 'm1',
            senderRole: 'teacher',
            subject: 'Notes',
            message: 'Class notes attached',
            isRead: false,
            status: 'sent',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [messagesRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      final controller = container.read(messagesControllerProvider.notifier);
      expect(
        container.read(messagesControllerProvider),
        isA<MessagesInitial>(),
      );

      await controller.loadMessages(studentId: 'stud_1');

      final state = container.read(messagesControllerProvider);
      expect(state, isA<MessagesLoaded>());
      final loaded = state as MessagesLoaded;
      expect(loaded.studentId, 'stud_1');
      expect(loaded.data.messages.length, 1);
      expect(loaded.data.unreadCount, 1);
    });

    test('loadMessages transitions to MessagesError on exception', () async {
      final fakeRepo = FakeMessagesRepository()..shouldThrow = true;

      final container = ProviderContainer(
        overrides: [messagesRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      final controller = container.read(messagesControllerProvider.notifier);
      await controller.loadMessages(studentId: 'stud_1');

      final state = container.read(messagesControllerProvider);
      expect(state, isA<MessagesError>());
      expect((state as MessagesError).message, contains('API Error'));
    });

    test('markAllAsRead marks unread messages as read', () async {
      final fakeRepo = FakeMessagesRepository();
      fakeRepo.mockData = MessagesDataEntity(
        studentId: 'stud_1',
        studentName: 'Ram',
        messages: [
          MessageItemEntity(
            id: 'm1',
            senderRole: 'teacher',
            subject: 'Notes',
            message: 'Class notes',
            isRead: false,
            status: 'sent',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [messagesRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      final controller = container.read(messagesControllerProvider.notifier);
      await controller.loadMessages(studentId: 'stud_1');

      await controller.markAllAsRead();

      final state =
          container.read(messagesControllerProvider) as MessagesLoaded;
      expect(state.data.unreadCount, 0);
      expect(state.data.messages.first.isRead, true);
    });
  });

  group('ParentMessagesScreen Widget tests', () {
    testWidgets(
      'renders Messages screen and displays messages with real data',
      (tester) async {
        final fakeRepo = FakeMessagesRepository();
        fakeRepo.mockData = MessagesDataEntity(
          studentId: 'child_1',
          studentName: 'Ram Pearson',
          activeTeacher: const TeacherContactEntity(
            id: 'teacher_1',
            firstName: 'Elizabeth',
            lastName: 'Vance',
            department: 'Software Engineering',
          ),
          messages: [
            MessageItemEntity(
              id: 'msg_1',
              senderRole: 'teacher',
              subject: 'Inquiry',
              message: 'Welcome to Junior Foundation!',
              isRead: false,
              status: 'sent',
              createdAt: DateTime.now(),
              senderName: 'Elizabeth Vance',
            ),
          ],
        );

        final child = ChildEntity(
          studentId: 'child_1',
          firstName: 'Ram',
          lastName: 'Pearson',
          grade: '5',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              messagesRepositoryProvider.overrideWithValue(fakeRepo),
              childrenControllerProvider.overrideWith(
                () => FakeChildrenController(
                  ChildrenLoaded(children: [child], activeChildId: 'child_1'),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentMessagesScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Messages'), findsOneWidget);
        expect(find.text('Showing messages for Ram'), findsOneWidget);
        expect(find.text('Elizabeth Vance'), findsOneWidget);
        expect(find.text('Welcome to Junior Foundation!'), findsOneWidget);
        expect(find.text("You're all caught up!"), findsOneWidget);
      },
    );

    testWidgets('shows empty state when message list is empty', (tester) async {
      final fakeRepo = FakeMessagesRepository();
      fakeRepo.mockData = const MessagesDataEntity(
        studentId: 'child_1',
        studentName: 'Ram Pearson',
        messages: [],
      );

      final child = ChildEntity(
        studentId: 'child_1',
        firstName: 'Ram',
        lastName: 'Pearson',
        grade: '5',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            messagesRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(
              () => FakeChildrenController(
                ChildrenLoaded(children: [child], activeChildId: 'child_1'),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentMessagesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No messages yet for Ram Pearson'), findsOneWidget);
    });
  });
}
