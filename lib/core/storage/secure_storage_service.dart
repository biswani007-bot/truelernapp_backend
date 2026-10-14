import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Contract for secure key-value token persistence.
abstract interface class SecureStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> deleteAccessToken();

  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> deleteRefreshToken();

  Future<void> saveUserId(String id);
  Future<String?> getUserId();

  Future<void> saveActiveChildId(String childId);
  Future<String?> getActiveChildId();
  Future<void> deleteActiveChildId();

  Future<void> clearAuthSession();
}

/// Standard production implementation backed by [FlutterSecureStorage].
class FlutterSecureStorageServiceImpl implements SecureStorageService {
  FlutterSecureStorageServiceImpl({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            wOptions: WindowsOptions(),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }

  @override
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  @override
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  @override
  Future<void> saveUserId(String id) async {
    await _storage.write(key: StorageKeys.userId, value: id);
  }

  @override
  Future<String?> getUserId() async {
    return _storage.read(key: StorageKeys.userId);
  }

  @override
  Future<void> saveActiveChildId(String childId) async {
    await _storage.write(key: StorageKeys.activeChildId, value: childId);
  }

  @override
  Future<String?> getActiveChildId() async {
    return _storage.read(key: StorageKeys.activeChildId);
  }

  @override
  Future<void> deleteActiveChildId() async {
    await _storage.delete(key: StorageKeys.activeChildId);
  }

  @override
  Future<void> clearAuthSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userRole);
    await _storage.delete(key: StorageKeys.activeChildId);
  }
}

/// Global provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return FlutterSecureStorageServiceImpl();
});
