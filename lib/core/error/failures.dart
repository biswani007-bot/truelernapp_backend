/// Base class for all domain-level failures returned by repositories/services.
sealed class Failure {
  const Failure(this.message, {this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode, errorCode: $errorCode)';
}

/// Emitted when host connectivity is lost or network is unreachable.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Network connection unavailable. Please check your internet connection.',
  ]);
}

/// Emitted when connection, send, or receive timeout limits are exceeded.
final class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'Connection timed out. Please try again.',
  ]);
}

/// Emitted when the server responds with an HTTP 4xx or 5xx status.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode, super.errorCode});
}

/// Emitted on HTTP 401 Unauthenticated or 403 Forbidden.
final class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Session expired or unauthorized. Please sign in again.',
    int? statusCode = 401,
    String? errorCode,
  ]) : super(statusCode: statusCode, errorCode: errorCode);
}

/// Emitted when request payload fails validation (HTTP 422).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.statusCode, this.errors});

  final Map<String, dynamic>? errors;
}

/// Emitted when an unexpected or unclassified exception occurs.
final class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred. Please try again later.',
  ]);
}
