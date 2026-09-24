import '../../domain/entities/parent_preferences_entity.dart';

/// DTO for Parent Preferences mapping to/from GET and PATCH /api/parent/preferences.
class ParentPreferencesDto {
  final String id;
  final Map<String, bool> channelPreferences;
  final Map<String, bool> eventPreferences;
  final bool muteAll;
  final bool digestEnabled;
  final String language;
  final String timezone;

  const ParentPreferencesDto({
    required this.id,
    required this.channelPreferences,
    required this.eventPreferences,
    required this.muteAll,
    required this.digestEnabled,
    required this.language,
    required this.timezone,
  });

  factory ParentPreferencesDto.fromJson(Map<String, dynamic> json) {
    final channelMap = <String, bool>{};
    if (json['channelPreferences'] is Map) {
      (json['channelPreferences'] as Map).forEach((key, val) {
        channelMap[key.toString()] = val == true;
      });
    }

    final eventMap = <String, bool>{};
    if (json['eventPreferences'] is Map) {
      (json['eventPreferences'] as Map).forEach((key, val) {
        eventMap[key.toString()] = val == true;
      });
    }

    return ParentPreferencesDto(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      channelPreferences: channelMap,
      eventPreferences: eventMap,
      muteAll: json['muteAll'] == true,
      digestEnabled: json['digestEnabled'] == true,
      language: json['language']?.toString() ?? 'en',
      timezone: json['timezone']?.toString() ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelPreferences': channelPreferences,
      'eventPreferences': eventPreferences,
      'muteAll': muteAll,
      'digestEnabled': digestEnabled,
      'language': language,
      'timezone': timezone,
    };
  }

  ParentPreferencesEntity toEntity() {
    return ParentPreferencesEntity(
      id: id,
      channelPreferences: channelPreferences,
      eventPreferences: eventPreferences,
      muteAll: muteAll,
      digestEnabled: digestEnabled,
      language: language,
      timezone: timezone,
    );
  }

  factory ParentPreferencesDto.fromEntity(ParentPreferencesEntity entity) {
    return ParentPreferencesDto(
      id: entity.id,
      channelPreferences: entity.channelPreferences,
      eventPreferences: entity.eventPreferences,
      muteAll: entity.muteAll,
      digestEnabled: entity.digestEnabled,
      language: entity.language,
      timezone: entity.timezone,
    );
  }
}
