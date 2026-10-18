import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../domain/entities/child_entity.dart';
import '../../domain/entities/demo_booking_entity.dart';
import 'children_controller.dart';
import 'children_state.dart';

/// Sealed state hierarchy representing the demo application and booking status
/// of a specific child under the authenticated parent account.
sealed class ChildDemoStatusState {
  const ChildDemoStatusState();
}

/// Initial state before child status resolution.
class ChildDemoInitial extends ChildDemoStatusState {
  const ChildDemoInitial();
}

/// Asynchronous status query in progress.
class ChildDemoLoading extends ChildDemoStatusState {
  const ChildDemoLoading({required this.studentId});
  final String studentId;
}

/// State 1: No demo application exists for the active child.
class ChildDemoNone extends ChildDemoStatusState {
  const ChildDemoNone({required this.studentId});
  final String studentId;
}

/// State 2: Demo application submitted but awaiting counselor scheduling/confirmation.
class ChildDemoPendingConfirmation extends ChildDemoStatusState {
  const ChildDemoPendingConfirmation({
    required this.studentId,
    this.leadId,
    this.courseName,
  });
  final String studentId;
  final String? leadId;
  final String? courseName;
}

/// State 4: Demo scheduled, but the 15-minute early entry window has not opened yet.
class ChildDemoScheduledTooEarly extends ChildDemoStatusState {
  const ChildDemoScheduledTooEarly({
    required this.studentId,
    required this.booking,
  });
  final String studentId;
  final DemoBookingEntity booking;
}

/// State 5: Demo eligible for joining (within 15m of start time or currently live).
class ChildDemoEligibleToJoin extends ChildDemoStatusState {
  const ChildDemoEligibleToJoin({
    required this.studentId,
    required this.booking,
  });
  final String studentId;
  final DemoBookingEntity booking;
}

/// State 6: Demo cancelled, expired, or completed.
class ChildDemoTerminal extends ChildDemoStatusState {
  const ChildDemoTerminal({
    required this.studentId,
    required this.booking,
    required this.isCancelled,
    required this.isExpired,
  });
  final String studentId;
  final DemoBookingEntity booking;
  final bool isCancelled;
  final bool isExpired;
}

/// State 7: Status could not be loaded because of a network or API error.
class ChildDemoError extends ChildDemoStatusState {
  const ChildDemoError({
    required this.studentId,
    required this.message,
  });
  final String studentId;
  final String message;
}

/// Extension methods for quick state discrimination in UI components.
extension ChildDemoStatusStateX on ChildDemoStatusState {
  /// Whether the 'Apply for Demo Class' floating action button should be visible.
  /// Strictly true ONLY when child has no demo application (ChildDemoNone),
  /// and false during loading, error, or when an application exists.
  bool get shouldShowApplyFab => this is ChildDemoNone;

  /// Whether a demo application or booking exists for this child.
  bool get hasDemoApplicationOrBooking =>
      this is ChildDemoPendingConfirmation ||
      this is ChildDemoScheduledTooEarly ||
      this is ChildDemoEligibleToJoin ||
      this is ChildDemoTerminal;

  /// The active demo booking if scheduled.
  DemoBookingEntity? get booking {
    final self = this;
    if (self is ChildDemoScheduledTooEarly) return self.booking;
    if (self is ChildDemoEligibleToJoin) return self.booking;
    if (self is ChildDemoTerminal) return self.booking;
    return null;
  }

  /// Current student ID associated with this status, if resolved.
  String? get studentId {
    final self = this;
    if (self is ChildDemoLoading) return self.studentId;
    if (self is ChildDemoNone) return self.studentId;
    if (self is ChildDemoPendingConfirmation) return self.studentId;
    if (self is ChildDemoScheduledTooEarly) return self.studentId;
    if (self is ChildDemoEligibleToJoin) return self.studentId;
    if (self is ChildDemoTerminal) return self.studentId;
    if (self is ChildDemoError) return self.studentId;
    return null;
  }
}

/// Controller responsible for resolving the demo status of the currently active child.
class ChildDemoStatusController extends Notifier<ChildDemoStatusState> {
  @override
  ChildDemoStatusState build() => const ChildDemoInitial();

  ApiClient get _apiClient => ref.read(apiClientProvider);

  int _currentToken = 0;

  /// Resets state on logout or account change.
  void reset() {
    _currentToken++;
    state = const ChildDemoInitial();
  }

  /// Manually set the status (useful for unit testing and direct UI updates).
  void setStatusForTesting(ChildDemoStatusState newState) {
    state = newState;
  }

  /// Resolves the demo status for the provided child studentId.
  Future<void> resolveStatusForChild({
    required String studentId,
    bool forceRefresh = false,
  }) async {
    if (studentId.isEmpty) {
      state = const ChildDemoInitial();
      return;
    }

    final token = ++_currentToken;

    // Avoid redundant loading state if already resolving for this child and not forcing refresh
    if (!forceRefresh && state is ChildDemoLoading && state.studentId == studentId) {
      return;
    }

    state = ChildDemoLoading(studentId: studentId);

    try {
      final response = await _apiClient.get<dynamic>(
        '/parent/demo',
        queryParameters: {'studentId': studentId},
      );

      if (token != _currentToken) return;

      DemoBookingEntity? booking;
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataObj = rawData['data'] ?? rawData;
        if (dataObj is Map<String, dynamic> && dataObj.isNotEmpty) {
          booking = DemoBookingEntity.fromJson(dataObj);
        }
      }

      // Authoritative verification against linked children
      final childrenState = ref.read(childrenControllerProvider);
      final linkedChildren = childrenState is ChildrenLoaded
          ? childrenState.children
          : <ChildEntity>[];

      ChildEntity? currentChild;
      if (childrenState is ChildrenLoaded) {
        for (final child in childrenState.children) {
          if (child.studentId == studentId) {
            currentChild = child;
            break;
          }
        }
      }

      if (booking != null) {
        final authoritativeChild = resolveAuthoritativeStudent(
          booking: booking,
          linkedChildren: linkedChildren,
        );

        // If authoritative child does not match the requested child, ignore mismatched booking
        if (authoritativeChild != null && authoritativeChild.studentId != studentId) {
          booking = null;
        }
      }

      if (booking != null) {
        final now = DateTime.now();
        final s = booking.status.trim().toLowerCase();

        if (s == 'cancelled' || s == 'canceled' || s == 'completed' || booking.isExpired(now)) {
          state = ChildDemoTerminal(
            studentId: studentId,
            booking: booking,
            isCancelled: s == 'cancelled' || s == 'canceled',
            isExpired: booking.isExpired(now),
          );
        } else if (s == 'pending' ||
            s == 'requested' ||
            s == 'submitted' ||
            s == 'awaiting_confirmation') {
          state = ChildDemoPendingConfirmation(
            studentId: studentId,
            leadId: booking.bookingId,
            courseName: booking.courseName,
          );
        } else if (booking.canEnterDemoClass(now)) {
          state = ChildDemoEligibleToJoin(
            studentId: studentId,
            booking: booking,
          );
        } else if (booking.isTooEarly(now)) {
          state = ChildDemoScheduledTooEarly(
            studentId: studentId,
            booking: booking,
          );
        } else {
          state = ChildDemoTerminal(
            studentId: studentId,
            booking: booking,
            isCancelled: false,
            isExpired: true,
          );
        }
        return;
      }

      // No scheduled booking returned. Check if an application has been submitted for this child
      final onboardingState = ref.read(onboardingControllerProvider);
      final childMatchesOnboarding = onboardingState.isSubmitted &&
          (onboardingState.childName.trim().isEmpty ||
              (currentChild != null &&
                  (onboardingState.childName.trim().toLowerCase() ==
                          currentChild.displayName.trim().toLowerCase() ||
                      onboardingState.childName.trim().toLowerCase() ==
                          currentChild.firstName.trim().toLowerCase())));

      if (childMatchesOnboarding) {
        state = ChildDemoPendingConfirmation(
          studentId: studentId,
          leadId: onboardingState.submissionLeadId,
          courseName: onboardingState.effectiveCourseName,
        );
      } else {
        state = ChildDemoNone(studentId: studentId);
      }
    } catch (e) {
      if (token != _currentToken) return;

      final errorStr = e.toString().toLowerCase();
      // If 404 "not found" or "no demo found", treat as no booking rather than system failure
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        final onboardingState = ref.read(onboardingControllerProvider);
        if (onboardingState.isSubmitted) {
          state = ChildDemoPendingConfirmation(
            studentId: studentId,
            leadId: onboardingState.submissionLeadId,
            courseName: onboardingState.effectiveCourseName,
          );
        } else {
          state = ChildDemoNone(studentId: studentId);
        }
      } else {
        // True network or API failure
        state = ChildDemoError(
          studentId: studentId,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

/// Global provider for [ChildDemoStatusController].
final childDemoStatusControllerProvider =
    NotifierProvider<ChildDemoStatusController, ChildDemoStatusState>(
      ChildDemoStatusController.new,
    );
