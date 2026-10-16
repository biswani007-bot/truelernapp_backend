import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/constants/api_constants.dart';
import 'package:truelearn/core/network/auth_interceptor.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';

class FakeSecureStorage implements SecureStorageService {
  String? token;
  bool shouldThrow = false;

  @override
  Future<String?> getAccessToken() async {
    if (shouldThrow) throw Exception('Storage read error');
    return token;
  }

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<void> deleteAccessToken() async => token = null;

  @override
  Future<void> clearAuthSession() async => token = null;

  @override
  Future<void> deleteRefreshToken() async {}

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> saveRefreshToken(String token) async {}

  @override
  Future<void> saveUserId(String id) async {}

  @override
  Future<void> deleteActiveChildId() async {}

  @override
  Future<String?> getActiveChildId() async => null;

  @override
  Future<void> saveActiveChildId(String childId) async {}
}

void main() {
  group('AuthInterceptor Tests', () {
    late FakeSecureStorage fakeStorage;
    late AuthInterceptor interceptor;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      interceptor = AuthInterceptor(storageService: fakeStorage, dio: Dio());
    });

    test(
      'attaches Bearer token when a valid token exists in secure storage',
      () async {
        fakeStorage.token = 'verified_jwt_sample';

        final options = RequestOptions(path: '/portal-config');
        final handler = RequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(
          options.headers[ApiConstants.authorizationHeader],
          'Bearer verified_jwt_sample',
        );
      },
    );

    test('does NOT attach Authorization header when no token exists', () async {
      fakeStorage.token = null;

      final options = RequestOptions(path: '/portal-config');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(
        options.headers.containsKey(ApiConstants.authorizationHeader),
        isFalse,
      );
    });

    test(
      'does NOT attach Authorization header when token is empty string',
      () async {
        fakeStorage.token = '';

        final options = RequestOptions(path: '/portal-config');
        final handler = RequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(
          options.headers.containsKey(ApiConstants.authorizationHeader),
          isFalse,
        );
      },
    );

    test('handles secure storage exception safely without crashing or injecting fake token', () async {
      fakeStorage.shouldThrow = true;

      final options = RequestOptions(path: '/portal-config');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(
        options.headers.containsKey(ApiConstants.authorizationHeader),
        isFalse,
      );
    });
  });
}
