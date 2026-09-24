/// Entity representing classroom access credentials returned by:
/// POST /api/parent/children/{childStudentId}/live-classes/{classId}/join
class ClassJoinEntity {
  const ClassJoinEntity({
    required this.token,
    required this.roomName,
    required this.jitsiDomain,
    required this.serverUrl,
    required this.meetingUrl,
    required this.isModerator,
    this.expiresAt,
    this.childId,
    this.childName,
    this.classId,
    this.classTitle,
  });

  /// Cryptographic JWT token for Jitsi Meet room authentication.
  final String token;

  /// Deterministic room name (e.g. "truelern-6ab0d936aabd606a21c0c72a").
  final String roomName;

  /// Jitsi domain (e.g. "livetl.visital.in").
  final String jitsiDomain;

  /// Full Jitsi server URL (e.g. "https://livetl.visital.in").
  final String serverUrl;

  /// Complete direct meeting URL including JWT token query parameter.
  final String meetingUrl;

  /// Whether user has moderator permissions (strictly false for observing parents).
  final bool isModerator;

  /// Unix timestamp when the classroom token expires.
  final int? expiresAt;

  /// ID of the child whose class is being observed.
  final String? childId;

  /// Name of the child whose class is being observed.
  final String? childName;

  /// ID of the live class session.
  final String? classId;

  /// Title of the live class session.
  final String? classTitle;
}
