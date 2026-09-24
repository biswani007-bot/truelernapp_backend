import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/parent_preferences_repository_impl.dart';
import '../../domain/repositories/parent_preferences_repository.dart';
import 'parent_preferences_state.dart';

class ParentPreferencesController extends Notifier<ParentPreferencesState> {
  @override
  ParentPreferencesState build() => const ParentPreferencesInitial();

  ParentPreferencesRepository get _repository => ref.read(parentPreferencesRepositoryProvider);

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

  Future<void> updateAttendanceSharing(bool enabled) async {
    final currentState = state;
    if (currentState is! ParentPreferencesLoaded) return;

    final oldPrefs = currentState.preferences;
    final updatedEvents = Map<String, bool>.from(oldPrefs.eventPreferences);
    updatedEvents['attendance'] = enabled;

    final updatedPrefs = oldPrefs.copyWith(eventPreferences: updatedEvents);

    // Optimistic update
    state = currentState.copyWith(preferences: updatedPrefs, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updatedPrefs);
      state = ParentPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Attendance sharing updated',
      );
    } catch (e) {
      // Rollback on failure
      state = ParentPreferencesLoaded(
        preferences: oldPrefs,
        isUpdating: false,
        feedbackMessage: 'Failed to update attendance preference',
        isError: true,
      );
    }
  }

  Future<void> updateLearningProgressSharing(bool enabled) async {
    final currentState = state;
    if (currentState is! ParentPreferencesLoaded) return;

    final oldPrefs = currentState.preferences;
    final updatedEvents = Map<String, bool>.from(oldPrefs.eventPreferences);
    updatedEvents['reports'] = enabled;

    final updatedPrefs = oldPrefs.copyWith(eventPreferences: updatedEvents);

    // Optimistic update
    state = currentState.copyWith(preferences: updatedPrefs, isUpdating: true);
    try {
      final saved = await _repository.updatePreferences(updatedPrefs);
      state = ParentPreferencesLoaded(
        preferences: saved,
        isUpdating: false,
        feedbackMessage: 'Learning progress sharing updated',
      );
    } catch (e) {
      // Rollback on failure
      state = ParentPreferencesLoaded(
        preferences: oldPrefs,
        isUpdating: false,
        feedbackMessage: 'Failed to update learning progress preference',
        isError: true,
      );
    }
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
