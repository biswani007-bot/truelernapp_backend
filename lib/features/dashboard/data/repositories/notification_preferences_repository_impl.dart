import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../models/notification_preferences_dto.dart';

class NotificationPreferencesRepositoryImpl implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<NotificationPreferencesEntity> getPreferences() async {
    final response = await apiClient.get<Map<String, dynamic>>('/notifications/preferences');
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from /notifications/preferences');
    }
    final rawData = data['data'];
    if (rawData is Map<String, dynamic>) {
      return NotificationPreferencesDto.fromJson(rawData).toEntity();
    }
    return NotificationPreferencesDto.fromJson(data).toEntity();
  }

  @override
  Future<NotificationPreferencesEntity> updatePreferences(NotificationPreferencesEntity preferences) async {
    final payload = NotificationPreferencesDto.toPayload(preferences);
    final response = await apiClient.post<Map<String, dynamic>>(
      '/notifications/preferences',
      data: payload,
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from POST /notifications/preferences');
    }
    final rawData = data['data'];
    if (rawData is Map<String, dynamic>) {
      return NotificationPreferencesDto.fromJson(rawData).toEntity();
    }
    return NotificationPreferencesDto.fromJson(data).toEntity();
  }
}

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationPreferencesRepositoryImpl(apiClient: apiClient);
});
