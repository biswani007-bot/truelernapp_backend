import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/data/repositories/class_summary_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_summary_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/class_summary_repository.dart';
import 'package:truelearn/features/classes/presentation/screens/class_summary_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class FakeScreenSummaryRepository implements ClassSummaryRepository {
  ClassSummaryEntity? entity;
  bool shouldThrow = false;

  @override
  Future<ClassSummaryEntity> getClassSummary({
    required String childStudentId,
    required String classId,
    ClassEntity? session,
  }) async {
    if (shouldThrow) {
      throw Exception('Failed to connect to TrueLern API');
    }
    return entity ??
        ClassSummaryEntity(
          classId: classId,
          classTitle: 'Intro to Advanced Next.js',
          teacherName: 'Elizabeth Vance',
          scheduledDurationMinutes: 90,
          attendedDurationMinutes: 85,
          attendanceStatus: 'present',
          isAttended: true,
          nextClassTitle: 'Intro to Full Stack Web Development',
          nextClassTimeFormatted: 'Tomorrow, 7 PM',
          assignmentTitle: 'Module 1 Practicum: Simple Request Router',
          assignmentDueDate: 'Due Friday',
          assignmentId: 'asg-101',
        );
  }
}

class FakeScreenChildrenController extends ChildrenController {
  @override
  ChildrenState build() {
    return const ChildrenLoaded(
      children: [
        ChildEntity(
          studentId: 'child_1',
          firstName: 'Sarah',
          lastName: 'Connor',
        ),
      ],
      activeChildId: 'child_1',
    );
  }
}

void main() {
  group('ClassSummaryScreen Widget Tests', () {
    late FakeScreenSummaryRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeScreenSummaryRepository();
    });

    testWidgets('renders loaded state from backend-driven entity with real teacher and durations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classSummaryRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(FakeScreenChildrenController.new),
          ],
          child: const MaterialApp(
            home: ClassSummaryScreen(
              classId: '6a8704c1630b0bf96212bbb9',
              childStudentId: 'child_1',
            ),
          ),
        ),
      );

      // Initially shows loading state while API completes
      expect(find.text('Loading session summary...'), findsOneWidget);

      // Advance frames to trigger postFrameCallback and resolve async loading
      await tester.pump();
      await tester.pump();

      // Verify Header (Figma 76:2342)
      expect(find.byKey(const Key('summary_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('summary_notifications_button')), findsOneWidget);

      // Verify Hero elements (Figma 76:2259, 76:2261)
      expect(find.text('Class Completed'), findsOneWidget);
      expect(find.text('Attended'), findsOneWidget);
      // Formatted as attended / scheduled
      expect(find.text('85 / 90 minutes'), findsOneWidget);
      expect(find.text('Teacher: Elizabeth Vance'), findsOneWidget);

      // Verify "WHAT WE PRACTICED" section with neutral evaluation state (no fake skills)
      expect(find.text('WHAT WE PRACTICED'), findsOneWidget);
      expect(find.text('Curriculum Evaluation'), findsOneWidget);

      // Verify "NEXT STEPS" section (Figma 76:2306)
      expect(find.text('NEXT STEPS'), findsOneWidget);
      expect(find.text('Intro to Full Stack Web Development'), findsOneWidget);
      expect(find.text('Tomorrow, 7 PM'), findsOneWidget);
      expect(find.text('Module 1 Practicum: Simple Request Router'), findsOneWidget);
      expect(find.text('Due Friday'), findsOneWidget);

      // Verify CTA button (Figma 76:2337)
      expect(find.byKey(const Key('view_assignment_button')), findsOneWidget);
      expect(find.text('VIEW ASSIGNMENT'), findsOneWidget);
    });

    testWidgets('renders dynamic skills cards when provided by backend', (tester) async {
      fakeRepo.entity = const ClassSummaryEntity(
        classId: 'class-with-skills',
        classTitle: 'Junior Foundation',
        teacherName: 'Elizabeth Vance',
        scheduledDurationMinutes: 60,
        skillsPracticed: [
          SkillPracticed(
            title: 'Critical Thinking',
            svgPath: 'assets/icons/voice_mic.svg',
            colorHex: 0xFF22D3EE,
            bgColorHex: 0x1A22D3EE,
          ),
          SkillPracticed(
            title: 'Collaboration',
            svgPath: 'assets/icons/comm_bubble.svg',
            colorHex: 0xFF14B8A6,
            bgColorHex: 0x1A14B8A6,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classSummaryRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(FakeScreenChildrenController.new),
          ],
          child: const MaterialApp(
            home: ClassSummaryScreen(
              classId: 'class-with-skills',
              childStudentId: 'child_1',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Critical Thinking'), findsOneWidget);
      expect(find.text('Collaboration'), findsOneWidget);
    });

    testWidgets('renders error state when API fails with retry button', (tester) async {
      fakeRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classSummaryRepositoryProvider.overrideWithValue(fakeRepo),
            childrenControllerProvider.overrideWith(FakeScreenChildrenController.new),
          ],
          child: const MaterialApp(
            home: ClassSummaryScreen(
              classId: 'class-fail',
              childStudentId: 'child_1',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to load summary'), findsOneWidget);
      expect(find.text('Failed to connect to TrueLern API'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Back to Classes'), findsOneWidget);
    });
  });
}
