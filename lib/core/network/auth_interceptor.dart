import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor that attaches a Bearer JWT to outgoing requests if available
/// and performs silent token rotation upon receiving a 401 Unauthorized response.
///
/// Strictly abides by TrueLern security invariants:
/// - NEVER generates fake JWTs.
/// - NEVER bypasses authentication.
/// - If no token exists in secure storage, request proceeds unauthenticated.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.storageService, required this.dio});

  final SecureStorageService storageService;
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix}$token';
      }
    } catch (_) {
      // If secure storage access fails, proceed without token rather than crashing
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestPath = err.requestOptions.path;

    // Do not attempt token refresh for authentication requests to avoid loops
    final isAuthEndpoint =
        requestPath.contains('/auth/login') ||
        requestPath.contains('/auth/refresh') ||
        requestPath.contains('/auth/mobile/google') ||
        requestPath.contains('/auth/mobile/refresh') ||
        requestPath.contains('/auth/mobile/logout') ||
        requestPath.contains('/auth/forgot-password');

    if (response?.statusCode == 401 && !isAuthEndpoint) {
      try {
        final refreshToken = await storageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // Perform silent token rotation against live API
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: dio.options.baseUrl,
              headers: {
                ApiConstants.contentTypeHeader: ApiConstants.applicationJson,
                ApiConstants.acceptHeader: ApiConstants.applicationJson,
              },
              responseType: ResponseType.json,
            ),
          );

          final refreshResponse = await refreshDio.post<dynamic>(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final responseData = refreshResponse.data;
          String? newAccessToken;
          String? newRefreshToken;

          if (responseData is Map<String, dynamic>) {
            final payload = responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData;
            newAccessToken = (payload['accessToken'] ?? payload['token'])
                ?.toString();
            newRefreshToken = payload['refreshToken']?.toString();
          }

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await storageService.saveAccessToken(newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await storageService.saveRefreshToken(newRefreshToken);
            }

            // Retry original request with newly rotated token
            final retryOptions = err.requestOptions;
            retryOptions.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix}$newAccessToken';

            final retriedResponse = await dio.fetch<dynamic>(retryOptions);
            return handler.resolve(retriedResponse);
          }
        }
      } catch (_) {
        // Refresh token failed or expired: invalidate local session
        await storageService.clearAuthSession();
      }
    }

    return handler.next(err);
  }
}
