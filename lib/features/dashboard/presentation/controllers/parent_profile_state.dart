import '../../domain/entities/parent_profile_entity.dart';

sealed class ParentProfileState {
  const ParentProfileState();
}

final class ParentProfileInitial extends ParentProfileState {
  const ParentProfileInitial();
}

final class ParentProfileLoading extends ParentProfileState {
  const ParentProfileLoading();
}

final class ParentProfileLoaded extends ParentProfileState {
  const ParentProfileLoaded({
    required this.profile,
    this.isUpdating = false,
    this.updateSuccessMessage,
    this.updateErrorMessage,
  });

  final ParentProfileEntity profile;
  final bool isUpdating;
  final String? updateSuccessMessage;
  final String? updateErrorMessage;

  ParentProfileLoaded copyWith({
    ParentProfileEntity? profile,
    bool? isUpdating,
    String? updateSuccessMessage,
    String? updateErrorMessage,
  }) {
    return ParentProfileLoaded(
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
      updateSuccessMessage: updateSuccessMessage,
      updateErrorMessage: updateErrorMessage,
    );
  }
}

final class ParentProfileError extends ParentProfileState {
  const ParentProfileError({required this.message});

  final String message;
}
