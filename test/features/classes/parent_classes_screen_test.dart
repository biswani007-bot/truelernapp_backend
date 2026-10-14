import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/screens/parent_classes_screen.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_date_navigator.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_event_card.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_filter_tabs.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_skeleton.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_student_selector.dart';
import 'package:truelearn/features/classes/presentation/widgets/empty_classes_widget.dart';
import 'package:truelearn/features/classes/presentation/widgets/error_classes_widget.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

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
  void setActiveChild(String studentId) {
    final current = state;
    if (current is ChildrenLoaded) {
      state = ChildrenLoaded(
        children: current.children,
        activeChildId: studentId,
      );
    }
  }
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testChildren = [
    ChildEntity(
      studentId: 'child_alex',
      firstName: 'Alex',
      lastName: 'Mercer',
      grade: 'Grade 4',
    ),
    ChildEntity(
      studentId: 'child_mia',
      firstName: 'Mia',
      lastName: 'Mercer',
      grade: 'Grade 6',
    ),
  ];

  final testClasses = [
    ClassEntity(
      id: 'cls_1',
      title: 'Junior Foundation first class',
      subject: 'Junior Foundation',
      status: 'UPCOMING',
      scheduledStartTime: DateTime(2026, 8, 26, 16, 0),
      scheduledEndTime: DateTime(2026, 8, 26, 17, 0),
      teacherName: 'Elizabeth Vance',
    ),
    ClassEntity(
      id: 'cls_2',
      title: 'Intro to Advanced Next.js',
      subject: 'Junior Foundation',
      status: 'UPCOMING',
      scheduledStartTime: DateTime(2026, 8, 26, 18, 0),
      scheduledEndTime: DateTime(2026, 8, 26, 19, 0),
      teacherName: 'Elizabeth Vance',
    ),
    ClassEntity(
      id: 'cls_3',
      title: 'Completed Class',
      subject: 'Junior Foundation',
      status: 'ATTENDED',
      scheduledStartTime: DateTime(2026, 8, 26, 9, 0),
      scheduledEndTime: DateTime(2026, 8, 26, 10, 0),
      teacherName: 'Elizabeth Vance',
    ),
  ];

  Widget createSubject({
    ChildrenState? childrenState,
    ClassesState? classesState,
    DateTime? currentDate,
  }) {
    final cState =
        childrenState ??
        const ChildrenLoaded(
          children: testChildren,
          activeChildId: 'child_alex',
        );

    final clState = classesState ?? ClassesLoaded(classes: testClasses);

    return ProviderScope(
      overrides: [
        childrenControllerProvider.overrideWith(
          () => FakeChildrenController(cState),
        ),
        classesControllerProvider.overrideWith(
          () => FakeClassesController(clState),
        ),
        currentDeviceDateProvider.overrideWithValue(
          currentDate ?? DateTime(2026, 8, 26),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ParentClassesScreen())),
    );
  }

  testWidgets(
    'renders Figma Frame 76:1820 TopAppBar, StudentSelector, DateNavigator, and Cards',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Top App Bar
      expect(find.byKey(const Key('parent_classes_screen')), findsOneWidget);
      expect(find.text('My Classes'), findsOneWidget);
      expect(find.byKey(const Key('classes_menu_button')), findsOneWidget);
      expect(
        find.byKey(const Key('classes_filter_icon_button')),
        findsOneWidget,
      );

      // Student Selector
      expect(find.byType(ClassesStudentSelector), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);

      // Date Navigator
      expect(find.byType(ClassesDateNavigator), findsOneWidget);

      // Filter Tabs
      expect(find.byType(ClassesFilterTabs), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Classes content
      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('Junior Foundation first class'), findsOneWidget);
      expect(find.text('Intro to Advanced Next.js'), findsOneWidget);
      expect(find.byType(ClassesEventCard), findsNWidgets(2));
      expect(
        find.byKey(const Key('explore_programs_button'), skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Filter tabs toggle between Upcoming, Completed, Missed, Cancelled',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Upcoming has 2 classes
      expect(find.byType(ClassesEventCard), findsNWidgets(2));

      // Tap Completed
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Completed has 1 class
      expect(find.text('Completed Class'), findsOneWidget);
      expect(find.byType(ClassesEventCard), findsNWidgets(1));

      // Tap Missed (has 0 classes) -> shows EmptyClassesWidget
      await tester.tap(find.text('Missed'));
      await tester.pumpAndSettle();
      expect(find.byType(EmptyClassesWidget), findsOneWidget);
      expect(find.byType(ClassesEventCard), findsNothing);
    },
  );

  testWidgets('Renders ClassesSkeleton when ClassesLoading', (tester) async {
    await tester.pumpWidget(
      createSubject(classesState: const ClassesLoading()),
    );
    await tester.pump();

    expect(find.byType(ClassesSkeleton), findsOneWidget);
    expect(find.byType(ClassesEventCard), findsNothing);
  });

  testWidgets('Renders ErrorClassesWidget when ClassesError', (tester) async {
    await tester.pumpWidget(
      createSubject(
        classesState: const ClassesError(message: 'Network failure'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorClassesWidget), findsOneWidget);
    expect(find.text('Network failure'), findsOneWidget);
  });

  testWidgets('Renders EmptyClassesWidget when ClassesLoaded with empty list', (
    tester,
  ) async {
    await tester.pumpWidget(
      createSubject(classesState: const ClassesLoaded(classes: [])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyClassesWidget), findsOneWidget);
    expect(find.byType(ClassesEventCard), findsNothing);
  });

  testWidgets('Switching child updates student selector pill state', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);

    // Tap child selector to open sheet
    final selectorButton = find.byKey(
      const Key('classes_student_selector_button'),
    );
    await tester.tap(selectorButton);
    await tester.pumpAndSettle();

    // Select Mia Mercer from sheet
    expect(find.text('Mia Mercer'), findsOneWidget);
    await tester.tap(find.text('Mia Mercer'));
    await tester.pumpAndSettle();

    expect(find.text('Mia'), findsOneWidget);
  });

  testWidgets(
    'Live class (status == "live") is visible in Upcoming filter for today',
    (tester) async {
      final liveClass = ClassEntity(
        id: 'cls_live_word_puzzle',
        title: 'Word Puzzle',
        subject: 'Junior Foundation',
        status: 'live',
        scheduledStartTime: DateTime(2026, 8, 26, 12, 45),
        scheduledEndTime: DateTime(2026, 8, 26, 15, 15),
        teacherName: 'Elizabeth Vance',
      );

      await tester.pumpWidget(
        createSubject(classesState: ClassesLoaded(classes: [liveClass])),
      );
      await tester.pumpAndSettle();

      // Upcoming is default tab; verify Word Puzzle is visible
      expect(find.text('Word Puzzle'), findsOneWidget);
      expect(find.byType(ClassesEventCard), findsOneWidget);
      expect(find.byType(EmptyClassesWidget), findsNothing);
    },
  );
}
