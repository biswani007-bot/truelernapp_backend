import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/parent_profile_repository_impl.dart';
import '../../domain/repositories/parent_profile_repository.dart';
import 'parent_profile_state.dart';

class ParentProfileController extends Notifier<ParentProfileState> {
  @override
  ParentProfileState build() => const ParentProfileInitial();

  ParentProfileRepository get _repository =>
      ref.read(parentProfileRepositoryProvider);

  int _requestToken = 0;

  Future<void> loadProfile({bool refresh = false}) async {
    final current = state;
    if (current is ParentProfileLoading) return;
    if (!refresh && current is ParentProfileLoaded) return;

    final token = ++_requestToken;
    state = const ParentProfileLoading();
    try {
      final profile = await _repository.getParentProfile();
      if (token != _requestToken) return;

      state = ParentProfileLoaded(profile: profile);

      // Synchronize authoritative Parent profile into shared Auth state
      ref
          .read(authControllerProvider.notifier)
          .updateUserProfile(name: profile.fullName, email: profile.email);
    } catch (e) {
      if (token != _requestToken) return;
      state = ParentProfileError(message: e.toString());
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
    String? city,
    String? stateName,
    String? country,
    String? postalCode,
  }) async {
    final currentState = state;
    if (currentState is! ParentProfileLoaded) return false;

    state = currentState.copyWith(
      isUpdating: true,
      updateSuccessMessage: null,
      updateErrorMessage: null,
    );
    try {
      final updatedProfile = await _repository.updateParentProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
        city: city,
        state: stateName,
        country: country,
        postalCode: postalCode,
      );
      state = ParentProfileLoaded(
        profile: updatedProfile,
        isUpdating: false,
        updateSuccessMessage: 'Profile information updated successfully',
      );

      // Synchronize authoritative Parent profile into shared Auth state
      ref
          .read(authControllerProvider.notifier)
          .updateUserProfile(
            name: updatedProfile.fullName,
            email: updatedProfile.email,
          );

      return true;
    } catch (e) {
      state = currentState.copyWith(
        isUpdating: false,
        updateErrorMessage: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  void clearMessages() {
    final currentState = state;
    if (currentState is ParentProfileLoaded) {
      state = currentState.copyWith(
        updateSuccessMessage: null,
        updateErrorMessage: null,
      );
    }
  }

  /// Resets state on logout or session invalidation.
  void reset() {
    _requestToken++;
    state = const ParentProfileInitial();
  }
}

final parentProfileControllerProvider =
    NotifierProvider<ParentProfileController, ParentProfileState>(
      ParentProfileController.new,
    );
