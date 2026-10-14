import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/parent_notification_entity.dart';
import '../../domain/repositories/parent_notifications_repository.dart';
import '../models/parent_notification_dto.dart';

class ParentNotificationsRepositoryImpl
    implements ParentNotificationsRepository {
  ParentNotificationsRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ParentNotificationItemEntity>> getNotifications({
    String? childStudentId,
  }) async {
    final queryParams = <String, dynamic>{
      if (childStudentId != null && childStudentId.trim().isNotEmpty)
        'childId': childStudentId.trim(),
    };

    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/notifications',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final body = response.data;
    if (body == null) {
      throw Exception('Empty response from /parent/notifications');
    }

    final rawData = body['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((json) => ParentNotificationDto.fromJson(json).toEntity())
          .toList();
    }

    return [];
  }
}

final parentNotificationsRepositoryProvider =
    Provider<ParentNotificationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ParentNotificationsRepositoryImpl(apiClient: apiClient);
});
