import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/domain/entities/demo_slot_entity.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/demo_slots_controller.dart';

class _MockDioAdapter implements HttpClientAdapter {
  _MockDioAdapter({required this.handler});

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DemoSlotsController Unit Tests', () {
    test('initial state is DemoSlotsInitial', () {
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: Dio()))],
      );
      addTearDown(container.dispose);

      final state = container.read(demoSlotsControllerProvider);
      expect(state, isA<DemoSlotsInitial>());
    });

    test('loadSlots transitions to DemoSlotsLoaded with parsed slots on 200 response', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          if (options.path.contains('/parent/demo/availability')) {
            return ResponseBody.fromString(
              '{"success": true, "data": [{"id": "slot-1", "courseId": "c1", "startDateTime": "2026-10-15T10:00:00Z", "endDateTime": "2026-10-15T10:45:00Z", "instructorName": "Dr. Smith", "dayLabel": "TODAY"}]}',
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('Not Found', 404);
        },
      );

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoSlotsControllerProvider.notifier);
      await notifier.loadSlots();

      final state = container.read(demoSlotsControllerProvider);
      expect(state, isA<DemoSlotsLoaded>());
      final loaded = state as DemoSlotsLoaded;
      expect(loaded.slots.length, 1);
      expect(loaded.slots.first.id, 'slot-1');
      expect(loaded.slots.first.instructorName, 'Dr. Smith');
    });

    test(
      'loadSlots handles 404 or API failure honestly by setting DemoSlotsError',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockDioAdapter(
          handler: (options) async {
            return ResponseBody.fromString(
              '{"message": "Endpoint not found"}',
              404,
            );
          },
        );

        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
        );
        addTearDown(container.dispose);

        final notifier = container.read(demoSlotsControllerProvider.notifier);
        await notifier.loadSlots();

        final state = container.read(demoSlotsControllerProvider);
        expect(state, isA<DemoSlotsError>());
        final error = state as DemoSlotsError;
        expect(error.message, isNotEmpty);
      },
    );

    test('loadSlots transitions to DemoSlotsLoaded with empty slots on 200 response with empty data', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          return ResponseBody.fromString(
            '{"success": true, "data": {"dates": [], "slotsByDate": {}}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoSlotsControllerProvider.notifier);
      await notifier.loadSlots();

      final state = container.read(demoSlotsControllerProvider);
      expect(state, isA<DemoSlotsLoaded>());
      final loaded = state as DemoSlotsLoaded;
      expect(loaded.slots, isEmpty);
    });

    test('loadSlots parses real backend slotsByDate envelope', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          return ResponseBody.fromString(
            '{"success": true, "data": {"dates": ["2026-10-14"], "slotsByDate": {"2026-10-14": [{"id": "slot-real", "scheduledStart": "2026-10-14T11:20:00.000Z", "timeString": "4:50 PM", "duration": 15}]}}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoSlotsControllerProvider.notifier);
      await notifier.loadSlots(courseId: 'c1');

      final state = container.read(demoSlotsControllerProvider);
      expect(state, isA<DemoSlotsLoaded>());
      final loaded = state as DemoSlotsLoaded;
      expect(loaded.slots.length, 1);
      final slot = loaded.slots.first;
      expect(slot.id, 'slot-real');
      expect(slot.formattedTime, '4:50');
      expect(slot.period, 'PM');
      expect(slot.duration, 15);
      expect(slot.courseId, 'c1');
    });

    test('bookSlot succeeds with 200/201 and sets success message', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          if (options.path.contains('/parent/demo/availability')) {
            return ResponseBody.fromString('{"data": []}', 200);
          }
          if (options.path.contains('/parent/demo') &&
              options.method == 'POST') {
            return ResponseBody.fromString(
              '{"success": true, "message": "Demo booked"}',
              201,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('Not Found', 404);
        },
      );

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoSlotsControllerProvider.notifier);
      await notifier.loadSlots(); // establishes DemoSlotsLoaded state

      final slot = DemoSlotEntity(
        id: 'slot-123',
        courseId: 'course-1',
        startDateTime: DateTime(2026, 10, 15, 14, 0),
        endDateTime: DateTime(2026, 10, 15, 14, 45),
      );

      final result = await notifier.bookSlot(
        slot: slot,
        studentId: 'student-999',
        courseId: 'course-1',
      );

      expect(result, isTrue);
      final state =
          container.read(demoSlotsControllerProvider) as DemoSlotsLoaded;
      expect(state.bookingSuccessMessage, contains('booked successfully'));
    });

    test(
      'bookSlot prevents duplicate submissions while booking is in progress',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockDioAdapter(
          handler: (options) async {
            if (options.path.contains('/parent/demo/availability')) {
              return ResponseBody.fromString('{"data": []}', 200);
            }
            if (options.path.contains('/parent/demo')) {
              // Simulate network delay
              await Future<void>.delayed(const Duration(milliseconds: 100));
              return ResponseBody.fromString('{"success": true}', 200);
            }
            return ResponseBody.fromString('Not Found', 404);
          },
        );

        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
        );
        addTearDown(container.dispose);

        final notifier = container.read(demoSlotsControllerProvider.notifier);
        await notifier.loadSlots();

        final slot = DemoSlotEntity(
          id: 'slot-123',
          courseId: 'course-1',
          startDateTime: DateTime(2026, 10, 15, 14, 0),
          endDateTime: DateTime(2026, 10, 15, 14, 45),
        );

        // Trigger first booking
        final firstFuture = notifier.bookSlot(
          slot: slot,
          studentId: 'student-999',
          courseId: 'course-1',
        );

        // Trigger concurrent second booking immediately
        final secondResult = await notifier.bookSlot(
          slot: slot,
          studentId: 'student-999',
          courseId: 'course-1',
        );

        expect(secondResult, isFalse); // Duplicate rejected immediately
        final firstResult = await firstFuture;
        expect(firstResult, isTrue);
      },
    );

    test(
      'fetchConfirmedDemo retrieves verified booking from GET /api/parent/demo',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockDioAdapter(
          handler: (options) async {
            if (options.path.contains('/parent/demo') &&
                options.method == 'GET') {
              return ResponseBody.fromString(
                '''
              {
                "success": true,
                "data": {
                  "demoId": "demo-retrieved-1",
                  "demoCode": "DEMO-991122",
                  "interestedCourse": "Creative Writing",
                  "scheduledStart": "2026-10-25T15:00:00.000Z",
                  "scheduledEnd": "2026-10-25T15:45:00.000Z",
                  "status": "scheduled",
                  "teacher": {
                    "id": "t1",
                    "name": "Prof. Smith"
                  },
                  "teacherStatus": "Assigned"
                }
              }
              ''',
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            return ResponseBody.fromString('Not Found', 404);
          },
        );

        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
        );
        addTearDown(container.dispose);

        final notifier = container.read(demoSlotsControllerProvider.notifier);
        final booking = await notifier.fetchConfirmedDemo(
          studentId: 'student-999',
        );

        expect(booking, isNotNull);
        expect(booking!.bookingId, 'demo-retrieved-1');
        expect(booking.demoCode, 'DEMO-991122');
        expect(booking.courseName, 'Creative Writing');
        expect(booking.teacherName, 'Prof. Smith');
        expect(booking.teacherStatus, 'Assigned');
      },
    );
  });
}
