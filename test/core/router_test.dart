import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_names.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_booking_entity.dart';

class FakeAuthRepo implements AuthRepository {
  String? token;

  @override
  Future<String?> checkPersistedSession() async => token;

  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async =>
      throw UnimplementedError();

  @override
  Future<PasswordPromptStatus> getPasswordPromptStatus() async =>
      const PasswordPromptStatus(
        showPrompt: false,
        hasPassword: true,
        dontAskAgain: false,
        cooldownActive: false,
      );

  @override
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  }) async => true;

  @override
  Future<bool> dismissPasswordPrompt({required String action}) async => true;

  Map<String, dynamic> mockParentContext = {
    'data': {
      'user': {'role': 'student'},
    },
  };

  @override
  Future<Map<String, dynamic>> getCurrentParentContext() async =>
      mockParentContext;

  @override
  Future<Map<String, dynamic>?> getParentDemo({String? studentId}) async =>
      null;

  @override
  Future<Map<String, dynamic>?> getParentStatus({String? studentId}) async =>
      null;

  @override
  Future<Map<String, dynamic>?> getChildDashboard(
    String childStudentId,
  ) async => null;

  @override
  Future<void> logout() async => token = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Router Tests', () {
    test('routerProvider can be instantiated with initial location /splash and handles /splash', () {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepo())],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppRoutePaths.splash,
      );
    });

    test('route path constants follow blueprint hierarchy', () {
      expect(AppRoutePaths.root, '/');
      expect(AppRoutePaths.splash, '/splash');
      expect(AppRoutePaths.login, '/login');
      expect(AppRoutePaths.parent, '/parent');
      expect(AppRoutePaths.parentDashboard, '/parent/dashboard');
      expect(AppRoutePaths.parentClasses, '/parent/classes');
      expect(AppRoutePaths.parentAssignments, '/parent/assignments');
      expect(AppRoutePaths.parentInvoices, '/parent/invoices');
      expect(AppRoutePaths.parentProfile, '/parent/profile');
    });

    testWidgets(
      'CASE 9: RouterNotifier redirects unauthenticated users away from /parent to /login',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepo())],
        );
        addTearDown(container.dispose);

        // Force unauthenticated state
        await container.read(authControllerProvider.notifier).checkSession();
        expect(container.read(authControllerProvider), isA<Unauthenticated>());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp.router(
                  routerConfig: ref.watch(routerProvider),
                );
              },
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        final router = container.read(routerProvider);
        router.go(AppRoutePaths.parentDashboard);
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, AppRoutePaths.login);
      },
    );

    testWidgets(
      'CASE 9: RouterNotifier redirects unauthenticated users away from nested parent routes to /login',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepo())],
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.notifier).checkSession();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp.router(
                  routerConfig: ref.watch(routerProvider),
                );
              },
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        final router = container.read(routerProvider);
        router.go('/parent/dashboard');
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, AppRoutePaths.login);
      },
    );

    testWidgets(
      'CASE 2: RouterNotifier redirects authenticated users away from /login to /parent',
      (WidgetTester tester) async {
        final fakeRepo = FakeAuthRepo()..token = 'existing_valid_token';
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        // Set authenticated state
        await container.read(authControllerProvider.notifier).checkSession();
        expect(container.read(authControllerProvider), isA<Authenticated>());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp.router(
                  routerConfig: ref.watch(routerProvider),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final router = container.read(routerProvider);
        router.go(AppRoutePaths.login);
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, AppRoutePaths.parentDashboard);
      },
    );

    testWidgets(
      'RouterNotifier does NOT redirect hydrated demoClassPreJoin to parentDashboard',
      (WidgetTester tester) async {
        final fakeRepo = FakeAuthRepo()..token = 'existing_valid_token';
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.notifier).checkSession();
        expect(container.read(authControllerProvider), isA<Authenticated>());

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
        await tester.pumpAndSettle();

        final routerNotifier = container.read(routerNotifierProvider);
        final validBooking = DemoBookingEntity(
          bookingId: 'demo-123',
          liveClassId: 'live-456',
          demoCode: 'DEMO-123456',
          courseName: 'Robotics 101',
          studentName: 'Freddy Sahoo',
          studentId: 'child-101',
          studentCode: 'STU-00101',
          startDateTime: DateTime.now().add(const Duration(minutes: 5)),
          endDateTime: DateTime.now().add(const Duration(minutes: 50)),
          status: 'scheduled',
          joinEligible: true,
        );

        // 1. Hydrated with state.extra: must NOT redirect (returns null)
        final redirectWithExtra = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse(AppRoutePaths.demoClassPreJoin),
            matchedLocation: AppRoutePaths.demoClassPreJoin,
            fullPath: AppRoutePaths.demoClassPreJoin,
            pathParameters: const {},
            pageKey: const ValueKey('preJoinExtra'),
            extra: validBooking,
          ),
        );
        expect(redirectWithExtra, isNull);

        // 2. Hydrated with queryParameters['bookingId']: must NOT redirect (returns null)
        final redirectWithQuery = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse('${AppRoutePaths.demoClassPreJoin}?bookingId=demo-123'),
            matchedLocation: AppRoutePaths.demoClassPreJoin,
            fullPath: AppRoutePaths.demoClassPreJoin,
            pathParameters: const {},
            pageKey: const ValueKey('preJoinQuery'),
          ),
        );
        expect(redirectWithQuery, isNull);

        // 3. Unhydrated (no extra, no query): MUST redirect to parentDashboard
        final redirectUnhydrated = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse(AppRoutePaths.demoClassPreJoin),
            matchedLocation: AppRoutePaths.demoClassPreJoin,
            fullPath: AppRoutePaths.demoClassPreJoin,
            pathParameters: const {},
            pageKey: const ValueKey('preJoinUnhydrated'),
          ),
        );
        expect(redirectUnhydrated, AppRoutePaths.parentDashboard);
      },
    );

    testWidgets(
      'RouterNotifier does NOT redirect hydrated demoClassWaiting or live classroom to parentDashboard',
      (WidgetTester tester) async {
        final fakeRepo = FakeAuthRepo()..token = 'existing_valid_token';
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.notifier).checkSession();
        expect(container.read(authControllerProvider), isA<Authenticated>());

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
        await tester.pumpAndSettle();

        final routerNotifier = container.read(routerNotifierProvider);
        final waitingBooking = DemoBookingEntity(
          bookingId: 'demo-789',
          courseName: 'Coding for Kids',
          studentName: 'Freddy Sahoo',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          status: 'scheduled',
        );

        // Hydrated waiting route: must NOT redirect
        final redirectWaitingHydrated = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse(AppRoutePaths.demoClassWaiting),
            matchedLocation: AppRoutePaths.demoClassWaiting,
            fullPath: AppRoutePaths.demoClassWaiting,
            pathParameters: const {},
            pageKey: const ValueKey('waitingHydrated'),
            extra: waitingBooking,
          ),
        );
        expect(redirectWaitingHydrated, isNull);

        // Unhydrated waiting route: MUST redirect to parentDashboard
        final redirectWaitingUnhydrated = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse(AppRoutePaths.demoClassWaiting),
            matchedLocation: AppRoutePaths.demoClassWaiting,
            fullPath: AppRoutePaths.demoClassWaiting,
            pathParameters: const {},
            pageKey: const ValueKey('waitingUnhydrated'),
          ),
        );
        expect(redirectWaitingUnhydrated, AppRoutePaths.parentDashboard);

        // Hydrated live classroom route: must NOT redirect
        final redirectLiveHydrated = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse('/parent/classes/demo-789/live'),
            matchedLocation: '/parent/classes/demo-789/live',
            fullPath: '/parent/classes/:classId/live',
            pathParameters: const {'classId': 'demo-789'},
            pageKey: const ValueKey('liveHydrated'),
            extra: {'session': 'mockSession'},
          ),
        );
        expect(redirectLiveHydrated, isNull);

        // Unhydrated live classroom route: MUST redirect to parentDashboard
        final redirectLiveUnhydrated = routerNotifier.redirect(
          capturedContext,
          GoRouterState(
            GoRouter(routes: []).configuration,
            uri: Uri.parse('/parent/classes/demo-789/live'),
            matchedLocation: '/parent/classes/demo-789/live',
            fullPath: '/parent/classes/:classId/live',
            pathParameters: const {'classId': 'demo-789'},
            pageKey: const ValueKey('liveUnhydrated'),
          ),
        );
        expect(redirectLiveUnhydrated, AppRoutePaths.parentDashboard);
      },
    );
  });
}
