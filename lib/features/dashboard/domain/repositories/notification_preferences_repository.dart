import '../entities/notification_preferences_entity.dart';

abstract class NotificationPreferencesRepository {
  Future<NotificationPreferencesEntity> getPreferences();
  Future<NotificationPreferencesEntity> updatePreferences(NotificationPreferencesEntity preferences);
}
