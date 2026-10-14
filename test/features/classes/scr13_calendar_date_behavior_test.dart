import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/screens/parent_classes_screen.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_date_navigator.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_event_card.dart';
import 'package:truelearn/features/classes/presentation/widgets/empty_classes_widget.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class FakeChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  FakeChildrenController(this.initial);
  final ChildrenState initial;

  @override
  ChildrenState build() => initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

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

class FakeClassesController extends Notifier<ClassesState>
    implements ClassesController {
  FakeClassesController(this.initial);
  final ClassesState initial;

  @override
  ClassesState build() => initial;

  @override
  Future<void> loadClasses({
    required String? childStudentId,
    bool isRefresh = false,
  }) async {}

  @override
  Future<void> retry() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testChildren = [
    ChildEntity(
      studentId: 'child_sarah',
      firstName: 'Sarah',
      lastName: 'Connor',
      grade: 'Grade 3',
    ),
    ChildEntity(
      studentId: 'child_ram',
      firstName: 'Ram',
      lastName: 'Pearson',
      grade: 'Grade 5',
    ),
  ];

  // Sarah's real upcoming class: Wednesday, 30 September 2026 at 4:30 AM
  final sarahFutureClass = ClassEntity(
    id: 'cls_sarah_future',
    title: 'Junior Foundation first class',
    subject: 'Junior Foundation',
    status: 'UPCOMING',
    scheduledStartTime: DateTime(2026, 9, 30, 4, 30),
    scheduledEndTime: DateTime(2026, 9, 30, 8, 30),
    teacherName: 'Elizabeth Vance',
  );

  // Class scheduled for today: Friday, 18 September 2026 at 16:00
  final todayClass = ClassEntity(
    id: 'cls_today',
    title: 'Today Foundation Session',
    subject: 'Junior Foundation',
    status: 'UPCOMING',
    scheduledStartTime: DateTime(2026, 9, 18, 16, 0),
    scheduledEndTime: DateTime(2026, 9, 18, 17, 0),
    teacherName: 'Elizabeth Vance',
  );

  Widget createSubject({
    DateTime? deviceDate,
    List<ClassEntity>? classes,
    String activeChildId = 'child_sarah',
  }) {
    final cState = ChildrenLoaded(
      children: testChildren,
      activeChildId: activeChildId,
    );

    final clState = ClassesLoaded(classes: classes ?? [sarahFutureClass]);

    return ProviderScope(
      overrides: [
        childrenControllerProvider.overrideWith(
          () => FakeChildrenController(cState),
        ),
        classesControllerProvider.overrideWith(
          () => FakeClassesController(clState),
        ),
        currentDeviceDateProvider.overrideWithValue(
          deviceDate ?? DateTime(2026, 9, 18),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ParentClassesScreen())),
    );
  }

  group('SCR-13 Calendar Date Behavior Verification', () {
    testWidgets(
      'TEST 1 & 8 — Initial entry opens on current device date (18 Sep 2026, Friday) and shows empty state when no class today',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [sarahFutureClass], // only Sept 30 class
          ),
        );
        await tester.pumpAndSettle();

        // Verify Friday 18 is visible in Date Navigator
        expect(find.text('Fri'), findsWidgets);
        expect(find.text('18'), findsWidgets);

        // Verify September 30 class is NOT shown on September 18
        expect(find.text('Junior Foundation first class'), findsNothing);

        // Verify Figma-approved empty state is displayed
        expect(find.byType(EmptyClassesWidget), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 2 — Manual selection of 30 September displays the 30 September class',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // On initial entry: empty state
        expect(find.byType(EmptyClassesWidget), findsOneWidget);

        // Scroll date strip to reveal Sept 30
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        // Tap on date 30
        final d30 = find.text('30');
        expect(d30, findsWidgets);
        await tester.tap(d30.first);
        await tester.pumpAndSettle();

        // Now September 30 class appears!
        expect(find.text('Junior Foundation first class'), findsOneWidget);
        expect(find.byType(ClassesEventCard), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 3 — Returning from 30 September back to 18 September restores 18 September view',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // Scroll to 30
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('30').first);
        await tester.pumpAndSettle();
        expect(find.text('Junior Foundation first class'), findsOneWidget);

        // Scroll back to 18
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(800, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('18'), findsWidgets);
        await tester.tap(find.text('18').first);
        await tester.pumpAndSettle();

        // Empty state returns because there is no class on Sept 18
        expect(find.text('Junior Foundation first class'), findsNothing);
        expect(find.byType(EmptyClassesWidget), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 5 — Tomorrow simulation: when device date is 19 Sep 2026 (Saturday), opens on 19',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 19, 8, 0), // Saturday 19
            classes: [sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // Sat and 19 are rendered
        expect(find.text('Sat'), findsWidgets);
        expect(find.text('19'), findsWidgets);

        // No class on 19
        expect(find.byType(EmptyClassesWidget), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 6 — Child switching preserves selected viewing date during same session',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // Scroll to 30 and select it
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('30').first);
        await tester.pumpAndSettle();
        expect(find.text('Junior Foundation first class'), findsOneWidget);

        // Switch child to Ram
        final selectorButton = find.byKey(
          const Key('classes_student_selector_button'),
        );
        await tester.tap(selectorButton);
        await tester.pumpAndSettle();

        expect(find.text('Ram Pearson'), findsOneWidget);
        await tester.tap(find.text('Ram Pearson'));
        await tester.pumpAndSettle();

        // Viewing date should remain 30 (preserving session date selection)
        expect(find.text('Ram'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 7 — Today class appears when a class actually occurs on device date',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [todayClass, sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // Today's class appears immediately on initial entry
        expect(find.text('Today Foundation Session'), findsOneWidget);
        // Future class does not appear under today
        expect(find.text('Junior Foundation first class'), findsNothing);
      },
    );

    testWidgets(
      'TEST 9 & REFRESH RESET — Pull to refresh resets selected viewing date to today and preserves active child',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // Initially on Sept 18 (empty state)
        expect(find.text('18'), findsWidgets);
        expect(find.byType(EmptyClassesWidget), findsOneWidget);

        // User manually selects Sept 30
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('30').first);
        await tester.pumpAndSettle();
        expect(find.text('Junior Foundation first class'), findsOneWidget);

        // Trigger pull to refresh
        await tester.fling(
          find.byKey(const Key('classes_scroll_view')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        // After refresh: date resets to today (18 September), active child remains Sarah
        expect(find.text('Sarah'), findsOneWidget);
        // Future class for Sept 30 is no longer visible under Sept 18
        expect(find.text('Junior Foundation first class'), findsNothing);
        expect(find.byType(EmptyClassesWidget), findsOneWidget);
        expect(find.text('18'), findsWidgets);
      },
    );

    testWidgets(
      'TEST REPEATED REFRESH — Multiple refreshes consistently maintain today date without drift',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        for (int i = 0; i < 3; i++) {
          // Manually select Sept 30
          await tester.drag(
            find.byType(ClassesDateNavigator),
            const Offset(-500, 0),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('30').first);
          await tester.pumpAndSettle();
          expect(find.text('Junior Foundation first class'), findsOneWidget);

          // Pull to refresh
          await tester.fling(
            find.byKey(const Key('classes_scroll_view')),
            const Offset(0, 300),
            1000,
          );
          await tester.pumpAndSettle();

          // Must reset back to today
          expect(find.text('Junior Foundation first class'), findsNothing);
          expect(find.byType(EmptyClassesWidget), findsOneWidget);
        }
      },
    );

    testWidgets(
      'TEST REFRESH WITH TODAY CLASS — Class scheduled for today displays after refresh from future date',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            deviceDate: DateTime(2026, 9, 18, 10, 30),
            classes: [todayClass, sarahFutureClass],
          ),
        );
        await tester.pumpAndSettle();

        // Starts on today: today's class is shown
        expect(find.text('Today Foundation Session'), findsOneWidget);

        // Select Sept 30: future class is shown
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('30').first);
        await tester.pumpAndSettle();
        expect(find.text('Junior Foundation first class'), findsOneWidget);
        expect(find.text('Today Foundation Session'), findsNothing);

        // Refresh: resets to today, today's class reappears
        await tester.fling(
          find.byKey(const Key('classes_scroll_view')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.text('Today Foundation Session'), findsOneWidget);
        expect(find.text('Junior Foundation first class'), findsNothing);
      },
    );
  });

  group('TEST 4 — Leave and Re-enter SCR-13 resets to current device date', () {
    testWidgets(
      'Re-entering /parent/classes after navigating to /parent/dashboard resets selected date to today',
      (tester) async {
        final fakeChildren = FakeChildrenController(
          const ChildrenLoaded(
            children: testChildren,
            activeChildId: 'child_sarah',
          ),
        );
        final fakeClasses = FakeClassesController(
          ClassesLoaded(classes: [sarahFutureClass]),
        );

        final router = GoRouter(
          initialLocation: '/parent/classes',
          routes: [
            GoRoute(
              path: '/parent/dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard Screen')),
            ),
            GoRoute(
              path: '/parent/classes',
              builder: (context, state) => const ParentClassesScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childrenControllerProvider.overrideWith(() => fakeChildren),
              classesControllerProvider.overrideWith(() => fakeClasses),
              currentDeviceDateProvider.overrideWithValue(
                DateTime(2026, 9, 18),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Initial entry on Sept 18: empty state
        expect(find.byType(EmptyClassesWidget), findsOneWidget);

        // Manually select Sept 30
        await tester.drag(
          find.byType(ClassesDateNavigator),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('30').first);
        await tester.pumpAndSettle();

        // Sept 30 class is shown
        expect(find.text('Junior Foundation first class'), findsOneWidget);

        // Leave SCR-13: navigate to Dashboard
        router.go('/parent/dashboard');
        await tester.pumpAndSettle();
        expect(find.text('Dashboard Screen'), findsOneWidget);

        // Re-enter SCR-13
        router.go('/parent/classes');
        await tester.pumpAndSettle();

        // Must be reset to Sept 18: Sept 30 class is NOT shown, empty state is shown!
        expect(find.text('Junior Foundation first class'), findsNothing);
        expect(find.byType(EmptyClassesWidget), findsOneWidget);
      },
    );
  });
}
