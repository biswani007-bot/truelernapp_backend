import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/error_handler.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/login_request.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';

/// Controller managing authentication state and login operations.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Checks if a valid session exists in secure storage.
  Future<bool> checkSession() async {
    state = const AuthCheckingSession();
    try {
      final token = await _repository.checkPersistedSession();
      if (token != null && token.isNotEmpty) {
        final decoded = decodeJwt(token);
        final role = decoded?['role'] as String?;
        final userId = decoded?['userId'] as String? ?? '';
        state = Authenticated(
          accessToken: token,
          user: UserDto(
            id: userId,
            role: role,
          ),
        );
        return true;
      }
    } catch (_) {
      // Storage failure defaults to unauthenticated
    }

    state = const Unauthenticated();
    return false;
  }

  static Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return json.decode(payload) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Submits credentials to POST /api/auth/login.
  ///
  /// Strictly adheres to TrueLern security rules:
  /// - Only enters [Authenticated] upon receiving HTTP 200 with valid tokens from server.
  /// - On server error (e.g. HTTP 500) or invalid credentials, enters [AuthFailureState] and stays on login.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AuthSubmitting();
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      state = Authenticated(
        accessToken: response.accessToken,
        user: response.user,
      );
      return true;
    } catch (error) {
      final failure = ErrorHandler.handle(error);
      state = AuthFailureState(
        message: failure.message,
        statusCode: failure.statusCode,
      );
      return false;
    }
  }

  /// Clears any transient failure state back to [Unauthenticated].
  void resetError() {
    if (state is AuthFailureState) {
      state = const Unauthenticated();
    }
  }

  /// Sets a frontend-only demo session for UI prototype flows without backend/network calls.
  void setDemoSession() {
    state = const Authenticated(
      accessToken: 'static_demo_token_prototype',
    );
  }

  /// Terminates session and clears persisted tokens.
  Future<void> logout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }
}

/// Global provider for [AuthController].
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
