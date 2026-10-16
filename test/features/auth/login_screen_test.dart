import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/services/google_sign_in_service.dart';
import 'package:truelearn/features/auth/presentation/screens/login_screen.dart';

class FakeGoogleSignInService implements GoogleSignInService {
  String? mockToken = 'mock_id_token';

  @override
  Future<String?> getIdToken() async => mockToken;

  @override
  Future<void> signOut() async {}
}

class FakeAuthRepository implements AuthRepository {
  Failure? failureToThrow;
  bool loginCalled = false;
  bool googleSignInCalled = false;

  @override
  Future<String?> checkPersistedSession() async => null;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    loginCalled = true;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return const AuthResponse(
      accessToken: 'test_token',
      user: UserDto(id: '1', name: 'Test', email: 'test@truelern.com'),
    );
  }

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async {
    googleSignInCalled = true;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return const AuthResponse(
      accessToken: 'test_google_token',
      user: UserDto(id: '1', name: 'Google User', email: 'google@truelern.com'),
    );
  }

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

  @override
  Future<Map<String, dynamic>> getCurrentParentContext() async => {};

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
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeAuthRepository fakeRepo;
  late FakeGoogleSignInService fakeGoogleService;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    fakeGoogleService = FakeGoogleSignInService();
  });

  Widget createLoginApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        googleSignInServiceProvider.overrideWithValue(fakeGoogleService),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen Hardening & Widget Tests', () {
    testWidgets('renders all Figma elements: title, inputs, button, footer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createLoginApp());
      await tester.pump();

      // Heading and subtitle (Figma 71:232)
      expect(find.text('Welcome'), findsOneWidget);
      expect(
        find.text('Sign in to continue your learning\njourney.'),
        findsOneWidget,
      );

      // Email field
      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Password field
      expect(find.text('Password'), findsOneWidget);

      // Continue Button
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);

      // Social Auth buttons
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign in with Microsoft'), findsNothing);
      expect(find.text('Create Account'), findsNothing);
      expect(find.text("Don't have an account? "), findsNothing);
      expect(find.text('Create account'), findsNothing);
    });

    testWidgets(
      'CASE 3: shows validation errors when submitting empty form and does not call API',
      (WidgetTester tester) async {
        await tester.pumpWidget(createLoginApp());
        await tester.pump();

        // Tap Continue without filling fields
        await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
        await tester.pump();

        // Validation errors
        expect(find.text('Please enter your email address.'), findsOneWidget);
        expect(find.text('Please enter your password.'), findsOneWidget);
        expect(fakeRepo.loginCalled, isFalse);
      },
    );

    testWidgets(
      'CASE 3: shows format validation error for invalid email and short password',
      (WidgetTester tester) async {
        await tester.pumpWidget(createLoginApp());
        await tester.pump();

        // Enter invalid email
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'invalid-email-format');
        await tester.enterText(fields.at(1), '123'); // short password

        await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
        await tester.pump();

        expect(
          find.text('Please enter a valid email address.'),
          findsOneWidget,
        );
        expect(
          find.text('Password must be at least 6 characters.'),
          findsOneWidget,
        );
        expect(fakeRepo.loginCalled, isFalse);
      },
    );

    testWidgets(
      'CASE 5: displays server error banner on HTTP 500 failure and permits retry',
      (WidgetTester tester) async {
        fakeRepo.failureToThrow = const ServerFailure(
          'Internal server error occurred (HTTP 500). Please retry.',
          statusCode: 500,
        );

        await tester.pumpWidget(createLoginApp());
        await tester.pump();

        // Fill in valid inputs
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'parent@truelern.com');
        await tester.enterText(fields.at(1), 'password123');

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
        await tester.pump(); // Start submitting
        await tester.pump(); // Finish future and state transition

        // Verify repo was invoked
        expect(fakeRepo.loginCalled, isTrue);

        // Verify user remains on Login screen and error banner is displayed
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          find.text('Internal server error occurred (HTTP 500). Please retry.'),
          findsOneWidget,
        );
        // User can still see the button and retry
        expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
      },
    );

    testWidgets('CASE 6: displays authentication failure banner on HTTP 401', (
      WidgetTester tester,
    ) async {
      fakeRepo.failureToThrow = const AuthFailure(
        'Invalid email or password. Please verify your credentials.',
        401,
      );

      await tester.pumpWidget(createLoginApp());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'parent@truelern.com');
      await tester.enterText(fields.at(1), 'wrong_pass');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Invalid email or password. Please verify your credentials.'),
        findsOneWidget,
      );
    });

    testWidgets('CASE 7: displays network failure banner on connection drop', (
      WidgetTester tester,
    ) async {
      fakeRepo.failureToThrow = const NetworkFailure(
        'Unable to connect to server. Please verify your internet connection.',
      );

      await tester.pumpWidget(createLoginApp());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'parent@truelern.com');
      await tester.enterText(fields.at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text(
          'Unable to connect to server. Please verify your internet connection.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping Google button initiates Google Sign-In and repository exchange',
      (WidgetTester tester) async {
        await tester.pumpWidget(createLoginApp());
        await tester.pump();

        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        expect(fakeRepo.googleSignInCalled, isTrue);
      },
    );
  });
}
