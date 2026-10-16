import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/parent_preferences_repository_impl.dart';
import '../../domain/repositories/parent_preferences_repository.dart';
import 'parent_preferences_state.dart';

class ParentPreferencesController extends Notifier<ParentPreferencesState> {
  @override
  ParentPreferencesState build() => const ParentPreferencesInitial();

  ParentPreferencesRepository get _repository =>
      ref.read(parentPreferencesRepositoryProvider);

  /// Resets state on logout or account switching.
  void reset() {
    state = const ParentPreferencesInitial();
  }

  Future<void> loadPreferences({bool refresh = false}) async {
    final current = state;
    if (current is ParentPreferencesLoading) return;
    if (!refresh && current is ParentPreferencesLoaded) return;

    state = const ParentPreferencesLoading();
    try {
      final prefs = await _repository.getPreferences();
      state = ParentPreferencesLoaded(preferences: prefs);
    } catch (e) {
      state = ParentPreferencesError(message: e.toString());
    }
  }

  Future<void> updateChannelPreference({
    bool? email,
    bool? sms,
    bool? whatsapp,
    bool? push,
    bool? inApp,
  }) async {
    final currentState = state;
    if (currentState is! ParentPreferencesLoaded) return;

    final oldPrefs = currentState.preferences;
    final updatedChannels = Map<String, bool>.from(oldPrefs.channelPreferences);
    if (email != null) updatedChannels['email'] = email;
    if (sms != null) updatedChannels['sms'] = sms;
    if (whatsapp != null) updatedChannels['whatsapp'] = whatsapp;
    if (push != null) updatedChannels['push'] = push;
    if (inApp != null) updatedChannels['in-app'] = inApp;

    final updatedPrefs = oldPrefs.copyWith(channelPreferences: updatedChannels);

    // Optimistic update
    state = currentState.copyWith(preferences: updatedPrefs, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updatedPrefs);
      state = ParentPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Channel preferences updated',
      );
    } catch (e) {
      // Rollback on failure
      state = ParentPreferencesLoaded(
        preferences: oldPrefs,
        isUpdating: false,
        feedbackMessage: 'Failed to update channel preference',
        isError: true,
      );
    }
  }

  Future<void> updateEventPreference({
    bool? attendance,
    bool? assignment,
    bool? reports,
    bool? admissions,
    bool? assessment,
    bool? certificate,
    bool? finance,
  }) async {
    final currentState = state;
    if (currentState is! ParentPreferencesLoaded) return;

    final oldPrefs = currentState.preferences;
    final updatedEvents = Map<String, bool>.from(oldPrefs.eventPreferences);
    if (attendance != null) updatedEvents['attendance'] = attendance;
    if (assignment != null) updatedEvents['assignment'] = assignment;
    if (reports != null) updatedEvents['reports'] = reports;
    if (admissions != null) updatedEvents['admissions'] = admissions;
    if (assessment != null) updatedEvents['assessment'] = assessment;
    if (certificate != null) updatedEvents['certificate'] = certificate;
    if (finance != null) updatedEvents['finance'] = finance;

    final updatedPrefs = oldPrefs.copyWith(eventPreferences: updatedEvents);

    state = currentState.copyWith(preferences: updatedPrefs, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updatedPrefs);
      state = ParentPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Notification preferences updated',
      );
    } catch (e) {
      state = ParentPreferencesLoaded(
        preferences: oldPrefs,
        isUpdating: false,
        feedbackMessage: 'Failed to update notification preference',
        isError: true,
      );
    }
  }

  Future<void> updateMuteAll(bool muteAll) async {
    final currentState = state;
    if (currentState is! ParentPreferencesLoaded) return;

    final oldPrefs = currentState.preferences;
    final updatedPrefs = oldPrefs.copyWith(muteAll: muteAll);

    state = currentState.copyWith(preferences: updatedPrefs, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updatedPrefs);
      state = ParentPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: muteAll
            ? 'All notifications muted'
            : 'Notifications unmuted',
      );
    } catch (e) {
      state = ParentPreferencesLoaded(
        preferences: oldPrefs,
        isUpdating: false,
        feedbackMessage: 'Failed to update mute settings',
        isError: true,
      );
    }
  }

  Future<void> updateDigestEnabled(bool digestEnabled) async {
    final currentState = state;
    if (currentState is! ParentPreferencesLoaded) return;

    final oldPrefs = currentState.preferences;
    final updatedPrefs = oldPrefs.copyWith(digestEnabled: digestEnabled);

    state = currentState.copyWith(preferences: updatedPrefs, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updatedPrefs);
      state = ParentPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Daily digest preference updated',
      );
    } catch (e) {
      state = ParentPreferencesLoaded(
        preferences: oldPrefs,
        isUpdating: false,
        feedbackMessage: 'Failed to update digest preference',
        isError: true,
      );
    }
  }

  Future<void> updateAttendanceSharing(bool enabled) async {
    await updateEventPreference(attendance: enabled);
  }

  Future<void> updateLearningProgressSharing(bool enabled) async {
    await updateEventPreference(reports: enabled);
  }

  void clearFeedback() {
    final currentState = state;
    if (currentState is ParentPreferencesLoaded) {
      state = currentState.copyWith(feedbackMessage: null, isError: false);
    }
  }
}

final parentPreferencesControllerProvider =
    NotifierProvider<ParentPreferencesController, ParentPreferencesState>(
      ParentPreferencesController.new,
    );
