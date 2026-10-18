import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/courses/data/repositories/courses_repository_impl.dart';
import 'package:truelearn/features/courses/domain/entities/course_entity.dart';
import 'package:truelearn/features/courses/domain/repositories/courses_repository.dart';
import 'package:truelearn/features/dashboard/data/models/add_child_request_dto.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:truelearn/features/onboarding/presentation/screens/onboarding_child_screen.dart';
import 'package:truelearn/features/onboarding/presentation/screens/onboarding_interests_screen.dart';

class _FakeAddChildRepo implements AddChildRepository {
  AddChildRequestDto? lastRequest;
  ChildEntity? childToReturn;

  @override
  Future<ChildEntity> addChild(AddChildRequestDto request) async {
    lastRequest = request;
    return childToReturn ??
        ChildEntity(
          studentId: 'child_new_123',
          firstName: request.firstName,
          lastName: request.lastName,
          relationshipType: request.relationshipType,
          gender: request.gender,
        );
  }

  @override
  Future<void> unlinkChild({required String childStudentId}) async {}
}

class _FakeCoursesRepo implements CoursesRepository {
  final List<CourseEntity> courses;
  _FakeCoursesRepo(this.courses);

  @override
  Future<List<CourseEntity>> getPublicCourses() async => courses;

  @override
  Future<CourseEntity?> getCourseById(String id) async =>
      courses.where((c) => c.id == id).firstOrNull ?? courses.firstOrNull;
}

class _FakeChildrenController extends ChildrenController {
  _FakeChildrenController(this._initialState);
  final ChildrenState _initialState;

  @override
  ChildrenState build() => _initialState;

  @override
  Future<void> loadChildren({bool isRefresh = false}) async {}

  @override
  void setActiveChild(String studentId) {
    if (state is ChildrenLoaded) {
      final cur = state as ChildrenLoaded;
      state = ChildrenLoaded(
        children: cur.children,
        activeChildId: studentId,
      );
    }
  }
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dummyCourse = CourseEntity(
    id: 'course_ace_1',
    courseCode: 'CRS-ACE',
    courseName: 'ACE Public Speaking',
    slug: 'ace-public-speaking',
    level: 'Foundational',
    duration: 12,
  );

  group('New Child Onboarding Flow Tests', () {
    testWidgets(
      'Authenticated parent adding child navigates forward to OnboardingInterestsScreen without popping or going to dashboard',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeRepo = _FakeAddChildRepo();
        final fakeAuth = _FakeAuthController(
          const Authenticated(
            accessToken: 'test_token',
            user: UserDto(id: 'parent_1', name: 'John Doe', email: 'john@example.com'),
          ),
        );

        String? navigatedRoute;
        final router = GoRouter(
          initialLocation: AppRoutePaths.onboardingChild,
          routes: [
            GoRoute(
              path: AppRoutePaths.onboardingChild,
              builder: (context, state) => const OnboardingChildScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.onboardingInterests,
              builder: (context, state) {
                navigatedRoute = AppRoutePaths.onboardingInterests;
                return const Scaffold(body: Text('Interests Screen Loaded'));
              },
            ),
            GoRoute(
              path: AppRoutePaths.parentDashboard,
              builder: (context, state) {
                navigatedRoute = AppRoutePaths.parentDashboard;
                return const Scaffold(body: Text('Student Dashboard'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              addChildRepositoryProvider.overrideWithValue(fakeRepo),
              authControllerProvider.overrideWith(() => fakeAuth),
              childrenControllerProvider.overrideWith(
                () => _FakeChildrenController(
                  const ChildrenLoaded(children: [], activeChildId: null),
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Verify form renders
        expect(find.byType(OnboardingChildScreen), findsOneWidget);

        // Fill child details
        await tester.enterText(find.byType(TextFormField).at(0), 'Leo');
        await tester.enterText(find.byType(TextFormField).at(1), 'Messi');
        await tester.pump();

        // Tap Continue button
        final continueBtn = find.text('Continue');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Verify API was called
        expect(fakeRepo.lastRequest, isNotNull);
        expect(fakeRepo.lastRequest!.firstName, 'Leo');
        expect(fakeRepo.lastRequest!.lastName, 'Messi');

        // MUST navigate forward to OnboardingInterests, NOT Student Dashboard!
        expect(navigatedRoute, AppRoutePaths.onboardingInterests);
        expect(find.text('Interests Screen Loaded'), findsOneWidget);
        expect(find.text('Student Dashboard'), findsNothing);
      },
    );

    testWidgets(
      'Authenticated parent on OnboardingInterestsScreen continues to DemoBookingDashboardScreen with selected course',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeCoursesRepo = _FakeCoursesRepo([dummyCourse]);
        final fakeAuth = _FakeAuthController(
          const Authenticated(
            accessToken: 'test_token',
            user: UserDto(id: 'parent_1', name: 'John Doe', email: 'john@example.com'),
          ),
        );

        String? navigatedRoute;
        String? passedCourseId;

        final router = GoRouter(
          initialLocation: AppRoutePaths.onboardingInterests,
          routes: [
            GoRoute(
              path: AppRoutePaths.onboardingInterests,
              builder: (context, state) => const OnboardingInterestsScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.demoBookingDashboard,
              builder: (context, state) {
                navigatedRoute = AppRoutePaths.demoBookingDashboard;
                passedCourseId = state.extra as String?;
                return const Scaffold(body: Text('Demo Booking Dashboard Loaded'));
              },
            ),
            GoRoute(
              path: AppRoutePaths.onboardingAccount,
              builder: (context, state) {
                navigatedRoute = AppRoutePaths.onboardingAccount;
                return const Scaffold(body: Text('Account Registration Screen'));
              },
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            coursesRepositoryProvider.overrideWithValue(fakeCoursesRepo),
            authControllerProvider.overrideWith(() => fakeAuth),
          ],
        );

        // Pre-load available courses in controller
        container.read(onboardingControllerProvider.notifier).loadCourses();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingInterestsScreen), findsOneWidget);

        // Tap Continue
        final continueBtn = find.text('Continue');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Must navigate to Demo Booking Dashboard with course ID, NOT Account registration
        expect(navigatedRoute, AppRoutePaths.demoBookingDashboard);
        expect(passedCourseId, dummyCourse.id);
        expect(find.text('Demo Booking Dashboard Loaded'), findsOneWidget);
        expect(find.text('Account Registration Screen'), findsNothing);
      },
    );

    testWidgets(
      'Unauthenticated user on OnboardingInterestsScreen continues to OnboardingAccountScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeCoursesRepo = _FakeCoursesRepo([dummyCourse]);
        final fakeAuth = _FakeAuthController(const Unauthenticated());

        String? navigatedRoute;

        final router = GoRouter(
          initialLocation: AppRoutePaths.onboardingInterests,
          routes: [
            GoRoute(
              path: AppRoutePaths.onboardingInterests,
              builder: (context, state) => const OnboardingInterestsScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.demoBookingDashboard,
              builder: (context, state) {
                navigatedRoute = AppRoutePaths.demoBookingDashboard;
                return const Scaffold(body: Text('Demo Booking Dashboard'));
              },
            ),
            GoRoute(
              path: AppRoutePaths.onboardingAccount,
              builder: (context, state) {
                navigatedRoute = AppRoutePaths.onboardingAccount;
                return const Scaffold(body: Text('Account Registration Screen'));
              },
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            coursesRepositoryProvider.overrideWithValue(fakeCoursesRepo),
            authControllerProvider.overrideWith(() => fakeAuth),
          ],
        );

        container.read(onboardingControllerProvider.notifier).loadCourses();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Continue
        final continueBtn = find.text('Continue');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // For unauthenticated, MUST navigate to OnboardingAccount
        expect(navigatedRoute, AppRoutePaths.onboardingAccount);
        expect(find.text('Account Registration Screen'), findsOneWidget);
        expect(find.text('Demo Booking Dashboard'), findsNothing);
      },
    );

    testWidgets(
      'RouterNotifier redirects AuthDestination.demoBookingDashboard to demoBookingDashboard route',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => _FakeAuthController(
                const Authenticated(
                  accessToken: 'token_123',
                  destination: AuthDestination.demoBookingDashboard,
                ),
              ),
            ),
          ],
        );

        late BuildContext capturedContext;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        final routerNotifier = container.read(routerNotifierProvider);
        final redirect = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse(AppRoutePaths.login),
            matchedLocation: AppRoutePaths.login,
            fullPath: AppRoutePaths.login,
            pathParameters: const {},
            pageKey: const ValueKey('login'),
          ),
        );

        expect(redirect, AppRoutePaths.demoBookingDashboard);
      },
    );
  });
}
