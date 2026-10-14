/// Storage keys used across secure and key-value persistence layers.
abstract final class StorageKeys {
  /// Key for the JWT access token stored in secure keystore/keychain.
  static const String accessToken = 'truelern_access_token';

  /// Key for the refresh token stored in secure keystore/keychain.
  static const String refreshToken = 'truelern_refresh_token';

  /// Key for current user identifier.
  static const String userId = 'truelern_user_id';

  /// Key for current user role (e.g. parent / student).
  static const String userRole = 'truelern_user_role';

  /// Key for active child/ward ID in parent context.
  static const String activeChildId = 'truelern_active_child_id';

  /// Key for the assessment proxy token returned by parent launch endpoint.
  static const String assessmentProxyToken = 'truelern_assessment_proxy_token';
}
