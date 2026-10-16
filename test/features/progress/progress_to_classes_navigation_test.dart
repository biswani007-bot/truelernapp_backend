import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_names.dart' show AppRouteNames;
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';
import 'package:truelearn/features/classes/presentation/screens/parent_classes_screen.dart';
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
    return ProgressEntity(
      childStudentId: childStudentId,
      overallCompletion: childStudentId == 'child_sarah' ? 72.0 : 45.0,
      studentName: childStudentId == 'child_sarah' ? 'Sarah' : 'Ram',
      activeTrack: 'Junior Foundation',
      assignmentCompletion: const ProgressMetricEntity(
        total: 4,
        completed: 3,
        percentage: 75.0,
      ),
      attendanceSummary: const ProgressMetricEntity(
        total: 10,
        completed: 8,
        percentage: 80.0,
      ),
      assessmentCompletion: const ProgressMetricEntity(
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

class _FakeClassesRepo implements ClassesRepository {
  String? lastRequestedChildId;

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async {
    lastRequestedChildId = childStudentId;
    return [
      ClassEntity(
        id: 'cls_$childStudentId',
        title: '$childStudentId Live Class',
        subject: 'Junior Foundation',
        status: 'UPCOMING',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 1)),
        scheduledEndTime: DateTime.now().add(const Duration(hours: 2)),
        teacherName: 'Elizabeth Vance',
      ),
    ];
  }

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    throw UnimplementedError();
  }
}

class _MockChildrenController extends ChildrenController {
  _MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;

  @override
  void setActiveChild(String studentId) {
    final cur = state;
    if (cur is ChildrenLoaded) {
      state = ChildrenLoaded(children: cur.children, activeChildId: studentId);
    }
  }

  void selectChild(String studentId) => setActiveChild(studentId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const testChildren = [
    ChildEntity(
      studentId: 'child_sarah',
      firstName: 'Sarah',
      lastName: 'Connor',
    ),
    ChildEntity(studentId: 'child_ram', firstName: 'Ram', lastName: 'Pearson'),
  ];

  late _FakeProgressRepo fakeProgressRepo;
  late _FakeClassesRepo fakeClassesRepo;

  setUp(() {
    fakeProgressRepo = _FakeProgressRepo();
    fakeClassesRepo = _FakeClassesRepo();
  });

  Widget buildNavigationApp({
    String initialChildId = 'child_sarah',
    String initialLocation = AppRoutePaths.learningProgress,
  }) {
    final mockChildrenCtrl = _MockChildrenController(
      ChildrenLoaded(children: testChildren, activeChildId: initialChildId),
    );

    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutePaths.parentDashboard,
          name: AppRouteNames.parentDashboard,
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('dashboard_open_progress_button'),
                onPressed: () => context.push(AppRoutePaths.learningProgress),
                child: const Text('Go to Progress'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.learningProgress,
          name: AppRouteNames.learningProgress,
          builder: (context, state) => const ParentLearningProgressScreen(),
          routes: [
            GoRoute(
              path: 'classes',
              name: AppRouteNames.progressClasses,
              builder: (context, state) => const ParentClassesScreen(),
            ),
          ],
        ),
        // Persistent shell branch route for My Classes tab
        GoRoute(
          path: AppRoutePaths.parentClasses,
          name: AppRouteNames.parentClasses,
          builder: (context, state) => const ParentClassesScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(fakeProgressRepo),
        classesRepositoryProvider.overrideWithValue(fakeClassesRepo),
        childrenControllerProvider.overrideWith(() => mockChildrenCtrl),
        currentDeviceDateProvider.overrideWithValue(DateTime.now()),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  testWidgets(
    'REGRESSION: Tapping View Classes & Schedule does not throw Navigator key reservation assertion, '
    'opens ParentClassesScreen, queries real child API, and pops back to Progress',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Start on Parent Dashboard
      await tester.pumpWidget(
        buildNavigationApp(initialLocation: AppRoutePaths.parentDashboard),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard_open_progress_button')),
        findsOneWidget,
      );

      // 2. Navigate to Progress Screen
      await tester.tap(find.byKey(const Key('dashboard_open_progress_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('parent_learning_progress_screen')),
        findsOneWidget,
      );
      expect(find.text('Progress'), findsWidgets);

      // 3. Find and tap "View Classes & Schedule" button
      final viewClassesBtn = find.byKey(
        const Key('view_detailed_report_button'),
      );
      expect(viewClassesBtn, findsOneWidget);

      // Scroll into view if needed
      await tester.ensureVisible(viewClassesBtn);
      await tester.pumpAndSettle();

      // Tap button — MUST NOT throw '!keyReservation.contains(key)'
      await tester.tap(viewClassesBtn);
      await tester.pumpAndSettle();

      // 4. Verify Parent Classes Schedule screen opened
      expect(find.byKey(const Key('parent_classes_screen')), findsOneWidget);
      expect(find.text('My Classes'), findsOneWidget);

      // 5. Verify real Classes repository was called with active child 'child_sarah'
      expect(fakeClassesRepo.lastRequestedChildId, 'child_sarah');
      expect(find.text('child_sarah Live Class'), findsOneWidget);

      // 6. Test Back navigation — tapping back button or popping returns to Progress screen
      final backButton = find.byKey(const Key('classes_menu_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // 7. Verify back on Progress screen
      expect(
        find.byKey(const Key('parent_learning_progress_screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('parent_classes_screen')), findsNothing);

      // 8. Test Back from Progress returns to Dashboard
      final progressBackBtn = find.byKey(const Key('progress_back_button'));
      expect(progressBackBtn, findsOneWidget);
      await tester.tap(progressBackBtn);
      await tester.pumpAndSettle();

      // 9. Verify back on Dashboard
      expect(
        find.byKey(const Key('dashboard_open_progress_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Child Switching: Changing selected child to Ram Pearson propagates to Classes Schedule screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildNavigationApp(initialChildId: 'child_sarah'),
      );
      await tester.pumpAndSettle();

      // Switch to Ram on Progress Screen
      final studentSelectorBtn = find.byKey(
        const Key('classes_student_selector_button'),
      );
      expect(studentSelectorBtn, findsOneWidget);
      await tester.tap(studentSelectorBtn);
      await tester.pumpAndSettle();

      final ramOption = find.text('Ram Pearson');
      expect(ramOption, findsWidgets);
      await tester.tap(ramOption.last);
      await tester.pumpAndSettle();

      // Tap "View Classes & Schedule"
      final viewClassesBtn = find.byKey(
        const Key('view_detailed_report_button'),
      );
      await tester.ensureVisible(viewClassesBtn);
      await tester.pumpAndSettle();

      await tester.tap(viewClassesBtn);
      await tester.pumpAndSettle();

      // Verify Classes Schedule opened with Ram
      expect(find.byKey(const Key('parent_classes_screen')), findsOneWidget);
      expect(fakeClassesRepo.lastRequestedChildId, 'child_ram');
      expect(find.text('child_ram Live Class'), findsOneWidget);
    },
  );
}
