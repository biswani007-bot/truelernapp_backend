/// Domain entity representing notification and communication preferences from `/api/notifications/preferences`.
class NotificationPreferencesEntity {
  const NotificationPreferencesEntity({
    required this.id,
    required this.userId,
    // Channel Preferences
    required this.emailEnabled,
    required this.smsEnabled,
    required this.whatsappEnabled,
    required this.pushEnabled,
    required this.inAppEnabled,
    // Event Preferences
    required this.admissionsAlerts,
    required this.enrollmentAlerts,
    required this.attendanceAlerts,
    required this.assignmentAlerts,
    required this.assessmentAlerts,
    required this.certificateAlerts,
    required this.financeAlerts,
    required this.reportsAlerts,
    // General
    required this.muteAll,
    required this.digestEnabled,
  });

  final String id;
  final String userId;

  // Channels
  final bool emailEnabled;
  final bool smsEnabled;
  final bool whatsappEnabled;
  final bool pushEnabled;
  final bool inAppEnabled;

  // Events
  final bool admissionsAlerts;
  final bool enrollmentAlerts;
  final bool attendanceAlerts;
  final bool assignmentAlerts;
  final bool assessmentAlerts;
  final bool certificateAlerts;
  final bool financeAlerts;
  final bool reportsAlerts;

  // General
  final bool muteAll;
  final bool digestEnabled;

  NotificationPreferencesEntity copyWith({
    String? id,
    String? userId,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? whatsappEnabled,
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? admissionsAlerts,
    bool? enrollmentAlerts,
    bool? attendanceAlerts,
    bool? assignmentAlerts,
    bool? assessmentAlerts,
    bool? certificateAlerts,
    bool? financeAlerts,
    bool? reportsAlerts,
    bool? muteAll,
    bool? digestEnabled,
  }) {
    return NotificationPreferencesEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      admissionsAlerts: admissionsAlerts ?? this.admissionsAlerts,
      enrollmentAlerts: enrollmentAlerts ?? this.enrollmentAlerts,
      attendanceAlerts: attendanceAlerts ?? this.attendanceAlerts,
      assignmentAlerts: assignmentAlerts ?? this.assignmentAlerts,
      assessmentAlerts: assessmentAlerts ?? this.assessmentAlerts,
      certificateAlerts: certificateAlerts ?? this.certificateAlerts,
      financeAlerts: financeAlerts ?? this.financeAlerts,
      reportsAlerts: reportsAlerts ?? this.reportsAlerts,
      muteAll: muteAll ?? this.muteAll,
      digestEnabled: digestEnabled ?? this.digestEnabled,
    );
  }
}
