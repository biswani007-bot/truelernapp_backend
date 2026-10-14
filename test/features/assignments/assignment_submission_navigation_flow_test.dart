import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_names.dart' hide AppRoutePaths;
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/assignments/data/repositories/assignments_repository_impl.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_submission_entity.dart';
import 'package:truelearn/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<String?> checkPersistedSession() async => 'fake_parent_jwt_token';
  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
}

class _FakeDashboardRepo implements DashboardRepository {
  @override
  Future<List<ChildEntity>> getLinkedChildren() async => const [
    ChildEntity(
      studentId: 'child_sarah',
      firstName: 'Sarah',
      lastName: 'Connor',
    ),
  ];

  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    return const DashboardEntity(
      studentName: 'Sarah Connor',
      activeTopic: 'Junior Foundation',
      pendingAssignmentsCount: 1,
      enrolledBatches: [
        EnrolledBatchEntity(
          id: 'batch_1',
          batchName: 'Batch 2026',
          courseName: 'Junior Foundation',
          instructor: 'Dr. Elizabeth Vance',
          batchCode: 'JF-2026-A',
        ),
      ],
    );
  }
}

class _FakeClassesRepo implements ClassesRepository {
  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async {
    return [
      ClassEntity(
        id: 'cls_1',
        title: 'Speaking With Confidence',
        subject: 'Junior Foundation',
        status: 'UPCOMING',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 1)),
        scheduledEndTime: DateTime.now().add(const Duration(hours: 2)),
        teacherName: 'Dr. Elizabeth Vance',
      ),
    ];
  }

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async => throw UnimplementedError();
}

class _FakeAssignmentsRepo implements AssignmentsRepository {
  @override
  Future<List<AssignmentEntity>> getAssignments({
    required String childStudentId,
  }) async {
    return [
      AssignmentEntity(
        id: 'asg_99',
        title: 'Design a Rube Goldberg Machine',
        topic: 'Practical Thinking',
        status: AssignmentStatus.completed,
        dueDate: 'Due: Friday, 11:59 PM',
        submission: AssignmentSubmissionEntity(
          id: 'sub_99',
          status: SubmissionStatus.submitted,
          submittedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          rawStatus: 'under_review',
        ),
      ),
    ];
  }

  @override
  Future<AssignmentEntity?> getAssignmentDetail({
    required String childStudentId,
    required String assignmentId,
  }) async {
    return AssignmentEntity(
      id: assignmentId,
      title: 'Design a Rube Goldberg Machine',
      topic: 'Practical Thinking',
      status: AssignmentStatus.completed,
      dueDate: 'Due: Friday, 11:59 PM',
      submission: AssignmentSubmissionEntity(
        id: 'sub_99',
        status: SubmissionStatus.submitted,
        submittedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        rawStatus: 'under_review',
      ),
    );
  }

  @override
  Future<AssignmentSubmissionEntity> submitAssignment({
    required String childStudentId,
    required String assignmentId,
    required String fileName,
    required int fileSize,
    required String fileType,
    String? fileUrl,
    String? comments,
  }) async => throw UnimplementedError();
}

class _MockChildrenController extends ChildrenController {
  @override
  ChildrenState build() => const ChildrenLoaded(
    children: [
      ChildEntity(
        studentId: 'child_sarah',
        firstName: 'Sarah',
        lastName: 'Connor',
      ),
    ],
    activeChildId: 'child_sarah',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Assignment Submission Navigation Flow Regression Tests', () {
    testWidgets(
      'Exact Sequence: Dashboard -> Assignment Submitted -> View Class Details -> Active Track -> Back -> BACK TO LEARNING -> Dashboard with no Navigator assertion',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepo()),
            classesRepositoryProvider.overrideWithValue(_FakeClassesRepo()),
            assignmentsRepositoryProvider.overrideWithValue(
              _FakeAssignmentsRepo(),
            ),
            childrenControllerProvider.overrideWith(
              () => _MockChildrenController(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Verify authenticated session
        await container.read(authControllerProvider.notifier).checkSession();

        final router = container.read(routerProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Dashboard
        router.go(AppRoutePaths.parentDashboard);
        await tester.pumpAndSettle();

        // Verify on Parent Dashboard
        expect(
          find.byKey(const Key('parent_dashboard_screen')),
          findsOneWidget,
        );

        // Open submitted assignment screen directly via router
        router.pushNamed(
          AppRouteNames.assignmentSubmitted,
          pathParameters: {'assignmentId': 'asg_99'},
        );
        await tester.pumpAndSettle();

        // Step A: Verify on Assignment Submitted screen
        expect(find.text('Assignment Submitted'), findsOneWidget);
        expect(
          find.byKey(const Key('view_class_details_link')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('back_to_learning_button')),
          findsOneWidget,
        );

        // Tap "View Class Details ->"
        await tester.ensureVisible(
          find.byKey(const Key('view_class_details_link')),
        );
        await tester.tap(find.byKey(const Key('view_class_details_link')));
        await tester.pumpAndSettle();

        // Step B: Verify on Active Track screen
        expect(
          find.byKey(const Key('current_program_back_button')),
          findsOneWidget,
        );
        expect(find.text('Skills in Focus'), findsOneWidget);

        // Tap TopAppBar Back Button -> returns to Assignment Submitted
        await tester.tap(find.byKey(const Key('current_program_back_button')));
        await tester.pumpAndSettle();

        expect(find.text('Assignment Submitted'), findsOneWidget);

        // Step C: Tap "BACK TO LEARNING" -> returns directly to Parent Dashboard
        await tester.ensureVisible(
          find.byKey(const Key('back_to_learning_button')),
        );
        await tester.tap(find.byKey(const Key('back_to_learning_button')));
        await tester.pumpAndSettle();

        // Verify landed on Parent Dashboard
        expect(
          find.byKey(const Key('parent_dashboard_screen')),
          findsOneWidget,
        );
        expect(find.text('Assignment Submitted'), findsNothing);

        // Step D: Repeat full cycle to confirm no Navigator key collision or dirty stack
        router.pushNamed(
          AppRouteNames.assignmentSubmitted,
          pathParameters: {'assignmentId': 'asg_99'},
        );
        await tester.pumpAndSettle();

        expect(find.text('Assignment Submitted'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('view_class_details_link')),
        );
        await tester.tap(find.byKey(const Key('view_class_details_link')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('current_program_back_button')),
          findsOneWidget,
        );
        expect(find.text('Skills in Focus'), findsOneWidget);

        // Simulate Android Back via TopAppBar back
        await tester.tap(find.byKey(const Key('current_program_back_button')));
        await tester.pumpAndSettle();

        expect(find.text('Assignment Submitted'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('back_to_learning_button')),
        );
        await tester.tap(find.byKey(const Key('back_to_learning_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('parent_dashboard_screen')),
          findsOneWidget,
        );
      },
    );
  });
}
