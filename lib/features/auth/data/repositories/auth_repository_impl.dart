import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/password_prompt_status.dart';

/// Concrete implementation of [AuthRepository] interacting with TrueLern production API.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiClient, required this.secureStorage});

  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    // Calls POST /api/auth/login using the single configured ApiClient
    final response = await apiClient.post<dynamic>(
      '/auth/login',
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw const ServerFailure('Invalid server response structure.');
    }

    final authResponse = AuthResponse.fromJson(
      response.data as Map<String, dynamic>,
    );

    if (authResponse.accessToken.isEmpty) {
      throw const ServerFailure(
        'Authentication token was not returned by the server.',
      );
    }

    // Persist session tokens only after genuine server validation
    await secureStorage.saveAccessToken(authResponse.accessToken);
    if (authResponse.refreshToken != null &&
        authResponse.refreshToken!.isNotEmpty) {
      await secureStorage.saveRefreshToken(authResponse.refreshToken!);
    }
    if (authResponse.user != null) {
      await secureStorage.saveUserId(authResponse.user!.id);
    }

    return authResponse;
  }

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async {
    final response = await apiClient.post<dynamic>(
      '/auth/mobile/google',
      data: {'idToken': idToken, 'platform': 'android'},
    );

    if (response.data is! Map<String, dynamic>) {
      throw const ServerFailure('Invalid server response structure.');
    }

    final authResponse = AuthResponse.fromJson(
      response.data as Map<String, dynamic>,
    );

    if (authResponse.accessToken.isEmpty) {
      throw const ServerFailure(
        'Authentication token was not returned by the server.',
      );
    }

    // Persist session tokens securely
    await secureStorage.saveAccessToken(authResponse.accessToken);
    if (authResponse.refreshToken != null &&
        authResponse.refreshToken!.isNotEmpty) {
      await secureStorage.saveRefreshToken(authResponse.refreshToken!);
    }
    if (authResponse.user != null) {
      await secureStorage.saveUserId(authResponse.user!.id);
    }

    return authResponse;
  }

  @override
  Future<String?> checkPersistedSession() async {
    try {
      final token = await secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (_) {
      // Storage read failure defaults to unauthenticated
    }
    return null;
  }

  @override
  Future<PasswordPromptStatus> getPasswordPromptStatus() async {
    final response = await apiClient.get<dynamic>(
      '/parent/security/password-prompt-status',
    );

    if (response.data is! Map<String, dynamic>) {
      throw const ServerFailure('Invalid password prompt status response.');
    }

    return PasswordPromptStatus.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final response = await apiClient.post<dynamic>(
      '/parent/security/setup-password',
      data: {'password': password, 'confirmPassword': confirmPassword},
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true || response.statusCode == 200;
    }
    return response.statusCode == 200;
  }

  @override
  Future<bool> dismissPasswordPrompt({required String action}) async {
    final response = await apiClient.post<dynamic>(
      '/parent/security/dismiss-password-prompt',
      data: {'action': action},
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true || response.statusCode == 200;
    }
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> getCurrentParentContext() async {
    final response = await apiClient.get<dynamic>('/auth/mobile/me');

    if (response.data is! Map<String, dynamic>) {
      throw const ServerFailure('Invalid parent context response.');
    }

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> getParentDemo({String? studentId}) async {
    final queryParams = <String, dynamic>{};
    if (studentId != null && studentId.isNotEmpty) {
      queryParams['studentId'] = studentId;
    }
    final response = await apiClient.get<dynamic>(
      '/parent/demo',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      if (map['data'] is Map<String, dynamic>) {
        return map['data'] as Map<String, dynamic>;
      }
      if (map['data'] is List && (map['data'] as List).isNotEmpty) {
        final first = (map['data'] as List).first;
        if (first is Map<String, dynamic>) return first;
      }
      if (map['lead'] != null ||
          map['demo'] != null ||
          map['demoSession'] != null) {
        return map;
      }
      return map;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getParentStatus({String? studentId}) async {
    final queryParams = <String, dynamic>{};
    if (studentId != null && studentId.isNotEmpty) {
      queryParams['studentId'] = studentId;
    }
    final response = await apiClient.get<dynamic>(
      '/parent/status',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      if (map['data'] is Map<String, dynamic>) {
        return map['data'] as Map<String, dynamic>;
      }
      if (map['state'] != null || map['action'] != null) {
        return map;
      }
      return map;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getChildDashboard(String childStudentId) async {
    final response = await apiClient.get<dynamic>(
      '/parent/children/$childStudentId/dashboard',
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      if (map['data'] is Map<String, dynamic>) {
        return map['data'] as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiClient.post<dynamic>(
          '/auth/mobile/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await secureStorage.clearAuthSession();
    }
  }
}

/// Global provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
