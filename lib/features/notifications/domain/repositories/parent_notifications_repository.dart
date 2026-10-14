import '../entities/parent_notification_entity.dart';

abstract class ParentNotificationsRepository {
  /// Fetches real parent notifications from the backend API, optionally scoped by [childStudentId].
  Future<List<ParentNotificationItemEntity>> getNotifications({
    String? childStudentId,
  });
}
