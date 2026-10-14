import '../entities/user_device_entity.dart';

abstract class UserDevicesRepository {
  /// Fetches active sessions and devices for the authenticated account.
  Future<List<UserDeviceEntity>> getDevices();

  /// Revokes an active device session by its sessionId.
  Future<void> revokeDevice(String sessionId);
}
