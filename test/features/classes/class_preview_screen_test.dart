import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/screens/class_preview_screen.dart';

import 'package:truelearn/features/classes/presentation/services/native_device_preview_service.dart';

class _MockDevicePreviewService implements NativeDevicePreviewService {
  @override
  Future<DevicePreviewPermissions> checkPermissions() async {
    return const DevicePreviewPermissions(
      cameraGranted: true,
      microphoneGranted: true,
    );
  }

  @override
  Future<DevicePreviewPermissions> requestPermissions() async {
    return const DevicePreviewPermissions(
      cameraGranted: true,
      microphoneGranted: true,
    );
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> startCamera() async {}

  @override
  Future<void> stopCamera() async {}

  @override
  Future<bool> isFrontCameraAvailable() async => true;
}

void main() {
  Widget createSubject({ClassEntity? session}) {
    return ProviderScope(
      overrides: [
        devicePreviewServiceProvider.overrideWithValue(
          _MockDevicePreviewService(),
        ),
      ],
      child: MaterialApp(
        home: ClassPreviewScreen(
          classId: session?.id ?? 'preview_1',
          session: session,
        ),
      ),
    );
  }

  testWidgets('renders Figma 76:3154 Class Preview components', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const session = ClassEntity(
      id: 'preview_1',
      title: 'Speaking With Confidence',
      subject: 'Communication',
      status: 'SCHEDULED',
      teacherName: 'Sarah Jenkins',
    );

    await tester.pumpWidget(createSubject(session: session));
    await tester.pumpAndSettle();

    // 1. Top App Bar
    expect(find.text('Class Preview'), findsOneWidget);
    expect(find.byKey(const Key('class_preview_back_button')), findsOneWidget);

    // 2. Hero Card
    expect(find.text('Communication'), findsOneWidget);
    expect(find.text('Speaking With Confidence'), findsOneWidget);
    expect(find.text('Teacher: Sarah Jenkins'), findsOneWidget);

    // 3. Camera Preview Section
    expect(find.text('Camera Preview'), findsOneWidget);
    expect(find.byKey(const Key('preview_mic_toggle')), findsOneWidget);
    expect(find.byKey(const Key('preview_camera_toggle')), findsOneWidget);

    // 4. Device Check
    expect(find.text('Device Check'), findsOneWidget);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Speaker'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));

    // 5. Actions
    final joinBtn = find.byKey(const Key('preview_join_live_class_button'));
    final testAudioBtn = find.byKey(const Key('preview_test_audio_button'));
    await tester.scrollUntilVisible(
      joinBtn,
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(joinBtn, findsOneWidget);
    expect(testAudioBtn, findsOneWidget);
    expect(find.text('JOIN LIVE CLASS'), findsOneWidget);
    expect(find.text('Test Audio'), findsOneWidget);
  });

  testWidgets('tapping camera and mic toggles updates state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Toggle camera off
    await tester.tap(find.byKey(const Key('preview_camera_toggle')));
    await tester.pump();
    expect(find.text('Camera is Turned Off'), findsOneWidget);

    // Toggle camera back on
    await tester.tap(find.byKey(const Key('preview_camera_toggle')));
    await tester.pump();
    expect(find.text('Camera is Turned Off'), findsNothing);

    // Toggle mic off
    await tester.tap(find.byKey(const Key('preview_mic_toggle')));
    await tester.pump();
    expect(
      find.text('Turned Off'),
      findsOneWidget,
    ); // Mic Device Check shows Turned Off

    // Toggle mic back on
    await tester.tap(find.byKey(const Key('preview_mic_toggle')));
    await tester.pump();
    expect(find.text('Turned Off'), findsNothing);
    expect(
      find.text('Ready'),
      findsOneWidget,
    ); // Mic Device Check shows Ready again
  });
}
