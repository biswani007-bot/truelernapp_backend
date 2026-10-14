import '../../domain/entities/user_device_entity.dart';

/// DTO mapping sessions from `GET /api/auth/devices`.
class UserDeviceDto {
  const UserDeviceDto({
    required this.id,
    required this.sessionId,
    this.deviceName,
    this.platform,
    this.appVersion,
    this.createdAt,
    this.lastSeenAt,
    this.expiresAt,
    this.isRevoked = false,
    this.isCurrent = false,
  });

  final String id;
  final String sessionId;
  final String? deviceName;
  final String? platform;
  final String? appVersion;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final DateTime? expiresAt;
  final bool isRevoked;
  final bool isCurrent;

  factory UserDeviceDto.fromJson(Map<String, dynamic> json) {
    return UserDeviceDto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString(),
      platform: json['platform']?.toString(),
      appVersion: json['appVersion']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      isRevoked: json['isRevoked'] == true,
      isCurrent: json['isCurrent'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sessionId': sessionId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'isRevoked': isRevoked,
      'isCurrent': isCurrent,
    };
  }

  UserDeviceEntity toEntity() {
    return UserDeviceEntity(
      id: id,
      sessionId: sessionId,
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
      expiresAt: expiresAt,
      isRevoked: isRevoked,
      isCurrent: isCurrent,
    );
  }
}
