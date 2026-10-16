import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/screens/password_setup_screen.dart';
import 'package:truelearn/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:truelearn/features/onboarding/presentation/screens/onboarding_account_screen.dart';
import 'package:truelearn/features/onboarding/presentation/screens/onboarding_child_screen.dart';
import 'package:truelearn/features/onboarding/presentation/screens/onboarding_interests_screen.dart';
import 'package:truelearn/features/onboarding/presentation/screens/onboarding_location_screen.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'status': 'success',
        'data': [
          {'title': 'ACE Public Speaking Program'},
          {'title': 'Junior Foundation'},
        ],
      } as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: {'status': 'success', 'leadId': 'lead_12345'} as T,
    );
  }
}

class FakeAuthRepo implements AuthRepository {
  bool setupPasswordCalled = false;
  bool dismissPromptCalled = false;

  @override
  Future<String?> checkPersistedSession() async => 'fake_token';

  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async =>
      throw UnimplementedError();

  @override
  Future<PasswordPromptStatus> getPasswordPromptStatus() async =>
      const PasswordPromptStatus(
        showPrompt: true,
        hasPassword: false,
        dontAskAgain: false,
        cooldownActive: false,
      );

  @override
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    setupPasswordCalled = true;
    return true;
  }

  @override
  Future<bool> dismissPasswordPrompt({required String action}) async {
    dismissPromptCalled = true;
    return true;
  }

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

  late FakeAuthRepo fakeAuthRepo;
  late FakeApiClient fakeApiClient;

  setUp(() {
    fakeAuthRepo = FakeAuthRepo();
    fakeApiClient = FakeApiClient();
  });

  group('PasswordSetupScreen Widget Tests', () {
    testWidgets('renders all security setup elements and checklist', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            apiClientProvider.overrideWithValue(fakeApiClient),
          ],
          child: const MaterialApp(home: PasswordSetupScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('Create New Password *'), findsOneWidget);
      expect(find.text('Confirm New Password *'), findsOneWidget);
      expect(find.text('Save Password'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
      expect(find.text("Don't Ask Again"), findsOneWidget);

      // Verify checklist items
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(
        find.text('At least 1 number or special character'),
        findsOneWidget,
      );
      expect(find.text('Passwords match'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            apiClientProvider.overrideWithValue(fakeApiClient),
          ],
          child: const MaterialApp(home: PasswordSetupScreen()),
        ),
      );
      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'Password123');
      await tester.enterText(textFields.at(1), 'DifferentPassword456');
      await tester.pump();

      await tester.ensureVisible(find.text('Save Password'));
      await tester.tap(find.text('Save Password'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(fakeAuthRepo.setupPasswordCalled, isFalse);
    });
  });

  group('Onboarding Screens Widget Tests', () {
    testWidgets(
      'OnboardingInterestsScreen renders step 1 elements and preserves course selection',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(fakeApiClient)],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: OnboardingInterestsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Interests'), findsOneWidget);
        expect(find.text("Course You're Interested In *"), findsOneWidget);
        expect(find.text('ACE Public Speaking Program'), findsOneWidget);
        expect(find.text('Time Zone *'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);

        // Verify selecting another course updates controller and UI
        final dropdowns = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdowns.first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Junior Foundation').last);
        await tester.pumpAndSettle();

        expect(find.text('Junior Foundation'), findsOneWidget);
        final controllerState = container.read(onboardingControllerProvider);
        expect(controllerState.interestedCourse, 'Junior Foundation');
      },
    );

    testWidgets('OnboardingAccountScreen renders step 2 elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(fakeApiClient)],
          child: const MaterialApp(home: OnboardingAccountScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Account details'), findsOneWidget);
      expect(find.text('Your Full Name *'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets(
      'OnboardingChildScreen renders web reference elements and step 1 badge',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiClientProvider.overrideWithValue(fakeApiClient)],
            child: const MaterialApp(home: OnboardingChildScreen()),
          ),
        );
        await tester.pump();

        expect(find.text('Welcome to TrueLern'), findsOneWidget);
        expect(
          find.text(
            "Add your child's details to set up their learning profile.",
          ),
          findsOneWidget,
        );
        expect(find.text('First Name *'), findsOneWidget);
        expect(find.text('Last Name *'), findsOneWidget);
        expect(find.text("Child's Age *"), findsOneWidget);
        expect(find.text('STEP 1 OF 4'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'OnboardingChildScreen validates required inputs before advancing',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiClientProvider.overrideWithValue(fakeApiClient)],
            child: const MaterialApp(home: OnboardingChildScreen()),
          ),
        );
        await tester.pump();

        // Tap Continue with empty fields
        await tester.ensureVisible(find.text('Continue'));
        await tester.tap(find.text('Continue'));
        await tester.pump();

        expect(
          find.text("Please enter your child's first name."),
          findsOneWidget,
        );

        // Enter first name with only 1 character
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'A');
        await tester.tap(find.text('Continue'));
        await tester.pump();

        expect(
          find.text('First name must be at least 2 characters.'),
          findsOneWidget,
        );

        // Enter valid first name and tap continue without last name
        await tester.enterText(textFields.at(0), 'Alex');
        await tester.tap(find.text('Continue'));
        await tester.pump();

        expect(
          find.text("Please enter your child's last name."),
          findsOneWidget,
        );
      },
    );

    testWidgets('OnboardingLocationScreen renders step 4 elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(fakeApiClient)],
          child: const MaterialApp(home: OnboardingLocationScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('ALMOST READY'), findsOneWidget);
      expect(find.text('Location Details'), findsOneWidget);
      expect(find.text('State *'), findsOneWidget);
      expect(find.text('City *'), findsOneWidget);
      expect(find.text('Complete Registration'), findsOneWidget);
    });
  });
}
