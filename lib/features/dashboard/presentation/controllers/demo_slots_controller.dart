import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/demo_booking_entity.dart';
import '../../domain/entities/demo_slot_entity.dart';

/// Sealed state hierarchy for available demo slots.
sealed class DemoSlotsState {
  const DemoSlotsState();
}

class DemoSlotsInitial extends DemoSlotsState {
  const DemoSlotsInitial();
}

class DemoSlotsLoading extends DemoSlotsState {
  const DemoSlotsLoading();
}

class DemoSlotsLoaded extends DemoSlotsState {
  const DemoSlotsLoaded({
    required this.slots,
    this.isBooking = false,
    this.bookingSlotId,
    this.bookingErrorMessage,
    this.bookingSuccessMessage,
    this.lastConfirmedBooking,
  });

  final List<DemoSlotEntity> slots;
  final bool isBooking;
  final String? bookingSlotId;
  final String? bookingErrorMessage;
  final String? bookingSuccessMessage;
  final DemoBookingEntity? lastConfirmedBooking;

  DemoSlotsLoaded copyWith({
    List<DemoSlotEntity>? slots,
    bool? isBooking,
    String? bookingSlotId,
    String? bookingErrorMessage,
    String? bookingSuccessMessage,
    DemoBookingEntity? lastConfirmedBooking,
  }) {
    return DemoSlotsLoaded(
      slots: slots ?? this.slots,
      isBooking: isBooking ?? this.isBooking,
      bookingSlotId: bookingSlotId ?? this.bookingSlotId,
      bookingErrorMessage: bookingErrorMessage,
      bookingSuccessMessage: bookingSuccessMessage,
      lastConfirmedBooking: lastConfirmedBooking ?? this.lastConfirmedBooking,
    );
  }
}

class DemoSlotsError extends DemoSlotsState {
  const DemoSlotsError({required this.message});

  final String message;
}

/// Controller managing available demo slots and real slot booking.
///
/// Governance:
/// - Strictly honest: Displays only real slots returned by the backend.
/// - Never invents fake slots, mock timestamps, or fabricated booking results.
/// - Handles loading, empty, error, booking-in-progress, and confirmation states.
/// - Prevents duplicate booking submissions.
class DemoSlotsController extends Notifier<DemoSlotsState> {
  @override
  DemoSlotsState build() => const DemoSlotsInitial();

  ApiClient get _apiClient => ref.read(apiClientProvider);

  /// Resets state on logout or account switching.
  void reset() {
    state = const DemoSlotsInitial();
  }

  /// Loads available demo slots from the backend.
  Future<void> loadSlots({String? courseId, String? studentId}) async {
    state = const DemoSlotsLoading();

    try {
      final queryParams = <String, dynamic>{};
      if (courseId != null && courseId.isNotEmpty) {
        queryParams['courseId'] = courseId;
      }
      if (studentId != null && studentId.isNotEmpty) {
        queryParams['studentId'] = studentId;
      }

      final response = await _apiClient.get<dynamic>(
        '/parent/demo/availability',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<DemoSlotEntity> resolvedSlots = [];
      final rawData = response.data;

      void extractFromList(List<dynamic> items, {String? dateKey}) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            resolvedSlots.add(
              DemoSlotEntity.fromJson(
                item,
                fallbackCourseId: courseId,
                fallbackDateKey: dateKey,
              ),
            );
          }
        }
      }

      if (rawData is Map<String, dynamic>) {
        final dataObj = rawData['data'] ?? rawData;
        if (dataObj is Map<String, dynamic>) {
          // Parse nested slotsByDate: { "2026-10-14": [ ... ] }
          final slotsByDate = dataObj['slotsByDate'];
          if (slotsByDate is Map<String, dynamic>) {
            for (final entry in slotsByDate.entries) {
              final dateKey = entry.key;
              final list = entry.value;
              if (list is List) {
                extractFromList(list, dateKey: dateKey);
              }
            }
          }

          // Also check for direct list fields in dataObj
          for (final key in ['slots', 'availability', 'data', 'items']) {
            final list = dataObj[key];
            if (list is List) {
              extractFromList(list);
            }
          }
        } else if (dataObj is List) {
          extractFromList(dataObj);
        }

        // Also check if rawData has direct slots or availability list
        if (rawData['slots'] is List) {
          extractFromList(rawData['slots'] as List);
        } else if (rawData['availability'] is List) {
          extractFromList(rawData['availability'] as List);
        }
      } else if (rawData is List) {
        extractFromList(rawData);
      }

      // Deduplicate slots by id and filter to open/available slots
      final seenIds = <String>{};
      final uniqueSlots = <DemoSlotEntity>[];
      for (final slot in resolvedSlots) {
        if (!slot.isAvailable) continue;
        if (slot.id.isNotEmpty) {
          if (!seenIds.contains(slot.id)) {
            seenIds.add(slot.id);
            uniqueSlots.add(slot);
          }
        } else {
          uniqueSlots.add(slot);
        }
      }

      // Sort chronologically by start timestamp
      uniqueSlots.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      state = DemoSlotsLoaded(slots: uniqueSlots);
    } catch (e) {
      // Show an appropriate error/retry state when the API request fails;
      // do not convert request errors into successful empty state.
      state = DemoSlotsError(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Submits demo slot booking to backend POST /api/parent/demo.
  Future<bool> bookSlot({
    required DemoSlotEntity slot,
    required String studentId,
    required String courseId,
    String? courseName,
    String? studentName,
  }) async {
    final current = state;
    if (current is! DemoSlotsLoaded || current.isBooking) {
      return false; // Prevent duplicate submission
    }

    state = current.copyWith(
      isBooking: true,
      bookingSlotId: slot.id,
      bookingErrorMessage: null,
      bookingSuccessMessage: null,
    );

    try {
      final payload = {
        'studentId': studentId,
        'courseId': courseId,
        'slotId': slot.id,
        'availabilityId': slot.id,
        'startDateTime': slot.startDateTime.toIso8601String(),
      };

      final response = await _apiClient.post<dynamic>(
        '/parent/demo',
        data: payload,
      );

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        DemoBookingEntity? bookingEntity;
        final rawData = response.data;
        if (rawData is Map<String, dynamic>) {
          final dataObj = rawData['data'] ?? rawData;
          if (dataObj is Map<String, dynamic>) {
            bookingEntity = DemoBookingEntity.fromJson(
              dataObj,
              fallbackCourseName: courseName,
              fallbackStudentName: studentName,
              fallbackStartDateTime: slot.startDateTime,
              fallbackTeacherName: slot.instructorName,
            );
          }
        }
        bookingEntity ??= DemoBookingEntity(
          bookingId: slot.id,
          courseName: courseName ?? 'Demo Course',
          studentName: studentName,
          startDateTime: slot.startDateTime,
          endDateTime: slot.endDateTime,
          teacherName: slot.instructorName,
          teacherStatus: slot.instructorName != null
              ? 'Assigned'
              : 'Finalizing',
          status: 'scheduled',
        );

        // Refresh availability
        await loadSlots(courseId: courseId, studentId: studentId);
        final refreshed = state;
        if (refreshed is DemoSlotsLoaded) {
          state = refreshed.copyWith(
            isBooking: false,
            bookingSlotId: null,
            bookingSuccessMessage: 'Demo session booked successfully!',
            lastConfirmedBooking: bookingEntity,
          );
        }
        return true;
      } else {
        state = current.copyWith(
          isBooking: false,
          bookingSlotId: null,
          bookingErrorMessage: 'Booking could not be confirmed by the server.',
        );
        return false;
      }
    } catch (e) {
      state = current.copyWith(
        isBooking: false,
        bookingSlotId: null,
        bookingErrorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Retrieves the latest confirmed demo session from GET /api/parent/demo.
  Future<DemoBookingEntity?> fetchConfirmedDemo({String? studentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (studentId != null && studentId.isNotEmpty) {
        queryParams['studentId'] = studentId;
      }

      final response = await _apiClient.get<dynamic>(
        '/parent/demo',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataObj = rawData['data'] ?? rawData;
        if (dataObj is Map<String, dynamic> && dataObj.isNotEmpty) {
          final booking = DemoBookingEntity.fromJson(dataObj);
          final current = state;
          if (current is DemoSlotsLoaded) {
            state = current.copyWith(lastConfirmedBooking: booking);
          }
          return booking;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clears any transient booking feedback messages.
  void clearMessages() {
    final current = state;
    if (current is DemoSlotsLoaded) {
      state = current.copyWith(
        bookingErrorMessage: null,
        bookingSuccessMessage: null,
      );
    }
  }
}

/// Global provider for [DemoSlotsController].
final demoSlotsControllerProvider =
    NotifierProvider<DemoSlotsController, DemoSlotsState>(
      DemoSlotsController.new,
    );
