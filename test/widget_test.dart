import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/app.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/screens/splash_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> checkPersistedSession() async => null;

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

  testWidgets(
    'TrueLern application root launches and renders Splash screen then resolves to Login',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: const TrueLernApp(),
        ),
      );

      await tester.pump();

      // Verify application starts cleanly with TrueLernApp root
      expect(find.byType(TrueLernApp), findsOneWidget);

      // Verify SplashScreen is rendered initially
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);

      // Advance past splash bootstrap delay (2500ms)
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      // Verify navigation resolved unauthenticated state to OnboardingScreen (Screen 1: Learn with Fun)
      expect(find.text('Learn with Fun'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to navigate to Screen 2: Grow Every Day
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Grow Every Day'), findsOneWidget);

      // Tap Next to navigate to Screen 3: Learning Without Limits
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Learning Without Limits'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started to navigate to Login
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
    },
  );
}
