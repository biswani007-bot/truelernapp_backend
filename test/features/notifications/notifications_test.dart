import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_notifications_screen.dart';
import 'package:truelearn/features/notifications/data/models/parent_notification_dto.dart';
import 'package:truelearn/features/notifications/data/repositories/parent_notifications_repository_impl.dart';
import 'package:truelearn/features/notifications/domain/entities/parent_notification_entity.dart';
import 'package:truelearn/features/notifications/domain/repositories/parent_notifications_repository.dart';
import 'package:truelearn/features/notifications/presentation/controllers/parent_notifications_controller.dart';
import 'package:truelearn/features/notifications/presentation/controllers/parent_notifications_state.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic responseData;
  bool shouldThrow = false;
  String? lastPath;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
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

class FakeParentNotificationsRepository
    implements ParentNotificationsRepository {
  List<ParentNotificationItemEntity> mockList = [];
  bool shouldThrow = false;
  int getNotificationsCalls = 0;
  Completer<List<ParentNotificationItemEntity>>? delayedCompleter;

  @override
  Future<List<ParentNotificationItemEntity>> getNotifications({
    String? childStudentId,
  }) async {
    getNotificationsCalls++;
    if (delayedCompleter != null) {
      return delayedCompleter!.future;
    }
    if (shouldThrow) throw Exception('API Error');
    return mockList;
  }
}

class _MockChildrenController extends ChildrenController {
  _MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;

  @override
  void setActiveChild(String studentId) {
    final current = state;
    if (current is ChildrenLoaded) {
      state = ChildrenLoaded(
        children: current.children,
        activeChildId: studentId,
      );
    }
  }
}

void main() {
  const childRony = ChildEntity(
    studentId: 'child_rony_id',
    firstName: 'Rony',
    lastName: 'Roul',
  );

  const childRam = ChildEntity(
    studentId: 'child_ram_id',
    firstName: 'Ram',
    lastName: 'Pearson',
  );

  const childSarah = ChildEntity(
    studentId: 'child_sarah_id',
    firstName: 'Sarah',
    lastName: 'Connor',
  );

  final testAllChildren = [childRony, childRam, childSarah];

  // Representative fixtures based on actual TrueLern backend API response
  final rawBackendFixtures = [
    {
      'id': 'notif_rony_1',
      'title': 'Message from Instructor Jack Sparrow',
      'content':
          'Instructor Jack Sparrow replied regarding Rony Roul: "hiiii dear"',
      'type': 'system',
      'createdAt': '2026-10-12T05:18:38.248Z',
    },
    {
      'id': 'notif_ram_1',
      'title': 'Message from Instructor Elizabeth Vance',
      'content': 'Instructor Elizabeth Vance replied regarding Ram Pearson: "hii"',
      'type': 'system',
      'createdAt': '2026-10-05T10:11:43.416Z',
    },
    {
      'id': 'notif_sarah_1',
      'title': 'Message from Instructor Elizabeth Vance',
      'content':
          'Instructor Elizabeth Vance replied regarding Sarah Connor: "Hope you doing well"',
      'type': 'system',
      'createdAt': '2026-09-29T10:37:15.343Z',
    },
    {
      'id': 'notif_parent_portal',
      'title': 'Welcome to TrueLern Parent Portal',
      'content':
          'You can now monitor classroom attendance, academic milestones, and live classes for your linked children.',
      'type': 'system',
      'createdAt': '2026-08-21T05:39:41.388Z',
    },
  ];

  group('ParentNotification DTO & Entity tests', () {
    test('ParentNotificationDto correctly parses json and maps category', () {
      final jsonLiveClass = {
        'id': 'notif_1',
        'title': 'Public Speaking Class starts soon',
        'content': 'Join early to test setup.',
        'type': 'live_class',
        'createdAt': '2026-10-06T10:00:00.000Z',
      };

      final dto1 = ParentNotificationDto.fromJson(jsonLiveClass);
      expect(dto1.id, 'notif_1');
      expect(dto1.title, 'Public Speaking Class starts soon');

      final entity1 = dto1.toEntity();
      expect(entity1.category, NotificationCategory.classes);

      final jsonAssignment = {
        'id': 'notif_2',
        'title': 'Practical Thinking assignment is due',
        'content': 'Submit before Friday.',
        'type': 'system',
      };
      final entity2 = ParentNotificationDto.fromJson(jsonAssignment).toEntity();
      expect(entity2.category, NotificationCategory.assignments);

      final jsonUpdate = {
        'id': 'notif_3',
        'title': 'Message from Instructor Elizabeth Vance',
        'content': 'Instructor Elizabeth Vance replied regarding Rony Roul: "hii"',
        'type': 'system',
      };
      final entity3 = ParentNotificationDto.fromJson(jsonUpdate).toEntity();
      expect(entity3.category, NotificationCategory.updates);
      expect(entity3.studentName, 'Rony Roul');
    });

    test('1 & 4. Scoping isolation: Rony sees only Rony and parent-wide items, NOT Ram or Sarah', () {
      final items = rawBackendFixtures
          .map((j) => ParentNotificationDto.fromJson(j).toEntity())
          .toList();

      final ronyItems = items
          .where((n) => n.belongsToChild(
                activeChild: childRony,
                allChildren: testAllChildren,
              ))
          .toList();

      expect(ronyItems.any((n) => n.id == 'notif_rony_1'), isTrue);
      expect(ronyItems.any((n) => n.id == 'notif_parent_portal'), isTrue);
      expect(ronyItems.any((n) => n.id == 'notif_ram_1'), isFalse);
      expect(ronyItems.any((n) => n.id == 'notif_sarah_1'), isFalse);
    });

    test('2 & 3. Switching to Ram loads Ram items, switching to Sarah loads Sarah items', () {
      final items = rawBackendFixtures
          .map((j) => ParentNotificationDto.fromJson(j).toEntity())
          .toList();

      final ramItems = items
          .where((n) => n.belongsToChild(
                activeChild: childRam,
                allChildren: testAllChildren,
              ))
          .toList();
      expect(ramItems.any((n) => n.id == 'notif_ram_1'), isTrue);
      expect(ramItems.any((n) => n.id == 'notif_parent_portal'), isTrue);
      expect(ramItems.any((n) => n.id == 'notif_rony_1'), isFalse);
      expect(ramItems.any((n) => n.id == 'notif_sarah_1'), isFalse);

      final sarahItems = items
          .where((n) => n.belongsToChild(
                activeChild: childSarah,
                allChildren: testAllChildren,
              ))
          .toList();
      expect(sarahItems.any((n) => n.id == 'notif_sarah_1'), isTrue);
      expect(sarahItems.any((n) => n.id == 'notif_parent_portal'), isTrue);
      expect(sarahItems.any((n) => n.id == 'notif_rony_1'), isFalse);
      expect(sarahItems.any((n) => n.id == 'notif_ram_1'), isFalse);
    });
  });

  group('ParentNotificationsRepositoryImpl tests', () {
    test('getNotifications calls /parent/notifications with childId parameter', () async {
      final mockApi = MockApiClient();
      mockApi.responseData = {
        'success': true,
        'message': 'Parent notifications retrieved successfully',
        'data': rawBackendFixtures,
      };

      final repo = ParentNotificationsRepositoryImpl(apiClient: mockApi);
      final list = await repo.getNotifications(childStudentId: 'child_rony_id');

      expect(mockApi.lastPath, '/parent/notifications');
      expect(mockApi.lastQueryParams?['childId'], 'child_rony_id');
      expect(list.length, 4);
    });
  });

  group('ParentNotificationsController tests', () {
    test('loadNotifications scopes notifications to active child', () async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = rawBackendFixtures
          .map((j) => ParentNotificationDto.fromJson(j).toEntity())
          .toList();

      final container = ProviderContainer(
        overrides: [
          parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
          childrenControllerProvider.overrideWith(
            () => _MockChildrenController(
              const ChildrenLoaded(
                children: [childRony, childRam, childSarah],
                activeChildId: 'child_rony_id',
              ),
            ),
          ),
        ],
      );

      final controller =
          container.read(parentNotificationsControllerProvider.notifier);
      await controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );

      final state = container.read(parentNotificationsControllerProvider);
      expect(state, isA<ParentNotificationsLoaded>());
      final loaded = state as ParentNotificationsLoaded;

      // Only Rony's and the parent-wide portal notification are present
      expect(loaded.notifications.length, 2);
      expect(loaded.notifications.map((n) => n.id),
          containsAll(['notif_rony_1', 'notif_parent_portal']));
      expect(loaded.notifications.any((n) => n.id == 'notif_ram_1'), isFalse);
      expect(loaded.notifications.any((n) => n.id == 'notif_sarah_1'), isFalse);
    });

    test('2 & 3. Switching children updates scoped notifications and switching back restores Rony', () async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = rawBackendFixtures
          .map((j) => ParentNotificationDto.fromJson(j).toEntity())
          .toList();

      final container = ProviderContainer(
        overrides: [
          parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller =
          container.read(parentNotificationsControllerProvider.notifier);

      // Load Rony
      await controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );
      var state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.notifications.map((n) => n.id),
          containsAll(['notif_rony_1', 'notif_parent_portal']));
      expect(state.childStudentId, childRony.studentId);

      // Switch to Ram
      await controller.loadNotifications(
        activeChild: childRam,
        allChildren: testAllChildren,
      );
      state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.notifications.map((n) => n.id),
          containsAll(['notif_ram_1', 'notif_parent_portal']));
      expect(state.childStudentId, childRam.studentId);
      expect(state.notifications.any((n) => n.id == 'notif_rony_1'), isFalse);

      // Switch back to Rony
      await controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );
      state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.notifications.map((n) => n.id),
          containsAll(['notif_rony_1', 'notif_parent_portal']));
      expect(state.childStudentId, childRony.studentId);
      expect(state.notifications.any((n) => n.id == 'notif_ram_1'), isFalse);
    });

    test('5. Category tabs filter scoped notifications correctly', () async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = [
        const ParentNotificationItemEntity(
          id: 'n_live',
          title: 'Math Live Class',
          content: 'Session for Rony',
          type: 'live_class',
          studentId: 'child_rony_id',
        ),
        const ParentNotificationItemEntity(
          id: 'n_assign',
          title: 'Science Assignment',
          content: 'Homework for Rony',
          type: 'assignment',
          studentId: 'child_rony_id',
        ),
        const ParentNotificationItemEntity(
          id: 'n_update',
          title: 'Teacher Feedback',
          content: 'Instructor replied regarding Rony Roul: "Good work"',
          type: 'system',
          studentId: 'child_rony_id',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller =
          container.read(parentNotificationsControllerProvider.notifier);
      await controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );

      controller.setTab('Classes');
      var state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, 'n_live');

      controller.setTab('Assignments');
      state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, 'n_assign');

      controller.setTab('Updates');
      state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, 'n_update');
    });

    test('6. Failed API requests trigger ParentNotificationsError and not false empty list', () async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.shouldThrow = true;

      final container = ProviderContainer(
        overrides: [
          parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller =
          container.read(parentNotificationsControllerProvider.notifier);
      await controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );

      final state = container.read(parentNotificationsControllerProvider);
      expect(state, isA<ParentNotificationsError>());
      final errorState = state as ParentNotificationsError;
      expect(errorState.message, contains('API Error'));
      expect(errorState.childStudentId, childRony.studentId);
    });

    test('7. Older in-flight response cannot overwrite currently selected child state', () async {
      final fakeRepo = FakeParentNotificationsRepository();
      final completer1 = Completer<List<ParentNotificationItemEntity>>();
      fakeRepo.delayedCompleter = completer1;

      final container = ProviderContainer(
        overrides: [
          parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller =
          container.read(parentNotificationsControllerProvider.notifier);

      // Start slow request for Rony
      final future1 = controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );

      // Fast switch to Ram with immediate response
      fakeRepo.delayedCompleter = null;
      fakeRepo.mockList = [
        const ParentNotificationItemEntity(
          id: 'ram_fast',
          title: 'Ram Update',
          content: 'Instructor replied regarding Ram Pearson: "Hello"',
          type: 'system',
        ),
      ];
      await controller.loadNotifications(
        activeChild: childRam,
        allChildren: testAllChildren,
      );

      var state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.childStudentId, childRam.studentId);
      expect(state.notifications.first.id, 'ram_fast');

      // Now slow request for Rony completes later
      completer1.complete([
        const ParentNotificationItemEntity(
          id: 'rony_slow',
          title: 'Rony Update',
          content: 'Instructor replied regarding Rony Roul: "Hi"',
          type: 'system',
        ),
      ]);
      await future1;

      // State MUST still remain Ram!
      state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.childStudentId, childRam.studentId);
      expect(state.notifications.first.id, 'ram_fast');
    });

    test('8. markAsRead updates notification state', () async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = [
        const ParentNotificationItemEntity(
          id: 'n_unread',
          title: 'Message',
          content: 'Instructor replied regarding Rony Roul: "hi"',
          type: 'system',
          isRead: false,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller =
          container.read(parentNotificationsControllerProvider.notifier);
      await controller.loadNotifications(
        activeChild: childRony,
        allChildren: testAllChildren,
      );

      var state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.notifications.first.isRead, isFalse);

      controller.markAsRead('n_unread');

      state = container.read(parentNotificationsControllerProvider)
          as ParentNotificationsLoaded;
      expect(state.notifications.first.isRead, isTrue);
    });
  });

  group('ParentNotificationsScreen Widget tests', () {
    testWidgets('renders Notifications screen with scoped items for active child', (tester) async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = [
        ParentNotificationItemEntity(
          id: 'n1',
          title: 'Your Public Speaking class starts in 15 minutes.',
          content: 'Join early to test setup.',
          type: 'live_class',
          studentId: 'child_rony_id',
          createdAt: DateTime.now(),
        ),
        ParentNotificationItemEntity(
          id: 'n_other',
          title: 'Other child class',
          content: 'Instructor replied regarding Ram Pearson: "Hi"',
          type: 'system',
          studentId: 'child_ram_id',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(
              () => _MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony, childRam],
                  activeChildId: 'child_rony_id',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ParentNotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('LIVE CLASS'), findsOneWidget);
      expect(find.text('Your Public Speaking class starts in 15 minutes.'),
          findsOneWidget);
      expect(find.text('View Classes'), findsOneWidget);

      // Other child's notification is NOT visible
      expect(find.text('Other child class'), findsNothing);
    });

    testWidgets('shows empty state when no items match tab', (tester) async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(
              () => _MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony_id',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ParentNotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No notifications in All'), findsOneWidget);
    });

    testWidgets('dynamic child switching updates notification feed without cross-child bleed', (tester) async {
      final fakeRepo = FakeParentNotificationsRepository();
      fakeRepo.mockList = rawBackendFixtures
          .map((j) => ParentNotificationDto.fromJson(j).toEntity())
          .toList();

      final childrenNotifier = _MockChildrenController(
        const ChildrenLoaded(
          children: [childRony, childRam, childSarah],
          activeChildId: 'child_rony_id',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parentNotificationsRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(() => childrenNotifier),
          ],
          child: const MaterialApp(
            home: ParentNotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Initial state (Rony active)
      expect(find.text('Message from Instructor Jack Sparrow'), findsOneWidget);
      expect(find.text('Message from Instructor Elizabeth Vance'), findsNothing);
      expect(find.text('Welcome to TrueLern Parent Portal'), findsOneWidget);

      // Step 2: Switch to Ram Pearson
      childrenNotifier.setActiveChild('child_ram_id');
      await tester.pumpAndSettle();

      expect(find.text('Message from Instructor Jack Sparrow'), findsNothing);
      expect(find.text('Message from Instructor Elizabeth Vance'), findsOneWidget);
      expect(find.text('Welcome to TrueLern Parent Portal'), findsOneWidget);

      // Step 3: Switch back to Rony
      childrenNotifier.setActiveChild('child_rony_id');
      await tester.pumpAndSettle();

      expect(find.text('Message from Instructor Jack Sparrow'), findsOneWidget);
      expect(find.text('Message from Instructor Elizabeth Vance'), findsNothing);
      expect(find.text('Welcome to TrueLern Parent Portal'), findsOneWidget);
    });
  });
}
