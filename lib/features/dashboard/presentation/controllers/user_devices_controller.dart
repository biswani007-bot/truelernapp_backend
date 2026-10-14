import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_devices_repository_impl.dart';
import '../../domain/repositories/user_devices_repository.dart';
import 'user_devices_state.dart';

class UserDevicesController extends Notifier<UserDevicesState> {
  @override
  UserDevicesState build() => const UserDevicesInitial();

  UserDevicesRepository get _repository =>
      ref.read(userDevicesRepositoryProvider);

  Future<void> loadDevices({bool forceRefresh = false}) async {
    final current = state;
    if (!forceRefresh && current is UserDevicesLoaded) return;
    if (current is UserDevicesLoading) return;

    state = const UserDevicesLoading();
    try {
      final devices = await _repository.getDevices();
      state = UserDevicesLoaded(devices: devices);
    } catch (e) {
      state = UserDevicesError(message: e.toString());
    }
  }

  Future<bool> revokeDevice(String sessionId) async {
    final current = state;
    if (current is! UserDevicesLoaded) return false;

    state = current.copyWith(revokingSessionId: sessionId);
    try {
      await _repository.revokeDevice(sessionId);
      final updatedList =
          current.devices.where((d) => d.sessionId != sessionId).toList();
      state = UserDevicesLoaded(
        devices: updatedList,
        revokingSessionId: null,
        feedbackMessage: 'Device signed out successfully',
        isError: false,
      );
      return true;
    } catch (e) {
      state = current.copyWith(
        revokingSessionId: null,
        feedbackMessage: 'Failed to sign out device. Please try again.',
        isError: true,
      );
      return false;
    }
  }

  void clearFeedback() {
    final current = state;
    if (current is UserDevicesLoaded && current.feedbackMessage != null) {
      state = current.copyWith(feedbackMessage: null);
    }
  }
}

final userDevicesControllerProvider =
    NotifierProvider<UserDevicesController, UserDevicesState>(
  UserDevicesController.new,
);
