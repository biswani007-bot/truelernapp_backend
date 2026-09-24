import '../../domain/entities/parent_preferences_entity.dart';

abstract class ParentPreferencesState {
  const ParentPreferencesState();
}

class ParentPreferencesInitial extends ParentPreferencesState {
  const ParentPreferencesInitial();
}

class ParentPreferencesLoading extends ParentPreferencesState {
  const ParentPreferencesLoading();
}

class ParentPreferencesLoaded extends ParentPreferencesState {
  final ParentPreferencesEntity preferences;
  final bool isUpdating;
  final String? feedbackMessage;
  final bool isError;

  const ParentPreferencesLoaded({
    required this.preferences,
    this.isUpdating = false,
    this.feedbackMessage,
    this.isError = false,
  });

  ParentPreferencesLoaded copyWith({
    ParentPreferencesEntity? preferences,
    bool? isUpdating,
    String? feedbackMessage,
    bool? isError,
  }) {
    return ParentPreferencesLoaded(
      preferences: preferences ?? this.preferences,
      isUpdating: isUpdating ?? this.isUpdating,
      feedbackMessage: feedbackMessage,
      isError: isError ?? this.isError,
    );
  }
}

class ParentPreferencesError extends ParentPreferencesState {
  final String message;

  const ParentPreferencesError({required this.message});
}
