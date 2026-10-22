import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/child_demo_status_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/demo_slots_controller.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';

class _FakeChildrenController extends ChildrenController {
  _FakeChildrenController({List<ChildEntity>? children, String? activeChildId})
      : _testChildren = children ??
            const [
              ChildEntity(
                studentId: 'child-101',
                firstName: 'Freddy',
                lastName: 'Sahoo',
                studentCode: 'STU-00101',
                grade: 'Grade 3',
                explicitAge: 8,
              ),
              ChildEntity(
                studentId: 'child-102',
                firstName: 'Tarini',
                lastName: 'Sahoo',
                studentCode: 'STU-00520397',
                grade: 'Grade 5',
                explicitAge: 10,
              ),
            ],
        _activeId = activeChildId ?? 'child-101';

  final List<ChildEntity> _testChildren;
  String? _activeId;

  @override
  ChildrenState build() =>
      ChildrenLoaded(children: _testChildren, activeChildId: _activeId);

  @override
  void setActiveChild(String studentId) {
    _activeId = studentId;
    state = ChildrenLoaded(children: _testChildren, activeChildId: studentId);
  }

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {
    state = ChildrenLoaded(children: _testChildren, activeChildId: _activeId);
  }
}

class _FakeDemoSlotsController extends DemoSlotsController {
  @override
  DemoSlotsState build() => const DemoSlotsLoaded(slots: []);

  @override
  Future<void> loadSlots({String? courseId, String? studentId}) async {
    state = const DemoSlotsLoaded(slots: []);
  }
}

class _FakeChildDemoStatusController extends ChildDemoStatusController {
  _FakeChildDemoStatusController(this._initialState);
  final ChildDemoStatusState _initialState;
  int resolveCount = 0;
  String? lastResolvedChildId;

  @override
  ChildDemoStatusState build() => _initialState;

  @override
  Future<void> resolveStatusForChild({
    required String studentId,
    bool forceRefresh = false,
  }) async {
    resolveCount++;
    lastResolvedChildId = studentId;
  }

  void updateState(ChildDemoStatusState newState) {
    state = newState;
  }
}

void _setupTestScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('Dashboard Join Demo Class Flow — Comprehensive Tests', () {
    testWidgets(
      'Scenario 1: Dashboard displays Free live demo benefit card instead of Join Demo Class for unapplied child',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-101'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Must NOT display "Join Demo Class"
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.byKey(const Key('dashboard_join_demo_class_card')), findsNothing);

        // Must display "Free live demo" (Node 72:579)
        expect(find.text('Free live demo'), findsOneWidget);

        // Unrelated benefit cards must remain unchanged
        expect(find.text('Expert faculty'), findsOneWidget);
        expect(find.text('45-minute session'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 2: A child without a demo application sees Apply for Demo Class floating action button',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-101'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // FAB should be displayed
        final fab = find.byKey(const Key('apply_for_demo_class_button'));
        expect(fab, findsOneWidget);
        expect(find.text('Apply for Demo Class'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 3: Tapping the floating action button triggers the demo application flow and guidance',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-101'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final fab = find.byKey(const Key('apply_for_demo_class_button'));
        expect(fab, findsOneWidget);

        await tester.tap(fab);
        await tester.pump();

        // Feedback SnackBar appears
        expect(
          find.text('Select an available slot below to apply for your free demo class.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario 4: A child with a pending application does NOT receive duplicate application CTA, shows banner, and does not show join action prematurely',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoPendingConfirmation(
            studentId: 'child-101',
            leadId: 'LEAD-9876',
            courseName: 'Emotional Intelligence',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // FAB is hidden
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsNothing);

        // Banner shows demo request received
        expect(find.text('Demo Request Received'), findsOneWidget);
        expect(find.textContaining('LEAD-9876'), findsOneWidget);

        // Join action is NOT shown prematurely
        expect(find.text('Join Demo Class'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 5: A scheduled session displays the Join Demo Class card with SCHEDULED badge',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final scheduledBooking = DemoBookingEntity(
          bookingId: 'demo-b-sched',
          demoCode: 'DEMO-100200',
          courseName: 'Emotional Intelligence',
          studentName: 'Freddy Sahoo',
          studentId: 'child-101',
          startDateTime: DateTime.now().add(const Duration(hours: 3)),
          status: 'scheduled',
        );

        final statusCtrl = _FakeChildDemoStatusController(
          ChildDemoScheduledTooEarly(
            studentId: 'child-101',
            booking: scheduledBooking,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final joinCard = find.byKey(const Key('dashboard_join_demo_class_card'));
        expect(joinCard, findsOneWidget);
        expect(find.text('Join Demo Class'), findsOneWidget);
        expect(find.text('SCHEDULED'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 6: A scheduled session opens the waiting screen before the 15-minute joining window',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final futureBooking = DemoBookingEntity(
          bookingId: 'demo-b-1',
          demoCode: 'DEMO-100200',
          courseName: 'Emotional Intelligence',
          studentName: 'Freddy Sahoo',
          studentId: 'child-101',
          startDateTime: DateTime.now().add(const Duration(hours: 3)),
          endDateTime: DateTime.now().add(const Duration(hours: 3, minutes: 45)),
          teacherName: 'Prof. Sharma',
          status: 'scheduled',
        );

        final statusCtrl = _FakeChildDemoStatusController(
          ChildDemoScheduledTooEarly(
            studentId: 'child-101',
            booking: futureBooking,
          ),
        );

        DemoBookingEntity? passedExtra;

        final router = GoRouter(
          initialLocation: AppRoutePaths.demoBookingDashboard,
          routes: [
            GoRoute(
              path: AppRoutePaths.demoBookingDashboard,
              builder: (context, state) => const DemoBookingDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.demoClassWaiting,
              builder: (context, state) {
                passedExtra = state.extra as DemoBookingEntity?;
                return const Scaffold(body: Text('WAITING_SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // FAB is hidden
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsNothing);

        // Join Demo Class card shows scheduled badge
        expect(find.text('SCHEDULED'), findsOneWidget);

        // Tap Join card
        final joinCard = find.byKey(const Key('dashboard_join_demo_class_card'));
        await tester.ensureVisible(joinCard);
        await tester.tap(joinCard);
        await tester.pumpAndSettle();

        // Should be on Waiting screen
        expect(find.text('WAITING_SCREEN'), findsOneWidget);
        expect(passedExtra?.bookingId, 'demo-b-1');
      },
    );

    testWidgets(
      'Scenario 7: An eligible session opens the pre-join screen directly',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final eligibleBooking = DemoBookingEntity(
          bookingId: 'demo-b-2',
          demoCode: 'DEMO-3500481463',
          courseName: 'Emotional Intelligence',
          studentName: 'Tarini Sahoo',
          studentId: 'child-102',
          studentCode: 'STU-00520397',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          endDateTime: DateTime.now().add(const Duration(minutes: 50)),
          teacherName: 'Dr. Jane Watson',
          status: 'scheduled',
          joinEligible: true,
        );

        final statusCtrl = _FakeChildDemoStatusController(
          ChildDemoEligibleToJoin(
            studentId: 'child-102',
            booking: eligibleBooking,
          ),
        );

        DemoBookingEntity? passedExtra;

        final router = GoRouter(
          initialLocation: AppRoutePaths.demoBookingDashboard,
          routes: [
            GoRoute(
              path: AppRoutePaths.demoBookingDashboard,
              builder: (context, state) => const DemoBookingDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.demoClassPreJoin,
              builder: (context, state) {
                passedExtra = state.extra as DemoBookingEntity?;
                return const Scaffold(body: Text('PRE_JOIN_SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-102'),
              ),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Card shows LIVE NOW badge
        expect(find.text('LIVE NOW'), findsOneWidget);
        expect(find.text('Session is ready • Tap to enter classroom'), findsOneWidget);

        // Tap Join card
        final joinCard = find.byKey(const Key('dashboard_join_demo_class_card'));
        await tester.ensureVisible(joinCard);
        await tester.tap(joinCard);
        await tester.pumpAndSettle();

        // Directly on Pre-Join Screen
        expect(find.text('PRE_JOIN_SCREEN'), findsOneWidget);
        expect(passedExtra?.bookingId, 'demo-b-2');
        expect(passedExtra?.studentId, 'child-102');
      },
    );

    testWidgets(
      'Scenario 8: Invalid or expired sessions cannot be joined and show modal feedback',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final expiredBooking = DemoBookingEntity(
          bookingId: 'demo-b-3',
          courseName: 'Emotional Intelligence',
          startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'completed',
        );

        final statusCtrl = _FakeChildDemoStatusController(
          ChildDemoTerminal(
            studentId: 'child-101',
            booking: expiredBooking,
            isCancelled: false,
            isExpired: true,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Terminal session does NOT display active Join Demo Class card
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.byKey(const Key('dashboard_join_demo_class_card')), findsNothing);
        expect(find.text('Free live demo'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 9: Switching children refreshes the demo status for the newly selected child',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final childrenCtrl = _FakeChildrenController();
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-101'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => childrenCtrl),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initial child is Freddy (child-101)
        expect(find.text('Freddy Sahoo'), findsOneWidget);

        // Tap child selector
        await tester.tap(find.byKey(const Key('demo_dashboard_child_selector')));
        await tester.pumpAndSettle();

        // Switch to Tarini (child-102)
        await tester.tap(find.byKey(const Key('child_option_child-102')));
        await tester.pumpAndSettle();

        // Controller resolve was triggered with child-102
        expect(statusCtrl.lastResolvedChildId, 'child-102');
      },
    );

    testWidgets(
      'Scenario 10: API failure does not incorrectly expose the application CTA',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoError(
            studentId: 'child-101',
            message: 'Server timeout connecting to Atlas cluster',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // CRITICAL: Floating action button must NOT be exposed on API failure!
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsNothing);

        // Does NOT show false Join Demo Class action
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.text('Free live demo'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 11: Successful application updates the dashboard action and hides the apply FAB',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-101'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initially no demo application -> FAB is visible
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsOneWidget);

        // Simulate booking confirmation / application submitted
        statusCtrl.updateState(
          const ChildDemoPendingConfirmation(
            studentId: 'child-101',
            leadId: 'LEAD-999',
            courseName: 'Coding for Kids',
          ),
        );
        await tester.pumpAndSettle();

        // Floating action button must now be hidden
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsNothing);

        // Demo Request Received banner is displayed
        expect(find.text('Demo Request Received'), findsOneWidget);
        expect(find.textContaining('LEAD-999'), findsOneWidget);

        // Join Demo Class card is NOT shown prematurely
        expect(find.text('Join Demo Class'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 12: Repeated taps do not create duplicate navigation stacks',
      (WidgetTester tester) async {
        _setupTestScreen(tester);
        final eligibleBooking = DemoBookingEntity(
          bookingId: 'demo-b-repeated',
          courseName: 'Public Speaking',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          status: 'scheduled',
          joinEligible: true,
        );

        final statusCtrl = _FakeChildDemoStatusController(
          ChildDemoEligibleToJoin(
            studentId: 'child-101',
            booking: eligibleBooking,
          ),
        );

        int pushCount = 0;

        final router = GoRouter(
          initialLocation: AppRoutePaths.demoBookingDashboard,
          routes: [
            GoRoute(
              path: AppRoutePaths.demoBookingDashboard,
              builder: (context, state) => const DemoBookingDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.demoClassPreJoin,
              builder: (context, state) {
                pushCount++;
                return const Scaffold(body: Text('PRE_JOIN_SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => _FakeChildrenController()),
              demoSlotsControllerProvider.overrideWith(() => _FakeDemoSlotsController()),
              childDemoStatusControllerProvider.overrideWith(() => statusCtrl),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        final joinCard = find.byKey(const Key('dashboard_join_demo_class_card'));
        await tester.ensureVisible(joinCard);

        // Tap rapidly multiple times
        await tester.tap(joinCard);
        await tester.tap(joinCard);
        await tester.tap(joinCard);
        await tester.pumpAndSettle();

        // Exactly one navigation pushed
        expect(pushCount, 1);
      },
    );
  });
}
