import 'package:dio/dio.dart';

import 'failures.dart';

/// Centralized error mapper converting low-level Dio/system exceptions into [Failure] objects.
abstract final class ErrorHandler {
  /// Converts any error/exception into a domain-level [Failure].
  static Failure handle(dynamic error) {
    if (error is DioException) {
      return fromDioException(error);
    }
    if (error is Failure) {
      return error;
    }
    return UnknownFailure(error?.toString() ?? 'An unexpected error occurred.');
  }

  /// Converts a [DioException] into a typed [Failure].
  static Failure fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        final responseData = dioException.response?.data;

        final message =
            _extractMessage(responseData) ??
            dioException.message ??
            'Server responded with HTTP $statusCode';
        final errorCode = _extractErrorCode(responseData);

        if (statusCode == 401 || statusCode == 403) {
          return AuthFailure(message, statusCode, errorCode);
        }

        if (statusCode == 422) {
          final errors = responseData is Map<String, dynamic>
              ? responseData['errors'] as Map<String, dynamic>?
              : null;
          return ValidationFailure(
            message,
            statusCode: statusCode,
            errors: errors,
          );
        }

        return ServerFailure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );

      case DioExceptionType.cancel:
        return const UnknownFailure('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const ServerFailure('SSL Certificate validation failed.');

      case DioExceptionType.unknown:
        return UnknownFailure(
          dioException.message ?? 'An unknown network error occurred.',
        );
    }
  }

  /// Extracts error message from standard JSON backend response formats.
  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
      if (data['error'] is String && (data['error'] as String).isNotEmpty) {
        return data['error'] as String;
      }
    }
    return null;
  }

  /// Extracts error code from backend response formats.
  static String? _extractErrorCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['code'] != null && data['code'].toString().isNotEmpty) {
        return data['code'].toString();
      }
      if (data['status'] != null &&
          data['status'] != 'fail' &&
          data['status'] != 'error') {
        return data['status'].toString();
      }
    }
    return null;
  }
}
