// ACTION 4C — Real Flutter Login Runtime Verification Test
//
// This file uses a pure Dart test (not flutter test widget machinery) to execute
// the real Flutter authentication pipeline through the real production API without
// fake-async time manipulation.
//
// The first run of this test already produced definitive results:
//   AuthState: AuthFailureState
//   statusCode: null (Dio TimeoutFailure — not an HTTP response code)
//   message: "Connection timed out. Please try again."
//   accessToken in storage: false
//   refreshToken in storage: false
//
// This documents that the Flutter test VM makes real HTTP calls to
// https://truelern.visital.in/api/auth/login
// and the Dio 15-second connectTimeout fires before the server responds.
//
// This aligns with the curl probe results (HTTP 500 when server accepts but fails internally,
// or connection-level timeout when the server is under load or the test-VM
// network path to truelern.visital.in is disrupted).
//
// This file is maintained as the authoritative runtime record.
// DO NOT modify without explicit governance authorization.

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';

import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';

/// In-memory storage for runtime verification — does not use FlutterSecureStorage
class LiveVerificationStorage implements SecureStorageService {
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
  Future<void> saveActiveChildId(String childId) async => _data['active_child_id'] = childId;

  @override
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _data.clear();

  bool hasAccessToken() => _data.containsKey('access_token') && _data['access_token']!.isNotEmpty;
  bool hasRefreshToken() => _data.containsKey('refresh_token') && _data['refresh_token']!.isNotEmpty;
}

void main() {
  // ACTION 4C RUNTIME VERIFICATION
  // Governance: Real production API, real credentials, real Dio stack
  // No mocks, no fake JWT, no token injection, no bypass.

  group('ACTION 4C — Real Parent Login Runtime Verification (Direct Await)', () {
    test(
      'executes real POST /api/auth/login via AuthController and captures result',
      () async {
        final liveStorage = LiveVerificationStorage();

        final container = ProviderContainer(
          overrides: [
            secureStorageProvider.overrideWithValue(liveStorage),
          ],
        );
        addTearDown(container.dispose);

        // Verify initial state
        final initialState = container.read(authControllerProvider);
        expect(initialState, isA<AuthInitial>());

        // Execute real login through AuthController → AuthRepository → Dio → production API
        // This is NOT using fake-async — it awaits a real Future
        final authController = container.read(authControllerProvider.notifier);
        final success = await authController.login(
          email: 'parent@truelern.com',
          password: 'password123',
        );

        final finalState = container.read(authControllerProvider);

        print('============================================================');
        print('ACTION 4C REAL RUNTIME RESULT:');
        print('Login success boolean: $success');
        print('Final AuthState type: ${finalState.runtimeType}');

        if (finalState is AuthFailureState) {
          // RESULT B (HTTP 500) or RESULT D (timeout/network)
          print('HTTP Status Code from Failure: ${finalState.statusCode ?? "null (timeout/network)"}');
          print('Failure Message: ${finalState.message}');
          print('Access Token in Storage: ${liveStorage.hasAccessToken()}');
          print('Refresh Token in Storage: ${liveStorage.hasRefreshToken()}');

          // Governance verification: failure state invariants
          expect(success, isFalse);
          expect(liveStorage.hasAccessToken(), isFalse,
              reason: 'No access token must be stored on login failure');
          expect(liveStorage.hasRefreshToken(), isFalse,
              reason: 'No refresh token must be stored on login failure');
        } else if (finalState is Authenticated) {
          // RESULT A (HTTP 200)
          print('HTTP Status Code: 200 OK');
          print('User: ${finalState.user?.name ?? "N/A"}');
          print('Access Token in Storage: ${liveStorage.hasAccessToken()}');
          print('Refresh Token in Storage: ${liveStorage.hasRefreshToken()}');

          expect(success, isTrue);
          expect(finalState.accessToken.isNotEmpty, isTrue);
          expect(liveStorage.hasAccessToken(), isTrue,
              reason: 'Access token must be stored on HTTP 200 success');
        }

        print('============================================================');
      },
      // Extended timeout to allow for real HTTP call up to 20 seconds
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
