import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/screens/class_details_screen.dart';
import 'package:truelearn/features/classes/presentation/screens/class_preview_screen.dart';
import 'package:truelearn/features/classes/presentation/screens/joining_class_screen.dart';
import 'package:truelearn/features/classes/presentation/services/native_device_preview_service.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class _MockClassesController extends Notifier<ClassesState>
    implements ClassesController {
  _MockClassesController(this._initial);
  final ClassesState _initial;

  @override
  ClassesState build() => _initial;

  @override
  Future<void> loadClasses({
    required String? childStudentId,
    bool isRefresh = false,
  }) async {}

  @override
  Future<void> retry() async {}

  @override
  void reset() {}
}

class _MockChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  _MockChildrenController(this._initial);
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 2 & 3 — ClassEntity Countdown & Entry Restriction Logic', () {
    final baseTime = DateTime(2026, 10, 12, 18, 30); // 6:30 PM

    test('1. Start 90 minutes away -> formatCountdown displays "Class is starting in 1 hour 30 minutes"', () {
      final session = ClassEntity(
        id: 'cls-90m',
        title: 'what is FUTURE?',
        scheduledStartTime: baseTime.add(
          const Duration(minutes: 90),
        ), // 8:00 PM
        scheduledEndTime: baseTime.add(const Duration(minutes: 150)),
        status: 'upcoming',
      );

      final countdown = session.formatCountdown(baseTime);
      expect(countdown, 'Class is starting in 1 hour 30 minutes');
    });

    test('2. Start 30 minutes away -> formatCountdown displays "Class is starting in 30 minutes"', () {
      final session = ClassEntity(
        id: 'cls-30m',
        title: 'test9',
        scheduledStartTime: baseTime.add(const Duration(minutes: 30)),
        scheduledEndTime: baseTime.add(const Duration(minutes: 90)),
        status: 'upcoming',
      );

      final countdown = session.formatCountdown(baseTime);
      expect(countdown, 'Class is starting in 30 minutes');
    });

    test('3. Start 16 minutes away -> entry blocked', () {
      final startTime = DateTime(2026, 10, 12, 20, 0); // 8:00 PM
      final checkTime = DateTime(
        2026,
        10,
        12,
        19,
        44,
      ); // 7:44 PM (16 minutes away)
      final session = ClassEntity(
        id: 'cls-16m',
        title: 'what is FUTURE?',
        scheduledStartTime: startTime,
        status: 'upcoming',
      );

      expect(session.isWithinEntryWindow(checkTime), isFalse);
      expect(session.canEnterLiveClass(checkTime), isFalse);
      expect(
        session.formatCountdown(checkTime),
        'Class is starting in 16 minutes',
      );
    });

    test('4. Start 15 minutes away -> entry permitted, subject to existing class eligibility', () {
      final startTime = DateTime(2026, 10, 12, 20, 0); // 8:00 PM
      final checkTime = DateTime(
        2026,
        10,
        12,
        19,
        45,
      ); // 7:45 PM (15 minutes away)
      final session = ClassEntity(
        id: 'cls-15m',
        title: 'what is FUTURE?',
        scheduledStartTime: startTime,
        status: 'upcoming',
      );

      expect(session.isWithinEntryWindow(checkTime), isTrue);
      expect(session.canEnterLiveClass(checkTime), isTrue);
      expect(
        session.formatCountdown(checkTime),
        'Class is starting in 15 minutes',
      );
    });

    test('5. Start 14 minutes away -> entry permitted, subject to existing class eligibility', () {
      final startTime = DateTime(2026, 10, 12, 20, 0); // 8:00 PM
      final checkTime = DateTime(
        2026,
        10,
        12,
        19,
        46,
      ); // 7:46 PM (14 minutes away)
      final session = ClassEntity(
        id: 'cls-14m',
        title: 'what is FUTURE?',
        scheduledStartTime: startTime,
        status: 'upcoming',
      );

      expect(session.isWithinEntryWindow(checkTime), isTrue);
      expect(session.canEnterLiveClass(checkTime), isTrue);
      expect(
        session.formatCountdown(checkTime),
        'Class is starting in 14 minutes',
      );
    });

    test('6. Start time has passed -> no stale positive countdown', () {
      final startTime = DateTime(2026, 10, 12, 20, 0);
      final checkTime = DateTime(2026, 10, 12, 20, 5); // 5 minutes past start
      final session = ClassEntity(
        id: 'cls-passed',
        title: 'Past Class',
        scheduledStartTime: startTime,
        scheduledEndTime: DateTime(2026, 10, 12, 21, 0),
        status: 'upcoming',
      );

      // formatCountdown must return null
      expect(session.formatCountdown(checkTime), isNull);
      // Entry remains permitted while class is ongoing
      expect(session.canEnterLiveClass(checkTime), isTrue);
    });

    test(
      '7. UTC/offset timestamp converts correctly to the scheduled local time',
      () {
        // Backend returns UTC timestamp 2026-10-12T14:30:00.000Z
        final utcStart = DateTime.parse('2026-10-12T14:30:00.000Z');
        final session = ClassEntity(
          id: 'cls-utc',
          title: 'UTC Class',
          scheduledStartTime: utcStart,
          status: 'upcoming',
        );

        // 90 minutes before UTC start: 13:00 UTC
        final checkTimeUtc = DateTime.parse('2026-10-12T13:00:00.000Z');
        expect(
          session.formatCountdown(checkTimeUtc),
          'Class is starting in 1 hour 30 minutes',
        );

        // 15 minutes before UTC start: 14:15 UTC
        final entryTimeUtc = DateTime.parse('2026-10-12T14:15:00.000Z');
        expect(session.isWithinEntryWindow(entryTimeUtc), isTrue);
        expect(session.canEnterLiveClass(entryTimeUtc), isTrue);

        // 16 minutes before UTC start: 14:14 UTC
        final earlyTimeUtc = DateTime.parse('2026-10-12T14:14:00.000Z');
        expect(session.isWithinEntryWindow(earlyTimeUtc), isFalse);
        expect(session.canEnterLiveClass(earlyTimeUtc), isFalse);
      },
    );

    test('8. Missing/invalid timestamp -> entry remains blocked', () {
      const session = ClassEntity(
        id: 'cls-no-time',
        title: 'Invalid Time Class',
        scheduledStartTime: null,
        status: 'upcoming',
      );

      expect(session.earliestEntryTime, isNull);
      expect(session.isWithinEntryWindow(), isFalse);
      expect(session.canEnterLiveClass(), isFalse);
      expect(session.formatCountdown(), isNull);
    });

    test('Past, completed, missed, or cancelled classes remain ineligible', () {
      final now = DateTime.now();
      final completedSession = ClassEntity(
        id: 'cls-comp',
        title: 'Completed Class',
        scheduledStartTime: now.subtract(const Duration(minutes: 60)),
        status: 'completed',
      );
      expect(completedSession.canEnterLiveClass(now), isFalse);

      final missedSession = ClassEntity(
        id: 'cls-miss',
        title: 'Missed Class',
        scheduledStartTime: now.subtract(const Duration(minutes: 60)),
        status: 'missed',
      );
      expect(missedSession.canEnterLiveClass(now), isFalse);

      final cancelledSession = ClassEntity(
        id: 'cls-canc',
        title: 'Cancelled Class',
        scheduledStartTime: now.add(const Duration(minutes: 10)),
        status: 'cancelled',
      );
      expect(cancelledSession.canEnterLiveClass(now), isFalse);
    });
  });

  group('ClassDetailsScreen Widget Entry Window Verification', () {
    Widget buildScreen({
      required ClassEntity session,
      DateTime Function()? currentTime,
    }) {
      return ProviderScope(
        overrides: [
          classesControllerProvider.overrideWith(
            () => _MockClassesController(ClassesLoaded(classes: [session])),
          ),
          childrenControllerProvider.overrideWith(
            () => _MockChildrenController(
              const ChildrenLoaded(children: [], activeChildId: 'child-1'),
            ),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 1416)),
            child: ClassDetailsScreen(
              classId: session.id,
              session: session,
              currentTime: currentTime,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Entry blocked when scheduled start is >15 minutes away (button disabled & notice shown)',
      (tester) async {
        final futureSession = ClassEntity(
          id: 'cls-far',
          title: 'what is FUTURE?',
          scheduledStartTime: DateTime.now().add(
            const Duration(hours: 1, minutes: 30),
          ),
          scheduledEndTime: DateTime.now().add(
            const Duration(hours: 2, minutes: 30),
          ),
          status: 'upcoming',
        );

        await tester.pumpWidget(buildScreen(session: futureSession));
        await tester.pumpAndSettle();

        // Countdown shows 1 hour 30 minutes
        final countdownFinder = find.byKey(
          const Key('class_details_countdown_text'),
        );
        expect(countdownFinder, findsOneWidget);
        final countdownText = tester.widget<Text>(countdownFinder).data!;
        expect(countdownText, contains('1 hour 30 minutes'));

        // Restriction message is visible
        expect(
          find.byKey(const Key('class_entry_restriction_message')),
          findsOneWidget,
        );
        expect(
          find.text('You can join 15 minutes before the class starts'),
          findsOneWidget,
        );

        // Button is disabled (onPressed is null)
        final buttonFinder = find.byKey(
          const Key('continue_to_live_class_button'),
        );
        expect(buttonFinder, findsOneWidget);
        final button = tester.widget<ElevatedButton>(buttonFinder);
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'Entry permitted when scheduled start is within 15 minutes (button enabled & notice hidden)',
      (tester) async {
        final imminentSession = ClassEntity(
          id: 'cls-imminent',
          title: 'what is FUTURE?',
          scheduledStartTime: DateTime.now().add(const Duration(minutes: 10)),
          scheduledEndTime: DateTime.now().add(const Duration(minutes: 70)),
          status: 'upcoming',
        );

        await tester.pumpWidget(buildScreen(session: imminentSession));
        await tester.pumpAndSettle();

        // Restriction message is not visible
        expect(
          find.byKey(const Key('class_entry_restriction_message')),
          findsNothing,
        );

        // Button is enabled (onPressed is not null)
        final buttonFinder = find.byKey(
          const Key('continue_to_live_class_button'),
        );
        expect(buttonFinder, findsOneWidget);
        final button = tester.widget<ElevatedButton>(buttonFinder);
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets(
      '9. The button changes state when the threshold is crossed without reopening screen',
      (tester) async {
        DateTime currentSimulatedTime = DateTime(
          2026,
          10,
          12,
          19,
          44,
          58,
        ); // 15m 2s before 20:00
        final session = ClassEntity(
          id: 'cls-threshold',
          title: 'what is FUTURE?',
          scheduledStartTime: DateTime(2026, 10, 12, 20, 0, 0),
          status: 'upcoming',
        );

        await tester.pumpWidget(
          buildScreen(
            session: session,
            currentTime: () => currentSimulatedTime,
          ),
        );
        await tester.pump();

        // Initially outside window: button is disabled
        var buttonFinder = find.byKey(
          const Key('continue_to_live_class_button'),
        );
        var button = tester.widget<ElevatedButton>(buttonFinder);
        expect(button.onPressed, isNull);
        expect(
          find.byKey(const Key('class_entry_restriction_message')),
          findsOneWidget,
        );

        // Advance simulated clock by 3 seconds so time is 19:45:01 (14m 59s before start, inside window)
        currentSimulatedTime = currentSimulatedTime.add(
          const Duration(seconds: 3),
        );
        await tester.pump(const Duration(seconds: 1));

        // Button automatically updates to enabled without reopening screen!
        buttonFinder = find.byKey(const Key('continue_to_live_class_button'));
        button = tester.widget<ElevatedButton>(buttonFinder);
        expect(button.onPressed, isNotNull);
        expect(
          find.byKey(const Key('class_entry_restriction_message')),
          findsNothing,
        );
      },
    );
  });

  group('10. Alternate Entry Paths Cannot Bypass 15-Minute Restriction', () {
    testWidgets(
      'ClassPreviewScreen blocks join button when class is outside 15-minute window',
      (tester) async {
        final earlySession = ClassEntity(
          id: 'cls-preview-early',
          title: 'what is FUTURE?',
          scheduledStartTime: DateTime.now().add(const Duration(minutes: 45)),
          status: 'upcoming',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              devicePreviewServiceProvider.overrideWithValue(
                _MockDevicePreviewService(),
              ),
              classesControllerProvider.overrideWith(
                () => _MockClassesController(
                  ClassesLoaded(classes: [earlySession]),
                ),
              ),
              childrenControllerProvider.overrideWith(
                () => _MockChildrenController(
                  const ChildrenLoaded(children: [], activeChildId: 'child-1'),
                ),
              ),
            ],
            child: MaterialApp(
              home: ClassPreviewScreen(
                classId: earlySession.id,
                session: earlySession,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final joinButtonFinder = find.byKey(
          const Key('preview_join_live_class_button'),
        );
        expect(joinButtonFinder, findsOneWidget);
        final joinButton = tester.widget<ElevatedButton>(joinButtonFinder);
        // Button must be disabled
        expect(joinButton.onPressed, isNull);
        expect(
          find.text('You can join 15 minutes before the class starts'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'JoiningClassScreen immediately halts with error when class is outside 15-minute window',
      (tester) async {
        final earlySession = ClassEntity(
          id: 'cls-joining-early',
          title: 'what is FUTURE?',
          scheduledStartTime: DateTime.now().add(const Duration(minutes: 60)),
          status: 'upcoming',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              classesControllerProvider.overrideWith(
                () => _MockClassesController(
                  ClassesLoaded(classes: [earlySession]),
                ),
              ),
              childrenControllerProvider.overrideWith(
                () => _MockChildrenController(
                  const ChildrenLoaded(children: [], activeChildId: 'child-1'),
                ),
              ),
            ],
            child: MaterialApp(
              home: JoiningClassScreen(
                classId: earlySession.id,
                session: earlySession,
                childStudentId: 'child-1',
              ),
            ),
          ),
        );
        // Run frame and post frame callback
        await tester.pump();
        await tester.pump();

        // Verifies error state triggered without attempting network connection
        expect(
          find.text('You can join 15 minutes before the class starts.'),
          findsOneWidget,
        );
      },
    );
  });
}
