import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/error_handler.dart';
import 'package:truelearn/core/error/failures.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('maps connection timeout to TimeoutFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final failure = ErrorHandler.fromDioException(dioException);
      expect(failure, isA<TimeoutFailure>());
    });

    test('maps connection error to NetworkFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final failure = ErrorHandler.fromDioException(dioException);
      expect(failure, isA<NetworkFailure>());
    });

    test('maps HTTP 401 to AuthFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
      );
      final failure = ErrorHandler.fromDioException(dioException);
      expect(failure, isA<AuthFailure>());
      expect(failure.statusCode, 401);
      expect(failure.message, 'Unauthorized');
    });

    test('maps HTTP 422 to ValidationFailure with error map', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'message': 'Invalid input',
            'errors': {'email': 'Invalid email format'},
          },
        ),
      );
      final failure = ErrorHandler.fromDioException(dioException);
      expect(failure, isA<ValidationFailure>());
      expect(failure.statusCode, 422);
      expect(
        (failure as ValidationFailure).errors?['email'],
        'Invalid email format',
      );
    });

    test('maps HTTP 500 to ServerFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
      );
      final failure = ErrorHandler.fromDioException(dioException);
      expect(failure, isA<ServerFailure>());
      expect(failure.statusCode, 500);
      expect(failure.message, 'Internal server error');
    });
  });
}
