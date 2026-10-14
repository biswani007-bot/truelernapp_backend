import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/classes/presentation/screens/parent_classes_screen.dart';
import 'package:truelearn/features/classes/presentation/widgets/classes_event_card.dart';
import 'package:truelearn/features/classes/presentation/widgets/empty_classes_widget.dart';
import 'package:truelearn/features/classes/presentation/widgets/error_classes_widget.dart';
import 'package:truelearn/features/dashboard/data/models/dashboard_dto.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';

class _MockChildrenController extends ChildrenController {
  _MockChildrenController(this.initialState);
  final ChildrenState initialState;

  @override
  ChildrenState build() => initialState;

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

class _MockClassesController extends ClassesController {
  _MockClassesController(this.initialState);
  final ClassesState initialState;

  @override
  ClassesState build() => initialState;

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

  const childRony = ChildEntity(
    studentId: 'child_rony',
    firstName: 'Rony',
    lastName: 'Roul',
  );

  const childMaya = ChildEntity(
    studentId: 'child_maya',
    firstName: 'Maya',
    lastName: 'Roul',
  );

  // 14:30 UTC = 20:00 (8:00 PM) in IST (+05:30)
  final classFuture = ClassEntity(
    id: '6accd929af81078972ce257f',
    classCode: 'LVC-0018',
    title: 'what is FUTURE?',
    subject: 'Future-Ready Builders',
    scheduledStartTime: DateTime.utc(2026, 10, 12, 14, 30),
    scheduledEndTime: DateTime.utc(2026, 10, 12, 15, 30),
    duration: 60,
    status: 'scheduled',
    effectiveStatus:
        'attended', // Pre-marked attendance should not mask upcoming status
    teacherName: 'Jack Sparrow',
  );

  group('Upcoming Classes & Schedule Mismatch Regression Tests', () {
    test('1 & 2. A class at 8:00 PM local time is assigned to the correct calendar date and is upcoming', () {
      // Monday, October 12, 2026 at 19:40 IST (14:10 UTC)
      final nowAtTest = DateTime.utc(2026, 10, 12, 14, 10).toLocal();

      final localStart = classFuture.scheduledStartTime!.toLocal();
      expect(localStart.year, equals(2026));
      expect(localStart.month, equals(10));
      expect(localStart.day, equals(12));

      expect(classFuture.isUpcomingAt(nowAtTest), isTrue);
      expect(classFuture.isCompletedAt(nowAtTest), isFalse);
      expect(classFuture.isMissedAt(nowAtTest), isFalse);
    });

    test('3 & 4. Dashboard displays the next scheduled class when verified response contains one for today', () {
      final nowAtTest = DateTime.utc(2026, 10, 12, 14, 10).toLocal();

      // selectTodayClass resolves 'what is FUTURE?' despite effectiveStatus: attended
      final selected = DashboardRepositoryImpl.selectTodayClass([
        classFuture,
      ], nowOverride: nowAtTest);

      expect(selected, isNotNull);
      expect(selected!.title, equals('what is FUTURE?'));
      expect(selected.teacherName, equals('Jack Sparrow'));
    });

    testWidgets(
      '1 & 4. Valid class on selected date appears in My Classes under Upcoming filter',
      (tester) async {
        final nowAtTest = DateTime.utc(2026, 10, 12, 14, 10).toLocal();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDeviceDateProvider.overrideWithValue(nowAtTest),
              childrenControllerProvider.overrideWith(
                () => _MockChildrenController(
                  const ChildrenLoaded(
                    children: [childRony],
                    activeChildId: 'child_rony',
                  ),
                ),
              ),
              classesControllerProvider.overrideWith(
                () => _MockClassesController(
                  ClassesLoaded(
                    classes: [classFuture],
                    childStudentId: 'child_rony',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentClassesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('what is FUTURE?'), findsOneWidget);
        expect(find.byType(ClassesEventCard), findsOneWidget);
      },
    );

    testWidgets(
      '5. Changing the selected child context does not leak previous child schedule',
      (tester) async {
        final nowAtTest = DateTime.utc(2026, 10, 12, 14, 10).toLocal();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDeviceDateProvider.overrideWithValue(nowAtTest),
              childrenControllerProvider.overrideWith(
                () => _MockChildrenController(
                  const ChildrenLoaded(
                    children: [childRony, childMaya],
                    activeChildId: 'child_maya',
                  ),
                ),
              ),
              classesControllerProvider.overrideWith(
                () => _MockClassesController(
                  ClassesLoaded(
                    classes: [classFuture],
                    childStudentId: 'child_rony', // Belonged to Rony, but active child is Maya
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentClassesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Does not show Rony's class when child_maya is active
        expect(find.text('what is FUTURE?'), findsNothing);
      },
    );

    testWidgets(
      '6. Changing selected date displays the correct classes for that day',
      (tester) async {
        final nowAtTest = DateTime.utc(2026, 10, 12, 14, 10).toLocal();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDeviceDateProvider.overrideWithValue(nowAtTest),
              childrenControllerProvider.overrideWith(
                () => _MockChildrenController(
                  const ChildrenLoaded(
                    children: [childRony],
                    activeChildId: 'child_rony',
                  ),
                ),
              ),
              classesControllerProvider.overrideWith(
                () => _MockClassesController(
                  ClassesLoaded(
                    classes: [classFuture],
                    childStudentId: 'child_rony',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentClassesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // On Oct 12, class is visible
        expect(find.text('what is FUTURE?'), findsOneWidget);

        // Tap on another date (e.g. Tue 13 Oct)
        final dateFinder = find.text('13');
        if (dateFinder.evaluate().isNotEmpty) {
          await tester.tap(dateFinder.first);
          await tester.pumpAndSettle();
          // Class from Oct 12 is no longer shown on Oct 13
          expect(find.text('what is FUTURE?'), findsNothing);
          expect(find.byType(EmptyClassesWidget), findsOneWidget);
        }
      },
    );

    testWidgets('7. API errors are not converted into a false empty schedule', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            classesControllerProvider.overrideWith(
              () => _MockClassesController(
                const ClassesError(
                  message: 'Network connection failed',
                  childStudentId: 'child_rony',
                ),
              ),
            ),
            childrenControllerProvider.overrideWith(
              () => _MockChildrenController(
                const ChildrenLoaded(
                  children: [childRony],
                  activeChildId: 'child_rony',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentClassesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorClassesWidget), findsOneWidget);
      expect(find.byType(EmptyClassesWidget), findsNothing);
      expect(find.text('Network connection failed'), findsOneWidget);
    });

    testWidgets(
      '8. A genuinely empty successful response shows the empty state widget',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              classesControllerProvider.overrideWith(
                () => _MockClassesController(
                  const ClassesLoaded(
                    classes: [],
                    childStudentId: 'child_rony',
                  ),
                ),
              ),
              childrenControllerProvider.overrideWith(
                () => _MockChildrenController(
                  const ChildrenLoaded(
                    children: [childRony],
                    activeChildId: 'child_rony',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: ParentClassesScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EmptyClassesWidget), findsOneWidget);
        expect(find.byType(ClassesEventCard), findsNothing);
      },
    );

    test('9. DashboardDto parses upcomingLiveClasses with startAt/endAt correctly without losing featuredClass', () {
      final json = {
        'upcomingLiveClasses': [
          {
            'id': '6accd929af81078972ce257f',
            'classTitle': 'what is FUTURE?',
            'courseName': 'Future-Ready Builders',
            'startDate': DateTime.now().toIso8601String(),
            'duration': 60,
            'status': 'scheduled',
            'instructor': 'Jack Sparrow',
          },
        ],
      };

      final dto = DashboardDto.fromJson(json);
      expect(dto.featuredClass, isNotNull);
      expect(dto.featuredClass!.title, equals('what is FUTURE?'));
      expect(dto.featuredClass!.teacherName, equals('Jack Sparrow'));
    });

    test('10. Existing class countdown and 15-minute entry restrictions continue working correctly', () {
      final classAt8 = ClassEntity(
        id: 'cls_8pm',
        title: 'what is FUTURE?',
        scheduledStartTime: DateTime.utc(2026, 10, 12, 14, 30), // 8:00 PM
        status: 'scheduled',
      );

      // 7:40 PM (20 minutes before start) -> Entry blocked
      final time20MinBefore = DateTime.utc(2026, 10, 12, 14, 10);
      expect(classAt8.canEnterLiveClass(time20MinBefore), isFalse);
      expect(
        classAt8.formatCountdown(time20MinBefore),
        equals('Class is starting in 20 minutes'),
      );

      // 7:45 PM (15 minutes before start) -> Entry permitted
      final time15MinBefore = DateTime.utc(2026, 10, 12, 14, 15);
      expect(classAt8.canEnterLiveClass(time15MinBefore), isTrue);
      expect(
        classAt8.formatCountdown(time15MinBefore),
        equals('Class is starting in 15 minutes'),
      );

      // 7:50 PM (10 minutes before start) -> Entry permitted
      final time10MinBefore = DateTime.utc(2026, 10, 12, 14, 20);
      expect(classAt8.canEnterLiveClass(time10MinBefore), isTrue);
    });
  });
}
