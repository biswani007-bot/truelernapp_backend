import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_state.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/screens/current_program_screen.dart';
import 'package:truelearn/features/classes/presentation/screens/parent_classes_screen.dart';
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

  void updateState(ChildrenState next) {
    state = next;
  }
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

  void updateState(DashboardState next) {
    state = next;
  }
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

  void updateState(ClassesState next) {
    state = next;
  }
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

  void updateState(AssignmentsState next) {
    state = next;
  }
}

void main() {
  const childRony = ChildEntity(
    studentId: 'child_rony',
    firstName: 'Rony',
    lastName: 'Roul',
    grade: 'Grade 2',
  );

  const childSarah = ChildEntity(
    studentId: 'child_sarah',
    firstName: 'Sarah',
    lastName: 'Connor',
    grade: 'Grade 3',
  );

  final testToday = DateTime(2026, 10, 13, 10, 0);

  group('Dashboard Backend Data & Progress Audit Tests', () {
    testWidgets('1. Progress percentage and progress-bar fill agree', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Backend returns 5.0% progress for Rony (Future-Ready Builders)
      const dashboard = DashboardEntity(
        studentName: 'Rony Roul',
        overallProgress: 5.0,
        enrolledBatches: [
          EnrolledBatchEntity(
            id: 'batch_frb',
            batchName: 'ALPHA BETA',
            courseName: 'Future-Ready Builders',
            instructor: 'Jack Sparrow',
            batchCode: 'BTH-0030',
            progressPercentage: 5.0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => MockDashboardController(
                const DashboardLoaded(
                  childStudentId: 'child_rony',
                  dashboard: dashboard,
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => MockClassesController(
                const ClassesLoaded(classes: [], childStudentId: 'child_rony'),
              ),
            ),
            assignmentsControllerProvider.overrideWith(
              () => MockAssignmentsController(
                const AssignmentsLoaded(
                  allAssignments: [],
                  childStudentId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check numeric percentage text
      expect(
        find.byKey(const Key('current_program_progress_percentage')),
        findsOneWidget,
      );
      expect(find.text('5%'), findsOneWidget);

      // Check progress bar fill widthFactor
      final fractionFinder = find.byType(FractionallySizedBox);
      expect(fractionFinder, findsWidgets);

      bool foundMatchingFill = false;
      for (final element in fractionFinder.evaluate()) {
        final widget = element.widget as FractionallySizedBox;
        if (widget.widthFactor != null && (widget.widthFactor! - 0.05).abs() < 0.001) {
          foundMatchingFill = true;
          break;
        }
      }
      expect(
        foundMatchingFill,
        isTrue,
        reason: 'Visual fill widthFactor must be 0.05 corresponding to 5%',
      );
    });

    testWidgets('2. A valid backend progress value is not replaced by an unrelated fallback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Attendance is 100%, but academic progress is 25%
      const dashboard = DashboardEntity(
        studentName: 'Rony Roul',
        attendanceRate: 100.0,
        overallProgress: 25.0,
        enrolledBatches: [
          EnrolledBatchEntity(
            id: 'batch_frb',
            batchName: 'ALPHA BETA',
            courseName: 'Future-Ready Builders',
            instructor: 'Jack Sparrow',
            batchCode: 'BTH-0030',
            progressPercentage: 25.0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => MockDashboardController(
                const DashboardLoaded(
                  childStudentId: 'child_rony',
                  dashboard: dashboard,
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => MockClassesController(
                const ClassesLoaded(classes: [], childStudentId: 'child_rony'),
              ),
            ),
            assignmentsControllerProvider.overrideWith(
              () => MockAssignmentsController(
                const AssignmentsLoaded(
                  allAssignments: [],
                  childStudentId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Progress shows 25%, not replaced by attendance 100% or arbitrary 50%
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('100%'), findsNothing);

      final fractionFinder = find.byType(FractionallySizedBox);
      bool foundMatchingFill = false;
      for (final element in fractionFinder.evaluate()) {
        final widget = element.widget as FractionallySizedBox;
        if (widget.widthFactor != null && (widget.widthFactor! - 0.25).abs() < 0.001) {
          foundMatchingFill = true;
          break;
        }
      }
      expect(foundMatchingFill, isTrue);
    });

    testWidgets('3. Missing progress data does not masquerade as a verified value', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Progress is null (e.g. newly enrolled without recorded progress)
      const dashboard = DashboardEntity(
        studentName: 'Rony Roul',
        overallProgress: null,
        enrolledBatches: [
          EnrolledBatchEntity(
            id: 'batch_frb',
            batchName: 'ALPHA BETA',
            courseName: 'Future-Ready Builders',
            instructor: 'Jack Sparrow',
            batchCode: 'BTH-0030',
            progressPercentage: null,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => MockDashboardController(
                const DashboardLoaded(
                  childStudentId: 'child_rony',
                  dashboard: dashboard,
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => MockClassesController(
                const ClassesLoaded(classes: [], childStudentId: 'child_rony'),
              ),
            ),
            assignmentsControllerProvider.overrideWith(
              () => MockAssignmentsController(
                const AssignmentsLoaded(
                  allAssignments: [],
                  childStudentId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Displays '--' instead of pretending to be '0%' or fake '50%'
      expect(
        find.byKey(const Key('current_program_progress_percentage')),
        findsOneWidget,
      );
      expect(find.text('--'), findsOneWidget);
      expect(
        find.byKey(const Key('current_program_progress_bar_fill')),
        findsNothing,
      );
    });

    testWidgets('4. Today\'s class is selected using actual date/time and documented status rules', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final liveTodayClass = ClassEntity(
        id: 'cls_live',
        title: 'test_record',
        status: 'scheduled',
        effectiveStatus: 'live',
        scheduledStartTime: DateTime(2026, 10, 13, 9, 56),
        scheduledEndTime: DateTime(2026, 10, 13, 13, 56),
        duration: 240,
        teacherName: 'Jack Sparrow',
      );

      final pastCancelledClass = ClassEntity(
        id: 'cls_canc',
        title: 'Cancelled Lecture',
        status: 'cancelled',
        scheduledStartTime: DateTime(2026, 10, 13, 8, 0),
        scheduledEndTime: DateTime(2026, 10, 13, 9, 0),
        duration: 60,
      );

      final pastCompletedClass = ClassEntity(
        id: 'cls_comp',
        title: 'Old Finished Session',
        status: 'completed',
        scheduledStartTime: DateTime(2026, 10, 12, 10, 0),
        scheduledEndTime: DateTime(2026, 10, 12, 11, 0),
        duration: 60,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => MockDashboardController(
                const DashboardLoaded(
                  childStudentId: 'child_rony',
                  dashboard: DashboardEntity(),
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => MockClassesController(
                ClassesLoaded(
                  classes: [pastCompletedClass, pastCancelledClass, liveTodayClass],
                  childStudentId: 'child_rony',
                ),
              ),
            ),
            assignmentsControllerProvider.overrideWith(
              () => MockAssignmentsController(
                const AssignmentsLoaded(
                  allAssignments: [],
                  childStudentId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: 'test_record' is selected; cancelled and past completed are excluded
      expect(find.text('test_record'), findsOneWidget);
      expect(find.text('Cancelled Lecture'), findsNothing);
      expect(find.text('Old Finished Session'), findsNothing);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('5. Assignment count agrees with correctly filtered assignment records', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final assignments = [
        const AssignmentEntity(
          id: 'asg_1',
          title: 'test',
          topic: 'Coding',
          status: AssignmentStatus.pending,
          dueDate: 'Due: Oct 19',
          childStudentId: 'child_rony',
        ),
        const AssignmentEntity(
          id: 'asg_2',
          title: 'yest',
          topic: 'Coding',
          status: AssignmentStatus.pending,
          dueDate: 'Due: Oct 14',
          childStudentId: 'child_rony',
        ),
        // Duplicate ID: must not be counted twice
        const AssignmentEntity(
          id: 'asg_1',
          title: 'test duplicate',
          topic: 'Coding',
          status: AssignmentStatus.pending,
          childStudentId: 'child_rony',
        ),
        // Overdue assignment: must NOT be counted as pending
        const AssignmentEntity(
          id: 'asg_3',
          title: 'Past Overdue Task',
          topic: 'Coding',
          status: AssignmentStatus.overdue,
          childStudentId: 'child_rony',
        ),
        // Completed assignment: must NOT be counted as pending
        const AssignmentEntity(
          id: 'asg_4',
          title: 'Completed Task',
          topic: 'Coding',
          status: AssignmentStatus.completed,
          childStudentId: 'child_rony',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => MockDashboardController(
                const DashboardLoaded(
                  childStudentId: 'child_rony',
                  dashboard: DashboardEntity(),
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => MockClassesController(
                const ClassesLoaded(classes: [], childStudentId: 'child_rony'),
              ),
            ),
            assignmentsControllerProvider.overrideWith(
              () => MockAssignmentsController(
                AssignmentsLoaded(
                  allAssignments: assignments,
                  childStudentId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Exactly '2 Pending' (overdue and completed excluded, duplicate deduplicated)
      expect(find.text('2 Pending'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('6. Switching children refreshes all three dashboard sections without stale leakage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childrenCtrl = MockChildrenController(
        const ChildrenLoaded(
          children: [childRony, childSarah],
          activeChildId: 'child_rony',
        ),
      );

      final dashCtrl = MockDashboardController(
        const DashboardLoaded(
          childStudentId: 'child_rony',
          dashboard: DashboardEntity(
            studentName: 'Rony Roul',
            overallProgress: 5.0,
            enrolledBatches: [
              EnrolledBatchEntity(
                id: 'batch_frb',
                batchName: 'ALPHA BETA',
                courseName: 'Future-Ready Builders',
                instructor: 'Jack Sparrow',
                batchCode: 'BTH-0030',
                progressPercentage: 5.0,
              ),
            ],
          ),
        ),
      );

      final classesCtrl = MockClassesController(
        ClassesLoaded(
          classes: [
            ClassEntity(
              id: 'cls_rony',
              title: 'test_record',
              scheduledStartTime: DateTime(2026, 10, 13, 9, 56),
              scheduledEndTime: DateTime(2026, 10, 13, 13, 56),
              effectiveStatus: 'live',
            ),
          ],
          childStudentId: 'child_rony',
        ),
      );

      final assignmentsCtrl = MockAssignmentsController(
        const AssignmentsLoaded(
          allAssignments: [
            AssignmentEntity(
              id: 'asg_rony',
              title: 'test',
              topic: 'Coding',
              status: AssignmentStatus.pending,
              childStudentId: 'child_rony',
            ),
          ],
          childStudentId: 'child_rony',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(() => childrenCtrl),
            dashboardControllerProvider.overrideWith(() => dashCtrl),
            classesControllerProvider.overrideWith(() => classesCtrl),
            assignmentsControllerProvider.overrideWith(() => assignmentsCtrl),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Future-Ready Builders'), findsWidgets);
      expect(find.text('test_record'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);

      // Now switch active child to Sarah while data hasn't arrived yet
      childrenCtrl.updateState(
        const ChildrenLoaded(
          children: [childRony, childSarah],
          activeChildId: 'child_sarah',
        ),
      );

      await tester.pump();

      // Verified: Stale data from Rony is NOT leaked while Sarah's data is loading
      expect(find.text('test_record'), findsNothing);
      expect(find.text('test'), findsNothing);

      // Now load Sarah's data
      dashCtrl.updateState(
        const DashboardLoaded(
          childStudentId: 'child_sarah',
          dashboard: DashboardEntity(
            studentName: 'Sarah Connor',
            overallProgress: 45.0,
            enrolledBatches: [
              EnrolledBatchEntity(
                id: 'batch_psm',
                batchName: 'Batch Alpha',
                courseName: 'Public Speaking Mastery',
                instructor: 'Dr. Jane Smith',
                batchCode: 'PSM-101',
                progressPercentage: 45.0,
              ),
            ],
          ),
        ),
      );

      classesCtrl.updateState(
        ClassesLoaded(
          classes: [
            ClassEntity(
              id: 'cls_sarah',
              title: 'Word Puzzle',
              scheduledStartTime: DateTime(2026, 10, 13, 15, 0),
              scheduledEndTime: DateTime(2026, 10, 13, 16, 0),
              status: 'scheduled',
              effectiveStatus: 'upcoming',
            ),
          ],
          childStudentId: 'child_sarah',
        ),
      );

      assignmentsCtrl.updateState(
        const AssignmentsLoaded(
          allAssignments: [
            AssignmentEntity(
              id: 'asg_sarah',
              title: 'Speech Video Submission',
              topic: 'Speaking',
              status: AssignmentStatus.pending,
              childStudentId: 'child_sarah',
            ),
          ],
          childStudentId: 'child_sarah',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Public Speaking Mastery'), findsWidgets);
      expect(find.text('Word Puzzle'), findsOneWidget);
      expect(find.text('Speech Video Submission'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('7. API errors are not presented as successful empty responses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDateProvider.overrideWithValue(testToday),
            childrenControllerProvider.overrideWith(
              () => MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => MockDashboardController(
                const DashboardError(
                  message: 'Network timeout: unable to reach TrueLern server',
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => MockClassesController(
                const ClassesError(
                  message: 'Failed to fetch live classes',
                  childStudentId: 'child_rony',
                ),
              ),
            ),
            assignmentsControllerProvider.overrideWith(
              () => MockAssignmentsController(
                const AssignmentsError(
                  'Failed to fetch assignments',
                  childStudentId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Error banners with retry buttons are displayed; not disguised as empty states
      expect(
        find.text('Network timeout: unable to reach TrueLern server'),
        findsOneWidget,
      );
      expect(find.text('Failed to fetch live classes'), findsOneWidget);
      expect(find.text('Failed to fetch assignments'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });
  });
}
