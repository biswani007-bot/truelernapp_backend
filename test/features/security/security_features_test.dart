import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:truelearn/core/router/route_paths.dart';
import 'package:truelearn/features/dashboard/data/models/security_activity_dto.dart';
import 'package:truelearn/features/dashboard/data/models/user_device_dto.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/security_activity_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/user_devices_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/parent_preferences_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/security_activity_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/user_device_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/parent_preferences_repository.dart';
import 'package:truelearn/features/dashboard/domain/repositories/security_activity_repository.dart';
import 'package:truelearn/features/dashboard/domain/repositories/user_devices_repository.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_communication_preferences_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_login_devices_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_recent_security_activity_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_security_privacy_screen.dart';

class MockUserDevicesRepository implements UserDevicesRepository {
  List<UserDeviceEntity> devicesList = [];
  bool getDevicesCalled = false;
  bool revokeDeviceCalled = false;
  String? lastRevokedSessionId;
  bool shouldThrowRevokeError = false;

  @override
  Future<List<UserDeviceEntity>> getDevices() async {
    getDevicesCalled = true;
    return List.from(devicesList);
  }

  @override
  Future<bool> revokeDevice(String sessionId) async {
    revokeDeviceCalled = true;
    lastRevokedSessionId = sessionId;
    if (shouldThrowRevokeError) {
      throw Exception('Network error revoking device');
    }
    devicesList.removeWhere((d) => d.sessionId == sessionId);
    return true;
  }
}

class MockSecurityActivityRepository implements SecurityActivityRepository {
  List<SecurityActivityEntity> activitiesList = [];
  bool getActivityLogsCalled = false;
  bool shouldThrowError = false;

  @override
  Future<List<SecurityActivityEntity>> getActivityLogs() async {
    getActivityLogsCalled = true;
    if (shouldThrowError) {
      throw Exception('Failed to load activity');
    }
    return List.from(activitiesList);
  }
}

class MockParentPreferencesRepository implements ParentPreferencesRepository {
  ParentPreferencesEntity currentPreferences = const ParentPreferencesEntity(
    id: 'pref-mock-1',
    channelPreferences: {
      'email': true,
      'push': true,
      'whatsapp': true,
      'sms': false,
    },
    eventPreferences: {
      'attendance': true,
      'assignment': true,
      'reports': true,
      'admissions': true,
    },
    muteAll: false,
    digestEnabled: false,
    language: 'en',
    timezone: 'UTC',
  );
  bool getPreferencesCalled = false;
  bool updatePreferencesCalled = false;
  ParentPreferencesEntity? lastUpdatedPreferences;
  bool shouldThrowUpdateError = false;

  @override
  Future<ParentPreferencesEntity> getPreferences() async {
    getPreferencesCalled = true;
    return currentPreferences;
  }

  @override
  Future<ParentPreferencesEntity> updatePreferences(
    ParentPreferencesEntity prefs,
  ) async {
    updatePreferencesCalled = true;
    lastUpdatedPreferences = prefs;
    if (shouldThrowUpdateError) {
      throw Exception('Failed to persist preferences');
    }
    currentPreferences = prefs;
    return currentPreferences;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserDevicesRepository mockDevicesRepo;
  late MockSecurityActivityRepository mockSecurityRepo;
  late MockParentPreferencesRepository mockPreferencesRepo;

  setUp(() {
    mockDevicesRepo = MockUserDevicesRepository();
    mockSecurityRepo = MockSecurityActivityRepository();
    mockPreferencesRepo = MockParentPreferencesRepository();
  });

  Widget wrapWithScope({required Widget child}) {
    return ProviderScope(
      overrides: [
        userDevicesRepositoryProvider.overrideWithValue(mockDevicesRepo),
        securityActivityRepositoryProvider.overrideWithValue(mockSecurityRepo),
        parentPreferencesRepositoryProvider.overrideWithValue(
          mockPreferencesRepo,
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Feature 1: Login & Devices (GET & DELETE /api/auth/devices)', () {
    test('UserDeviceDto deserialization and toEntity mapping', () {
      final json = {
        '_id': 'device-obj-1',
        'sessionId': 'sess-123',
        'deviceName': 'Chrome on Windows 11',
        'platform': 'Web Browser',
        'appVersion': '1.0.0',
        'createdAt': '2026-10-10T08:00:00.000Z',
        'lastSeenAt': '2026-10-13T10:00:00.000Z',
        'isRevoked': false,
        'isCurrent': true,
      };

      final dto = UserDeviceDto.fromJson(json);
      expect(dto.id, 'device-obj-1');
      expect(dto.sessionId, 'sess-123');
      expect(dto.deviceName, 'Chrome on Windows 11');
      expect(dto.platform, 'Web Browser');
      expect(dto.isCurrent, isTrue);
      expect(dto.isRevoked, isFalse);

      final domain = dto.toEntity();
      expect(domain.sessionId, 'sess-123');
      expect(domain.isCurrent, isTrue);
      expect(domain.displayName, 'Chrome on Windows 11');
      expect(domain.lastActiveFormatted, 'Active Now');
    });

    test('UserDeviceEntity display and relative time formatting', () {
      final androidDevice = UserDeviceEntity(
        id: '1',
        sessionId: 's1',
        deviceName: 'Samsung Galaxy S24',
        platform: 'Android 14',
        createdAt: DateTime.now(),
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isRevoked: false,
        isCurrent: false,
      );
      expect(androidDevice.displayName, 'Samsung Galaxy S24');
      expect(androidDevice.displaySubtitle, 'Android 14');
      expect(androidDevice.lastActiveFormatted, contains('5m ago'));
    });

    testWidgets('ParentLoginDevicesScreen renders current and other devices', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockDevicesRepo.devicesList = [
        UserDeviceEntity(
          id: 'dev-1',
          sessionId: 'current-session-id',
          deviceName: 'Pixel 8 (This Device)',
          platform: 'Android 14',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          lastSeenAt: DateTime.now(),
          isRevoked: false,
          isCurrent: true,
        ),
        UserDeviceEntity(
          id: 'dev-2',
          sessionId: 'other-session-id',
          deviceName: 'Chrome on Windows',
          platform: 'Windows Desktop',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 3)),
          isRevoked: false,
          isCurrent: false,
        ),
      ];

      await tester.pumpWidget(
        wrapWithScope(child: const ParentLoginDevicesScreen()),
      );
      await tester.pumpAndSettle();

      expect(mockDevicesRepo.getDevicesCalled, isTrue);
      expect(find.text('Login & Devices'), findsOneWidget);
      expect(find.text('CURRENT DEVICE'), findsOneWidget);
      expect(find.text('Active Now'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Pixel 8'),
        ),
        findsOneWidget,
      );
      expect(find.text('OTHER ACTIVE DEVICES'), findsOneWidget);
      expect(find.text('Chrome on Windows'), findsOneWidget);
      expect(
        find.byKey(const Key('revoke_device_other-session-id')),
        findsOneWidget,
      );
    });

    testWidgets('Revoke session triggers confirmation dialog and API call', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockDevicesRepo.devicesList = [
        UserDeviceEntity(
          id: 'dev-1',
          sessionId: 'current-sess',
          deviceName: 'Current Phone',
          platform: 'Android',
          createdAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
          isRevoked: false,
          isCurrent: true,
        ),
        UserDeviceEntity(
          id: 'dev-2',
          sessionId: 'target-revoke-session',
          deviceName: 'Safari on iPad',
          platform: 'iOS',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 1)),
          isRevoked: false,
          isCurrent: false,
        ),
      ];

      await tester.pumpWidget(
        wrapWithScope(child: const ParentLoginDevicesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safari on iPad'), findsOneWidget);

      // Tap Revoke icon button
      await tester.tap(
        find.byKey(const Key('revoke_device_target-revoke-session')),
      );
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Sign Out Device?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap confirm Sign Out in dialog
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify API was called with the session ID
      expect(mockDevicesRepo.revokeDeviceCalled, isTrue);
      expect(mockDevicesRepo.lastRevokedSessionId, 'target-revoke-session');

      // Verify the revoked device is removed from the UI
      expect(find.text('Safari on iPad'), findsNothing);
      expect(
        find.text('No other devices are currently signed into your account.'),
        findsOneWidget,
      );
    });
  });

  group('Feature 2: Recent Security Activity (GET /api/auth/activity)', () {
    test('SecurityActivityDto deserialization and mapping', () {
      final json = {
        '_id': 'act-99',
        'action': 'LOGIN_SUCCESS',
        'entity': 'AUTH',
        'entityId': 'user-1',
        'ip': '10.0.0.1',
        'userAgent': 'Dart/3.0 (Flutter)',
        'timestamp': '2026-10-13T09:30:00.000Z',
        'metadata': {'status': 'ok'},
      };

      final dto = SecurityActivityDto.fromJson(json);
      expect(dto.id, 'act-99');
      expect(dto.action, 'LOGIN_SUCCESS');
      expect(dto.ip, '10.0.0.1');

      final domain = dto.toEntity();
      expect(domain.displayTitle, 'Account Login');
      expect(domain.iconData, Icons.login_rounded);
    });

    testWidgets('ParentRecentSecurityActivityScreen displays audit logs & filters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockSecurityRepo.activitiesList = [
        SecurityActivityEntity(
          id: 'log-1',
          action: 'LOGIN',
          entity: 'auth',
          ip: '203.0.113.195',
          userAgent: 'Chrome / Windows',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        SecurityActivityEntity(
          id: 'log-2',
          action: 'SESSION_REVOKED',
          entity: 'session',
          ip: '203.0.113.200',
          userAgent: 'Flutter Mobile App',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        wrapWithScope(child: const ParentRecentSecurityActivityScreen()),
      );
      await tester.pumpAndSettle();

      expect(mockSecurityRepo.getActivityLogsCalled, isTrue);
      expect(find.text('Recent Security Activity'), findsOneWidget);
      expect(find.text('Account Login'), findsOneWidget);
      expect(find.text('Session Revocation'), findsOneWidget);

      // Test Logins filter chip
      await tester.tap(find.text('Logins'));
      await tester.pumpAndSettle();

      expect(find.text('Account Login'), findsOneWidget);
      expect(find.text('Session Revocation'), findsNothing);

      // Test Devices filter chip
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();

      expect(find.text('Account Login'), findsNothing);
      expect(find.text('Session Revocation'), findsOneWidget);

      // Test All filter chip resets
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Account Login'), findsOneWidget);
      expect(find.text('Session Revocation'), findsOneWidget);
    });
  });

  group(
    'Feature 3: Communication Preferences (GET & PATCH /api/parent/preferences)',
    () {
      test('ParentPreferencesEntity helpers and copyWith', () {
        const entity = ParentPreferencesEntity(
          id: 'test-id',
          channelPreferences: {
            'email': true,
            'sms': false,
            'push': true,
            'whatsapp': false,
          },
          eventPreferences: {
            'attendance': true,
            'assignment': false,
            'reports': true,
            'admissions': false,
          },
          muteAll: false,
          digestEnabled: true,
          language: 'en',
          timezone: 'Asia/Kolkata',
        );

        expect(entity.pushEnabled, isTrue);
        expect(entity.emailEnabled, isTrue);
        expect(entity.whatsappEnabled, isFalse);
        expect(entity.smsEnabled, isFalse);
        expect(entity.attendanceAlerts, isTrue);
        expect(entity.assignmentAlerts, isFalse);
        expect(entity.reportsAlerts, isTrue);
        expect(entity.admissionsAlerts, isFalse);
        expect(entity.digestEnabled, isTrue);
        expect(entity.muteAll, isFalse);

        final updated = entity.copyWith(muteAll: true);
        expect(updated.muteAll, isTrue);
        expect(updated.pushEnabled, isTrue);
      });

      testWidgets(
        'Toggling channels in ParentCommunicationPreferencesScreen invokes updatePreferences',
        (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            wrapWithScope(child: const ParentCommunicationPreferencesScreen()),
          );
          await tester.pumpAndSettle();

          expect(mockPreferencesRepo.getPreferencesCalled, isTrue);
          expect(find.text('Communication Preferences'), findsOneWidget);
          expect(find.text('Push Notifications'), findsOneWidget);
          expect(find.text('Email Notifications'), findsOneWidget);
          expect(find.text('WhatsApp Notifications'), findsOneWidget);
          expect(find.text('SMS Notifications'), findsOneWidget);
          expect(find.text('Class & Attendance Reminders'), findsOneWidget);
          expect(find.text('Assignments & Homework'), findsOneWidget);

          // Find switch for Push Notifications and tap it
          final switches = find.byType(Switch);
          expect(switches, findsWidgets);

          // Tap Push switch (index 2)
          await tester.tap(switches.at(2));
          await tester.pumpAndSettle();

          expect(mockPreferencesRepo.updatePreferencesCalled, isTrue);
          expect(
            mockPreferencesRepo.lastUpdatedPreferences?.pushEnabled,
            isFalse,
          );
        },
      );

      testWidgets('Mute All toggle updates muteAll field', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithScope(child: const ParentCommunicationPreferencesScreen()),
        );
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        // Switch index 0 is "Mute All Notifications"
        await tester.tap(switches.at(0));
        await tester.pumpAndSettle();

        expect(mockPreferencesRepo.updatePreferencesCalled, isTrue);
        expect(mockPreferencesRepo.lastUpdatedPreferences?.muteAll, isTrue);
      });

      testWidgets('Daily Digest toggle updates digestEnabled field', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithScope(child: const ParentCommunicationPreferencesScreen()),
        );
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        // Switch index 1 is "Daily Digest Mode"
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();

        expect(mockPreferencesRepo.updatePreferencesCalled, isTrue);
        expect(
          mockPreferencesRepo.lastUpdatedPreferences?.digestEnabled,
          isTrue,
        );
      });
    });

  group('Navigation from ParentSecurityPrivacyScreen', () {
    testWidgets(
      'Tapping sub-features triggers navigation to corresponding routes',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final router = GoRouter(
          initialLocation: AppRoutePaths.parentSecurityPrivacy,
          routes: [
            GoRoute(
              path: AppRoutePaths.parentSecurityPrivacy,
              builder: (context, state) => const ParentSecurityPrivacyScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.parentLoginDevices,
              builder: (context, state) => const ParentLoginDevicesScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.parentRecentSecurityActivity,
              builder:
                  (context, state) =>
                      const ParentRecentSecurityActivityScreen(),
            ),
            GoRoute(
              path: AppRoutePaths.parentCommunicationPreferences,
              builder:
                  (context, state) =>
                      const ParentCommunicationPreferencesScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userDevicesRepositoryProvider.overrideWithValue(mockDevicesRepo),
              securityActivityRepositoryProvider.overrideWithValue(
                mockSecurityRepo,
              ),
              parentPreferencesRepositoryProvider.overrideWithValue(
                mockPreferencesRepo,
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Security & Privacy'), findsOneWidget);
        expect(find.text('Login & Devices'), findsOneWidget);
        expect(find.text('Recent Security Activity'), findsOneWidget);
        expect(find.text('Communication Preferences'), findsOneWidget);

        // Tap Login & Devices
        await tester.tap(find.text('Login & Devices'));
        await tester.pumpAndSettle();
        expect(find.byType(ParentLoginDevicesScreen), findsOneWidget);

        // Tap back
        await tester.tap(find.byKey(const Key('btn_back_login_devices')));
        await tester.pumpAndSettle();

        // Tap Recent Security Activity
        await tester.tap(find.text('Recent Security Activity'));
        await tester.pumpAndSettle();
        expect(find.byType(ParentRecentSecurityActivityScreen), findsOneWidget);

        // Tap back
        await tester.tap(find.byKey(const Key('btn_back_sub_app_bar')));
        await tester.pumpAndSettle();

        // Tap Communication Preferences
        await tester.tap(find.text('Communication Preferences'));
        await tester.pumpAndSettle();
        expect(
          find.byType(ParentCommunicationPreferencesScreen),
          findsOneWidget,
        );
      },
    );
  });
}
