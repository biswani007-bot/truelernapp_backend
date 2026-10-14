import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_learning_progress_screen.dart';
import 'package:truelearn/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:truelearn/features/progress/domain/entities/progress_entity.dart';
import 'package:truelearn/features/progress/domain/repositories/progress_repository.dart';

class _FakeProgressRepo implements ProgressRepository {
  @override
  Future<ProgressEntity> getChildProgress({
    required String childStudentId,
    String? studentName,
    String? activeTrack,
  }) async {
    return const ProgressEntity(
      childStudentId: 'child_1',
      overallCompletion: 72.0,
      studentName: 'Alex',
      activeTrack: 'Public Speaking & Communication',
      assignmentCompletion: ProgressMetricEntity(
        total: 4,
        completed: 3,
        percentage: 75.0,
      ),
      attendanceSummary: ProgressMetricEntity(
        total: 10,
        completed: 8,
        percentage: 80.0,
      ),
      assessmentCompletion: ProgressMetricEntity(
        total: 2,
        completed: 1,
        percentage: 50.0,
      ),
    );
  }

  @override
  Future<double> getStudentCourseProgress({required String courseId}) async =>
      100.0;
}

class MockChildrenController extends ChildrenController {
  MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(_FakeProgressRepo()),
        childrenControllerProvider.overrideWith(
          () => MockChildrenController(
            const ChildrenLoaded(
              children: [
                ChildEntity(
                  studentId: 'child_1',
                  firstName: 'Alex',
                  lastName: 'Mercer',
                ),
              ],
              activeChildId: 'child_1',
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: ParentLearningProgressScreen()),
    );
  }

  group('ParentLearningProgressScreen', () {
    testWidgets('renders all UI elements accurately with Progress title', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Top App Bar
      expect(
        find.byKey(const Key('learning_progress_drawer_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('learning_progress_bell_button')),
        findsOneWidget,
      );

      // Header & Pill
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('My Progress'), findsNothing);
      expect(find.text('Public Speaking & Communication'), findsOneWidget);

      // Overall Progress Dial Card
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('Overall Mastery'), findsOneWidget);

      // Dynamic Metric Cards
      expect(find.byKey(const Key('metric_card_assignments')), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.byKey(const Key('metric_card_attendance')), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.byKey(const Key('metric_card_assessments')), findsOneWidget);
      expect(find.text('Assessments'), findsOneWidget);

      // Single Bottom Navigation Bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Classes'), findsOneWidget);
      expect(find.text('Assignment'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
