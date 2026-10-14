import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_names.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_state.dart';
import 'package:truelearn/features/assignments/presentation/screens/assignment_submission_screen.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/program_details_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/controllers/program_details_provider.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class FakeAuthController extends AuthController {
  FakeAuthController(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const testChildId = 'child_test_101';
  const testChild = ChildEntity(
    studentId: testChildId,
    firstName: 'Alice',
    lastName: 'Wonder',
  );

  final testClass = ClassEntity(
    id: 'cls_live_999',
    title: 'Advanced AI Session',
    scheduledStartTime: DateTime.now().add(const Duration(hours: 2)),
    scheduledEndTime: DateTime.now().add(const Duration(hours: 3)),
    status: 'scheduled',
    teacherName: 'Prof. Xavier',
  );

  final testAssignment = AssignmentEntity(
    id: 'asg_task_777',
    title: 'Design a Robot',
    topic: 'Robotics',
    description: 'Build a sample layout',
    status: AssignmentStatus.pending,
    dueDate: 'Due: Oct 20',
    childStudentId: testChildId,
  );

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => FakeAuthController(
            const Authenticated(
              accessToken: 'test_token',
              user: UserDto(
                id: 'parent_1',
                email: 'parent@truelearn.com',
                role: 'PARENT',
                name: 'Parent User',
              ),
            ),
          ),
        ),
        childrenControllerProvider.overrideWith(
          () => FakeChildrenController(
            const ChildrenLoaded(
              children: [testChild],
              activeChildId: testChildId,
            ),
          ),
        ),
        classesControllerProvider.overrideWith(
          () => FakeClassesController(
            ClassesLoaded(childStudentId: testChildId, classes: [testClass]),
          ),
        ),
        assignmentsControllerProvider.overrideWith(
          () => FakeAssignmentsController(
            AssignmentsLoaded(
              childStudentId: testChildId,
              allAssignments: [testAssignment],
            ),
          ),
        ),
        programDetailsProvider(testChildId).overrideWith(
          (ref) async => const ProgramDetailsEntity(
            courseName: 'Robotics 101',
            courseCode: 'ROB-01',
            description: 'Learn modern robotics and logic.',
            level: 'Beginner',
            progress: 25,
          ),
        ),
      ],
    );
  }

  testWidgets(
    'TopicDetailScreen navigates to Live Class and View Assignment without keyReservation assertion',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = createContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to TopicDetailScreen
      router.push(AppRoutePaths.topicDetail);
      await tester.pumpAndSettle();

      expect(find.text('Robotics 101'), findsOneWidget);
      expect(find.text('Advanced AI Session'), findsOneWidget);
      expect(find.text('Design a Robot'), findsOneWidget);

      // 2. Tap Live Class card once
      final liveClassCard = find.byKey(
        const Key('topic_detail_live_class_card'),
      );
      expect(liveClassCard, findsOneWidget);
      await tester.tap(liveClassCard);
      await tester.pumpAndSettle();

      // Verify we arrived at ClassDetailsScreen without any assertion crash
      expect(
        find.byKey(const Key('back_to_my_classes_button')),
        findsOneWidget,
      );
      expect(find.text('Advanced AI Session'), findsOneWidget);

      // 3. Android back navigation from Live Class
      final backButton = find.byKey(const Key('back_to_my_classes_button'));
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verified back on TopicDetailScreen
      expect(find.text('Robotics 101'), findsOneWidget);

      // 4. Tap View Assignment button once
      final assignmentBtn = find.byKey(
        const Key('topic_detail_assignment_submit_button'),
      );
      expect(assignmentBtn, findsOneWidget);
      await tester.ensureVisible(assignmentBtn);
      await tester.pumpAndSettle();
      await tester.tap(assignmentBtn);
      await tester.pumpAndSettle();

      // Verify we arrived at AssignmentSubmissionScreen without assertion crash
      expect(find.byType(AssignmentSubmissionScreen), findsOneWidget);

      // 5. Back navigation from Assignment
      final navState = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navState.pop();
      await tester.pumpAndSettle();

      // Verified back on TopicDetailScreen
      expect(find.text('Robotics 101'), findsOneWidget);

      // 6. Rapidly tap Live Class multiple times (verify debouncing & no duplicate push)
      await tester.tap(liveClassCard);
      await tester.tap(liveClassCard);
      await tester.pumpAndSettle();

      // Screen opens exactly once
      expect(
        find.byKey(const Key('back_to_my_classes_button')),
        findsOneWidget,
      );

      // Pop back
      await tester.tap(find.byKey(const Key('back_to_my_classes_button')));
      await tester.pumpAndSettle();

      // 7. Successive navigation between both destinations
      await tester.ensureVisible(assignmentBtn);
      await tester.tap(assignmentBtn);
      await tester.pumpAndSettle();
      expect(find.byType(AssignmentSubmissionScreen), findsOneWidget);

      final navState2 = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navState2.pop();
      await tester.pumpAndSettle();

      await tester.tap(liveClassCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('back_to_my_classes_button')),
        findsOneWidget,
      );
    },
  );
}
