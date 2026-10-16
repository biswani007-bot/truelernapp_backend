import 'package:flutter/material.dart';

/// Entity representing an audit log entry returned by `GET /api/auth/activity`.
@immutable
class SecurityActivityEntity {
  const SecurityActivityEntity({
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

  /// User-friendly title for the security action.
  String get displayTitle {
    final act = action.toUpperCase();
    if (act.contains('LOGIN')) return 'Account Login';
    if (act.contains('LOGOUT')) return 'Account Sign Out';
    if (act.contains('PASSWORD')) return 'Password Update';
    if (act.contains('DEVICE') || act.contains('SESSION')) {
      return 'Session Revocation';
    }
    if (act.contains('TOKEN')) return 'Security Token Refresh';
    if (act.contains('AUTH')) return 'Authentication Event';
    return action
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  /// User-friendly description combining entity, IP, and client info.
  String get displayDescription {
    final parts = <String>[];
    if (ip != null && ip!.isNotEmpty) {
      parts.add('IP: $ip');
    }
    if (userAgent != null && userAgent!.isNotEmpty) {
      final ua = userAgent!;
      if (ua.contains('Android')) {
        parts.add('Android Device');
      } else if (ua.contains('iPhone') || ua.contains('iPad')) {
        parts.add('iOS Device');
      } else if (ua.contains('Macintosh') || ua.contains('Mac OS')) {
        parts.add('macOS');
      } else if (ua.contains('Windows')) {
        parts.add('Windows PC');
      } else {
        parts.add('Web Client');
      }
    }
    if (parts.isEmpty) {
      return entity.isNotEmpty ? 'Target: $entity' : 'Security event recorded';
    }
    return parts.join(' • ');
  }

  /// Relative or formatted timestamp.
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }

  /// Material icon matching the activity type.
  IconData get iconData {
    final act = action.toUpperCase();
    if (act.contains('LOGIN')) return Icons.login_rounded;
    if (act.contains('LOGOUT')) return Icons.logout_rounded;
    if (act.contains('PASSWORD')) return Icons.lock_reset_rounded;
    if (act.contains('DEVICE') || act.contains('SESSION')) {
      return Icons.phonelink_erase_rounded;
    }
    if (act.contains('TOKEN')) return Icons.key_rounded;
    return Icons.security_rounded;
  }

  /// Theme accent color for the event type.
  Color get iconColor {
    final act = action.toUpperCase();
    if (act.contains('LOGIN')) return const Color(0xFF10B981);
    if (act.contains('LOGOUT') || act.contains('REVOKE')) {
      return const Color(0xFFEF4444);
    }
    if (act.contains('PASSWORD')) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityActivityEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
