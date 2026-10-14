import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/data/repositories/assignments_repository_impl.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_submission_entity.dart';
import 'package:truelearn/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_state.dart';
import 'package:truelearn/features/assignments/presentation/screens/assignments_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class MockAssignmentsRepository implements AssignmentsRepository {
  List<AssignmentEntity> itemsToReturn = const [
    AssignmentEntity(
      id: 'asg_1',
      title: "The Grandmaster's Homework",
      topic: 'Practical Thinking',
      status: AssignmentStatus.pending,
      dueDate: 'Due: Feb 20',
      buttonText: 'Open Assignment',
    ),
    AssignmentEntity(
      id: 'asg_2',
      title: 'Confidence Quiz',
      topic: 'Communication',
      status: AssignmentStatus.completed,
      score: 95,
      totalMarks: 100,
    ),
    AssignmentEntity(
      id: 'asg_3',
      title: 'Daily Habits Tracker',
      topic: 'Time Management',
      status: AssignmentStatus.overdue,
      overdueDate: 'Was due: Feb 10',
      buttonText: 'Submit Late',
      isLateSubmissionAllowed: true,
    ),
  ];

  @override
  Future<List<AssignmentEntity>> getAssignments({
    required String childStudentId,
  }) async {
    return itemsToReturn;
  }

  @override
  Future<AssignmentEntity?> getAssignmentDetail({
    required String childStudentId,
    required String assignmentId,
  }) async {
    return itemsToReturn.cast<AssignmentEntity?>().firstWhere(
      (a) => a?.id == assignmentId,
      orElse: () => null,
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
  }) async {
    return AssignmentSubmissionEntity(
      id: 'sub_test',
      status: SubmissionStatus.submitted,
      submittedAt: DateTime.now(),
      files: [
        SubmissionFileEntity(
          fileName: fileName,
          fileSize: fileSize,
          fileType: fileType,
          url: fileUrl,
        ),
      ],
    );
  }
}

class FakeChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  @override
  ChildrenState build() => const ChildrenLoaded(
    children: [
      ChildEntity(
        studentId: 'child_1',
        firstName: 'Mia',
        lastName: 'Mercer',
        grade: 'Grade 5',
      ),
    ],
    activeChildId: 'child_1',
  );

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AssignmentsScreen renders title, filter tabs, cards, and competitions banner',
    (tester) async {
      final mockRepo = MockAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => FakeChildrenController(),
            ),
          ],
          child: const MaterialApp(home: AssignmentsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Top App Bar & Screen Title
      expect(find.text('My Assignments'), findsOneWidget);
      expect(find.byKey(const Key('assignments_menu_button')), findsOneWidget);
      expect(
        find.byKey(const Key('assignments_notifications_button')),
        findsOneWidget,
      );

      // 2. Verify Filter Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // 3. Verify Cards List
      expect(find.text("The Grandmaster's Homework"), findsOneWidget);
      expect(find.text('Confidence Quiz'), findsOneWidget);
      expect(find.text('Daily Habits Tracker'), findsOneWidget);

      // 4. Verify Badges & Actions
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(find.text('Open Assignment'), findsOneWidget);
      expect(find.text('95/100'), findsOneWidget);
      expect(find.text('Submit Late'), findsOneWidget);

      // 5. Verify Upcoming Competitions banner
      expect(find.text('Upcoming Competitions'), findsOneWidget);
      expect(find.text('Register Now'), findsOneWidget);

      // 6. Test Filter Tab Switching to 'Pending'
      await tester.tap(find.byKey(const Key('filter_tab_Pending')));
      await tester.pumpAndSettle();

      expect(find.text("The Grandmaster's Homework"), findsOneWidget);
      expect(find.text('Confidence Quiz'), findsNothing);
      expect(find.text('Daily Habits Tracker'), findsNothing);
    },
  );

  testWidgets(
    'AssignmentsScreen renders skeleton loader while assignments are loading',
    (tester) async {
      final mockRepo = MockAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => FakeChildrenController(),
            ),
            assignmentsControllerProvider.overrideWith(
              () => DelayedLoadingAssignmentsController(),
            ),
          ],
          child: const MaterialApp(home: AssignmentsScreen()),
        ),
      );

      // Initial pump without settling completes the microtask but keeps controller in loading
      await tester.pump();

      // Verify skeleton appears and no mock cards are shown
      expect(
        find.byKey(const Key('assignments_skeleton_list')),
        findsOneWidget,
      );
      expect(find.text("The Grandmaster's Homework"), findsNothing);
      expect(find.text('Confidence Quiz'), findsNothing);
      expect(find.text('Daily Habits Tracker'), findsNothing);
    },
  );

  testWidgets(
    'AssignmentsScreen renders empty state when API returns empty list',
    (tester) async {
      final mockRepo = MockAssignmentsRepository()..itemsToReturn = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(mockRepo),
            childrenControllerProvider.overrideWith(
              () => FakeChildrenController(),
            ),
          ],
          child: const MaterialApp(home: AssignmentsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No assignments found'), findsOneWidget);
      expect(find.text("The Grandmaster's Homework"), findsNothing);
    },
  );

  testWidgets('AssignmentsScreen renders error state and retries on failure', (
    tester,
  ) async {
    final mockRepo = FailingAssignmentsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentsRepositoryProvider.overrideWithValue(mockRepo),
          childrenControllerProvider.overrideWith(
            () => FakeChildrenController(),
          ),
        ],
        child: const MaterialApp(home: AssignmentsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Failed to load assignments'), findsOneWidget);
    expect(find.byKey(const Key('assignments_retry_button')), findsOneWidget);
    expect(find.text("The Grandmaster's Homework"), findsNothing);

    // Test retry
    mockRepo.shouldFail = false;
    await tester.tap(find.byKey(const Key('assignments_retry_button')));
    await tester.pumpAndSettle();

    expect(find.text("The Grandmaster's Homework"), findsOneWidget);
    expect(find.text('Failed to load assignments'), findsNothing);
  });

  testWidgets(
    'AssignmentsScreen strictly filters by child and clears data when switching children',
    (tester) async {
      final multiRepo = ChildSpecificMockAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(multiRepo),
            childrenControllerProvider.overrideWith(
              () => MultiChildrenController(),
            ),
          ],
          child: const MaterialApp(home: AssignmentsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initially child_1 (Mia) is active
      expect(find.text("Mia's Math Quest"), findsOneWidget);
      expect(find.text('No assignments found'), findsNothing);

      // 2. Switch to child_2 (Sarah) who has 0 assignments
      expect(
        find.byKey(const Key('classes_student_selector_button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('classes_student_selector_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sarah Connor'), findsOneWidget);
      await tester.tap(find.text('Sarah Connor'));
      await tester.pumpAndSettle();

      // Sarah has 0 assignments -> empty state displayed, Mia's assignment must NOT appear
      expect(find.text("Mia's Math Quest"), findsNothing);
      expect(find.text('No assignments found'), findsOneWidget);

      // 3. Switch back to child_1 (Mia)
      await tester.tap(
        find.byKey(const Key('classes_student_selector_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mia Mercer'), findsOneWidget);
      await tester.tap(find.text('Mia Mercer'));
      await tester.pumpAndSettle();

      // Mia's assignment re-appears, empty state is gone
      expect(find.text("Mia's Math Quest"), findsOneWidget);
      expect(find.text('No assignments found'), findsNothing);
    },
  );
}

class MultiChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  @override
  ChildrenState build() => const ChildrenLoaded(
    children: [
      ChildEntity(
        studentId: 'child_1',
        firstName: 'Mia',
        lastName: 'Mercer',
        grade: 'Grade 5',
      ),
      ChildEntity(
        studentId: 'child_2',
        firstName: 'Sarah',
        lastName: 'Connor',
        grade: 'Grade 4',
      ),
    ],
    activeChildId: 'child_1',
  );

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {
    state = ChildrenLoaded(
      children: const [
        ChildEntity(
          studentId: 'child_1',
          firstName: 'Mia',
          lastName: 'Mercer',
          grade: 'Grade 5',
        ),
        ChildEntity(
          studentId: 'child_2',
          firstName: 'Sarah',
          lastName: 'Connor',
          grade: 'Grade 4',
        ),
      ],
      activeChildId: studentId,
    );
  }
}

class ChildSpecificMockAssignmentsRepository implements AssignmentsRepository {
  final Map<String, List<AssignmentEntity>> data = {
    'child_1': [
      const AssignmentEntity(
        id: 'asg_child1',
        title: "Mia's Math Quest",
        topic: 'Mathematics',
        status: AssignmentStatus.pending,
        dueDate: 'Due: Tomorrow',
        childStudentId: 'child_1',
      ),
    ],
    'child_2': [],
  };

  @override
  Future<List<AssignmentEntity>> getAssignments({
    required String childStudentId,
  }) async {
    return data[childStudentId] ?? [];
  }

  @override
  Future<AssignmentEntity?> getAssignmentDetail({
    required String childStudentId,
    required String assignmentId,
  }) async {
    return null;
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
  }) async {
    throw UnimplementedError();
  }
}

class DelayedLoadingAssignmentsController extends Notifier<AssignmentsState>
    implements AssignmentsController {
  @override
  AssignmentsState build() => const AssignmentsLoading();

  @override
  Future<void> loadAssignments({
    String? childStudentId,
    bool isRefresh = false,
  }) async {}

  @override
  void setFilter(String filter) {}
}

class FailingAssignmentsRepository extends MockAssignmentsRepository {
  bool shouldFail = true;

  @override
  Future<List<AssignmentEntity>> getAssignments({
    required String childStudentId,
  }) async {
    if (shouldFail) {
      throw Exception('Network error 500');
    }
    return itemsToReturn;
  }
}
