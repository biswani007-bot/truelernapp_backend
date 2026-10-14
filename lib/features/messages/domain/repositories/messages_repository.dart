import '../entities/message_entity.dart';

abstract class MessagesRepository {
  /// Fetches conversation messages and teachers for the given studentId.
  Future<MessagesDataEntity> getMessages({required String studentId});

  /// Sends a new message from parent regarding the student.
  Future<MessageItemEntity> sendMessage({
    required String studentId,
    required String message,
    String? subject,
  });

  /// Marks a specific message as read.
  Future<bool> markAsRead({
    required String studentId,
    required String messageId,
  });
}
