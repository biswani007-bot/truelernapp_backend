import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';

/// Secure token manager specifically for assessment proxy session tokens.
abstract final class AssessmentProxyStorage {
  static String? _cachedToken;
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    wOptions: WindowsOptions(),
  );

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      await _storage.write(key: StorageKeys.assessmentProxyToken, value: token);
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    try {
      final stored = await _storage.read(key: StorageKeys.assessmentProxyToken);
      _cachedToken = stored;
      return stored;
    } catch (_) {
      return _cachedToken;
    }
  }

  static Future<void> deleteToken() async {
    _cachedToken = null;
    try {
      await _storage.delete(key: StorageKeys.assessmentProxyToken);
    } catch (_) {}
  }
}
