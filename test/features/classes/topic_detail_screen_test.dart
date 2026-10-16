import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_state.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/program_details_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/controllers/program_details_provider.dart';
import 'package:truelearn/features/classes/presentation/screens/parent_classes_screen.dart';
import 'package:truelearn/features/classes/presentation/screens/topic_detail_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_state.dart';

class MockChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  MockChildrenController(this.initial);
  final ChildrenState initial;

  @override
  ChildrenState build() => initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {
    if (state is ChildrenLoaded) {
      state = ChildrenLoaded(
        children: (state as ChildrenLoaded).children,
        activeChildId: studentId,
      );
    }
  }

  @override
  void reset() {}
}

class MockDashboardController extends Notifier<DashboardState>
    implements DashboardController {
  MockDashboardController(this.initial);
  final DashboardState initial;

  @override
  DashboardState build() => initial;

  @override
  Future<void> loadDashboard({
    required String? childStudentId,
    bool isRefresh = false,
  }) async {}

  @override
  Future<void> loadStudentDashboard({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void reset() {}
}

class MockClassesController extends Notifier<ClassesState>
    implements ClassesController {
  MockClassesController(this.initial);
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

  @override
  void reset() {}
}

class MockAssignmentsController extends Notifier<AssignmentsState>
    implements AssignmentsController {
  MockAssignmentsController(this.initial);
  final AssignmentsState initial;

  @override
  AssignmentsState build() => initial;

  @override
  Future<void> loadAssignments({
    String? childStudentId,
    bool isRefresh = false,
  }) async {}

  @override
  void setFilter(String filter) {}

  @override
  void reset() {}
}

void main() {
  const testChildId = 'child_rony_123';
  final fixedNow = DateTime(2026, 10, 13, 10, 0, 0);

  const testChild = ChildEntity(
    studentId: testChildId,
    firstName: 'Rony',
    lastName: 'Roul',
    explicitAge: 7,
    gender: 'male',
  );

  Widget createTestWidget({
    required ChildrenState childrenState,
    required DashboardState dashboardState,
    required ClassesState classesState,
    required AssignmentsState assignmentsState,
    ProgramDetailsEntity? programDetails,
    List<RouteBase>? extraRoutes,
  }) {
    final router = GoRouter(
      initialLocation: '/topic',
      routes: [
        GoRoute(
          path: '/topic',
          builder: (context, state) => const TopicDetailScreen(),
        ),
        ...?extraRoutes,
      ],
    );

    return ProviderScope(
      overrides: [
        currentDeviceDateProvider.overrideWithValue(fixedNow),
        childrenControllerProvider.overrideWith(
          () => MockChildrenController(childrenState),
        ),
        dashboardControllerProvider.overrideWith(
          () => MockDashboardController(dashboardState),
        ),
        classesControllerProvider.overrideWith(
          () => MockClassesController(classesState),
        ),
        assignmentsControllerProvider.overrideWith(
          () => MockAssignmentsController(assignmentsState),
        ),
        if (programDetails != null)
          programDetailsProvider(testChildId)
              .overrideWith((ref) => Future.value(programDetails)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('TopicDetailScreen Backend API Connection & Audit Tests', () {
    testWidgets(
      '1. Successful API response mapping for each supported section',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final programDetails = ProgramDetailsEntity(
          courseName: 'Future-Ready Builders',
          courseCode: 'TL-FRB-02',
          description:
              'A project-based program for technology and problem-solving.',
          level: 'intermediate',
          instructor: 'Jack Sparrow',
          progress: 5.0,
        );

        final liveClass = ClassEntity(
          id: 'class_live_1',
          title: 'test_record',
          scheduledStartTime: DateTime(2026, 10, 13, 9, 56),
          scheduledEndTime: DateTime(2026, 10, 13, 13, 56),
          teacherName: 'Jack Sparrow',
          status: 'scheduled',
          effectiveStatus: 'live',
        );

        final assignment = AssignmentEntity(
          id: 'assignment_1',
          title: 'test',
          description: '<p>Project submission file</p>',
          topic: 'Communication',
          status: AssignmentStatus.pending,
          dueDate: 'Due: Oct 19, 2026',
          childStudentId: testChildId,
        );

        await tester.pumpWidget(
          createTestWidget(
            childrenState: const ChildrenLoaded(
              children: [testChild],
              activeChildId: testChildId,
            ),
            dashboardState: const DashboardLoaded(
              childStudentId: testChildId,
              dashboard: DashboardEntity(
                overallProgress: 5.0,
                activeTopic: 'Future-Ready Builders',
              ),
            ),
            classesState: ClassesLoaded(
              childStudentId: testChildId,
              classes: [liveClass],
            ),
            assignmentsState: AssignmentsLoaded(
              childStudentId: testChildId,
              allAssignments: [assignment],
            ),
            programDetails: programDetails,
          ),
        );

        await tester.pumpAndSettle();

        // Top App Bar
        expect(
          find.byKey(const Key('topic_detail_back_button')),
          findsOneWidget,
        );

        // Hero Section displays actual backend data
        expect(find.text('TL-FRB-02'), findsOneWidget);
        expect(find.text('Future-Ready Builders'), findsOneWidget);
        expect(
          find.text(
            'A project-based program for technology and problem-solving.',
          ),
          findsOneWidget,
        );

        // Live Class Card displays actual class title, time, teacher
        expect(find.text('Live Class'), findsOneWidget);
        expect(find.text('test_record'), findsOneWidget);
        expect(find.text('Instructor: Jack Sparrow'), findsOneWidget);
        expect(
          find.byKey(const Key('topic_detail_live_class_card')),
          findsOneWidget,
        );

        // Assignment Card displays actual assignment title, due date, description
        expect(find.text('Assignment'), findsOneWidget);
        expect(find.text('test'), findsOneWidget);
        expect(find.text('Due: Oct 19, 2026'), findsOneWidget);
        expect(find.text('Project submission file'), findsOneWidget);
        expect(
          find.byKey(const Key('topic_detail_assignment_submit_button')),
          findsOneWidget,
        );

        // Topic Progress Card displays authoritative 5%
        expect(find.text('Topic Progress'), findsOneWidget);
        expect(find.textContaining('5', findRichText: true), findsWidgets);
        expect(find.textContaining('%', findRichText: true), findsWidgets);
        expect(find.text('In Progress'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Missing optional response fields handled gracefully without crashes',
      (tester) async {
        final minimalProgram = ProgramDetailsEntity(
          courseName: null,
          courseCode: null,
          description: null,
          progress: null,
        );

        final minimalClass = ClassEntity(
          id: 'class_min_1',
          title: 'Session Without Teacher',
          scheduledStartTime: DateTime(2026, 10, 13, 11, 0),
          scheduledEndTime: DateTime(2026, 10, 13, 12, 0),
          status: 'scheduled',
        );

        final minimalAssignment = AssignmentEntity(
          id: 'ass_min_1',
          title: 'Minimal Assignment',
          description: null,
          topic: 'General',
          status: AssignmentStatus.pending,
          dueDate: null,
          childStudentId: testChildId,
        );

        await tester.pumpWidget(
          createTestWidget(
            childrenState: const ChildrenLoaded(
              children: [testChild],
              activeChildId: testChildId,
            ),
            dashboardState: const DashboardLoaded(
              childStudentId: testChildId,
              dashboard: DashboardEntity(),
            ),
            classesState: ClassesLoaded(
              childStudentId: testChildId,
              classes: [minimalClass],
            ),
            assignmentsState: AssignmentsLoaded(
              childStudentId: testChildId,
              allAssignments: [minimalAssignment],
            ),
            programDetails: minimalProgram,
          ),
        );

        await tester.pumpAndSettle();

        // Verify no crashes and graceful fallbacks
        expect(find.text('Session Without Teacher'), findsOneWidget);
        expect(find.text('Minimal Assignment'), findsOneWidget);
        expect(find.textContaining('--', findRichText: true), findsWidgets);
        expect(find.text('Pending Start'), findsOneWidget);
      },
    );

    testWidgets('3. Empty API responses display clean empty states', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          childrenState: const ChildrenLoaded(
            children: [testChild],
            activeChildId: testChildId,
          ),
          dashboardState: const DashboardLoaded(
            childStudentId: testChildId,
            dashboard: DashboardEntity(),
          ),
          classesState: const ClassesLoaded(
            childStudentId: testChildId,
            classes: [],
          ),
          assignmentsState: const AssignmentsLoaded(
            childStudentId: testChildId,
            allAssignments: [],
          ),
          programDetails: ProgramDetailsEntity(
            courseName: 'Future-Ready Builders',
            progress: 0.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Empty states are shown cleanly without fabricating records
      expect(find.text('No Live Classes Scheduled'), findsOneWidget);
      expect(
        find.text('No upcoming sessions are scheduled for this child.'),
        findsOneWidget,
      );
      expect(find.text('No Pending Assignments'), findsOneWidget);
      expect(
        find.text('You are all caught up on assignments for this track.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '4. API failures display distinct error banners with retry action',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            childrenState: const ChildrenLoaded(
              children: [testChild],
              activeChildId: testChildId,
            ),
            dashboardState: const DashboardLoaded(
              childStudentId: testChildId,
              dashboard: DashboardEntity(),
            ),
            classesState: const ClassesError(
              message: 'Connection timed out for schedule.',
            ),
            assignmentsState: const AssignmentsError(
              'Unable to load assignments.',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Error messages appear distinctly
        expect(find.text('Connection timed out for schedule.'), findsOneWidget);
        expect(find.text('Unable to load assignments.'), findsOneWidget);
        expect(find.text('Retry'), findsWidgets);
      },
    );

    testWidgets(
      '5. Unsupported sections and nonfunctional actions are removed',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            childrenState: const ChildrenLoaded(
              children: [testChild],
              activeChildId: testChildId,
            ),
            dashboardState: const DashboardLoaded(
              childStudentId: testChildId,
              dashboard: DashboardEntity(),
            ),
            classesState: const ClassesLoaded(
              childStudentId: testChildId,
              classes: [],
            ),
            assignmentsState: const AssignmentsLoaded(
              childStudentId: testChildId,
              allAssignments: [],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify removal of mock Practice section
        expect(find.text('Practice'), findsNothing);
        expect(find.text('Self-paced modules'), findsNothing);
        expect(find.text('Voice'), findsNothing);
        expect(find.text('Poise'), findsNothing);
        expect(find.text('Clarity'), findsNothing);
        expect(find.text('Start Practice'), findsNothing);

        // Verify removal of hardcoded mock descriptions
        expect(find.text('Tomorrow, 7:00 PM'), findsNothing);
        expect(find.textContaining('Instructor Sarah'), findsNothing);
        expect(find.text('Due in 3 days'), findsNothing);
        expect(
          find.textContaining('Record a 2-minute reflection'),
          findsNothing,
        );
        expect(find.text('Submit Reflection'), findsNothing);
      },
    );

    testWidgets('6. Correct class and assignment navigation where supported', (
      tester,
    ) async {
      final liveClass = ClassEntity(
        id: 'cls_target_99',
        title: 'Interactive Robotics',
        scheduledStartTime: DateTime(2026, 10, 13, 10, 30),
        scheduledEndTime: DateTime(2026, 10, 13, 11, 30),
        status: 'scheduled',
      );

      final assignment = AssignmentEntity(
        id: 'ass_target_88',
        title: 'Build a Bridge',
        topic: 'Engineering',
        status: AssignmentStatus.pending,
        dueDate: 'Due: Oct 25',
        childStudentId: testChildId,
      );

      String? pushedRoute;

      final extraRoutes = [
        GoRoute(
          path: '/parent/classes/:classId',
          builder: (context, state) {
            pushedRoute = '/parent/classes/${state.pathParameters['classId']}';
            return const Scaffold(body: Text('Class Details Screen'));
          },
        ),
        GoRoute(
          path: '/parent/assignments/:assignmentId',
          builder: (context, state) {
            pushedRoute =
                '/parent/assignments/${state.pathParameters['assignmentId']}';
            return const Scaffold(body: Text('Assignment Details Screen'));
          },
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          childrenState: const ChildrenLoaded(
            children: [testChild],
            activeChildId: testChildId,
          ),
          dashboardState: const DashboardLoaded(
            childStudentId: testChildId,
            dashboard: DashboardEntity(),
          ),
          classesState: ClassesLoaded(
            childStudentId: testChildId,
            classes: [liveClass],
          ),
          assignmentsState: AssignmentsLoaded(
            childStudentId: testChildId,
            allAssignments: [assignment],
          ),
          extraRoutes: extraRoutes,
        ),
      );

      await tester.pumpAndSettle();

      // Tap Live Class card -> navigates to /parent/classes/:classId
      final classCard = find.byKey(const Key('topic_detail_live_class_card'));
      expect(classCard, findsOneWidget);
      await tester.tap(classCard);
      await tester.pumpAndSettle();
      expect(pushedRoute, equals('/parent/classes/cls_target_99'));
      expect(find.text('Class Details Screen'), findsOneWidget);

      // Pop back
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      // Tap View Assignment button -> navigates to /parent/assignments/:assignmentId
      final assignmentBtn = find.byKey(
        const Key('topic_detail_assignment_submit_button'),
      );
      expect(assignmentBtn, findsOneWidget);
      await tester.ensureVisible(assignmentBtn);
      await tester.pumpAndSettle();
      await tester.tap(assignmentBtn);
      await tester.pumpAndSettle();
      expect(pushedRoute, equals('/parent/assignments/ass_target_88'));
      expect(find.text('Assignment Details Screen'), findsOneWidget);
    });

    testWidgets(
      '7. Switching child updates child context without stale leakage',
      (tester) async {
        final childAAssignment = AssignmentEntity(
          id: 'ass_A',
          title: 'Child A Assignment',
          topic: 'Math',
          status: AssignmentStatus.pending,
          childStudentId: 'child_A',
        );

        final childBAssignment = AssignmentEntity(
          id: 'ass_B',
          title: 'Child B Assignment',
          topic: 'Science',
          status: AssignmentStatus.pending,
          childStudentId: 'child_B',
        );

        await tester.pumpWidget(
          createTestWidget(
            childrenState: const ChildrenLoaded(
              children: [
                ChildEntity(
                  studentId: 'child_A',
                  firstName: 'Child',
                  lastName: 'A',
                  explicitAge: 7,
                ),
                ChildEntity(
                  studentId: 'child_B',
                  firstName: 'Child',
                  lastName: 'B',
                  explicitAge: 9,
                ),
              ],
              activeChildId: 'child_A',
            ),
            dashboardState: const DashboardLoaded(
              childStudentId: 'child_A',
              dashboard: DashboardEntity(),
            ),
            classesState: const ClassesLoaded(
              childStudentId: 'child_A',
              classes: [],
            ),
            assignmentsState: AssignmentsLoaded(
              childStudentId: 'child_A',
              allAssignments: [childAAssignment, childBAssignment],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Child A is active -> Child A assignment is shown
        expect(find.text('Child A Assignment'), findsOneWidget);
        expect(find.text('Child B Assignment'), findsNothing);
      },
    );
  });
}
