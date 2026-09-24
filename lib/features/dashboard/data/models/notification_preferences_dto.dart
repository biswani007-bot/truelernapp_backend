import '../../domain/entities/notification_preferences_entity.dart';

class NotificationPreferencesDto {
  const NotificationPreferencesDto({
    required this.id,
    required this.userId,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.whatsappEnabled,
    required this.pushEnabled,
    required this.inAppEnabled,
    required this.admissionsAlerts,
    required this.enrollmentAlerts,
    required this.attendanceAlerts,
    required this.assignmentAlerts,
    required this.assessmentAlerts,
    required this.certificateAlerts,
    required this.financeAlerts,
    required this.reportsAlerts,
    required this.muteAll,
    required this.digestEnabled,
  });

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) {
    final channels = json['channelPreferences'] as Map<String, dynamic>? ?? {};
    final events = json['eventPreferences'] as Map<String, dynamic>? ?? {};

    return NotificationPreferencesDto(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['user'] as String? ?? '',
      emailEnabled: channels['email'] as bool? ?? true,
      smsEnabled: channels['sms'] as bool? ?? true,
      whatsappEnabled: channels['whatsapp'] as bool? ?? true,
      pushEnabled: channels['push'] as bool? ?? true,
      inAppEnabled: channels['in-app'] as bool? ?? true,
      admissionsAlerts: events['admissions'] as bool? ?? true,
      enrollmentAlerts: events['enrollment'] as bool? ?? true,
      attendanceAlerts: events['attendance'] as bool? ?? true,
      assignmentAlerts: events['assignment'] as bool? ?? true,
      assessmentAlerts: events['assessment'] as bool? ?? true,
      certificateAlerts: events['certificate'] as bool? ?? true,
      financeAlerts: events['finance'] as bool? ?? true,
      reportsAlerts: events['reports'] as bool? ?? true,
      muteAll: json['muteAll'] as bool? ?? false,
      digestEnabled: json['digestEnabled'] as bool? ?? false,
    );
  }

  final String id;
  final String userId;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool whatsappEnabled;
  final bool pushEnabled;
  final bool inAppEnabled;
  final bool admissionsAlerts;
  final bool enrollmentAlerts;
  final bool attendanceAlerts;
  final bool assignmentAlerts;
  final bool assessmentAlerts;
  final bool certificateAlerts;
  final bool financeAlerts;
  final bool reportsAlerts;
  final bool muteAll;
  final bool digestEnabled;

  NotificationPreferencesEntity toEntity() {
    return NotificationPreferencesEntity(
      id: id,
      userId: userId,
      emailEnabled: emailEnabled,
      smsEnabled: smsEnabled,
      whatsappEnabled: whatsappEnabled,
      pushEnabled: pushEnabled,
      inAppEnabled: inAppEnabled,
      admissionsAlerts: admissionsAlerts,
      enrollmentAlerts: enrollmentAlerts,
      attendanceAlerts: attendanceAlerts,
      assignmentAlerts: assignmentAlerts,
      assessmentAlerts: assessmentAlerts,
      certificateAlerts: certificateAlerts,
      financeAlerts: financeAlerts,
      reportsAlerts: reportsAlerts,
      muteAll: muteAll,
      digestEnabled: digestEnabled,
    );
  }

  static Map<String, dynamic> toPayload(NotificationPreferencesEntity entity) {
    return {
      'channelPreferences': {
        'email': entity.emailEnabled,
        'sms': entity.smsEnabled,
        'whatsapp': entity.whatsappEnabled,
        'push': entity.pushEnabled,
        'in-app': entity.inAppEnabled,
      },
      'eventPreferences': {
        'admissions': entity.admissionsAlerts,
        'enrollment': entity.enrollmentAlerts,
        'attendance': entity.attendanceAlerts,
        'assignment': entity.assignmentAlerts,
        'assessment': entity.assessmentAlerts,
        'certificate': entity.certificateAlerts,
        'finance': entity.financeAlerts,
        'reports': entity.reportsAlerts,
      },
      'muteAll': entity.muteAll,
      'digestEnabled': entity.digestEnabled,
    };
  }
}
