import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_dashboard_screen.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/bento_snapshot_grid.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/child_selector_row.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/featured_class_card.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/my_learning_section.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_profile_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/parent_profile_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/parent_profile_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  List<ChildEntity> children = [];
  DashboardEntity? dashboard;
  Map<String, DashboardEntity>? childDashboards;
  Failure? failure;
  int childrenCallCount = 0;
  int dashboardCallCount = 0;
  Completer<List<ChildEntity>>? childrenCompleter;
  Completer<DashboardEntity>? dashboardCompleter;

  @override
  Future<List<ChildEntity>> getLinkedChildren() async {
    childrenCallCount++;
    if (failure != null) throw failure!;
    if (childrenCompleter != null) {
      return childrenCompleter!.future;
    }
    return children;
  }

  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    dashboardCallCount++;
    if (failure != null) throw failure!;
    if (dashboardCompleter != null) {
      return dashboardCompleter!.future;
    }
    if (childDashboards != null &&
        childDashboards!.containsKey(childStudentId)) {
      return childDashboards![childStudentId]!;
    }
    return dashboard ??
        const DashboardEntity(
          attendanceRate: 100.0,
          upcomingClassesCount: 1,
          pendingAssignmentsCount: 0,
          totalBalanceDue: 0.0,
        );
  }
}

class FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<void> saveAccessToken(String token) async =>
      _data['access_token'] = token;

  @override
  Future<void> deleteAccessToken() async => _data.remove('access_token');

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> saveRefreshToken(String token) async =>
      _data['refresh_token'] = token;

  @override
  Future<void> deleteRefreshToken() async => _data.remove('refresh_token');

  @override
  Future<String?> getUserId() async => _data['user_id'];

  @override
  Future<void> saveUserId(String id) async => _data['user_id'] = id;

  @override
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> saveActiveChildId(String childId) async =>
      _data['active_child_id'] = childId;

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _data.clear();
}

class FakeAuthController extends AuthController {
  FakeAuthController(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

const _fakeParentProfile = ParentProfileEntity(
  id: 'p1',
  parentId: 'PAR-1001',
  firstName: 'John',
  middleName: '',
  lastName: 'Walker',
  email: 'parent@truelearn.com',
  phone: '1234567890',
  alternatePhone: '',
  address: '123 Main St',
  city: 'New York',
  state: 'NY',
  country: 'USA',
  postalCode: '10001',
  status: 'ACTIVE',
  occupation: '',
  organization: '',
  designation: '',
);

class FakeParentProfileRepository implements ParentProfileRepository {
  @override
  Future<ParentProfileEntity> getParentProfile() async {
    return _fakeParentProfile;
  }

  @override
  Future<ParentProfileEntity> updateParentProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) async {
    return _fakeParentProfile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeDashboardRepository fakeRepo;
  late FakeSecureStorage fakeStorage;
  late FakeParentProfileRepository fakeProfileRepo;

  setUp(() {
    fakeRepo = FakeDashboardRepository();
    fakeStorage = FakeSecureStorage();
    fakeProfileRepo = FakeParentProfileRepository();

    fakeRepo.children = [
      const ChildEntity(
        studentId: 'child_1',
        firstName: 'Sarah',
        lastName: 'Connor',
        grade: 'Grade 4',
      ),
      const ChildEntity(
        studentId: 'child_2',
        firstName: 'Alex',
        lastName: 'Mercer',
        grade: 'Grade 3',
      ),
    ];
    fakeRepo.dashboard = const DashboardEntity(
      attendanceRate: 100.0,
      upcomingClassesCount: 1,
      pendingAssignmentsCount: 0,
      totalBalanceDue: 0.0,
      activeTopic: 'Junior Foundation',
      featuredClass: ClassEntity(
        id: 'cls_1',
        title: 'Junior Foundation first class',
        subject: 'Foundation',
        teacherName: 'Elizabeth Vance',
        status: 'UPCOMING',
      ),
      enrolledBatches: [
        EnrolledBatchEntity(
          id: 'b_1',
          batchName: 'Batch 1 — Junior Foundation, Ages 6 to 10',
          instructor: 'Elizabeth Vance',
        ),
      ],
    );
  });

  Widget createTestWidget({
    AuthState authState = const Authenticated(
      accessToken: 'tok',
      user: UserDto(
        id: 'p1',
        email: 'parent@truelearn.com',
        role: 'PARENT',
        name: 'John Walker',
      ),
    ),
  }) {
    return ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(fakeRepo),
        secureStorageProvider.overrideWithValue(fakeStorage),
        authControllerProvider.overrideWith(
          () => FakeAuthController(authState),
        ),
        parentProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
      ],
      child: const MaterialApp(home: ParentDashboardScreen()),
    );
  }

  testWidgets(
    'renders Figma 76:3476 Student Dashboard with active child and real dashboard metrics',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Child Selector strip
      expect(find.byType(ChildSelectorRow), findsOneWidget);
      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);

      // Verify Greeting header
      expect(
        find.text("Hi, Sarah! Let's go on today's adventure!"),
        findsOneWidget,
      );

      // Verify Featured Primary Card
      expect(find.byType(FeaturedClassCard), findsOneWidget);
      expect(find.text("TODAY'S CLASS"), findsOneWidget);
      expect(find.text('Junior Foundation first class'), findsOneWidget);
      expect(find.text('Join Class'), findsOneWidget);

      // Verify My Learning section
      expect(find.byType(MyLearningSection), findsOneWidget);
      expect(find.text('My Learning'), findsOneWidget);
      expect(
        find.text('Batch 1 — Junior Foundation, Ages 6 to 10'),
        findsOneWidget,
      );

      // Verify Bento Grid snapshot
      expect(find.byType(BentoSnapshotGrid), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.byKey(const Key('bento_attendance_card')), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    },
  );

  testWidgets(
    'switching child updates active greeting and requests selected child dashboard',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text("Hi, Sarah! Let's go on today's adventure!"),
        findsOneWidget,
      );

      // Tap on Alex
      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();

      expect(
        find.text("Hi, Alex! Let's go on today's adventure!"),
        findsOneWidget,
      );
      expect(await fakeStorage.getActiveChildId(), 'child_2');
    },
  );

  testWidgets(
    'refresh keeps active child stable and does not reset to first child',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select Alex
      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();
      expect(
        find.text("Hi, Alex! Let's go on today's adventure!"),
        findsOneWidget,
      );

      // Trigger pull to refresh
      await tester.fling(
        find.byKey(const Key('dashboard_scroll_view')),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Active child MUST still be Alex
      expect(
        find.text("Hi, Alex! Let's go on today's adventure!"),
        findsOneWidget,
      );
      expect(await fakeStorage.getActiveChildId(), 'child_2');
    },
  );

  testWidgets(
    'tapping Join Class navigates to SCR-13 My Classes (/parent/classes)',
    (tester) async {
      String? pushedLocation;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/classes',
            builder: (context, state) {
              pushedLocation = state.uri.toString();
              return const Scaffold(body: Text('SCR-13 Classes'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(fakeRepo),
            secureStorageProvider.overrideWithValue(fakeStorage),
            authControllerProvider.overrideWith(
              () => FakeAuthController(
                const Authenticated(
                  accessToken: 'tok',
                  user: UserDto(
                    id: 'p1',
                    email: 'parent@truelearn.com',
                    role: 'PARENT',
                    name: 'John Walker',
                  ),
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join Class'), findsOneWidget);
      await tester.tap(find.text('Join Class'));
      await tester.pumpAndSettle();

      expect(pushedLocation, '/parent/classes');
      expect(find.text('SCR-13 Classes'), findsOneWidget);
    },
  );

  testWidgets(
    'when no upcoming class, button is View Classes and navigates to SCR-13',
    (tester) async {
      fakeRepo.dashboard = const DashboardEntity(
        attendanceRate: 95.0,
        upcomingClassesCount: 0,
        pendingAssignmentsCount: 1,
        totalBalanceDue: 0.0,
        featuredClass: null,
      );

      String? pushedLocation;
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/classes',
            builder: (context, state) {
              pushedLocation = state.uri.toString();
              return const Scaffold(body: Text('SCR-13 Classes'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(fakeRepo),
            secureStorageProvider.overrideWithValue(fakeStorage),
            authControllerProvider.overrideWith(
              () => FakeAuthController(
                const Authenticated(
                  accessToken: 'tok',
                  user: UserDto(
                    id: 'p1',
                    email: 'parent@truelearn.com',
                    role: 'PARENT',
                    name: 'John Walker',
                  ),
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View Classes'), findsOneWidget);
      await tester.tap(find.text('View Classes'));
      await tester.pumpAndSettle();

      expect(pushedLocation, '/parent/classes');
      expect(find.text('SCR-13 Classes'), findsOneWidget);
    },
  );

  testWidgets(
    'future class scheduled days ahead is NOT shown under TODAY\'S CLASS; shows empty state',
    (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 12));
      fakeRepo.dashboard = DashboardEntity(
        attendanceRate: 100.0,
        upcomingClassesCount: 1,
        pendingAssignmentsCount: 0,
        totalBalanceDue: 0.0,
        featuredClass: ClassEntity(
          id: 'future-class-sarah',
          title: 'Junior Foundation first class',
          subject: 'Junior Foundation',
          teacherName: 'Elizabeth Vance',
          scheduledStartTime: futureDate,
          scheduledEndTime: futureDate.add(const Duration(hours: 1)),
          status: 'SCHEDULED',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Section header "TODAY'S CLASS" must exist
      expect(find.text("TODAY'S CLASS"), findsOneWidget);

      // Future class title MUST NOT be displayed in today's class
      expect(find.text('Junior Foundation first class'), findsNothing);

      // Empty state should be displayed
      expect(find.text('No live class today'), findsOneWidget);
      expect(find.text('Check upcoming classes in schedule'), findsOneWidget);
      expect(find.text('View Classes'), findsOneWidget);
    },
  );

  testWidgets(
    'class scheduled for today IS shown under TODAY\'S CLASS with Join Class button',
    (tester) async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day, 16, 0);
      fakeRepo.dashboard = DashboardEntity(
        attendanceRate: 100.0,
        upcomingClassesCount: 1,
        pendingAssignmentsCount: 0,
        totalBalanceDue: 0.0,
        featuredClass: ClassEntity(
          id: 'today-class-sarah',
          title: 'Today Foundation Session',
          subject: 'Junior Foundation',
          teacherName: 'Elizabeth Vance',
          scheduledStartTime: todayDate,
          scheduledEndTime: todayDate.add(const Duration(hours: 1)),
          status: 'SCHEDULED',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Section header "TODAY'S CLASS" must exist
      expect(find.text("TODAY'S CLASS"), findsOneWidget);

      // Today's class title MUST be displayed
      expect(find.text('Today Foundation Session'), findsOneWidget);
      expect(find.textContaining('Elizabeth Vance'), findsOneWidget);
      expect(find.text('Join Class'), findsOneWidget);
    },
  );

  group('Parent Dashboard Skeleton Loading State Tests (Scenarios A-G)', () {
    testWidgets(
      'A. Initial dashboard loading: skeleton visible, no child name, no stale dashboard data',
      (tester) async {
        fakeRepo.childrenCompleter = Completer<List<ChildEntity>>();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Child selector skeleton must be visible
        expect(find.byType(ChildSelectorSkeleton), findsOneWidget);
        expect(find.byType(ChildSelectorRow), findsNothing);

        // Dashboard skeleton must be visible
        expect(find.byType(ParentDashboardSkeleton), findsOneWidget);

        // No child name visible
        expect(find.text('Sarah'), findsNothing);
        expect(find.text('Alex'), findsNothing);
        expect(
          find.text("Hi, Sarah! Let's go on today's adventure!"),
          findsNothing,
        );
        expect(
          find.text("Hi, Alex! Let's go on today's adventure!"),
          findsNothing,
        );

        // No stale dashboard cards or metrics visible
        expect(find.text("TODAY'S CLASS"), findsNothing);
        expect(find.text('My Learning'), findsNothing);
        expect(find.text('Attendance'), findsNothing);
      },
    );

    testWidgets(
      'B. Children loading -> dashboard loading: skeleton remains until active child dashboard ready',
      (tester) async {
        fakeRepo.childrenCompleter = Completer<List<ChildEntity>>();
        fakeRepo.dashboardCompleter = Completer<DashboardEntity>();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Phase 1: Children loading
        expect(find.byType(ChildSelectorSkeleton), findsOneWidget);
        expect(find.byType(ParentDashboardSkeleton), findsOneWidget);

        // Resolve children API
        fakeRepo.childrenCompleter!.complete([
          const ChildEntity(
            studentId: 'child_1',
            firstName: 'Sarah',
            lastName: 'Connor',
            grade: 'Grade 4',
          ),
          const ChildEntity(
            studentId: 'child_2',
            firstName: 'Alex',
            lastName: 'Mercer',
            grade: 'Grade 3',
          ),
        ]);
        await tester.pump();
        await tester.pump();

        // Phase 2: Children resolved, active child set, but dashboard API still unresolved
        expect(find.byType(ChildSelectorSkeleton), findsNothing);
        expect(find.byType(ChildSelectorRow), findsOneWidget);
        expect(find.text('Sarah'), findsOneWidget);

        // Dashboard skeleton MUST still be visible because child dashboard is still loading
        expect(find.byType(ParentDashboardSkeleton), findsOneWidget);
        expect(find.text("TODAY'S CLASS"), findsNothing);
        expect(find.text('Junior Foundation first class'), findsNothing);
      },
    );

    testWidgets(
      'C. Successful load: skeleton disappears, correct real child appears, real dashboard appears',
      (tester) async {
        fakeRepo.childrenCompleter = Completer<List<ChildEntity>>();
        fakeRepo.dashboardCompleter = Completer<DashboardEntity>();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Complete children
        fakeRepo.childrenCompleter!.complete([
          const ChildEntity(
            studentId: 'child_1',
            firstName: 'Sarah',
            lastName: 'Connor',
            grade: 'Grade 4',
          ),
        ]);
        await tester.pump();

        // Complete dashboard
        fakeRepo.dashboardCompleter!.complete(fakeRepo.dashboard);
        await tester.pumpAndSettle();

        // Skeleton disappeared completely
        expect(find.byType(ChildSelectorSkeleton), findsNothing);
        expect(find.byType(ParentDashboardSkeleton), findsNothing);

        // Real active child & greeting
        expect(find.text('Sarah'), findsOneWidget);
        expect(
          find.text("Hi, Sarah! Let's go on today's adventure!"),
          findsOneWidget,
        );

        // Real dashboard data
        expect(find.text("TODAY'S CLASS"), findsOneWidget);
        expect(find.text('Junior Foundation first class'), findsOneWidget);
        expect(
          find.text('Batch 1 — Junior Foundation, Ages 6 to 10'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'D. Child switching: old child data does not bleed, skeleton appears immediately, new child data renders after API',
      (tester) async {
        final sarahDashboard = const DashboardEntity(
          attendanceRate: 100.0,
          upcomingClassesCount: 1,
          featuredClass: ClassEntity(
            id: 'sarah_cls',
            title: 'Sarah Class Title',
            subject: 'Math',
            teacherName: 'Teacher A',
            status: 'UPCOMING',
          ),
        );

        final alexDashboard = const DashboardEntity(
          attendanceRate: 85.0,
          upcomingClassesCount: 2,
          featuredClass: ClassEntity(
            id: 'alex_cls',
            title: 'Alex Class Title',
            subject: 'Science',
            teacherName: 'Teacher B',
            status: 'UPCOMING',
          ),
        );

        fakeRepo.childDashboards = {
          'child_1': sarahDashboard,
          'child_2': alexDashboard,
        };

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially Sarah dashboard loaded
        expect(find.text('Sarah Class Title'), findsOneWidget);
        expect(
          find.text("Hi, Sarah! Let's go on today's adventure!"),
          findsOneWidget,
        );

        // Set completer for Alex switch
        fakeRepo.dashboardCompleter = Completer<DashboardEntity>();

        // Tap on Alex
        await tester.tap(find.text('Alex'));
        await tester.pump();

        // Active child is now Alex in child selector
        // Dashboard MUST immediately enter skeleton state — old Sarah data must NOT appear under Alex
        expect(find.byType(ParentDashboardSkeleton), findsOneWidget);
        expect(find.text('Sarah Class Title'), findsNothing);
        expect(find.text('Alex Class Title'), findsNothing);

        // Now complete Alex dashboard
        fakeRepo.dashboardCompleter!.complete(alexDashboard);
        await tester.pumpAndSettle();

        // Skeleton gone, Alex real data visible
        expect(find.byType(ParentDashboardSkeleton), findsNothing);
        expect(
          find.text("Hi, Alex! Let's go on today's adventure!"),
          findsOneWidget,
        );
        expect(find.text('Alex Class Title'), findsOneWidget);
        expect(find.text('Sarah Class Title'), findsNothing);
      },
    );

    testWidgets(
      'E. Pull-to-refresh: active child remains unchanged, refreshed data appears after API completion',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to Alex
        await tester.tap(find.text('Alex'));
        await tester.pumpAndSettle();
        expect(
          find.text("Hi, Alex! Let's go on today's adventure!"),
          findsOneWidget,
        );

        // Trigger refresh
        await tester.fling(
          find.byKey(const Key('dashboard_scroll_view')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        // Active child MUST still be Alex
        expect(
          find.text("Hi, Alex! Let's go on today's adventure!"),
          findsOneWidget,
        );
        expect(await fakeStorage.getActiveChildId(), 'child_2');
        expect(find.byType(ParentDashboardSkeleton), findsNothing);
      },
    );

    testWidgets(
      'F. API error: skeleton stops, error banner and retry UI appear',
      (tester) async {
        fakeRepo.failure = const ServerFailure('Connection timed out');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Skeleton must NOT remain indefinitely
        expect(find.byType(ParentDashboardSkeleton), findsNothing);

        // Error banner with message and retry button must be shown
        expect(find.text('Connection timed out'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'G. Empty API response: skeleton disappears, empty state shown, not skeleton',
      (tester) async {
        fakeRepo.dashboard = const DashboardEntity(
          attendanceRate: 0.0,
          upcomingClassesCount: 0,
          pendingAssignmentsCount: 0,
          totalBalanceDue: 0.0,
          featuredClass: null,
          enrolledBatches: [],
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Skeleton must NOT remain indefinitely
        expect(find.byType(ParentDashboardSkeleton), findsNothing);

        // Genuine empty state for Today's class and My Learning
        expect(find.text('No live class today'), findsOneWidget);
        expect(find.text('No enrolled courses'), findsOneWidget);
      },
    );

    testWidgets(
      'H. Child Selector displays authoritative Age matching My Child screen semantics (never hardcoded Age 9)',
      (tester) async {
        fakeRepo.children = [
          const ChildEntity(
            studentId: 'child_rony',
            firstName: 'Rony',
            lastName: 'Roul',
            dateOfBirth: '2019-01-12T00:00:00.000Z',
          ),
          const ChildEntity(
            studentId: 'child_mia',
            firstName: 'Mia',
            lastName: 'Wong',
            explicitAge: 5,
          ),
        ];

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ChildSelectorRow), findsOneWidget);
        expect(find.text('Rony'), findsOneWidget);
        expect(find.text('Age 7'), findsOneWidget); // Dynamic age from DOB
        expect(find.text('Mia'), findsOneWidget);
        expect(find.text('Age 5'), findsOneWidget); // Dynamic explicit age
        expect(
          find.text('Age 9'),
          findsNothing,
        ); // Hardcoded fallback must NOT appear
      },
    );
  });
}
