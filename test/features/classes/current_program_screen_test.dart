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
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_state.dart';

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
  void setActiveChild(String studentId) {}

  @override
  void reset() {}
}

class FakeDashboardController extends Notifier<DashboardState>
    implements DashboardController {
  FakeDashboardController(this.initial);
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

  @override
  void reset() {}
}

class FakeAssignmentsController extends Notifier<AssignmentsState>
    implements AssignmentsController {
  FakeAssignmentsController(this.initial);
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
  testWidgets(
    'CurrentProgramScreen renders structural elements in loading state',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CurrentProgramScreen())),
      );

      // Initial frame
      await tester.pump();

      // 1. Top App Bar back button is always rendered
      expect(
        find.byKey(const Key('current_program_back_button')),
        findsOneWidget,
      );

      // 2. Skills in Focus section is always shown
      expect(find.text('Skills in Focus'), findsOneWidget);
    },
  );

  testWidgets(
    'CurrentProgramScreen renders dynamic backend API data and CTA button when loaded',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const child = ChildEntity(
        studentId: 'child_1',
        firstName: 'Sarah',
        lastName: 'Connor',
        grade: 'Grade 3',
      );

      const dashboard = DashboardEntity(
        studentName: 'Sarah Connor',
        attendanceRate: 50.0,
        upcomingClassesCount: 1,
        pendingAssignmentsCount: 1,
        enrolledBatches: [
          EnrolledBatchEntity(
            id: 'batch_1',
            batchName: 'Batch Alpha',
            courseName: 'Public Speaking Mastery',
            instructor: 'Dr. Jane Smith',
            batchCode: 'PSM-101',
          ),
        ],
      );

      final classItem = ClassEntity(
        id: 'cls_1',
        title: 'Speech Structure & Delivery',
        subject: 'Public Speaking',
        status: 'UPCOMING',
        scheduledStartTime: DateTime.now().add(const Duration(days: 1)),
        scheduledEndTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
        teacherName: 'Dr. Jane Smith',
      );

      const assignment = AssignmentEntity(
        id: 'asg_1',
        title: 'Introductory Speech Video',
        topic: 'Public Speaking',
        dueDate: 'Due in 2 days',
        status: AssignmentStatus.pending,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            childrenControllerProvider.overrideWith(
              () => FakeChildrenController(
                const ChildrenLoaded(
                  children: [child],
                  activeChildId: 'child_1',
                ),
              ),
            ),
            dashboardControllerProvider.overrideWith(
              () => FakeDashboardController(
                const DashboardLoaded(
                  childStudentId: 'child_1',
                  dashboard: dashboard,
                ),
              ),
            ),
            classesControllerProvider.overrideWith(
              () => FakeClassesController(ClassesLoaded(classes: [classItem])),
            ),
            assignmentsControllerProvider.overrideWith(
              () => FakeAssignmentsController(
                const AssignmentsLoaded(allAssignments: [assignment]),
              ),
            ),
          ],
          child: const MaterialApp(home: CurrentProgramScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dynamic track/course name from API
      expect(find.text('Public Speaking Mastery'), findsWidgets);
      expect(find.text('ACTIVE TRACK'), findsOneWidget);

      // Verify live class from API
      expect(find.text('Speech Structure & Delivery'), findsOneWidget);

      // Verify assignment from API
      expect(find.text('Introductory Speech Video'), findsOneWidget);
      expect(find.text('1 Pending'), findsOneWidget);

      // Verify View All Tasks button
      expect(find.byKey(const Key('view_all_tasks_button')), findsOneWidget);

      // Verify Skills in Focus
      expect(find.text('Skills in Focus'), findsOneWidget);
    },
  );
}
