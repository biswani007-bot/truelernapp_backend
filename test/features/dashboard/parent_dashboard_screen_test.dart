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
import 'package:truelearn/features/dashboard/presentation/widgets/featured_class_card.dart';
import 'package:truelearn/features/dashboard/presentation/widgets/my_learning_section.dart';

class FakeDashboardRepository implements DashboardRepository {
  List<ChildEntity> children = [];
  DashboardEntity? dashboard;
  Failure? failure;
  int childrenCallCount = 0;
  int dashboardCallCount = 0;

  @override
  Future<List<ChildEntity>> getLinkedChildren() async {
    childrenCallCount++;
    if (failure != null) throw failure!;
    return children;
  }

  @override
  Future<DashboardEntity> getChildDashboard({required String childStudentId}) async {
    dashboardCallCount++;
    if (failure != null) throw failure!;
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
  Future<void> saveAccessToken(String token) async => _data['access_token'] = token;

  @override
  Future<void> deleteAccessToken() async => _data.remove('access_token');

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> saveRefreshToken(String token) async => _data['refresh_token'] = token;

  @override
  Future<void> deleteRefreshToken() async => _data.remove('refresh_token');

  @override
  Future<String?> getUserId() async => _data['user_id'];

  @override
  Future<void> saveUserId(String id) async => _data['user_id'] = id;

  @override
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> saveActiveChildId(String childId) async => _data['active_child_id'] = childId;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeDashboardRepository fakeRepo;
  late FakeSecureStorage fakeStorage;

  setUp(() {
    fakeRepo = FakeDashboardRepository();
    fakeStorage = FakeSecureStorage();

    fakeRepo.children = [
      const ChildEntity(studentId: 'child_1', firstName: 'Sarah', lastName: 'Connor', grade: 'Grade 4'),
      const ChildEntity(studentId: 'child_2', firstName: 'Alex', lastName: 'Mercer', grade: 'Grade 3'),
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
        authControllerProvider.overrideWith(() => FakeAuthController(authState)),
      ],
      child: const MaterialApp(
        home: ParentDashboardScreen(),
      ),
    );
  }

  testWidgets('renders Figma 76:3476 Student Dashboard with active child and real dashboard metrics', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Child Selector strip
    expect(find.byType(ChildSelectorRow), findsOneWidget);
    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);

    // Verify Greeting header
    expect(find.text("Hi, Sarah! Let's go on today's adventure!"), findsOneWidget);

    // Verify Featured Primary Card
    expect(find.byType(FeaturedClassCard), findsOneWidget);
    expect(find.text("TODAY'S CLASS"), findsOneWidget);
    expect(find.text('Junior Foundation first class'), findsOneWidget);
    expect(find.text('Join Class'), findsOneWidget);

    // Verify My Learning section
    expect(find.byType(MyLearningSection), findsOneWidget);
    expect(find.text('My Learning'), findsOneWidget);
    expect(find.text('Batch 1 — Junior Foundation, Ages 6 to 10'), findsOneWidget);

    // Verify Bento Grid snapshot
    expect(find.byType(BentoSnapshotGrid), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.byKey(const Key('bento_attendance_card')), findsOneWidget);
    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('switching child updates active greeting and requests selected child dashboard', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text("Hi, Sarah! Let's go on today's adventure!"), findsOneWidget);

    // Tap on Alex
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    expect(find.text("Hi, Alex! Let's go on today's adventure!"), findsOneWidget);
    expect(await fakeStorage.getActiveChildId(), 'child_2');
  });

  testWidgets('refresh keeps active child stable and does not reset to first child', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Select Alex
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(find.text("Hi, Alex! Let's go on today's adventure!"), findsOneWidget);

    // Trigger pull to refresh
    await tester.fling(find.byKey(const Key('dashboard_scroll_view')), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    // Active child MUST still be Alex
    expect(find.text("Hi, Alex! Let's go on today's adventure!"), findsOneWidget);
    expect(await fakeStorage.getActiveChildId(), 'child_2');
  });

  testWidgets('tapping Join Class navigates to SCR-13 My Classes (/parent/classes)', (tester) async {
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
          authControllerProvider.overrideWith(() => FakeAuthController(const Authenticated(
            accessToken: 'tok',
            user: UserDto(id: 'p1', email: 'parent@truelearn.com', role: 'PARENT', name: 'John Walker'),
          ))),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join Class'), findsOneWidget);
    await tester.tap(find.text('Join Class'));
    await tester.pumpAndSettle();

    expect(pushedLocation, '/parent/classes');
    expect(find.text('SCR-13 Classes'), findsOneWidget);
  });

  testWidgets('when no upcoming class, button is View Classes and navigates to SCR-13', (tester) async {
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
          authControllerProvider.overrideWith(() => FakeAuthController(const Authenticated(
            accessToken: 'tok',
            user: UserDto(id: 'p1', email: 'parent@truelearn.com', role: 'PARENT', name: 'John Walker'),
          ))),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Classes'), findsOneWidget);
    await tester.tap(find.text('View Classes'));
    await tester.pumpAndSettle();

    expect(pushedLocation, '/parent/classes');
    expect(find.text('SCR-13 Classes'), findsOneWidget);
  });

  testWidgets('future class scheduled days ahead is NOT shown under TODAY\'S CLASS; shows empty state', (tester) async {
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
  });

  testWidgets('class scheduled for today IS shown under TODAY\'S CLASS with Join Class button', (tester) async {
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
  });
}

