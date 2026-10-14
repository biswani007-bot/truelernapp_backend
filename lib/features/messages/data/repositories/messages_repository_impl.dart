import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import '../models/message_dto.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<MessagesDataEntity> getMessages({required String studentId}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/children/$studentId/messages',
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Empty response received from /parent/children/$studentId/messages');
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return MessagesDataDto.fromJson(data).toEntity();
    }

    return MessagesDataDto.fromJson(body).toEntity();
  }

  @override
  Future<MessageItemEntity> sendMessage({
    required String studentId,
    required String message,
    String? subject,
  }) async {
    final payload = <String, dynamic>{
      'message': message,
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
    };

    final response = await apiClient.post<Map<String, dynamic>>(
      '/parent/children/$studentId/messages',
      data: payload,
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Empty response received from POST /parent/children/$studentId/messages');
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return MessageItemDto.fromJson(data).toEntity();
    }

    return MessageItemDto.fromJson(body).toEntity();
  }

  @override
  Future<bool> markAsRead({
    required String studentId,
    required String messageId,
  }) async {
    final response = await apiClient.patch<Map<String, dynamic>>(
      '/parent/children/$studentId/messages/$messageId/read',
      data: <String, dynamic>{},
    );

    final body = response.data;
    return body != null && body['success'] == true;
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MessagesRepositoryImpl(apiClient: apiClient);
});
