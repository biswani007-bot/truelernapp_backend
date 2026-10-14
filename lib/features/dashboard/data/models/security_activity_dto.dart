import '../../domain/entities/security_activity_entity.dart';

/// DTO mapping activity log records from `GET /api/auth/activity`.
class SecurityActivityDto {
  const SecurityActivityDto({
    required this.id,
    required this.action,
    required this.entity,
    this.entityId,
    this.ip,
    this.userAgent,
    required this.timestamp,
    this.metadata,
  });

  final String id;
  final String action;
  final String entity;
  final String? entityId;
  final String? ip;
  final String? userAgent;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  factory SecurityActivityDto.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp = DateTime.now();
    if (json['timestamp'] != null) {
      parsedTimestamp =
          DateTime.tryParse(json['timestamp'].toString()) ?? parsedTimestamp;
    } else if (json['createdAt'] != null) {
      parsedTimestamp =
          DateTime.tryParse(json['createdAt'].toString()) ?? parsedTimestamp;
    }

    Map<String, dynamic>? meta;
    if (json['metadata'] is Map<String, dynamic>) {
      meta = json['metadata'] as Map<String, dynamic>;
    }

    return SecurityActivityDto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? 'SYSTEM_EVENT',
      entity: json['entity']?.toString() ?? 'auth',
      entityId: json['entityId']?.toString(),
      ip: json['ip']?.toString(),
      userAgent: json['userAgent']?.toString(),
      timestamp: parsedTimestamp,
      metadata: meta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'action': action,
      'entity': entity,
      if (entityId != null) 'entityId': entityId,
      if (ip != null) 'ip': ip,
      if (userAgent != null) 'userAgent': userAgent,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  SecurityActivityEntity toEntity() {
    return SecurityActivityEntity(
      id: id,
      action: action,
      entity: entity,
      entityId: entityId,
      ip: ip,
      userAgent: userAgent,
      timestamp: timestamp,
      metadata: metadata,
    );
  }
}
