import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
