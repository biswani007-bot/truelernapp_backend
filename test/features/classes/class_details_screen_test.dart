import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/screens/class_details_screen.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class _StaticClassesController extends Notifier<ClassesState>
    implements ClassesController {
  _StaticClassesController(this._initial);
  final ClassesState _initial;

  @override
  ClassesState build() => _initial;

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

class _StaticChildrenController extends Notifier<ChildrenState>
    implements ChildrenController {
  _StaticChildrenController(this._initial);
  final ChildrenState _initial;

  @override
  ChildrenState build() => _initial;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  Future<void> retry() async {}

  @override
  void setActiveChild(String studentId) {}

  @override
  void reset() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSession = ClassEntity(
    id: 'test-cls-001',
    classCode: 'LVC-0004',
    title: 'Junior Foundation first class',
    subject: 'Junior Foundation',
    scheduledStartTime: DateTime(2026, 9, 30, 4, 30),
    scheduledEndTime: DateTime(2026, 9, 30, 8, 30),
    duration: 240,
    status: 'upcoming',
    teacherName: 'Elizabeth Vance',
  );

  Widget createTestWidget({
    required String classId,
    ClassEntity? session,
    ClassesState? classesState,
    ChildrenState? childrenState,
  }) {
    return ProviderScope(
      overrides: [
        if (classesState != null)
          classesControllerProvider.overrideWith(
            () => _StaticClassesController(classesState),
          ),
        if (childrenState != null)
          childrenControllerProvider.overrideWith(
            () => _StaticChildrenController(childrenState),
          ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 1416)),
          child: ClassDetailsScreen(classId: classId, session: session),
        ),
      ),
    );
  }

  group('SCR-14 ClassDetailsScreen Verification', () {
    testWidgets(
      '1-8. Renders dynamic fields from ClassEntity (title, category, teacher, date, time, duration, status)',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(classId: testSession.id, session: testSession),
        );
        await tester.pumpAndSettle();

        // Screen container exists
        expect(find.byKey(const Key('class_details_screen')), findsOneWidget);

        // Category / course pill is dynamic
        expect(
          find.byKey(const Key('class_details_category_pill')),
          findsOneWidget,
        );
        expect(find.text('JUNIOR FOUNDATION'), findsOneWidget);
        expect(find.text('COMMUNICATION & PUBLIC SPEAKING'), findsNothing);

        // Title is dynamic
        expect(find.byKey(const Key('class_details_title')), findsOneWidget);
        expect(find.text('Junior Foundation first class'), findsOneWidget);
        expect(find.text('Speaking With Confidence'), findsNothing);

        // Teacher is dynamic
        expect(
          find.byKey(const Key('class_details_info_teacher')),
          findsOneWidget,
        );
        expect(find.text('Elizabeth Vance'), findsOneWidget);
        expect(find.text('Sarah M.'), findsNothing);

        // Duration is dynamic (240 Minutes)
        expect(
          find.byKey(const Key('class_details_info_duration')),
          findsOneWidget,
        );
        expect(find.text('240 Minutes'), findsOneWidget);

        // Time range is dynamic
        expect(
          find.byKey(const Key('class_details_info_time')),
          findsOneWidget,
        );
        expect(find.text('4:30 AM - 8:30 AM'), findsOneWidget);
        expect(find.text('7:00 PM - 7:45 PM'), findsNothing);

        // Date is dynamic
        expect(
          find.byKey(const Key('class_details_info_date')),
          findsOneWidget,
        );
        expect(find.text('Wed, 30 Sep'), findsOneWidget);

        // Status badge is dynamic
        expect(
          find.byKey(const Key('class_details_status_badge')),
          findsOneWidget,
        );
        expect(find.text('UPCOMING'), findsOneWidget);
      },
    );

    testWidgets(
      '7 & 8. Today Focus and What We Will Practice display neutral messages without fake data',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(classId: testSession.id, session: testSession),
        );
        await tester.pumpAndSettle();

        // Section headers preserved
        expect(find.text("Today's Focus"), findsOneWidget);
        expect(find.text("What We'll Practice"), findsOneWidget);

        // Neutral content without fabricated text
        expect(
          find.text('Focus details are not available for this session.'),
          findsOneWidget,
        );
        expect(
          find.text('Practice details are not available for this session.'),
          findsOneWidget,
        );

        // Fake data from Figma mockups is NOT present
        expect(
          find.textContaining('Mastering vocal delivery techniques'),
          findsNothing,
        );
        expect(find.text('Voice Control'), findsNothing);
        expect(find.text('Clear Speech'), findsNothing);
      },
    );

    testWidgets('9. Dynamic Countdown does not use hardcoded 18 minutes', (
      tester,
    ) async {
      final soonSession = ClassEntity(
        id: 'cls-soon',
        title: 'Impending Live Class',
        scheduledStartTime: DateTime.now().add(const Duration(minutes: 25)),
        scheduledEndTime: DateTime.now().add(const Duration(minutes: 70)),
        duration: 45,
        status: 'upcoming',
      );

      await tester.pumpWidget(
        createTestWidget(classId: soonSession.id, session: soonSession),
      );
      await tester.pumpAndSettle();

      expect(find.text('Class is starting in 18 minutes'), findsNothing);
      final countdownFinder = find.byKey(
        const Key('class_details_countdown_text'),
      );
      expect(countdownFinder, findsOneWidget);
      final text = tester.widget<Text>(countdownFinder).data;
      expect(text, contains('Class is starting in '));
      expect(text, contains('minutes'));
      expect(text, isNot(contains('18 minutes')));
    });

    testWidgets(
      '10 & 11. Handles missing teacher and duration gracefully with safe fallback dashes',
      (tester) async {
        final minimalSession = const ClassEntity(
          id: 'cls-minimal',
          title: 'Minimal Class',
        );

        await tester.pumpWidget(
          createTestWidget(classId: minimalSession.id, session: minimalSession),
        );
        await tester.pumpAndSettle();

        // Missing fields show safe dashes
        expect(find.text('Minimal Class'), findsOneWidget);
        expect(
          find.text('—'),
          findsNWidgets(4),
        ); // Date, Time, Duration, Teacher
      },
    );

    testWidgets(
      '12. Continue to Live Class button triggers navigation without crashing',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(classId: testSession.id, session: testSession),
        );
        await tester.pumpAndSettle();

        final ctaButton = find.byKey(
          const Key('continue_to_live_class_button'),
        );
        expect(ctaButton, findsOneWidget);

        await tester.ensureVisible(ctaButton);
        await tester.tap(ctaButton);
        await tester.pumpAndSettle();

        expect(ctaButton, findsOneWidget);
      },
    );

    testWidgets('13. Back button calls Navigator.pop', (tester) async {
      bool didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              const MaterialPage(child: Scaffold(body: Text('Root Page'))),
              MaterialPage(
                child: ProviderScope(
                  child: ClassDetailsScreen(
                    classId: testSession.id,
                    session: testSession,
                  ),
                ),
              ),
            ],
            onDidRemovePage: (_) {
              didPop = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byKey(const Key('back_to_my_classes_button'));
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });

    testWidgets(
      '14 & 15. Fallback resolution looks up class from ClassesController if extra is null',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            classId: testSession.id,
            session: null, // extra is null
            classesState: ClassesLoaded(classes: [testSession]),
          ),
        );
        await tester.pumpAndSettle();

        // Successfully resolved from controller state
        expect(find.text('Junior Foundation first class'), findsOneWidget);
        expect(find.text('Elizabeth Vance'), findsOneWidget);
      },
    );

    testWidgets(
      '16. Unknown classId displays graceful Class Session Not Found state',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            classId: 'non-existent-id',
            session: null,
            classesState: const ClassesLoaded(classes: []),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Class Session Not Found'), findsOneWidget);
        expect(find.text('Return to Schedule'), findsOneWidget);
      },
    );
  });
}
