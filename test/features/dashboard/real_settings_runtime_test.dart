import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/dashboard/data/repositories/notification_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_profile_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/repositories/notification_preferences_repository.dart';
import 'package:truelearn/features/dashboard/domain/repositories/parent_preferences_repository.dart';
import 'package:truelearn/features/dashboard/domain/repositories/parent_profile_repository.dart';

// ignore_for_file: avoid_print

class LiveVerificationStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<void> saveAccessToken(String token) async => _data['access_token'] = token;

  @override
  Future<void> deleteAccessToken() async => _data.remove('access_token');

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> saveRefreshToken(String token) async => _data['refresh_token'] = token;

  @override
  Future<void> deleteRefreshToken() async => _data.remove('refresh_token');

  @override
  Future<String?> getUserId() async => _data['user_id'];

  @override
  Future<void> saveUserId(String id) async => _data['user_id'] = id;

  @override
  Future<void> saveActiveChildId(String childId) async => _data['active_child_id'] = childId;

  @override
  Future<String?> getActiveChildId() async => _data['active_child_id'];

  @override
  Future<void> deleteActiveChildId() async => _data.remove('active_child_id');

  @override
  Future<void> clearAuthSession() async => _data.clear();
}

void main() {
  group('Real Settings Runtime Verification (Live TrueLern Backend)', () {
    late ProviderContainer container;
    late ParentProfileRepository profileRepo;
    late ParentPreferencesRepository privacyRepo;
    late NotificationPreferencesRepository commRepo;

    setUpAll(() async {
      final storage = LiveVerificationStorage();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );

      final authNotifier = container.read(authControllerProvider.notifier);
      final loginOk = await authNotifier.login(
        email: 'parent@truelern.com',
        password: 'password123',
      );

      final authState = container.read(authControllerProvider);
      print('============================================================');
      print('REAL SETTINGS RUNTIME VERIFICATION');
      print('Login success: $loginOk');
      print('AuthState: ${authState.runtimeType}');
      expect(authState, isA<Authenticated>());

      profileRepo = container.read(parentProfileRepositoryProvider);
      privacyRepo = container.read(parentPreferencesRepositoryProvider);
      commRepo = container.read(notificationPreferencesRepositoryProvider);
    });

    tearDownAll(() {
      container.dispose();
    });

    // ─────────────────────────────────────────────────────────
    // Screen 1: Personal Information Runtime Verification
    // ─────────────────────────────────────────────────────────
    test('1. Personal Information: GET profile -> 200, PATCH profile -> 200, persistence verified', () async {
      // 1. GET /api/parent/profile
      final profile = await profileRepo.getParentProfile();
      expect(profile.email, 'parent@truelern.com');
      expect(profile.firstName, isNotEmpty);
      expect(profile.lastName, isNotEmpty);
      expect(profile.parentId, startsWith('PAR-'));
      print('Personal Information: name=${profile.fullName}, email=${profile.email}, id=${profile.parentId}');

      // 2. PATCH /api/parent/profile
      final originalAddress = profile.address;
      final testAddress = '400 Castro Street, Suite 200';
      final updatedProfile = await profileRepo.updateParentProfile(
        firstName: profile.firstName,
        lastName: profile.lastName,
        phone: profile.phone,
        address: testAddress,
      );
      expect(updatedProfile.address, testAddress);

      // 3. Confirm persistence by reading back
      final reloadedProfile = await profileRepo.getParentProfile();
      expect(reloadedProfile.address, testAddress);

      // Revert address back
      await profileRepo.updateParentProfile(
        firstName: profile.firstName,
        lastName: profile.lastName,
        phone: profile.phone,
        address: originalAddress,
      );
      print('Personal Information: PATCH & Persistence Verified 100%');
    });

    // ─────────────────────────────────────────────────────────
    // Screen 2: Privacy Preferences Runtime Verification
    // ─────────────────────────────────────────────────────────
    test('2. Privacy Preferences: GET preferences -> 200, PATCH preferences -> 200, persistence verified', () async {
      // 1. GET /api/parent/preferences
      final prefs = await privacyRepo.getPreferences();
      expect(prefs.id, isNotEmpty);
      expect(prefs.eventPreferences, isNotNull);
      print('Privacy Preferences: id=${prefs.id}, attendance=${prefs.shareAttendanceData}, reports=${prefs.shareLearningProgress}');

      // 2. PATCH /api/parent/preferences
      final originalAttendance = prefs.shareAttendanceData;
      final toggledAttendance = !originalAttendance;

      final updatedEvents = Map<String, bool>.from(prefs.eventPreferences);
      updatedEvents['attendance'] = toggledAttendance;
      final updated = prefs.copyWith(eventPreferences: updatedEvents);

      final patchResult = await privacyRepo.updatePreferences(updated);
      expect(patchResult.shareAttendanceData, toggledAttendance);

      // 3. Reload from server and confirm persistence
      final reloaded = await privacyRepo.getPreferences();
      expect(reloaded.shareAttendanceData, toggledAttendance);

      // Revert back
      updatedEvents['attendance'] = originalAttendance;
      await privacyRepo.updatePreferences(prefs.copyWith(eventPreferences: updatedEvents));
      print('Privacy Preferences: PATCH & Persistence Verified 100%');
    });

    // ─────────────────────────────────────────────────────────
    // Screen 3: Communication Preferences Runtime Verification
    // ─────────────────────────────────────────────────────────
    test('3. Communication Preferences: GET preferences -> 200, POST preferences -> 200, persistence verified', () async {
      // 1. GET /api/notifications/preferences
      final commPrefs = await commRepo.getPreferences();
      expect(commPrefs.id, isNotEmpty);
      print('Communication Preferences: push=${commPrefs.pushEnabled}, email=${commPrefs.emailEnabled}, whatsapp=${commPrefs.whatsappEnabled}');

      // 2. POST /api/notifications/preferences
      final originalPush = commPrefs.pushEnabled;
      final toggledPush = !originalPush;
      final updated = commPrefs.copyWith(pushEnabled: toggledPush);

      final postResult = await commRepo.updatePreferences(updated);
      expect(postResult.pushEnabled, toggledPush);

      // 3. Reload from server and confirm persistence
      final reloaded = await commRepo.getPreferences();
      expect(reloaded.pushEnabled, toggledPush);

      // Revert back
      await commRepo.updatePreferences(commPrefs.copyWith(pushEnabled: originalPush));
      print('Communication Preferences: POST & Persistence Verified 100%');
    });
  });
}
