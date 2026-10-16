import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_slot_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/demo_slots_controller.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';

class _FakeChildrenController extends ChildrenController {
  _FakeChildrenController({List<ChildEntity>? children, String? activeChildId})
    : _testChildren =
          children ??
          const [
            ChildEntity(
              studentId: 'child-1',
              firstName: 'Rony',
              lastName: 'Sharma',
              grade: 'Grade 3',
              explicitAge: 8,
            ),
            ChildEntity(
              studentId: 'child-2',
              firstName: 'Ananya',
              lastName: 'Sharma',
              grade: 'Grade 5',
              explicitAge: 10,
            ),
          ],
      _activeId = activeChildId ?? 'child-1';

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

class _FakeDemoSlotsEmptyController extends DemoSlotsController {
  bool refreshCalled = false;

  @override
  DemoSlotsState build() => const DemoSlotsLoaded(slots: []);

  @override
  Future<void> loadSlots({String? courseId, String? studentId}) async {
    refreshCalled = true;
    state = const DemoSlotsLoaded(slots: []);
  }
}

class _FakeDemoSlotsWithSlotsController extends DemoSlotsController {
  @override
  DemoSlotsState build() => DemoSlotsLoaded(
    slots: [
      DemoSlotEntity(
        id: 'slot-101',
        courseId: 'course-speaking',
        startDateTime: DateTime(2026, 10, 15, 16, 30),
        endDateTime: DateTime(2026, 10, 15, 17, 15),
        instructorName: 'Prof. Anderson',
        dayLabel: 'TODAY',
      ),
      DemoSlotEntity(
        id: 'slot-102',
        courseId: 'course-speaking',
        startDateTime: DateTime(2026, 10, 16, 18, 00),
        endDateTime: DateTime(2026, 10, 16, 18, 45),
        instructorName: 'Ms. Sarah',
        dayLabel: 'TOMORROW',
      ),
    ],
  );
}

void main() {
  group('DemoBookingDashboardScreen Comprehensive Tests', () {
    testWidgets(
      'renders dashboard structure and completely omits Choose Preferred Date & Time',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsEmptyController(),
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. TopAppBar & Header
        expect(find.text('Dashboard'), findsOneWidget);
        expect(
          find.byKey(const Key('demo_dashboard_hamburger_button')),
          findsOneWidget,
        );

        // 2. Hero Card
        expect(find.text('FREE DEMO'), findsOneWidget);
        expect(find.text('TrueLern Programs'), findsOneWidget);

        // 3. Slots Section Header
        expect(find.text('Next Available Slots'), findsOneWidget);
        expect(
          find.byKey(const Key('demo_dashboard_child_selector')),
          findsOneWidget,
        );

        // 4. Verify "Choose Preferred Date & Time" section is completely removed
        expect(find.text('Choose Preferred Date & Time'), findsNothing);
        expect(find.text("Can't find a suitable slot?"), findsNothing);

        // 5. Benefits Section
        expect(find.text('Free live demo'), findsOneWidget);
        expect(find.text('Expert faculty'), findsOneWidget);
        expect(find.text('45-minute session'), findsOneWidget);

        // 6. Footer Note
        expect(
          find.text('FREE DEMO • 45 MINS • EXPERT INSTRUCTOR\n• NO COMMITMENT'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'child selector displays active child, opens bottom sheet with linked children and Add Child action',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsEmptyController(),
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Active child name is displayed in the pill
        expect(find.text('Rony Sharma'), findsOneWidget);

        // Tap child selector pill
        final selector = find.byKey(const Key('demo_dashboard_child_selector'));
        await tester.tap(selector);
        await tester.pumpAndSettle();

        // Modal bottom sheet should be open
        expect(find.text('Select Child'), findsOneWidget);

        // Both linked children displayed with their details
        expect(find.text('Rony Sharma'), findsWidgets);
        expect(find.text('Ananya Sharma'), findsOneWidget);
        expect(find.text('Grade: Grade 3 • Age: 8'), findsOneWidget);
        expect(find.text('Grade: Grade 5 • Age: 10'), findsOneWidget);

        // Add Child button is present at the bottom
        final addChildButton = find.byKey(
          const Key('demo_dashboard_add_child_button'),
        );
        expect(addChildButton, findsOneWidget);
        expect(find.text('Add Child'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting another child updates active child context and closes bottom sheet',
      (WidgetTester tester) async {
        final controller = _FakeChildrenController();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => controller),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsEmptyController(),
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initial active child is Rony Sharma
        expect(controller._activeId, 'child-1');

        // Tap child selector
        await tester.tap(
          find.byKey(const Key('demo_dashboard_child_selector')),
        );
        await tester.pumpAndSettle();

        // Tap child option for Ananya Sharma
        final ananyaTile = find.byKey(const Key('child_option_child-2'));
        expect(ananyaTile, findsOneWidget);
        await tester.tap(ananyaTile);
        await tester.pumpAndSettle();

        // Bottom sheet is dismissed and controller active child is updated
        expect(find.text('Select Child'), findsNothing);
        expect(controller._activeId, 'child-2');
        expect(find.text('Ananya Sharma'), findsOneWidget);
      },
    );

    testWidgets(
      'slots section shows honest empty state when backend returns 0 slots and refresh works',
      (WidgetTester tester) async {
        final slotsCtrl = _FakeDemoSlotsEmptyController();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(),
              ),
              demoSlotsControllerProvider.overrideWith(() => slotsCtrl),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Honest empty state is shown instead of fake slots
        expect(find.text('No Demo Slots Available'), findsOneWidget);
        expect(
          find.text(
            'There are currently no free demo slots scheduled for this course. Please refresh or contact academic support.',
          ),
          findsOneWidget,
        );

        // Refresh Availability button
        final refreshButton = find.byKey(
          const Key('refresh_demo_slots_button'),
        );
        expect(refreshButton, findsOneWidget);
        await tester.ensureVisible(refreshButton);
        await tester.tap(refreshButton);
        await tester.pump();

        expect(slotsCtrl.refreshCalled, isTrue);
      },
    );

    testWidgets(
      'slots section displays real slot cards when backend returns slots',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(),
              ),
              demoSlotsControllerProvider.overrideWith(
                () => _FakeDemoSlotsWithSlotsController(),
              ),
            ],
            child: const MaterialApp(home: DemoBookingDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Honest empty state should NOT be shown
        expect(find.text('No Demo Slots Available'), findsNothing);

        // Real slots rendered
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('4:30'), findsOneWidget);
        expect(find.text('Instructor: Prof. Anderson'), findsOneWidget);

        expect(find.text('TOMORROW'), findsOneWidget);
        expect(find.text('6:00'), findsOneWidget);
        expect(find.text('Instructor: Ms. Sarah'), findsOneWidget);

        // Both slots have Book this demo CTA
        expect(find.text('Book this demo'), findsNWidgets(2));
      },
    );
  });
}
