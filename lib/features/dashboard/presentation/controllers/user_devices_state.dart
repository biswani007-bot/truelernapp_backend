import 'package:flutter/foundation.dart';

import '../../domain/entities/user_device_entity.dart';

@immutable
sealed class UserDevicesState {
  const UserDevicesState();
}

class UserDevicesInitial extends UserDevicesState {
  const UserDevicesInitial();
}

class UserDevicesLoading extends UserDevicesState {
  const UserDevicesLoading();
}

class UserDevicesLoaded extends UserDevicesState {
  const UserDevicesLoaded({
    required this.devices,
    this.revokingSessionId,
    this.feedbackMessage,
    this.isError = false,
  });

  final List<UserDeviceEntity> devices;
  final String? revokingSessionId;
  final String? feedbackMessage;
  final bool isError;

  UserDeviceEntity? get currentDevice {
    try {
      return devices.firstWhere((d) => d.isCurrent && !d.isRevoked);
    } catch (_) {
      return null;
    }
  }

  List<UserDeviceEntity> get otherDevices {
    return devices.where((d) => !d.isCurrent && !d.isRevoked).toList();
  }

  UserDevicesLoaded copyWith({
    List<UserDeviceEntity>? devices,
    String? revokingSessionId,
    String? feedbackMessage,
    bool? isError,
  }) {
    return UserDevicesLoaded(
      devices: devices ?? this.devices,
      revokingSessionId: revokingSessionId,
      feedbackMessage: feedbackMessage,
      isError: isError ?? false,
    );
  }
}

class UserDevicesError extends UserDevicesState {
  const UserDevicesError({required this.message});

  final String message;
}
