import '../../domain/entities/login_methods_entity.dart';

/// Data Transfer Object representing the Login Methods data extracted
/// from verified backend responses (`/api/parent/profile` and `/api/parent/preferences`).
class LoginMethodsDto {
  const LoginMethodsDto({
    required this.email,
    required this.phone,
    required this.hasPassword,
    required this.isSecurityActive,
    required this.isWhatsAppPreferred,
    required this.isEmailPreferred,
  });

  factory LoginMethodsDto.fromProfileJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? prefJson,
  }) {
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;
    final security = json['security'] is Map<String, dynamic>
        ? json['security'] as Map<String, dynamic>
        : <String, dynamic>{};

    final channelPrefs =
        prefJson != null &&
            prefJson['channelPreferences'] is Map<String, dynamic>
        ? prefJson['channelPreferences'] as Map<String, dynamic>
        : null;

    final emailVal = (profile['email'] as String?)?.trim().isNotEmpty == true
        ? (profile['email'] as String).trim()
        : (security['email'] as String? ?? '').trim();

    final phoneVal = (profile['phone'] as String? ?? '').trim();

    return LoginMethodsDto(
      email: emailVal,
      phone: phoneVal,
      hasPassword: security['hasPassword'] as bool? ?? true,
      isSecurityActive: security['isActive'] as bool? ?? true,
      isWhatsAppPreferred: channelPrefs != null
          ? (channelPrefs['whatsapp'] as bool? ?? true)
          : true,
      isEmailPreferred: channelPrefs != null
          ? (channelPrefs['email'] as bool? ?? true)
          : true,
    );
  }

  final String email;
  final String phone;
  final bool hasPassword;
  final bool isSecurityActive;
  final bool isWhatsAppPreferred;
  final bool isEmailPreferred;

  LoginMethodsEntity toEntity() {
    return LoginMethodsEntity(
      email: email,
      phone: phone,
      hasPassword: hasPassword,
      isSecurityActive: isSecurityActive,
      isWhatsAppPreferred: isWhatsAppPreferred,
      isEmailPreferred: isEmailPreferred,
    );
  }
}
