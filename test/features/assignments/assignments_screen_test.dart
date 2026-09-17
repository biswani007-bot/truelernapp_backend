import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/assignments/data/repositories/assignments_repository_impl.dart';
import 'package:truelearn/features/assignments/domain/entities/assignment_entity.dart';
import 'package:truelearn/features/assignments/domain/repositories/assignments_repository.dart';
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
  Future<List<AssignmentEntity>> getAssignments({required String childStudentId}) async {
    return itemsToReturn;
  }
}

class FakeChildrenController extends Notifier<ChildrenState> implements ChildrenController {
  @override
  ChildrenState build() => const ChildrenLoaded(
        children: [
          ChildEntity(studentId: 'child_1', firstName: 'Mia', lastName: 'Mercer', grade: 'Grade 5'),
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

  testWidgets('AssignmentsScreen renders title, filter tabs, cards, and competitions banner',
      (tester) async {
    final mockRepo = MockAssignmentsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentsRepositoryProvider.overrideWithValue(mockRepo),
          childrenControllerProvider.overrideWith(() => FakeChildrenController()),
        ],
        child: const MaterialApp(
          home: AssignmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Top App Bar & Screen Title
    expect(find.text('My Assignments'), findsOneWidget);
    expect(find.byKey(const Key('assignments_menu_button')), findsOneWidget);
    expect(find.byKey(const Key('assignments_notifications_button')), findsOneWidget);

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
  });
}
