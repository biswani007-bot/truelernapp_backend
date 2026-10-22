import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/domain/repositories/classes_repository.dart';
import 'package:truelearn/features/classes/presentation/screens/live_classroom_screen.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/screens/demo_waiting_for_admin_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  Map<String, dynamic>? statusResponse;
  bool throwError = false;
  String? queriedStudentId;

  @override
  Future<Map<String, dynamic>?> getParentStatus({String? studentId}) async {
    queriedStudentId = studentId;
    if (throwError) {
      throw Exception('503 Service Unavailable: Temporary network interruption');
    }
    return statusResponse;
  }

  @override
  Future<Map<String, dynamic>?> getParentDemo({String? studentId}) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockClassesRepository implements ClassesRepository {
  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String classId,
    String? childStudentId,
  }) async {
    return ClassJoinEntity(
      token: 'valid_mock_jwt_token',
      roomName: 'room-demo-$classId',
      jitsiDomain: 'livetl.visital.in',
      serverUrl: 'https://livetl.visital.in',
      isModerator: false,
      meetingUrl: 'https://livetl.visital.in/room-demo-$classId',
      expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  const testChild = ChildEntity(
    studentId: 'STU-DEMO-001',
    firstName: 'Alice',
    lastName: 'Smith',
  );

  final testBooking = DemoBookingEntity(
    bookingId: 'DEMO-BOOKING-999',
    demoCode: 'DEMO-999',
    courseName: 'Coding Fundamentals',
    studentName: 'Alice Smith',
    studentId: 'STU-DEMO-001',
    startDateTime: DateTime.now().subtract(const Duration(minutes: 10)),
    endDateTime: DateTime.now().add(const Duration(minutes: 35)),
    status: 'scheduled',
    teacherName: 'Prof. Xavier',
  );

  const testJoinData = ClassJoinEntity(
    token: 'test_token',
    roomName: 'truelern-demo-room',
    jitsiDomain: 'livetl.visital.in',
    serverUrl: 'https://livetl.visital.in',
    isModerator: false,
    meetingUrl: 'https://livetl.visital.in/truelern-demo-room',
  );

  group('Demo Call End Navigation Tests', () {
    testWidgets(
      'Tapping End Call in demo classroom navigates to waiting-for-admin screen preserving session & booking',
      (tester) async {
        String? navigatedRoute;
        DemoBookingEntity? capturedBooking;
        String? capturedBookingId;

        final router = GoRouter(
          initialLocation: '/parent/classes/DEMO-BOOKING-999/live',
          routes: [
            GoRoute(
              path: '/parent/classes/:classId/live',
              builder: (context, state) => LiveClassroomScreen(
                classId: 'DEMO-BOOKING-999',
                fromDemo: true,
                booking: testBooking,
                childStudentId: 'STU-DEMO-001',
                joinData: testJoinData,
              ),
            ),
            GoRoute(
              path: AppRoutePaths.demoWaitingForAdmin,
              builder: (context, state) {
                navigatedRoute = state.uri.toString();
                capturedBooking = state.extra is DemoBookingEntity
                    ? state.extra as DemoBookingEntity
                    : null;
                capturedBookingId = state.uri.queryParameters['bookingId'];
                return Scaffold(
                  body: Text('WaitingScreenTarget: $capturedBookingId'),
                );
              },
            ),
          ],
        );

        final mockClassesRepo = _MockClassesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              classesRepositoryProvider.overrideWithValue(mockClassesRepo),
              childrenControllerProvider.overrideWith(
                () => _StaticChildrenController(
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'STU-DEMO-001',
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Find and tap the leave/exit button
        final exitButton = find.byKey(const Key('classroom_floating_leave_button'));
        expect(exitButton, findsOneWidget);

        await tester.tap(exitButton);
        await tester.pumpAndSettle();

        // Verify navigation went to demoWaitingForAdmin
        expect(navigatedRoute, contains(AppRoutePaths.demoWaitingForAdmin));
        expect(capturedBookingId, equals('DEMO-BOOKING-999'));
        expect(capturedBooking?.studentName, equals('Alice Smith'));
        expect(find.text('WaitingScreenTarget: DEMO-BOOKING-999'), findsOneWidget);
      },
    );

    testWidgets(
      'Repeated end-call events do not trigger duplicate navigation',
      (tester) async {
        int navigationCount = 0;

        final router = GoRouter(
          initialLocation: '/parent/classes/DEMO-BOOKING-999/live',
          routes: [
            GoRoute(
              path: '/parent/classes/:classId/live',
              builder: (context, state) => LiveClassroomScreen(
                classId: 'DEMO-BOOKING-999',
                fromDemo: true,
                booking: testBooking,
                joinData: testJoinData,
              ),
            ),
            GoRoute(
              path: AppRoutePaths.demoWaitingForAdmin,
              builder: (context, state) {
                navigationCount++;
                return const Scaffold(body: Text('Waiting Screen'));
              },
            ),
          ],
        );

        final mockClassesRepo = _MockClassesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              classesRepositoryProvider.overrideWithValue(mockClassesRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final exitButton = find.byKey(const Key('classroom_floating_leave_button'));
        expect(exitButton, findsOneWidget);

        // Tap once
        await tester.tap(exitButton);
        await tester.pump();

        // Attempt second tap if still in transition
        if (exitButton.evaluate().isNotEmpty) {
          await tester.tap(exitButton, warnIfMissed: false);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(navigationCount, equals(1));
      },
    );

    testWidgets(
      'Non-demo class exit navigates to class summary screen',
      (tester) async {
        String? summaryNavigatedClassId;

        final regularSession = ClassEntity(
          id: 'CLASS-COHORT-456',
          title: 'Mathematics Batch A',
          scheduledStartTime: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        final router = GoRouter(
          initialLocation: '/parent/classes/CLASS-COHORT-456/live',
          routes: [
            GoRoute(
              path: '/parent/classes/:classId/live',
              builder: (context, state) => LiveClassroomScreen(
                classId: 'CLASS-COHORT-456',
                fromDemo: false,
                session: regularSession,
                joinData: testJoinData,
              ),
            ),
            GoRoute(
              path: '/parent/classes/:classId/summary',
              builder: (context, state) {
                summaryNavigatedClassId = state.pathParameters['classId'];
                return Scaffold(body: Text('Summary: $summaryNavigatedClassId'));
              },
            ),
          ],
        );

        final mockClassesRepo = _MockClassesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              classesRepositoryProvider.overrideWithValue(mockClassesRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final exitButton = find.byKey(const Key('classroom_floating_leave_button'));
        expect(exitButton, findsOneWidget);

        await tester.tap(exitButton);
        await tester.pumpAndSettle();

        expect(summaryNavigatedClassId, equals('CLASS-COHORT-456'));
        expect(find.text('Summary: CLASS-COHORT-456'), findsOneWidget);
      },
    );

    testWidgets(
      'A pending demo remains on the waiting screen with pending message and child identity',
      (tester) async {
        final mockAuthRepo = _FakeAuthRepository();
        mockAuthRepo.statusResponse = {
          'state': 'STATE_3',
          'action': 'awaiting_admin',
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              childrenControllerProvider.overrideWith(
                () => _StaticChildrenController(
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'STU-DEMO-001',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: DemoWaitingForAdminScreen(
                booking: testBooking,
                bookingId: 'DEMO-BOOKING-999',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pending review banner & message
        expect(find.text('Demo Completed — Awaiting Review'), findsOneWidget);
        expect(find.text('Demo Session Completed'), findsOneWidget);
        expect(
          find.textContaining('Please wait while the admin reviews your demo and confirms enrollment.'),
          findsOneWidget,
        );

        // Child details
        expect(find.text('Alice Smith'), findsOneWidget);
        expect(find.text('DEMO-999'), findsOneWidget);
        expect(find.text('Coding Fundamentals'), findsOneWidget);

        // Invoices and enrolled details NOT shown prematurely
        expect(find.byKey(const Key('waiting_admin_view_invoice_button')), findsNothing);
        expect(find.byKey(const Key('waiting_admin_dashboard_button')), findsNothing);

        // Status check button present
        expect(find.byKey(const Key('waiting_admin_check_status_button')), findsOneWidget);
      },
    );

    testWidgets(
      'Temporary API error does not cause a dashboard redirect',
      (tester) async {
        final mockAuthRepo = _FakeAuthRepository();
        mockAuthRepo.throwError = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              childrenControllerProvider.overrideWith(
                () => _StaticChildrenController(
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'STU-DEMO-001',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: DemoWaitingForAdminScreen(
                booking: testBooking,
                bookingId: 'DEMO-BOOKING-999',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifies user is still on Waiting for Admin screen, not redirected
        expect(find.text('Waiting for Admin Enrollment'), findsOneWidget);
        expect(find.text('Demo Completed — Awaiting Review'), findsOneWidget);
      },
    );

    testWidgets(
      'When backend confirms demo completion (STATE_5), app navigates to student dashboard and resets demo state',
      (tester) async {
        final mockAuthRepo = _FakeAuthRepository();
        mockAuthRepo.statusResponse = {
          'state': 'STATE_5',
          'action': 'dashboard',
        };

        String? finalDestination;

        final router = GoRouter(
          initialLocation: AppRoutePaths.demoWaitingForAdmin,
          routes: [
            GoRoute(
              path: AppRoutePaths.demoWaitingForAdmin,
              builder: (context, state) => DemoWaitingForAdminScreen(
                booking: testBooking,
                bookingId: 'DEMO-BOOKING-999',
              ),
            ),
            GoRoute(
              path: AppRoutePaths.parentDashboard,
              builder: (context, state) {
                finalDestination = AppRoutePaths.parentDashboard;
                return const Scaffold(body: Text('Student Dashboard Target'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              childrenControllerProvider.overrideWith(
                () => _StaticChildrenController(
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'STU-DEMO-001',
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verified automatic navigation to student dashboard
        expect(finalDestination, equals(AppRoutePaths.parentDashboard));
        expect(find.text('Student Dashboard Target'), findsOneWidget);
      },
    );

    testWidgets(
      'Status check uses the correct child student ID from booking and children controller',
      (tester) async {
        final mockAuthRepo = _FakeAuthRepository();
        mockAuthRepo.statusResponse = {
          'state': 'STATE_3',
          'action': 'awaiting_admin',
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              childrenControllerProvider.overrideWith(
                () => _StaticChildrenController(
                  const ChildrenLoaded(
                    children: [testChild],
                    activeChildId: 'STU-DEMO-001',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: DemoWaitingForAdminScreen(
                booking: testBooking,
                bookingId: 'DEMO-BOOKING-999',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(mockAuthRepo.queriedStudentId, equals('STU-DEMO-001'));
      },
    );
  });
}
