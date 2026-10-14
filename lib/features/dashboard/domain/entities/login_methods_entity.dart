/// Domain entity representing verified login methods and associated credentials.
class LoginMethodsEntity {
  const LoginMethodsEntity({
    required this.email,
    required this.phone,
    required this.hasPassword,
    required this.isSecurityActive,
    this.isWhatsAppPreferred = true,
    this.isEmailPreferred = true,
  });

  /// Registered user email (from parent profile & security)
  final String email;

  /// Registered user phone/WhatsApp contact (from parent profile)
  final String phone;

  /// Whether user has password credential configured on backend
  final bool hasPassword;

  /// Whether parent security account is active
  final bool isSecurityActive;

  /// Whether WhatsApp channel is preferred
  final bool isWhatsAppPreferred;

  /// Whether Email channel is preferred
  final bool isEmailPreferred;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginMethodsEntity &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          phone == other.phone &&
          hasPassword == other.hasPassword &&
          isSecurityActive == other.isSecurityActive &&
          isWhatsAppPreferred == other.isWhatsAppPreferred &&
          isEmailPreferred == other.isEmailPreferred;

  @override
  int get hashCode => Object.hash(
    email,
    phone,
    hasPassword,
    isSecurityActive,
    isWhatsAppPreferred,
    isEmailPreferred,
  );
}
