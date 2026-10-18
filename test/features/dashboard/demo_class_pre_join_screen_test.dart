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

class MockDevicePreviewService implements NativeDevicePreviewService {
  MockDevicePreviewService({
    this.permissions = const DevicePreviewPermissions(
      cameraGranted: true,
      microphoneGranted: true,
    ),
    this.frontCameraAvailable = true,
  });

  DevicePreviewPermissions permissions;
  bool frontCameraAvailable;

  int startCameraCalls = 0;
  int stopCameraCalls = 0;
  int openAppSettingsCalls = 0;
  int requestPermissionsCalls = 0;
  int checkPermissionsCalls = 0;

  @override
  Future<DevicePreviewPermissions> checkPermissions() async {
    checkPermissionsCalls++;
    return permissions;
  }

  @override
  Future<DevicePreviewPermissions> requestPermissions() async {
    requestPermissionsCalls++;
    return permissions;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCalls++;
  }

  @override
  Future<void> startCamera() async {
    startCameraCalls++;
  }

  @override
  Future<void> stopCamera() async {
    stopCameraCalls++;
  }

  @override
  Future<bool> isFrontCameraAvailable() async => frontCameraAvailable;
}

class FakeClassesRepository implements ClassesRepository {
  FakeClassesRepository({
    this.joinResult,
    this.joinError,
  });

  ClassJoinEntity? joinResult;
  Object? joinError;
  int joinCallCount = 0;

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async => [];

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    joinCallCount++;
    if (joinError != null) {
      throw joinError!;
    }
    return joinResult ??
        ClassJoinEntity(
          token: 'jwt-auth-token-123',
          roomName: 'room-demo-$classId',
          jitsiDomain: 'livetl.visital.in',
          serverUrl: 'https://livetl.visital.in',
          meetingUrl: 'https://livetl.visital.in/room-demo-$classId',
          isModerator: false,
          childId: childStudentId,
          classId: classId,
          classTitle: 'Demo Live Session',
        );
  }
}

class _FakeChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  _FakeChildrenController(this._initial);
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

  const testChild = ChildEntity(
    studentId: 'child-student-001',
    firstName: 'Tommy',
    lastName: 'Jenkins',
    grade: 'Grade 4',
  );

  Widget createSubject({
    required DemoBookingEntity booking,
    MockDevicePreviewService? mockDeviceService,
    FakeClassesRepository? fakeClassesRepo,
    ChildrenState? childrenState,
  }) {
    return ProviderScope(
      overrides: [
        devicePreviewServiceProvider.overrideWithValue(
          mockDeviceService ?? MockDevicePreviewService(),
        ),
        classesRepositoryProvider.overrideWithValue(
          fakeClassesRepo ?? FakeClassesRepository(),
        ),
        childrenControllerProvider.overrideWith(
          () => _FakeChildrenController(
            childrenState ??
                const ChildrenLoaded(
                  children: [testChild],
                  activeChildId: 'child-student-001',
                ),
          ),
        ),
      ],
      child: MaterialApp(
        home: DemoClassPreJoinScreen(booking: booking),
      ),
    );
  }

  group('DemoClassPreJoinScreen Widget Tests', () {
    testWidgets(
      'Case 7: Displays correct booking and participant verification details',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Eligible start time (within 15-minute window)
        final eligibleStart = DateTime.now().add(const Duration(minutes: 5));
        final booking = DemoBookingEntity(
          bookingId: 'demo-live-001',
          demoCode: 'DEMO-847291',
          courseName: 'ACE Public Speaking',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: eligibleStart,
          teacherName: 'Ms. Sarah Jenkins',
          status: 'scheduled',
        );

        await tester.pumpWidget(createSubject(booking: booking));
        await tester.pumpAndSettle();

        // Header & Session title
        expect(find.byKey(const Key('demo_pre_join_title')), findsOneWidget);
        expect(find.text('ACE Public Speaking'), findsOneWidget);
        expect(find.text('Ready to Join • Entry Open'), findsOneWidget);

        // Participant Information
        expect(find.text('Enrolled Student: Tommy Jenkins'), findsOneWidget);
        expect(find.text('Faculty: Ms. Sarah Jenkins'), findsOneWidget);
        expect(find.text('Booking Reference: DEMO-847291'), findsOneWidget);
        expect(find.text('Verified Ward'), findsOneWidget);

        // Device Check
        expect(find.text('Device Check'), findsOneWidget);
        expect(find.text('Microphone'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Speaker'), findsOneWidget);
      },
    );

    testWidgets(
      'Case 8 & 9: Camera and microphone toggles update visible control states',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockDeviceService = MockDevicePreviewService();
        final eligibleStart = DateTime.now().add(const Duration(minutes: 10));
        final booking = DemoBookingEntity(
          bookingId: 'demo-toggle-001',
          courseName: 'Coding Fundamentals',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: eligibleStart,
          status: 'scheduled',
        );

        await tester.pumpWidget(
          createSubject(
            booking: booking,
            mockDeviceService: mockDeviceService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Camera On'), findsOneWidget);

        // 1. Toggle camera off
        await tester.tap(find.byKey(const Key('demo_pre_join_camera_toggle')));
        await tester.pumpAndSettle();

        expect(find.text('Camera Off'), findsOneWidget);
        expect(find.text('Camera is turned off'), findsOneWidget);
        expect(mockDeviceService.stopCameraCalls, greaterThanOrEqualTo(1));

        // 2. Toggle mic off
        await tester.tap(find.byKey(const Key('demo_pre_join_mic_toggle')));
        await tester.pumpAndSettle();

        // Device check shows Turned Off
        expect(find.text('Turned Off'), findsWidgets);
      },
    );

    testWidgets(
      'Case 8b: Denied permissions shows grant permission view',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockDeviceService = MockDevicePreviewService(
          permissions: const DevicePreviewPermissions(
            cameraGranted: false,
            microphoneGranted: false,
          ),
        );

        final eligibleStart = DateTime.now().add(const Duration(minutes: 5));
        final booking = DemoBookingEntity(
          bookingId: 'demo-perm-denied',
          courseName: 'Math Olympiad',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: eligibleStart,
          status: 'scheduled',
        );

        await tester.pumpWidget(
          createSubject(
            booking: booking,
            mockDeviceService: mockDeviceService,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('camera_permission_denied_view')),
          findsOneWidget,
        );
        expect(find.text('Grant Permission'), findsOneWidget);
      },
    );

    testWidgets(
      'Case 12: Repeated button taps do not produce duplicate join requests',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeClassesRepo = FakeClassesRepository();
        final eligibleStart = DateTime.now().add(const Duration(minutes: 5));
        final booking = DemoBookingEntity(
          bookingId: 'demo-dedup-001',
          courseName: 'Public Speaking',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: eligibleStart,
          status: 'scheduled',
        );

        await tester.pumpWidget(
          createSubject(
            booking: booking,
            fakeClassesRepo: fakeClassesRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Join multiple times rapidly
        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pump();

        expect(fakeClassesRepo.joinCallCount, equals(1));
      },
    );

    testWidgets(
      'Case 10 & 13: Unauthorized or API failure displays useful in-app feedback',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeClassesRepo = FakeClassesRepository(
          joinError: const ServerFailure(
            'Access denied. Participant is not authorized for this demo class.',
            statusCode: 403,
          ),
        );

        final eligibleStart = DateTime.now().add(const Duration(minutes: 5));
        final booking = DemoBookingEntity(
          bookingId: 'demo-unauthorized',
          courseName: 'Public Speaking',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: eligibleStart,
          status: 'scheduled',
        );

        await tester.pumpWidget(
          createSubject(
            booking: booking,
            fakeClassesRepo: fakeClassesRepo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Access denied. Participant is not authorized for this demo class.'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Case 11: Attempting to join expired or cancelled session shows error and blocks join',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeClassesRepo = FakeClassesRepository();

        // Expired booking (ended 1 hour ago)
        final expiredBooking = DemoBookingEntity(
          bookingId: 'demo-expired',
          courseName: 'Public Speaking',
          studentName: 'Tommy Jenkins',
          studentId: 'child-student-001',
          startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'scheduled',
        );

        await tester.pumpWidget(
          createSubject(
            booking: expiredBooking,
            fakeClassesRepo: fakeClassesRepo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('demo_join_classroom_button')));
        await tester.pumpAndSettle();

        expect(fakeClassesRepo.joinCallCount, equals(0));
        expect(find.text('This demo session has already concluded.'), findsOneWidget);
      },
    );
  });
}
