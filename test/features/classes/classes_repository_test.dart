import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/classes/data/models/class_dto.dart';
import 'package:truelearn/features/classes/data/repositories/classes_repository_impl.dart';

class FakeDioAdapter implements HttpClientAdapter {
  ResponseBody? responseToReturn;
  DioException? errorToThrow;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseToReturn ??
        ResponseBody.fromString(
          '{"success":true,"message":"Child live classes retrieved successfully","data":[],"meta":{}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ClassDto Parsing', () {
    test('parses populated class JSON with nested teacher object', () {
      final json = {
        '_id': 'class_123',
        'title': 'Mathematics - Algebra Basics',
        'subject': 'Mathematics',
        'scheduledStartTime': '2026-09-10T10:00:00.000Z',
        'scheduledEndTime': '2026-09-10T11:00:00.000Z',
        'status': 'UPCOMING',
        'teacher': {
          'name': 'Prof. Sharma',
          'avatar': 'https://example.com/avatar.png',
        },
        'meetingUrl': 'https://meet.jit.si/truelearn_room_1',
        'roomName': 'truelearn_room_1',
      };

      final dto = ClassDto.fromJson(json);
      final entity = dto.toEntity();

      expect(entity.id, 'class_123');
      expect(entity.title, 'Mathematics - Algebra Basics');
      expect(entity.subject, 'Mathematics');
      expect(entity.scheduledStartTime, DateTime.parse('2026-09-10T10:00:00.000Z'));
      expect(entity.scheduledEndTime, DateTime.parse('2026-09-10T11:00:00.000Z'));
      expect(entity.status, 'UPCOMING');
      expect(entity.isUpcoming, isTrue);
      expect(entity.isLive, isFalse);
      expect(entity.isCompleted, isFalse);
      expect(entity.teacherName, 'Prof. Sharma');
      expect(entity.teacherAvatar, 'https://example.com/avatar.png');
      expect(entity.meetingUrl, 'https://meet.jit.si/truelearn_room_1');
      expect(entity.roomName, 'truelearn_room_1');
    });

    test('parses teacher with firstName and lastName when name is absent', () {
      final json = {
        '_id': 'class_456',
        'title': 'Science Experiment',
        'teacher': {
          'firstName': 'Anita',
          'lastName': 'Deshmukh',
        },
      };

      final entity = ClassDto.fromJson(json).toEntity();
      expect(entity.teacherName, 'Anita Deshmukh');
    });

    test('parses subject when subject is a nested object', () {
      final json = {
        'id': 'class_789',
        'title': 'English Grammar',
        'subject': {
          'name': 'English Literature',
        },
      };

      final entity = ClassDto.fromJson(json).toEntity();
      expect(entity.id, 'class_789');
      expect(entity.subject, 'English Literature');
    });

    test('handles null and missing optional fields defensively', () {
      final json = <String, dynamic>{
        '_id': 'class_empty',
        'title': 'Placeholder Class',
      };

      final entity = ClassDto.fromJson(json).toEntity();
      expect(entity.id, 'class_empty');
      expect(entity.title, 'Placeholder Class');
      expect(entity.subject, isNull);
      expect(entity.scheduledStartTime, isNull);
      expect(entity.scheduledEndTime, isNull);
      expect(entity.status, isNull);
      expect(entity.teacherName, isNull);
      expect(entity.teacherAvatar, isNull);
      expect(entity.meetingUrl, isNull);
      expect(entity.roomName, isNull);
      expect(entity.isLive, isFalse);
      expect(entity.isUpcoming, isFalse);
      expect(entity.isCompleted, isFalse);
    });

    test('entity equality and hashCode operate on id', () {
      final e1 = ClassDto.fromJson({'_id': 'c1', 'title': 'A'}).toEntity();
      final e2 = ClassDto.fromJson({'_id': 'c1', 'title': 'B'}).toEntity();
      final e3 = ClassDto.fromJson({'_id': 'c2', 'title': 'A'}).toEntity();

      expect(e1 == e2, isTrue);
      expect(e1 == e3, isFalse);
      expect(e1.hashCode, e2.hashCode);
    });
  });

  group('ClassesRepositoryImpl', () {
    late Dio dio;
    late FakeDioAdapter adapter;
    late ApiClient apiClient;
    late ClassesRepositoryImpl repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://truelern.visital.in/api'));
      adapter = FakeDioAdapter();
      dio.httpClientAdapter = adapter;
      apiClient = ApiClient(dio: dio);
      repository = ClassesRepositoryImpl(apiClient: apiClient);
    });

    test('returns empty list when data array is empty (verified production response)', () async {
      adapter.responseToReturn = ResponseBody.fromString(
        '{"success":true,"message":"Child live classes retrieved successfully","data":[],"meta":{}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      final result = await repository.getLiveClasses('6a87e05e9b5f64a15873f66c');
      expect(result, isEmpty);
      expect(result, isA<List>());
    });

    test('returns parsed List<ClassEntity> when data array contains items', () async {
      adapter.responseToReturn = ResponseBody.fromString(
        '''
        {
          "success": true,
          "data": [
            {
              "_id": "6a991100aa",
              "title": "Physics - Optics",
              "subject": "Physics",
              "scheduledStartTime": "2026-09-12T09:00:00.000Z",
              "scheduledEndTime": "2026-09-12T10:00:00.000Z",
              "status": "UPCOMING",
              "teacher": { "name": "Dr. Bose" }
            }
          ]
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      final result = await repository.getLiveClasses('6a87e05e9b5f64a15873f66c');
      expect(result.length, 1);
      expect(result.first.id, '6a991100aa');
      expect(result.first.title, 'Physics - Optics');
      expect(result.first.teacherName, 'Dr. Bose');
      expect(result.first.isUpcoming, isTrue);
    });

    test('returns empty list if data is null or unexpected shape', () async {
      adapter.responseToReturn = ResponseBody.fromString(
        '{"success":true,"data":null}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      final result = await repository.getLiveClasses('some_child_id');
      expect(result, isEmpty);
    });

    test('throws ServerFailure on HTTP 500 error', () async {
      adapter.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/parent/children/123/live-classes'),
        response: Response(
          requestOptions: RequestOptions(path: '/parent/children/123/live-classes'),
          statusCode: 500,
          data: {'message': 'Internal Server Error'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => repository.getLiveClasses('123'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('throws NetworkFailure when connection fails', () async {
      adapter.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/parent/children/123/live-classes'),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );

      expect(
        () => repository.getLiveClasses('123'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('joinLiveClass calls POST /live-classes/{classId}/token and parses verified production payload', () async {
      adapter.responseToReturn = ResponseBody.fromString(
        '''
        {
          "success": true,
          "message": "Classroom access granted",
          "data": {
            "token": "test-jwt-token",
            "roomName": "truelern-6ab0d936aabd606a21c0c72a",
            "jitsiDomain": "livetl.visital.in",
            "serverUrl": "https://livetl.visital.in",
            "isModerator": false,
            "expiresAt": 1726927200,
            "studentId": "child-123",
            "liveClass": {
              "id": "class-456",
              "title": "testing"
            }
          }
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      final result = await repository.joinLiveClass(
        childStudentId: 'child-123',
        classId: 'class-456',
      );

      // Verify exact endpoint called
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastOptions?.path, '/live-classes/class-456/token');
      expect(adapter.lastOptions?.path, isNot(contains('/parent/children')));

      // Verify ClassJoinEntity field mapping
      expect(result.token, 'test-jwt-token');
      expect(result.roomName, 'truelern-6ab0d936aabd606a21c0c72a');
      expect(result.jitsiDomain, 'livetl.visital.in');
      expect(result.serverUrl, 'https://livetl.visital.in');
      expect(result.isModerator, isFalse);
      expect(result.expiresAt, 1726927200);
      expect(result.childId, 'child-123');
      expect(result.classId, 'class-456');
      expect(result.classTitle, 'testing');
    });

    test('joinLiveClass throws AuthFailure on 403 Forbidden error', () async {
      adapter.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/live-classes/class-456/token'),
        response: Response(
          requestOptions: RequestOptions(path: '/live-classes/class-456/token'),
          statusCode: 403,
          data: {'message': 'Access Denied'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => repository.joinLiveClass(childStudentId: 'child-123', classId: 'class-456'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}

