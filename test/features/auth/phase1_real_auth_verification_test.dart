import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';

// ignore_for_file: avoid_print

class InMemoryLiveStorage implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getAccessToken() async => _storage['access_token'];

  @override
  Future<void> saveAccessToken(String token) async =>
      _storage['access_token'] = token;

  @override
  Future<void> deleteAccessToken() async => _storage.remove('access_token');

  @override
  Future<String?> getRefreshToken() async => _storage['refresh_token'];

  @override
  Future<void> saveRefreshToken(String token) async =>
      _storage['refresh_token'] = token;

  @override
  Future<void> deleteRefreshToken() async => _storage.remove('refresh_token');

  @override
  Future<String?> getUserId() async => _storage['user_id'];

  @override
  Future<void> saveUserId(String id) async => _storage['user_id'] = id;

  @override
  Future<void> saveActiveChildId(String childId) async =>
      _storage['active_child_id'] = childId;

  @override
  Future<String?> getActiveChildId() async => _storage['active_child_id'];

  @override
  Future<void> deleteActiveChildId() async =>
      _storage.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _storage.clear();

  bool hasAccessToken() =>
      _storage.containsKey('access_token') &&
      _storage['access_token']!.isNotEmpty;
  bool hasRefreshToken() =>
      _storage.containsKey('refresh_token') &&
      _storage['refresh_token']!.isNotEmpty;
}

void main() {
  group('PHASE 1 REAL API AUTHENTICATION TESTS', () {
    late InMemoryLiveStorage liveStorage;
    late ProviderContainer container;

    setUp(() {
      liveStorage = InMemoryLiveStorage();
      container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(liveStorage)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Test A: Invalid login returns 401, sets AuthFailureState with API message, leaves storage empty', () async {
      final authNotifier = container.read(authControllerProvider.notifier);

      final result = await authNotifier.login(
        email: 'wrong_user@example.com',
        password: 'bad_password_xyz',
      );

      final state = container.read(authControllerProvider);

      expect(result, isFalse);
      expect(state, isA<AuthFailureState>());

      final failure = state as AuthFailureState;
      expect(failure.statusCode, equals(401));
      expect(failure.message, contains('Invalid'));
      expect(liveStorage.hasAccessToken(), isFalse);
      expect(liveStorage.hasRefreshToken(), isFalse);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Test B: Valid login returns 200 OK, stores real tokens, and sets Authenticated with user profile', () async {
      final authNotifier = container.read(authControllerProvider.notifier);

      final result = await authNotifier.login(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      final state = container.read(authControllerProvider);

      expect(result, isTrue);
      expect(state, isA<Authenticated>());

      final auth = state as Authenticated;
      expect(auth.accessToken.isNotEmpty, isTrue);
      expect(auth.user?.name, isNotEmpty);
      expect(auth.user?.role?.toLowerCase(), equals('parent'));

      expect(liveStorage.hasAccessToken(), isTrue);
      expect(liveStorage.hasRefreshToken(), isTrue);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Test C: App restart / session restoration restores Authenticated state from persisted secure token', () async {
      // Pre-condition: User had previously authenticated and tokens were stored in storage
      await liveStorage.saveAccessToken('existing_persisted_access_token');
      await liveStorage.saveRefreshToken('existing_persisted_refresh_token');

      // App reboots: New container created with initial state
      final freshContainer = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(liveStorage)],
      );
      addTearDown(freshContainer.dispose);

      expect(freshContainer.read(authControllerProvider), isA<AuthInitial>());

      final restored = await freshContainer
          .read(authControllerProvider.notifier)
          .checkSession();

      expect(restored, isTrue);
      final state = freshContainer.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      expect(
        (state as Authenticated).accessToken,
        equals('existing_persisted_access_token'),
      );
    });

    test(
      'Test D: Logout clears server session and purges all secure storage keys',
      () async {
        // Step 1: Login
        final authNotifier = container.read(authControllerProvider.notifier);
        await authNotifier.login(
          email: 'parent@truelern.com',
          password: 'password123',
        );

        expect(liveStorage.hasAccessToken(), isTrue);
        expect(container.read(authControllerProvider), isA<Authenticated>());

        // Step 2: Logout
        await authNotifier.logout();

        expect(liveStorage.hasAccessToken(), isFalse);
        expect(liveStorage.hasRefreshToken(), isFalse);
        expect(container.read(authControllerProvider), isA<Unauthenticated>());
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
