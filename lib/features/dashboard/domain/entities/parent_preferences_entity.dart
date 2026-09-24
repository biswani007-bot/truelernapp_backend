/// Domain entity representing authenticated Parent Preferences.
/// Governed by:
/// - GET /api/parent/preferences
/// - PATCH /api/parent/preferences
class ParentPreferencesEntity {
  final String id;
  final Map<String, bool> channelPreferences;
  final Map<String, bool> eventPreferences;
  final bool muteAll;
  final bool digestEnabled;
  final String language;
  final String timezone;

  const ParentPreferencesEntity({
    required this.id,
    required this.channelPreferences,
    required this.eventPreferences,
    required this.muteAll,
    required this.digestEnabled,
    required this.language,
    required this.timezone,
  });

  /// Convenience getter for attendance data sharing
  bool get shareAttendanceData => eventPreferences['attendance'] ?? true;

  /// Convenience getter for learning progress reports sharing
  bool get shareLearningProgress => eventPreferences['reports'] ?? true;

  ParentPreferencesEntity copyWith({
    String? id,
    Map<String, bool>? channelPreferences,
    Map<String, bool>? eventPreferences,
    bool? muteAll,
    bool? digestEnabled,
    String? language,
    String? timezone,
  }) {
    return ParentPreferencesEntity(
      id: id ?? this.id,
      channelPreferences: channelPreferences ?? this.channelPreferences,
      eventPreferences: eventPreferences ?? this.eventPreferences,
      muteAll: muteAll ?? this.muteAll,
      digestEnabled: digestEnabled ?? this.digestEnabled,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
    );
  }
}
