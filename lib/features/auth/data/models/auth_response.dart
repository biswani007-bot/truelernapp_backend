/// User details returned in authentication response.
class UserDto {
  const UserDto({
    required this.id,
    this.name,
    this.email,
    this.role,
  });

  final String id;
  final String? name;
  final String? email;
  final String? role;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    // The TrueLern API returns `role` as a nested object: {"name": "parent", ...}
    // not as a plain string. Extract the role name safely.
    final roleField = json['role'];
    final String? roleName;
    if (roleField is Map<String, dynamic>) {
      roleName = roleField['name'] as String?;
    } else if (roleField is String) {
      roleName = roleField;
    } else {
      roleName = null;
    }

    final firstName = json['firstName'] as String?;
    final lastName = json['lastName'] as String?;
    final String? combinedName;
    if (firstName != null || lastName != null) {
      combinedName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    } else if (json['name'] is String) {
      combinedName = json['name'] as String?;
    } else {
      combinedName = null;
    }

    return UserDto(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: combinedName,
      email: json['email'] as String?,
      role: roleName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}

/// Authentication response payload containing tokens and user session data.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final UserDto? user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Check if wrapped in standard { "data": { ... } } structure
    final payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return AuthResponse(
      accessToken: (payload['accessToken'] ?? payload['token'] ?? '').toString(),
      refreshToken: payload['refreshToken'] as String?,
      user: payload['user'] is Map<String, dynamic>
          ? UserDto.fromJson(payload['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
