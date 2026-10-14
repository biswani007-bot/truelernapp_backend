import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/screens/class_preview_screen.dart';
import 'package:truelearn/features/classes/presentation/services/native_device_preview_service.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sarah = ChildEntity(
    studentId: 'sarah-student-id-001',
    firstName: 'Sarah',
    lastName: 'Connor',
    grade: 'Grade 3',
  );

  final testSession = ClassEntity(
    id: 'class-word-puzzle-999',
    title: 'Word Puzzle',
    subject: 'Junior Foundation',
    status: 'LIVE',
    teacherName: 'Elizabeth Vance',
  );

  Widget createSubject({
    required MockDevicePreviewService mockService,
    ChildEntity activeChild = sarah,
    ClassEntity? session,
  }) {
    return ProviderScope(
      overrides: [
        devicePreviewServiceProvider.overrideWithValue(mockService),
        childrenControllerProvider.overrideWith(
          () => _StaticChildrenController(
            ChildrenLoaded(
              children: [activeChild],
              activeChildId: activeChild.studentId,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: ClassPreviewScreen(
          classId: session?.id ?? testSession.id,
          session: session ?? testSession,
        ),
      ),
    );
  }

  group('Real Camera & Microphone Preview (Phase 12 Tests)', () {
    testWidgets('1. Both permissions granted initializes real camera preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockDevicePreviewService(
        permissions: const DevicePreviewPermissions(
          cameraGranted: true,
          microphoneGranted: true,
        ),
      );

      await tester.pumpWidget(createSubject(mockService: mockService));
      await tester.pumpAndSettle();

      // Native AndroidView platform view must be rendered instead of fake image asset
      expect(
        find.byKey(const Key('native_camera_preview_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('camera_permission_required_view')),
        findsNothing,
      );
      expect(find.text('Camera is Turned Off'), findsNothing);

      // Verify no static fake figma image asset is used as the camera feed
      final imageFinders = find.byType(Image);
      for (final candidate in tester.widgetList<Image>(imageFinders)) {
        if (candidate.image is AssetImage) {
          final asset = candidate.image as AssetImage;
          expect(
            asset.assetName,
            isNot(equals('assets/images/figma_webcam_feed.png')),
          );
        }
      }

      // Device Check shows Connected and Ready
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(mockService.startCameraCalls, greaterThanOrEqualTo(1));
    });

    testWidgets(
      '2. Camera permission denied shows permission required UI and halts camera preview',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService(
          permissions: const DevicePreviewPermissions(
            cameraGranted: false,
            microphoneGranted: true,
          ),
        );

        await tester.pumpWidget(createSubject(mockService: mockService));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('camera_permission_required_view')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('native_camera_preview_view')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('camera_grant_permission_button')),
          findsOneWidget,
        );

        // Device Check reflects Permission Required for Camera
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget); // Mic is still granted
      },
    );

    testWidgets(
      '3. Microphone permission denied reflects Permission Required in Device Check',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService(
          permissions: const DevicePreviewPermissions(
            cameraGranted: true,
            microphoneGranted: false,
          ),
        );

        await tester.pumpWidget(createSubject(mockService: mockService));
        await tester.pumpAndSettle();

        // Camera preview is active
        expect(
          find.byKey(const Key('native_camera_preview_view')),
          findsOneWidget,
        );

        // Device Check reflects Microphone Permission Required
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Both permissions denied shows Camera Permission Required and both warnings',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService(
          permissions: const DevicePreviewPermissions(
            cameraGranted: false,
            microphoneGranted: false,
          ),
        );

        await tester.pumpWidget(createSubject(mockService: mockService));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('camera_permission_required_view')),
          findsOneWidget,
        );
        expect(find.text('Permission Required'), findsNWidgets(2));
      },
    );

    testWidgets(
      '5. Camera toggle OFF disables stream and shows disabled view',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService();

        await tester.pumpWidget(createSubject(mockService: mockService));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('native_camera_preview_view')),
          findsOneWidget,
        );

        // Tap camera toggle button
        await tester.tap(find.byKey(const Key('preview_camera_toggle')));
        await tester.pumpAndSettle();

        // Camera stream is replaced by disabled view
        expect(
          find.byKey(const Key('native_camera_preview_view')),
          findsNothing,
        );
        expect(find.byKey(const Key('camera_turned_off_view')), findsOneWidget);
        expect(find.text('Camera is Turned Off'), findsOneWidget);
        expect(mockService.stopCameraCalls, greaterThanOrEqualTo(1));

        // Device Check reflects Turned Off
        expect(find.text('Turned Off'), findsOneWidget);

        // Tap camera toggle button again to re-enable
        await tester.tap(find.byKey(const Key('preview_camera_toggle')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('native_camera_preview_view')),
          findsOneWidget,
        );
        expect(find.text('Connected'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Microphone toggle updates visual mute state and synchronizes Device Check',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService();

        await tester.pumpWidget(createSubject(mockService: mockService));
        await tester.pumpAndSettle();

        // Initial state: Mic ON -> Ready with checkmark
        expect(
          find.byIcon(Icons.mic_rounded),
          findsNWidgets(2),
        ); // Preview toggle + Device check row
        expect(find.text('Ready'), findsOneWidget);
        expect(
          find.byIcon(Icons.check_circle_rounded),
          findsNWidgets(3),
        ); // Mic, Cam, Speaker

        // Toggle mic OFF
        await tester.tap(find.byKey(const Key('preview_mic_toggle')));
        await tester.pumpAndSettle();

        // Muted state: Mic OFF -> Turned Off with neutral minus icon
        expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
        expect(find.text('Ready'), findsNothing);
        expect(find.text('Turned Off'), findsOneWidget);
        expect(
          find.byIcon(Icons.remove_circle_outline_rounded),
          findsOneWidget,
        );
        expect(
          find.byIcon(Icons.check_circle_rounded),
          findsNWidgets(2),
        ); // Cam and Speaker still OK

        // Toggle mic back ON
        await tester.tap(find.byKey(const Key('preview_mic_toggle')));
        await tester.pumpAndSettle();

        // Restored state: Mic ON -> Ready with checkmark
        expect(find.byIcon(Icons.mic_rounded), findsNWidgets(2));
        expect(find.text('Ready'), findsOneWidget);
        expect(find.text('Turned Off'), findsNothing);
        expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
      },
    );

    testWidgets('7. Screen disposal invokes stopCamera on native service', (
      tester,
    ) async {
      final mockService = MockDevicePreviewService();

      await tester.pumpWidget(createSubject(mockService: mockService));
      await tester.pumpAndSettle();

      // Replace screen with placeholder to trigger dispose
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(mockService.stopCameraCalls, greaterThanOrEqualTo(1));
    });

    testWidgets(
      '8. Active child name appears dynamically in floating presence pill',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService();

        await tester.pumpWidget(
          createSubject(
            mockService: mockService,
            activeChild: const ChildEntity(
              studentId: 'ram-123',
              firstName: 'Ram',
              lastName: 'Verma',
              grade: 'Grade 5',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ram Verma'), findsOneWidget);
        expect(find.text('Alex Rivera'), findsNothing);
        expect(find.text('Sarah Connor'), findsNothing);
      },
    );

    testWidgets('9. JOIN LIVE CLASS blocks navigation if permissions denied', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockDevicePreviewService(
        permissions: const DevicePreviewPermissions(
          cameraGranted: false,
          microphoneGranted: false,
        ),
      );

      await tester.pumpWidget(createSubject(mockService: mockService));
      await tester.pumpAndSettle();

      final joinBtn = find.byKey(const Key('preview_join_live_class_button'));
      await tester.scrollUntilVisible(
        joinBtn,
        200,
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(joinBtn);
      await tester.pump();

      // Verify snackbar is shown explaining permission requirement
      expect(
        find.text(
          'Camera and microphone permissions are required to join the live class.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      '10. Multi-child context isolation: does not leak state across children',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockDevicePreviewService();

        // Mount screen for Sarah
        await tester.pumpWidget(
          createSubject(
            mockService: mockService,
            activeChild: const ChildEntity(
              studentId: 'sarah-001',
              firstName: 'Sarah',
              lastName: 'Connor',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sarah Connor'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);

        // Sarah turns mic OFF
        await tester.tap(find.byKey(const Key('preview_mic_toggle')));
        await tester.pumpAndSettle();
        expect(find.text('Turned Off'), findsOneWidget);

        // Now open preview for Ram
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          createSubject(
            mockService: mockService,
            activeChild: const ChildEntity(
              studentId: 'ram-002',
              firstName: 'Ram',
              lastName: 'Verma',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ram has fresh clean preview with Ram's name and independent Ready state
        expect(find.text('Ram Verma'), findsOneWidget);
        expect(find.text('Sarah Connor'), findsNothing);
        expect(find.text('Ready'), findsOneWidget);
      },
    );
  });
}
