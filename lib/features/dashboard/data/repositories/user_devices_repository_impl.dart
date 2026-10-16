import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_device_entity.dart';
import '../../domain/repositories/user_devices_repository.dart';
import '../models/user_device_dto.dart';

class UserDevicesRepositoryImpl implements UserDevicesRepository {
  const UserDevicesRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<UserDeviceEntity>> getDevices() async {
    final response = await apiClient.get<Map<String, dynamic>>('/auth/devices');
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from /auth/devices');
    }

    final rawList = data['data'];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => UserDeviceDto.fromJson(item).toEntity())
          .toList();
    }
    return [];
  }

  @override
  Future<void> revokeDevice(String sessionId) async {
    final response = await apiClient.delete<Map<String, dynamic>>(
      '/auth/devices',
      queryParameters: {'sessionId': sessionId},
    );
    if (response.data == null) {
      throw Exception('Empty response from DELETE /auth/devices');
    }
  }
}

final userDevicesRepositoryProvider = Provider<UserDevicesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserDevicesRepositoryImpl(apiClient: client);
});
