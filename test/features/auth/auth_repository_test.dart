import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  Response<dynamic>? responseToReturn;
  Object? errorToThrow;
  String? lastPath;
  dynamic lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return (responseToReturn as Response<T>?) ??
        Response<T>(
          requestOptions: RequestOptions(path: path),
          data: <String, dynamic>{
            'accessToken': 'genuine_jwt_token_123',
            'refreshToken': 'genuine_refresh_token_456',
            'user': <String, dynamic>{
              'id': 'usr_parent_1',
              'name': 'Parent Name',
              'email': 'parent@truelern.com',
              'role': 'parent',
            },
          } as T,
          statusCode: 200,
        );
  }
}

class FakeSecureStorage implements SecureStorageService {
  String? accessToken;
  String? refreshToken;
  String? userId;
  String? activeChildId;
  bool clearAuthSessionCalled = false;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> deleteAccessToken() async => accessToken = null;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> deleteRefreshToken() async => refreshToken = null;

  @override
  Future<void> saveUserId(String id) async => userId = id;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> saveActiveChildId(String childId) async =>
      activeChildId = childId;

  @override
  Future<String?> getActiveChildId() async => activeChildId;

  @override
  Future<void> deleteActiveChildId() async => activeChildId = null;

  @override
  Future<void> clearAuthSession() async {
    clearAuthSessionCalled = true;
    accessToken = null;
    refreshToken = null;
    userId = null;
    activeChildId = null;
  }
}

void main() {
  group('AuthRepositoryImpl Hardening Tests', () {
    late FakeApiClient fakeApiClient;
    late FakeSecureStorage fakeSecureStorage;
    late AuthRepositoryImpl repository;

    setUp(() {
      fakeApiClient = FakeApiClient();
      fakeSecureStorage = FakeSecureStorage();
      repository = AuthRepositoryImpl(
        apiClient: fakeApiClient,
        secureStorage: fakeSecureStorage,
      );
    });

    test('login sends expected payload to /auth/login and stores tokens on genuine success', () async {
      const request = LoginRequest(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      final result = await repository.login(request);

      expect(fakeApiClient.lastPath, '/auth/login');
      expect(fakeApiClient.lastData, {
        'email': 'parent@truelern.com',
        'password': 'password123',
      });
      expect(result.accessToken, 'genuine_jwt_token_123');
      expect(fakeSecureStorage.accessToken, 'genuine_jwt_token_123');
      expect(fakeSecureStorage.refreshToken, 'genuine_refresh_token_456');
      expect(fakeSecureStorage.userId, 'usr_parent_1');
    });

    test('login NEVER stores token on HTTP 500 ServerFailure', () async {
      fakeApiClient.errorToThrow = const ServerFailure(
        'Internal server error occurred (HTTP 500). Please retry.',
        statusCode: 500,
      );

      const request = LoginRequest(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      await expectLater(
        () => repository.login(request),
        throwsA(isA<ServerFailure>()),
      );

      // Verify zero tokens were written
      expect(fakeSecureStorage.accessToken, isNull);
      expect(fakeSecureStorage.refreshToken, isNull);
      expect(fakeSecureStorage.userId, isNull);
    });

    test('login NEVER stores token on HTTP 401 AuthFailure', () async {
      fakeApiClient.errorToThrow = const AuthFailure(
        'Invalid email or password.',
        401,
      );

      const request = LoginRequest(
        email: 'parent@truelern.com',
        password: 'wrongpassword',
      );

      await expectLater(
        () => repository.login(request),
        throwsA(isA<AuthFailure>()),
      );

      expect(fakeSecureStorage.accessToken, isNull);
    });

    test('login NEVER stores token on NetworkFailure', () async {
      fakeApiClient.errorToThrow = const NetworkFailure(
        'Unable to connect to server. Please verify your internet connection.',
      );

      const request = LoginRequest(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      await expectLater(
        () => repository.login(request),
        throwsA(isA<NetworkFailure>()),
      );

      expect(fakeSecureStorage.accessToken, isNull);
    });

    test(
      'checkPersistedSession restores existing token from storage',
      () async {
        fakeSecureStorage.accessToken = 'persisted_session_token';

        final token = await repository.checkPersistedSession();

        expect(token, 'persisted_session_token');
      },
    );

    test(
      'checkPersistedSession returns null when storage has no token',
      () async {
        fakeSecureStorage.accessToken = null;

        final token = await repository.checkPersistedSession();

        expect(token, isNull);
      },
    );

    test('logout invokes clearAuthSession on secure storage', () async {
      fakeSecureStorage.accessToken = 'active_token';

      await repository.logout();

      expect(fakeSecureStorage.clearAuthSessionCalled, isTrue);
      expect(fakeSecureStorage.accessToken, isNull);
    });
  });
}
