import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_preferences_repository_impl.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import 'notification_preferences_state.dart';

class NotificationPreferencesController
    extends Notifier<NotificationPreferencesState> {
  @override
  NotificationPreferencesState build() =>
      const NotificationPreferencesInitial();

  NotificationPreferencesRepository get _repository =>
      ref.read(notificationPreferencesRepositoryProvider);

  /// Resets state on logout or account switching.
  void reset() {
    state = const NotificationPreferencesInitial();
  }

  Future<void> loadPreferences({bool refresh = false}) async {
    final current = state;
    if (current is NotificationPreferencesLoading) return;
    if (!refresh && current is NotificationPreferencesLoaded) return;

    state = const NotificationPreferencesLoading();
    try {
      final prefs = await _repository.getPreferences();
      state = NotificationPreferencesLoaded(preferences: prefs);
    } catch (e) {
      state = NotificationPreferencesError(message: e.toString());
    }
  }

  Future<void> updateChannelPreference({
    bool? email,
    bool? sms,
    bool? whatsapp,
    bool? push,
  }) async {
    final currentState = state;
    if (currentState is! NotificationPreferencesLoaded) return;

    final updated = currentState.preferences.copyWith(
      emailEnabled: email ?? currentState.preferences.emailEnabled,
      smsEnabled: sms ?? currentState.preferences.smsEnabled,
      whatsappEnabled: whatsapp ?? currentState.preferences.whatsappEnabled,
      pushEnabled: push ?? currentState.preferences.pushEnabled,
    );

    // Optimistically update
    state = currentState.copyWith(preferences: updated, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updated);
      state = NotificationPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Preferences updated',
      );
    } catch (e) {
      state = currentState.copyWith(
        isUpdating: false,
        feedbackMessage: 'Failed to update preferences',
        isError: true,
      );
    }
  }

  Future<void> updateEventPreference({
    bool? assignment,
    bool? attendance,
    bool? reports,
    bool? admissions,
    bool? enrollment,
  }) async {
    final currentState = state;
    if (currentState is! NotificationPreferencesLoaded) return;

    final updated = currentState.preferences.copyWith(
      assignmentAlerts: assignment ?? currentState.preferences.assignmentAlerts,
      attendanceAlerts: attendance ?? currentState.preferences.attendanceAlerts,
      reportsAlerts: reports ?? currentState.preferences.reportsAlerts,
      admissionsAlerts: admissions ?? currentState.preferences.admissionsAlerts,
      enrollmentAlerts: enrollment ?? currentState.preferences.enrollmentAlerts,
    );

    state = currentState.copyWith(preferences: updated, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updated);
      state = NotificationPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Preferences updated',
      );
    } catch (e) {
      state = currentState.copyWith(
        isUpdating: false,
        feedbackMessage: 'Failed to update preferences',
        isError: true,
      );
    }
  }

  void clearFeedback() {
    final currentState = state;
    if (currentState is NotificationPreferencesLoaded) {
      state = currentState.copyWith(feedbackMessage: null, isError: false);
    }
  }
}

final notificationPreferencesControllerProvider =
    NotifierProvider<
      NotificationPreferencesController,
      NotificationPreferencesState
    >(NotificationPreferencesController.new);
