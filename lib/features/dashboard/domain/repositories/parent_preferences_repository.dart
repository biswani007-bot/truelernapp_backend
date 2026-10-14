import '../entities/parent_preferences_entity.dart';

abstract class ParentPreferencesRepository {
  Future<ParentPreferencesEntity> getPreferences();
  Future<ParentPreferencesEntity> updatePreferences(
    ParentPreferencesEntity preferences,
  );
}
