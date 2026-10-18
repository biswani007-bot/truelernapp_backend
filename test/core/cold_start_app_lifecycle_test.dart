import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/router/app_router.dart';
import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';

class MockLifecycleAuthRepo implements AuthRepository {
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
      'user': {'role': 'parent', 'id': 'parent-123'},
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

  group('Cold Start App Lifecycle & Transient Route Protection', () {
    testWidgets(
      'Authenticated cold start on transient routes redirects safely to Parent Dashboard',
      (WidgetTester tester) async {
        final mockRepo = MockLifecycleAuthRepo()..token = 'valid_session_token';
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

        // Bootstrap authenticated session
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

        // 1. Transient demo waiting screen should redirect to parent dashboard
        router.go(AppRoutePaths.demoClassWaiting);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, AppRoutePaths.parentDashboard);

        // 2. Transient payment successful screen should redirect to parent dashboard
        router.go(AppRoutePaths.paymentSuccessful);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, AppRoutePaths.parentDashboard);

        // 3. Transient live classroom route should redirect to parent dashboard
        router.go('/parent/classes/class-123/live');
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, AppRoutePaths.parentDashboard);

        // 4. Permanent routes (e.g. parent invoices list and details) must NOT be redirected
        router.go(AppRoutePaths.parentInvoices);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, AppRoutePaths.parentInvoices);
      },
    );

    testWidgets(
      'Unauthenticated cold start with transient route redirects to splash or login',
      (WidgetTester tester) async {
        final mockRepo = MockLifecycleAuthRepo()..token = null;
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

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
        router.go(AppRoutePaths.demoWaitingForAdmin);
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, AppRoutePaths.login);
      },
    );
  });
}
