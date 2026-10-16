import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/constants/storage_keys.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService Tests', () {
    late SecureStorageService storageService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storageService = FlutterSecureStorageServiceImpl();
    });

    test('FlutterSecureStorageServiceImpl can be instantiated', () {
      expect(storageService, isA<SecureStorageService>());
    });

    test('StorageKeys are defined consistently', () {
      expect(StorageKeys.accessToken, 'truelern_access_token');
      expect(StorageKeys.refreshToken, 'truelern_refresh_token');
      expect(StorageKeys.userId, 'truelern_user_id');
      expect(StorageKeys.userRole, 'truelern_user_role');
      expect(StorageKeys.activeChildId, 'truelern_active_child_id');
    });

    test(
      'saveAccessToken and getAccessToken persist token correctly',
      () async {
        await storageService.saveAccessToken('token_abc123');
        final token = await storageService.getAccessToken();
        expect(token, 'token_abc123');
      },
    );

    test(
      'saveRefreshToken and getRefreshToken persist refresh token correctly',
      () async {
        await storageService.saveRefreshToken('refresh_xyz789');
        final token = await storageService.getRefreshToken();
        expect(token, 'refresh_xyz789');
      },
    );

    test('saveUserId and getUserId persist user ID correctly', () async {
      await storageService.saveUserId('usr_456');
      final id = await storageService.getUserId();
      expect(id, 'usr_456');
    });

    test('saveActiveChildId and getActiveChildId persist active child ID correctly', () async {
      await storageService.saveActiveChildId('child_123');
      final id = await storageService.getActiveChildId();
      expect(id, 'child_123');
      await storageService.deleteActiveChildId();
      expect(await storageService.getActiveChildId(), isNull);
    });

    test('clearAuthSession removes all authenticated session keys', () async {
      await storageService.saveAccessToken('token_to_clear');
      await storageService.saveRefreshToken('refresh_to_clear');
      await storageService.saveUserId('user_to_clear');
      await storageService.saveActiveChildId('child_to_clear');

      await storageService.clearAuthSession();

      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
      expect(await storageService.getUserId(), isNull);
      expect(await storageService.getActiveChildId(), isNull);
    });
  });
}
