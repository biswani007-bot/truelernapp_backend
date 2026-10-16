import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';

/// Test double implementing [AuthRepository] exclusively for unit test verification.
class FakeAuthRepository implements AuthRepository {
  String? persistedToken;
  AuthResponse? loginSuccessResponse;
  Failure? failureToThrow;
  bool logoutCalled = false;

  @override
  Future<String?> checkPersistedSession() async {
    return persistedToken;
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return loginSuccessResponse ??
        const AuthResponse(
          accessToken: 'valid_test_token',
          user: UserDto(
            id: 'u-1',
            name: 'Parent User',
            email: 'parent@truelern.com',
            role: 'parent',
          ),
        );
  }

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async {
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    return loginSuccessResponse ??
        const AuthResponse(
          accessToken: 'valid_google_token',
          user: UserDto(
            id: 'u-google',
            name: 'Google Parent',
            email: 'google@truelern.com',
            role: 'parent',
          ),
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
  Future<void> logout() async {
    logoutCalled = true;
    persistedToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAuthRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    fakeRepo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController Hardening Tests', () {
    test('initial state is AuthInitial', () {
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthInitial>());
    });

    test(
      'CASE 1: checkSession resolves to Unauthenticated when no token exists',
      () async {
        fakeRepo.persistedToken = null;

        final result = await container
            .read(authControllerProvider.notifier)
            .checkSession();

        expect(result, isFalse);
        final state = container.read(authControllerProvider);
        expect(state, isA<Unauthenticated>());
      },
    );

    test('CASE 2: checkSession resolves to Authenticated when persisted token exists', () async {
      fakeRepo.persistedToken = 'persisted_jwt_token';

      final result = await container
          .read(authControllerProvider.notifier)
          .checkSession();

      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).accessToken, 'persisted_jwt_token');
    });

    test(
      'CASE 4: login enters Authenticated only upon genuine success response',
      () async {
        final notifier = container.read(authControllerProvider.notifier);

        final success = await notifier.login(
          email: 'parent@truelern.com',
          password: 'password123',
        );

        expect(success, isTrue);
        final state = container.read(authControllerProvider);
        expect(state, isA<Authenticated>());
        expect((state as Authenticated).accessToken, 'valid_test_token');
      },
    );

    test('CASE 5: login handles HTTP 500 ServerFailure, sets AuthFailureState, does not authenticate', () async {
      fakeRepo.failureToThrow = const ServerFailure(
        'Internal server error occurred (HTTP 500). Please retry.',
        statusCode: 500,
      );

      final notifier = container.read(authControllerProvider.notifier);

      final success = await notifier.login(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      // Must NOT claim success
      expect(success, isFalse);

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthFailureState>());
      final failureState = state as AuthFailureState;
      expect(failureState.statusCode, 500);
      expect(failureState.message, contains('500'));
    });

    test('CASE 6: login handles HTTP 401/403 AuthFailure and sets AuthFailureState', () async {
      fakeRepo.failureToThrow = const AuthFailure(
        'Invalid email or password. Please verify your credentials.',
        401,
      );

      final notifier = container.read(authControllerProvider.notifier);

      final success = await notifier.login(
        email: 'parent@truelern.com',
        password: 'wrong_password',
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthFailureState>());
      final failureState = state as AuthFailureState;
      expect(failureState.statusCode, 401);
      expect(failureState.message, contains('credentials'));
    });

    test('CASE 7: login handles TimeoutFailure cleanly', () async {
      fakeRepo.failureToThrow = const TimeoutFailure(
        'Connection timed out while reaching server. Please check your connection and retry.',
      );

      final notifier = container.read(authControllerProvider.notifier);

      final success = await notifier.login(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthFailureState>());
      expect((state as AuthFailureState).message, contains('timed out'));
    });

    test('CASE 7: login handles NetworkFailure and remains in AuthFailureState', () async {
      fakeRepo.failureToThrow = const NetworkFailure(
        'Unable to connect to server. Please verify your internet connection.',
      );

      final notifier = container.read(authControllerProvider.notifier);

      final success = await notifier.login(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthFailureState>());
      expect(
        (state as AuthFailureState).message,
        contains('internet connection'),
      );
    });

    test(
      'resetError resets state from AuthFailureState to Unauthenticated',
      () async {
        fakeRepo.failureToThrow = const ServerFailure(
          'Server error',
          statusCode: 500,
        );

        final notifier = container.read(authControllerProvider.notifier);
        await notifier.login(
          email: 'parent@truelern.com',
          password: 'password123',
        );

        expect(container.read(authControllerProvider), isA<AuthFailureState>());

        notifier.resetError();
        expect(container.read(authControllerProvider), isA<Unauthenticated>());
      },
    );

    test('CASE 8: logout transitions state to Unauthenticated and calls repository logout', () async {
      fakeRepo.persistedToken = 'active_token';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.checkSession();

      expect(container.read(authControllerProvider), isA<Authenticated>());

      await notifier.logout();

      expect(fakeRepo.logoutCalled, isTrue);
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    });
  });
}
