import '../../domain/entities/notification_preferences_entity.dart';

sealed class NotificationPreferencesState {
  const NotificationPreferencesState();
}

final class NotificationPreferencesInitial extends NotificationPreferencesState {
  const NotificationPreferencesInitial();
}

final class NotificationPreferencesLoading extends NotificationPreferencesState {
  const NotificationPreferencesLoading();
}

final class NotificationPreferencesLoaded extends NotificationPreferencesState {
  const NotificationPreferencesLoaded({
    required this.preferences,
    this.isUpdating = false,
    this.feedbackMessage,
    this.isError = false,
  });

  final NotificationPreferencesEntity preferences;
  final bool isUpdating;
  final String? feedbackMessage;
  final bool isError;

  NotificationPreferencesLoaded copyWith({
    NotificationPreferencesEntity? preferences,
    bool? isUpdating,
    String? feedbackMessage,
    bool? isError,
  }) {
    return NotificationPreferencesLoaded(
      preferences: preferences ?? this.preferences,
      isUpdating: isUpdating ?? this.isUpdating,
      feedbackMessage: feedbackMessage,
      isError: isError ?? this.isError,
    );
  }
}

final class NotificationPreferencesError extends NotificationPreferencesState {
  const NotificationPreferencesError({required this.message});

  final String message;
}
