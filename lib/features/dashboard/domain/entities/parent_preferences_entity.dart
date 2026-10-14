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

  /// Delivery channel convenience getters
  bool get pushEnabled => channelPreferences['push'] ?? true;
  bool get emailEnabled => channelPreferences['email'] ?? true;
  bool get whatsappEnabled => channelPreferences['whatsapp'] ?? true;
  bool get smsEnabled => channelPreferences['sms'] ?? false;
  bool get inAppEnabled => channelPreferences['in-app'] ?? true;

  /// Event category convenience getters
  bool get shareAttendanceData => eventPreferences['attendance'] ?? true;
  bool get shareLearningProgress => eventPreferences['reports'] ?? true;
  bool get attendanceAlerts => eventPreferences['attendance'] ?? true;
  bool get assignmentAlerts => eventPreferences['assignment'] ?? true;
  bool get reportsAlerts => eventPreferences['reports'] ?? true;
  bool get admissionsAlerts => eventPreferences['admissions'] ?? true;
  bool get assessmentAlerts => eventPreferences['assessment'] ?? true;
  bool get certificateAlerts => eventPreferences['certificate'] ?? true;
  bool get financeAlerts => eventPreferences['finance'] ?? true;

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
