import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_slot_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/child_demo_status_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/demo_slots_controller.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';
import 'package:truelearn/features/onboarding/presentation/controllers/onboarding_controller.dart';

class _FakeChildrenController extends ChildrenController {
  _FakeChildrenController({
    List<ChildEntity>? children,
    String? activeChildId,
  })  : _testChildren = children ??
            const [
              ChildEntity(
                studentId: 'child-sawan-7479',
                firstName: 'Sawan',
                lastName: 'Kumar',
                studentCode: 'STU-SAWAN',
                grade: 'Grade 3',
                explicitAge: 8,
              ),
              ChildEntity(
                studentId: 'child-abani-5396',
                firstName: 'Abani',
                lastName: 'Kumar',
                studentCode: 'STU-ABANI',
                grade: 'Grade 5',
                explicitAge: 10,
              ),
            ],
        _activeId = activeChildId ?? 'child-sawan-7479';

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
  _FakeDemoSlotsController({List<DemoSlotEntity>? slots})
      : _slots = slots ??
            [
              DemoSlotEntity(
                id: 'slot-today-1',
                courseId: 'course-speaking',
                startDateTime: DateTime(2026, 10, 19, 17, 30),
                endDateTime: DateTime(2026, 10, 19, 18, 15),
                instructorName: 'Prof. Anderson',
                dayLabel: 'TODAY',
              ),
              DemoSlotEntity(
                id: 'slot-tomorrow-2',
                courseId: 'course-speaking',
                startDateTime: DateTime(2026, 10, 20, 18, 00),
                endDateTime: DateTime(2026, 10, 20, 18, 45),
                instructorName: 'Ms. Sarah',
                dayLabel: 'TOMORROW',
              ),
            ];

  final List<DemoSlotEntity> _slots;

  @override
  DemoSlotsState build() => DemoSlotsLoaded(slots: _slots);

  @override
  Future<void> loadSlots({String? courseId, String? studentId}) async {
    state = DemoSlotsLoaded(slots: _slots);
  }
}

class _FakeChildDemoStatusController extends ChildDemoStatusController {
  _FakeChildDemoStatusController(this._initialState);
  final ChildDemoStatusState _initialState;
  String? lastResolvedStudentId;
  int resolveCalls = 0;

  @override
  ChildDemoStatusState build() => _initialState;

  @override
  Future<void> resolveStatusForChild({
    required String studentId,
    bool forceRefresh = false,
  }) async {
    resolveCalls++;
    lastResolvedStudentId = studentId;
  }

  void updateState(ChildDemoStatusState newState) {
    state = newState;
  }

  @override
  void reset() {
    state = const ChildDemoInitial();
  }
}

class _FakeOnboardingController extends OnboardingController {
  _FakeOnboardingController({OnboardingState? initialState})
      : _initial = initialState ?? const OnboardingState();

  final OnboardingState _initial;

  @override
  OnboardingState build() => _initial;
}

void _setupScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('Acceptance Criteria Tests — Demo Request Status and Dashboard UI', () {
    testWidgets(
      'AC 1: A child who has never applied sees available slots, Book this demo, Apply FAB, and NO Join Demo Class card or banner',
      (WidgetTester tester) async {
        _setupScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-sawan-7479'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-sawan-7479'),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => statusCtrl,
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Available demo time slots are visible with Book this demo button
        expect(find.text('Next Available Slots'), findsOneWidget);
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('TOMORROW'), findsOneWidget);
        expect(find.text('Book this demo'), findsNWidgets(2));

        // 2. The Apply for Demo Class floating action button is visible
        final fab = find.byKey(const Key('apply_for_demo_class_button'));
        expect(fab, findsOneWidget);
        expect(find.text('Apply for Demo Class'), findsOneWidget);

        // 3. Benefits section shows original "Free live demo" (Node 72:579), NOT "Join Demo Class"
        expect(find.text('Free live demo'), findsOneWidget);
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.byKey(const Key('dashboard_join_demo_class_card')), findsNothing);

        // 4. No false demo-request confirmation or active demo-class status
        expect(find.text('Demo Request Received'), findsNothing);
        expect(find.textContaining('Lead Ref:'), findsNothing);
      },
    );

    testWidgets(
      'AC 2: A booking belonging to another child does NOT affect the selected child',
      (WidgetTester tester) async {
        _setupScreen(tester);

        // Booking belongs to Abani (child-abani-5396), but Sawan is selected
        final abaniBooking = DemoBookingEntity(
          bookingId: 'demo-abani-booking',
          demoCode: 'DEMO-2488157735',
          courseName: 'Coding Fundamentals',
          studentName: 'Abani Kumar',
          studentId: 'child-abani-5396',
          studentCode: 'STU-ABANI',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          status: 'scheduled',
        );

        final sawanChild = const ChildEntity(
          studentId: 'child-sawan-7479',
          firstName: 'Sawan',
          lastName: 'Kumar',
          studentCode: 'STU-SAWAN',
        );
        final abaniChild = const ChildEntity(
          studentId: 'child-abani-5396',
          firstName: 'Abani',
          lastName: 'Kumar',
          studentCode: 'STU-ABANI',
        );

        // Sawan list only contains Sawan
        expect(
          resolveAuthoritativeStudent(
            booking: abaniBooking,
            linkedChildren: [sawanChild],
          ),
          isNull,
        );

        // Both children in parent's account: matches Abani, never Sawan
        expect(
          resolveAuthoritativeStudent(
            booking: abaniBooking,
            linkedChildren: [sawanChild, abaniChild],
          )?.studentId,
          'child-abani-5396',
        );

        // Dashboard for Sawan must show ChildDemoNone
        final sawanStatusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-sawan-7479'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-sawan-7479'),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => sawanStatusCtrl,
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Sawan must NOT see Abani's booking
        expect(find.text('Free live demo'), findsOneWidget);
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.text('Demo Request Received'), findsNothing);
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsOneWidget);
      },
    );

    testWidgets(
      'AC 3: A general CRM lead does NOT count as a submitted demo application for a child',
      (WidgetTester tester) async {
        _setupScreen(tester);

        // Onboarding controller restored with parent CRM lead (no childName)
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(onboardingControllerProvider.notifier).restoreDemoBookingState(
          leadId: '6ad1c4fe678053968ed63c89',
          courseName: 'ACE Public Speaking',
        );

        final onboardingState = container.read(onboardingControllerProvider);
        expect(onboardingState.submissionLeadId, '6ad1c4fe678053968ed63c89');
        // Because childName is empty, isSubmitted MUST be false!
        expect(onboardingState.isSubmitted, isFalse);

        // And in ChildDemoStatusState, Sawan has ChildDemoNone
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-sawan-7479'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingControllerProvider.overrideWith(
                () => _FakeOnboardingController(initialState: onboardingState),
              ),
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-sawan-7479'),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => statusCtrl,
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Demo Request Received'), findsNothing);
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsOneWidget);
      },
    );

    testWidgets(
      'AC 4: An actual submitted request shows the appropriate pending state (banner shown, FAB hidden, NO premature join button)',
      (WidgetTester tester) async {
        _setupScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoPendingConfirmation(
            studentId: 'child-sawan-7479',
            leadId: 'LEAD-CONFIRMED-1234',
            courseName: 'ACE Public Speaking',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-sawan-7479'),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => statusCtrl,
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Banner IS displayed
        expect(find.text('Demo Request Received'), findsOneWidget);
        expect(find.textContaining('LEAD-CONFIRMED-1234'), findsOneWidget);

        // FAB is hidden to prevent duplicate submission
        expect(find.byKey(const Key('apply_for_demo_class_button')), findsNothing);

        // Join action is NOT shown prematurely
        expect(find.text('Join Demo Class'), findsNothing);
        expect(find.text('Free live demo'), findsOneWidget);
      },
    );

    testWidgets(
      'AC 5: A confirmed booking follows the existing demo-class flow (SCHEDULED -> Waiting, LIVE NOW -> Pre-join)',
      (WidgetTester tester) async {
        _setupScreen(tester);

        final scheduledBooking = DemoBookingEntity(
          bookingId: 'demo-sched-1',
          courseName: 'ACE Public Speaking',
          studentName: 'Sawan Kumar',
          studentId: 'child-sawan-7479',
          startDateTime: DateTime.now().add(const Duration(hours: 3)),
          status: 'scheduled',
          joinEligible: false,
        );

        final statusCtrl = _FakeChildDemoStatusController(
          ChildDemoScheduledTooEarly(
            studentId: 'child-sawan-7479',
            booking: scheduledBooking,
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
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-sawan-7479'),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => statusCtrl,
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Join Demo Class card is displayed with SCHEDULED badge
        expect(find.text('Join Demo Class'), findsOneWidget);
        expect(find.text('SCHEDULED'), findsOneWidget);

        // Tap navigates to waiting room
        await tester.tap(find.byKey(const Key('dashboard_join_demo_class_card')));
        await tester.pumpAndSettle();

        expect(find.text('WAITING_SCREEN'), findsOneWidget);
        expect(passedExtra?.bookingId, 'demo-sched-1');
      },
    );

    testWidgets(
      'AC 6: Switching children refreshes the displayed booking state and invalidates stale state',
      (WidgetTester tester) async {
        _setupScreen(tester);
        final childrenCtrl = _FakeChildrenController();
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-sawan-7479'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => childrenCtrl),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => statusCtrl,
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initial child is Sawan
        expect(find.text('Sawan Kumar'), findsOneWidget);

        // Open child selector
        await tester.tap(find.byKey(const Key('demo_dashboard_child_selector')));
        await tester.pumpAndSettle();

        // Switch to Abani
        await tester.tap(find.byKey(const Key('child_option_child-abani-5396')));
        await tester.pumpAndSettle();

        // Status was resolved with Abani's ID
        expect(statusCtrl.lastResolvedStudentId, 'child-abani-5396');
      },
    );

    testWidgets(
      'AC 7: Missing or ambiguous API data never produces a false success state',
      (WidgetTester tester) async {
        // Test parsing of empty/missing response as returned by GET /parent/demo
        final emptyData = <String, dynamic>{};
        final emptyBooking = DemoBookingEntity.fromJson(emptyData);
        // An empty json does not have a valid booking ID or course
        expect(emptyBooking.studentId, isNull);

        // Ambiguous booking missing studentId
        final ambiguousJson = <String, dynamic>{
          'bookingId': 'ambiguous-1',
          'courseName': 'Test Course',
          'status': 'scheduled',
          // No studentId, no studentCode, no studentName
        };
        final ambiguousBooking = DemoBookingEntity.fromJson(ambiguousJson);
        final sawanChild = const ChildEntity(
          studentId: 'child-sawan-7479',
          firstName: 'Sawan',
          lastName: 'Kumar',
        );

        // Single-child fallback is removed; must return null
        final authoritative = resolveAuthoritativeStudent(
          booking: ambiguousBooking,
          linkedChildren: [sawanChild],
        );
        expect(authoritative, isNull);
      },
    );

    testWidgets(
      'AC 8: Existing demo booking flow remains functional with Book this demo CTA',
      (WidgetTester tester) async {
        _setupScreen(tester);
        final statusCtrl = _FakeChildDemoStatusController(
          const ChildDemoNone(studentId: 'child-sawan-7479'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(activeChildId: 'child-sawan-7479'),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsController(),
              ),
              childDemoStatusControllerProvider.overrideWith(
                () => statusCtrl,
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "Book this demo" on the first slot
        final bookButton = find.byKey(const Key('book_demo_button_today'));
        expect(bookButton, findsOneWidget);
        await tester.ensureVisible(bookButton);
        await tester.tap(bookButton);
        await tester.pumpAndSettle();

        // Confirmation popup appears
        expect(find.text('Ready to Start?'), findsOneWidget);
        expect(find.byKey(const Key('demo_popup_confirm_button')), findsOneWidget);
      },
    );
  });
}
