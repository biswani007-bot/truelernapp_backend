import 'package:flutter/foundation.dart';

/// Entity representing an active user session/device returned by `GET /api/auth/devices`.
@immutable
class UserDeviceEntity {
  const UserDeviceEntity({
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

  /// User-friendly display title for the device.
  String get displayName {
    if (deviceName != null && deviceName!.trim().isNotEmpty) {
      return deviceName!.trim();
    }
    if (platform != null && platform!.trim().isNotEmpty) {
      return '${platform!.trim()} Device';
    }
    return 'Authorized Device';
  }

  /// User-friendly device platform subtitle.
  String get displaySubtitle {
    final parts = <String>[];
    if (platform != null && platform!.trim().isNotEmpty) {
      parts.add(platform!.trim());
    }
    if (appVersion != null && appVersion!.trim().isNotEmpty) {
      parts.add('v${appVersion!.trim()}');
    }
    if (parts.isEmpty) {
      return 'Active session';
    }
    return parts.join(' • ');
  }

  /// Relative or formatted last active timestamp.
  String get lastActiveFormatted {
    if (isCurrent) return 'Active Now';
    if (lastSeenAt == null) return 'Recently active';

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt!);

    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Last active: ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last active: ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last active: ${difference.inDays}d ago';
    } else {
      return 'Last active: ${lastSeenAt!.day}/${lastSeenAt!.month}/${lastSeenAt!.year}';
    }
  }

  UserDeviceEntity copyWith({
    String? id,
    String? sessionId,
    String? deviceName,
    String? platform,
    String? appVersion,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    DateTime? expiresAt,
    bool? isRevoked,
    bool? isCurrent,
  }) {
    return UserDeviceEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRevoked: isRevoked ?? this.isRevoked,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDeviceEntity &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          isRevoked == other.isRevoked &&
          isCurrent == other.isCurrent;

  @override
  int get hashCode =>
      sessionId.hashCode ^ isRevoked.hashCode ^ isCurrent.hashCode;
}
