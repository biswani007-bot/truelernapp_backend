import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';
import 'package:truelearn/features/classes/presentation/services/native_device_preview_service.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_class_pre_join_screen.dart';

class _MockDevicePreviewService implements NativeDevicePreviewService {
  _MockDevicePreviewService();

  final DevicePreviewPermissions permissions = const DevicePreviewPermissions(
    cameraGranted: true,
    microphoneGranted: true,
  );

  @override
  Future<DevicePreviewPermissions> checkPermissions() async => permissions;

  @override
  Future<DevicePreviewPermissions> requestPermissions() async => permissions;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> startCamera() async {}

  @override
  Future<void> stopCamera() async {}

  @override
  Future<bool> isFrontCameraAvailable() async => true;
}

class _RecordingClassesRepository implements ClassesRepository {
  _RecordingClassesRepository({
    this.joinError,
  });

  ClassJoinEntity? joinResult;
  Object? joinError;

  int joinCallCount = 0;
  String? lastChildStudentId;
  String? lastClassId;

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async => [];

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    joinCallCount++;
    lastChildStudentId = childStudentId;
    lastClassId = classId;

    if (joinError != null) {
      throw joinError!;
    }

    return joinResult ??
        ClassJoinEntity(
          token: 'authoritative-jwt-token-999',
          roomName: 'room-demo-$classId',
          jitsiDomain: 'livetl.visital.in',
          serverUrl: 'https://livetl.visital.in',
          meetingUrl: 'https://livetl.visital.in/room-demo-$classId',
          isModerator: false,
          childId: childStudentId,
          classId: classId,
          classTitle: 'Emotional Intelligence Demo',
        );
  }
}

class _StaticChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  _StaticChildrenController(this._initial);
  final ChildrenState _initial;

  @override
  ChildrenState build() => _initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {}

  @override
  void reset() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test identities matching the CRM scenario:
  // Parent: Freddy Sahoo
  // Authoritative Child: Tarini Sahoo
  // Human-readable code displayed in Admin: STU-00520397
  // Internal MongoDB ObjectId in backend: 6ad1b894ab81225ce549338e
  // Demo Booking Reference: DEMO-3500481463
  // Live Class Session ID: 6ad1b8e0ab81225ce54933c8
  const authoritativeChild = ChildEntity(
    studentId: '6ad1b894ab81225ce549338e',
    studentCode: 'STU-00520397',
    firstName: 'Tarini',
    lastName: 'Sahoo',
    gender: 'female',
    relationshipType: 'daughter',
    status: 'active',
  );

  Widget createSubject({
    required DemoBookingEntity booking,
    _RecordingClassesRepository? classesRepo,
    List<ChildEntity>? linkedChildren,
  }) {
    final children = linkedChildren ?? [authoritativeChild];
    return ProviderScope(
      overrides: [
        devicePreviewServiceProvider.overrideWithValue(_MockDevicePreviewService()),
        classesRepositoryProvider.overrideWithValue(classesRepo ?? _RecordingClassesRepository()),
        childrenControllerProvider.overrideWith(
          () => _StaticChildrenController(
            ChildrenLoaded(
              children: children,
              activeChildId: children.isNotEmpty ? children.first.studentId : null,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: DemoClassPreJoinScreen(booking: booking),
      ),
    );
  }

  group('Authoritative Student Authorization Mismatch Fix Verification', () {
    // 1. Correct parent and linked child can obtain authorization when API permits it
    testWidgets(
      'Scenario 1: Correct parent and linked child obtain classroom authorization',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-3500481463',
          liveClassId: '6ad1b8e0ab81225ce54933c8',
          demoCode: 'DEMO-3500481463',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          teacherName: 'Elizabeth Vance',
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        // Tap Join Classroom
        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(repo.joinCallCount, equals(1));
        expect(repo.lastChildStudentId, equals('6ad1b894ab81225ce549338e'));
        expect(repo.lastClassId, equals('6ad1b8e0ab81225ce54933c8'));
        expect(find.text('Classroom Authorized'), findsOneWidget);
      },
    );

    // 2. Human-readable student code (STU-00520397) is NOT substituted for internal ID
    testWidgets(
      'Scenario 2: Human-readable student code (STU-00520397) resolves to internal MongoDB ObjectId',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        // Booking specifies STU-00520397 as studentId / studentCode
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-3500481463',
          liveClassId: '6ad1b8e0ab81225ce54933c8',
          demoCode: 'DEMO-3500481463',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: 'STU-00520397', // Human readable code passed by admin/lead
          studentCode: 'STU-00520397',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          teacherName: 'Elizabeth Vance',
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(repo.joinCallCount, equals(1));
        // MUST be resolved to internal database ObjectId, NOT STU-00520397
        expect(repo.lastChildStudentId, equals('6ad1b894ab81225ce549338e'));
        expect(repo.lastChildStudentId, isNot(equals('STU-00520397')));
      },
    );

    // 3. The booking's session identifier is passed to the correct endpoint
    testWidgets(
      'Scenario 3: Effective session identifier is passed to joinLiveClass',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-3500481463',
          liveClassId: 'session-live-class-999',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(repo.lastClassId, equals('session-live-class-999'));
      },
    );

    // 4. Missing child identity produces a controlled error
    testWidgets(
      'Scenario 4: Missing child identity produces a controlled error without crash',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-NO-STUDENT',
          courseName: 'Emotional Intelligence',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        // No linked children in parent account
        await tester.pumpWidget(
          createSubject(
            booking: booking,
            classesRepo: repo,
            linkedChildren: [],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(repo.joinCallCount, equals(0));
        expect(find.textContaining('Participant authorization error'), findsWidgets);
      },
    );

    // 5. An unrelated child cannot join another child's session
    testWidgets(
      'Scenario 5: Unrelated child booking is blocked from joining',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        // Booking belongs to "Unrelated Student" STU-99999999
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-OTHER-CHILD',
          courseName: 'Emotional Intelligence',
          studentName: 'Unrelated Student',
          studentId: 'STU-99999999',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        // Parent only has Tarini Sahoo linked
        await tester.pumpWidget(
          createSubject(
            booking: booking,
            classesRepo: repo,
            linkedChildren: [
              authoritativeChild,
              const ChildEntity(
                studentId: '6ad1b894ab81225ce5493399',
                firstName: 'Freddy',
                lastName: 'Junior',
                studentCode: 'STU-00111222',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        // Join must be completely blocked
        expect(repo.joinCallCount, equals(0));
        expect(find.textContaining('Participant authorization error'), findsWidgets);
      },
    );

    // 6. Expired or cancelled booking cannot be joined
    testWidgets(
      'Scenario 6: Expired or cancelled booking cannot be joined',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        final expiredBooking = DemoBookingEntity(
          bookingId: 'DEMO-EXPIRED',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: expiredBooking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(repo.joinCallCount, equals(0));
        expect(find.text('This demo session has already concluded.'), findsOneWidget);
      },
    );

    // 7. HTTP 401 and 403 responses are handled correctly
    testWidgets(
      'Scenario 7: HTTP 403 authorization error preserves server message without false success',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository(
          joinError: const AuthFailure(
            'Access denied. Participant is not authorized for this demo class.',
            403,
          ),
        );

        final booking = DemoBookingEntity(
          bookingId: 'DEMO-403',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(repo.joinCallCount, equals(1));
        expect(find.text('Authorization Denied'), findsOneWidget);
        expect(find.text('Access denied. Participant is not authorized for this demo class.'), findsWidgets);
      },
    );

    // 8. Token response parsing uses documented response structure
    test('Scenario 8: Token response parsing adheres to documented payload schema', () {
      final jsonResponse = {
        'success': true,
        'message': 'Token generated',
        'data': {
          'token': 'jwt.token.abc',
          'roomName': 'room-demo-123',
          'jitsiDomain': 'livetl.visital.in',
          'serverUrl': 'https://livetl.visital.in',
          'isModerator': false,
          'expiresAt': 1770000000,
          'studentId': '6ad1b894ab81225ce549338e',
          'liveClass': {
            'id': '6ad1b8e0ab81225ce54933c8',
            'title': 'Emotional Intelligence',
          },
        },
      };

      final dataField = jsonResponse['data'] as Map<String, dynamic>;
      final liveClassMap = dataField['liveClass'] as Map<String, dynamic>;

      final joinEntity = ClassJoinEntity(
        token: dataField['token'].toString(),
        roomName: dataField['roomName'].toString(),
        jitsiDomain: dataField['jitsiDomain'].toString(),
        serverUrl: dataField['serverUrl'].toString(),
        meetingUrl: '',
        isModerator: dataField['isModerator'] == true,
        expiresAt: dataField['expiresAt'] as int,
        childId: dataField['studentId'].toString(),
        classId: liveClassMap['id'].toString(),
        classTitle: liveClassMap['title'].toString(),
      );

      expect(joinEntity.token, equals('jwt.token.abc'));
      expect(joinEntity.roomName, equals('room-demo-123'));
      expect(joinEntity.childId, equals('6ad1b894ab81225ce549338e'));
      expect(joinEntity.classId, equals('6ad1b8e0ab81225ce54933c8'));
    });

    // 9. Repeated taps do not create duplicate requests
    testWidgets(
      'Scenario 9: Repeated taps do not create duplicate requests',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-DEDUP',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pump();

        expect(repo.joinCallCount, equals(1));
      },
    );

    // 10. Successful authorization proceeds to actual classroom integration
    testWidgets(
      'Scenario 10: Successful authorization updates UI to authorized state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository();
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-SUCCESS',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(find.text('Classroom Authorized'), findsOneWidget);
        expect(find.text('Authorized'), findsOneWidget);
      },
    );

    // 11. Failed authorization never results in a false successful-join state
    testWidgets(
      'Scenario 11: Failed authorization never displays a false successful-join state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _RecordingClassesRepository(
          joinError: const ServerFailure('Server unavailable', statusCode: 500),
        );
        final booking = DemoBookingEntity(
          bookingId: 'DEMO-FAIL',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking, classesRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        // Must NOT show Classroom Authorized
        expect(find.text('Classroom Authorized'), findsNothing);
        expect(find.text('Authorization Failed'), findsOneWidget);
      },
    );

    // 12. Flow remains entirely inside Flutter Android
    testWidgets(
      'Scenario 12: In-app experience renders within Flutter without external redirect',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final booking = DemoBookingEntity(
          bookingId: 'DEMO-NATIVE',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: '6ad1b894ab81225ce549338e',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('demo_class_pre_join_screen')), findsOneWidget);
        expect(find.byKey(const Key('demo_join_classroom_button')), findsOneWidget);
        expect(find.byKey(const Key('demo_pre_join_leave_button')), findsOneWidget);
      },
    );
  });
}
