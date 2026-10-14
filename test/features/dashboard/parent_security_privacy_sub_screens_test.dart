import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truelearn/features/dashboard/data/repositories/notification_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_profile_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/notification_preferences_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/parent_preferences_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/parent_profile_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/notification_preferences_repository.dart';
import 'package:truelearn/features/dashboard/domain/repositories/parent_preferences_repository.dart';
import 'package:truelearn/features/dashboard/domain/repositories/parent_profile_repository.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_communication_preferences_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_data_privacy_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_personal_info_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_privacy_policy_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_privacy_preferences_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_recent_security_activity_screen.dart';
import 'package:truelearn/features/dashboard/presentation/screens/parent_terms_conditions_screen.dart';

import 'package:truelearn/features/dashboard/data/repositories/security_activity_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/security_activity_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/security_activity_repository.dart';

class MockParentProfileRepository implements ParentProfileRepository {
  ParentProfileEntity profile = const ParentProfileEntity(
    id: 'test-parent-id',
    parentId: 'PAR-1001',
    firstName: 'Marcus',
    middleName: '',
    lastName: 'Mercer',
    email: 'parent@truelern.com',
    phone: '+1-555-0199',
    alternatePhone: '',
    address: '400 Castro Street',
    city: 'San Francisco',
    state: 'CA',
    country: 'USA',
    postalCode: '94114',
    status: 'active',
    occupation: 'Senior Systems Architect',
    organization: 'Global Cloud Labs',
    designation: 'Principal Director',
  );

  bool getProfileCalled = false;
  bool updateProfileCalled = false;

  @override
  Future<ParentProfileEntity> getParentProfile() async {
    getProfileCalled = true;
    return profile;
  }

  @override
  Future<ParentProfileEntity> updateParentProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) async {
    updateProfileCalled = true;
    profile = profile.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
    );
    return profile;
  }
}

class MockSecurityActivityRepository implements SecurityActivityRepository {
  List<SecurityActivityEntity> activities = [
    SecurityActivityEntity(
      id: 'act-1',
      action: 'LOGIN',
      entity: 'auth',
      ip: '192.168.1.1',
      userAgent: 'Android Device',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    SecurityActivityEntity(
      id: 'act-2',
      action: 'SESSION_REVOKED',
      entity: 'session',
      ip: '192.168.1.2',
      userAgent: 'Chrome on macOS',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  bool getActivityLogsCalled = false;

  @override
  Future<List<SecurityActivityEntity>> getActivityLogs() async {
    getActivityLogsCalled = true;
    return activities;
  }
}

class MockParentPreferencesRepository implements ParentPreferencesRepository {
  ParentPreferencesEntity preferences = const ParentPreferencesEntity(
    id: 'pref-67890',
    channelPreferences: {'email': true, 'push': true, 'whatsapp': true, 'sms': false},
    eventPreferences: {'attendance': true, 'reports': true, 'assignment': true, 'admissions': true},
    muteAll: false,
    digestEnabled: false,
    language: 'en',
    timezone: 'UTC',
  );

  bool getPreferencesCalled = false;
  bool updatePreferencesCalled = false;

  @override
  Future<ParentPreferencesEntity> getPreferences() async {
    getPreferencesCalled = true;
    return preferences;
  }

  @override
  Future<ParentPreferencesEntity> updatePreferences(
    ParentPreferencesEntity prefs,
  ) async {
    updatePreferencesCalled = true;
    preferences = prefs;
    return preferences;
  }
}

class MockNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  NotificationPreferencesEntity preferences =
      const NotificationPreferencesEntity(
        id: 'pref-123',
        userId: 'user-123',
        emailEnabled: true,
        smsEnabled: true,
        whatsappEnabled: true,
        pushEnabled: true,
        inAppEnabled: true,
        admissionsAlerts: true,
        enrollmentAlerts: true,
        attendanceAlerts: true,
        assignmentAlerts: true,
        assessmentAlerts: true,
        certificateAlerts: true,
        financeAlerts: true,
        reportsAlerts: true,
        muteAll: false,
        digestEnabled: false,
      );

  bool getPreferencesCalled = false;
  bool updatePreferencesCalled = false;

  @override
  Future<NotificationPreferencesEntity> getPreferences() async {
    getPreferencesCalled = true;
    return preferences;
  }

  @override
  Future<NotificationPreferencesEntity> updatePreferences(
    NotificationPreferencesEntity prefs,
  ) async {
    updatePreferencesCalled = true;
    preferences = prefs;
    return preferences;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Parent Security & Privacy Sub-Screens Suite', () {
    late MockParentProfileRepository mockProfileRepo;
    late MockParentPreferencesRepository mockPrivacyRepo;
    late MockNotificationPreferencesRepository mockPrefRepo;
    late MockSecurityActivityRepository mockSecurityRepo;

    setUp(() {
      mockProfileRepo = MockParentProfileRepository();
      mockPrivacyRepo = MockParentPreferencesRepository();
      mockPrefRepo = MockNotificationPreferencesRepository();
      mockSecurityRepo = MockSecurityActivityRepository();
    });

    Widget wrap(Widget screen) {
      return ProviderScope(
        overrides: [
          parentProfileRepositoryProvider.overrideWithValue(mockProfileRepo),
          parentPreferencesRepositoryProvider.overrideWithValue(
            mockPrivacyRepo,
          ),
          notificationPreferencesRepositoryProvider.overrideWithValue(
            mockPrefRepo,
          ),
          securityActivityRepositoryProvider.overrideWithValue(
            mockSecurityRepo,
          ),
        ],
        child: MaterialApp(home: screen),
      );
    }

    testWidgets(
      '1. ParentRecentSecurityActivityScreen renders and filters work',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrap(const ParentRecentSecurityActivityScreen()),
        );
        await tester.pumpAndSettle();

        expect(mockSecurityRepo.getActivityLogsCalled, isTrue);
        expect(find.text('Recent Security Activity'), findsOneWidget);
        expect(find.text('Account Login'), findsOneWidget);

        // Verify filter chips
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Logins'), findsOneWidget);
        expect(find.text('Devices'), findsOneWidget);
        expect(find.text('Security'), findsOneWidget);

        // Tap on Devices filter chip
        await tester.tap(find.text('Devices'));
        await tester.pumpAndSettle();
        expect(find.text('Session Revocation'), findsOneWidget);
        expect(find.text('Account Login'), findsNothing);
      },
    );

    testWidgets(
      '2. ParentPersonalInfoScreen loads real profile and supports edit',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const ParentPersonalInfoScreen()));
        await tester.pumpAndSettle();

        expect(mockProfileRepo.getProfileCalled, isTrue);
        expect(find.text('Personal Information'), findsOneWidget);
        expect(find.text('Marcus Mercer'), findsWidgets);
        expect(find.text('parent@truelern.com'), findsWidgets);
        expect(find.text('+1-555-0199'), findsWidgets);
        expect(find.text('Update Information'), findsOneWidget);

        // Tap Update Information to trigger bottom sheet
        await tester.tap(find.text('Update Information'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Personal Information'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);

        // Tap Save Changes
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(mockProfileRepo.updateProfileCalled, isTrue);
      },
    );

    testWidgets(
      '3. ParentPrivacyPreferencesScreen loads backend prefs and updates',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const ParentPrivacyPreferencesScreen()));
        await tester.pumpAndSettle();

        expect(mockPrivacyRepo.getPreferencesCalled, isTrue);
        expect(find.text('Privacy Preferences'), findsOneWidget);
        expect(find.text('Profile Visibility'), findsOneWidget);
        expect(find.text('Data Sharing'), findsOneWidget);
        expect(find.text('Analytics & Improvement'), findsOneWidget);

        // Tap "Share learning progress" switch (index 2)
        final switches = find.byType(Switch);
        expect(switches, findsWidgets);

        // Tap the third switch (Share learning progress)
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();

        expect(mockPrivacyRepo.updatePreferencesCalled, isTrue);
      },
    );

    testWidgets(
      '4. ParentCommunicationPreferencesScreen loads backend prefs and updates',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrap(const ParentCommunicationPreferencesScreen()),
        );
        await tester.pumpAndSettle();

        expect(mockPrivacyRepo.getPreferencesCalled, isTrue);
        expect(find.text('Communication Preferences'), findsOneWidget);
        expect(find.text('Push Notifications'), findsOneWidget);
        expect(find.text('Email Notifications'), findsOneWidget);
        expect(find.text('WhatsApp Notifications'), findsOneWidget);

        final switches = find.byType(Switch);
        expect(switches, findsWidgets);

        // Toggle first switch (Mute All)
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        expect(mockPrivacyRepo.updatePreferencesCalled, isTrue);
      },
    );

    testWidgets(
      '5. ParentDataPrivacyScreen renders download and delete actions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const ParentDataPrivacyScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Data & Privacy'), findsOneWidget);
        expect(find.text('Download Your Data'), findsOneWidget);
        expect(find.text('Delete Account'), findsOneWidget);
        expect(find.text('What data is included?'), findsOneWidget);

        // Tap Download Data
        await tester.tap(find.text('Request Data Download'));
        await tester.pumpAndSettle();

        expect(find.text('Request Account Data'), findsOneWidget);
        expect(find.text('Understood'), findsOneWidget);
        await tester.tap(find.text('Understood'));
        await tester.pumpAndSettle();

        // Tap Delete Account
        await tester.tap(find.text('Delete My Account'));
        await tester.pumpAndSettle();

        expect(find.text('Delete TrueLern Account?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('6. ParentPrivacyPolicyScreen renders document structure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(const ParentPrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('TrueLern Privacy Policy'), findsOneWidget);
      expect(find.text('1. Introduction'), findsOneWidget);
      expect(find.text('2. Information We Collect'), findsOneWidget);
      expect(find.text('3. How We Use Your Information'), findsOneWidget);
    });

    testWidgets('7. ParentTermsConditionsScreen renders document structure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(const ParentTermsConditionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('TrueLern Terms & Conditions'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. Use of Services'), findsOneWidget);
      expect(find.text('3. Account Responsibility'), findsOneWidget);
    });
  });
}
