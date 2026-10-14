import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/dashboard/data/repositories/notification_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_preferences_repository_impl.dart';
import 'package:truelearn/features/dashboard/data/repositories/parent_profile_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/notification_preferences_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/parent_preferences_entity.dart';

class MockApiClient extends Fake implements ApiClient {
  dynamic getResponse;
  dynamic patchResponse;
  dynamic postResponse;
  bool shouldThrowGet = false;
  bool shouldThrowPatch = false;
  bool shouldThrowPost = false;

  String? lastGetPath;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;
  String? lastPostPath;
  dynamic lastPostData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    if (shouldThrowGet) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network failure',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: getResponse as T?,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPatchPath = path;
    lastPatchData = data as Map<String, dynamic>?;
    if (shouldThrowPatch) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Patch failure',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: patchResponse as T?,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    if (shouldThrowPost) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Post failure',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: postResponse as T?,
    );
  }
}

void main() {
  group('Security & Privacy Repositories Tests', () {
    late MockApiClient mockApiClient;
    late ParentProfileRepositoryImpl profileRepo;
    late ParentPreferencesRepositoryImpl privacyRepo;
    late NotificationPreferencesRepositoryImpl commRepo;

    setUp(() {
      mockApiClient = MockApiClient();
      profileRepo = ParentProfileRepositoryImpl(apiClient: mockApiClient);
      privacyRepo = ParentPreferencesRepositoryImpl(apiClient: mockApiClient);
      commRepo = NotificationPreferencesRepositoryImpl(
        apiClient: mockApiClient,
      );
    });

    // ──────────────────────────────────────────────
    // 1. Personal Information Tests
    // ──────────────────────────────────────────────
    test('ParentProfile: response mapping & profile loading', () async {
      mockApiClient.getResponse = {
        'success': true,
        'message': 'Parent profile retrieved successfully',
        'data': {
          'profile': {
            'id': '6a87de6461b5b8570e7a7ed9',
            'parentId': 'PAR-1001',
            'firstName': 'Marcus',
            'lastName': 'Mercer',
            'email': 'parent@truelern.com',
            'phone': '+1-555-0199',
            'address': '400 Castro Street',
            'city': 'San Francisco',
            'state': 'CA',
            'country': 'USA',
            'postalCode': '94114',
            'status': 'active',
            'occupation': 'Senior Systems Architect',
            'organization': 'Global Cloud Labs',
            'designation': 'Principal Director',
          },
        },
      };

      final profile = await profileRepo.getParentProfile();

      expect(mockApiClient.lastGetPath, '/parent/profile');
      expect(profile.firstName, 'Marcus');
      expect(profile.lastName, 'Mercer');
      expect(profile.fullName, 'Marcus Mercer');
      expect(profile.email, 'parent@truelern.com');
      expect(profile.phone, '+1-555-0199');
      expect(profile.parentId, 'PAR-1001');
      expect(profile.fullAddress, contains('400 Castro Street'));
    });

    test('ParentProfile: update profile sends PATCH payload', () async {
      mockApiClient.patchResponse = {
        'success': true,
        'message': 'Parent profile updated successfully',
        'data': {
          'profile': {
            'id': '6a87de6461b5b8570e7a7ed9',
            'parentId': 'PAR-1001',
            'firstName': 'Marcus',
            'lastName': 'Wayne',
            'email': 'parent@truelern.com',
            'phone': '+1-555-9999',
            'address': '100 Market St',
            'city': 'San Francisco',
            'state': 'CA',
            'country': 'USA',
            'postalCode': '94114',
            'status': 'active',
          },
        },
      };

      final updated = await profileRepo.updateParentProfile(
        firstName: 'Marcus',
        lastName: 'Wayne',
        phone: '+1-555-9999',
        address: '100 Market St',
      );

      expect(mockApiClient.lastPatchPath, '/parent/profile');
      expect(mockApiClient.lastPatchData?['firstName'], 'Marcus');
      expect(mockApiClient.lastPatchData?['lastName'], 'Wayne');
      expect(mockApiClient.lastPatchData?['phone'], '+1-555-9999');
      expect(updated.lastName, 'Wayne');
    });

    test('ParentProfile: API failure throws exception', () async {
      mockApiClient.shouldThrowGet = true;
      expect(
        () => profileRepo.getParentProfile(),
        throwsA(isA<DioException>()),
      );
    });

    // ──────────────────────────────────────────────
    // 2. Privacy Preferences Tests
    // ──────────────────────────────────────────────
    test('PrivacyPreferences: response mapping & preference loading', () async {
      mockApiClient.getResponse = {
        'success': true,
        'message': 'Parent preferences retrieved successfully',
        'data': {
          'id': 'pref-67890',
          'channelPreferences': {'email': true, 'push': true},
          'eventPreferences': {'attendance': true, 'reports': false},
          'muteAll': false,
          'digestEnabled': false,
          'language': 'en',
          'timezone': 'UTC',
        },
      };

      final prefs = await privacyRepo.getPreferences();

      expect(mockApiClient.lastGetPath, '/parent/preferences');
      expect(prefs.id, 'pref-67890');
      expect(prefs.shareAttendanceData, isTrue);
      expect(prefs.shareLearningProgress, isFalse);
    });

    test('PrivacyPreferences: preference update sends PATCH', () async {
      mockApiClient.patchResponse = {
        'success': true,
        'message': 'Parent preferences updated successfully',
        'data': {
          'id': 'pref-67890',
          'channelPreferences': {'email': true, 'push': true},
          'eventPreferences': {'attendance': false, 'reports': true},
          'muteAll': false,
          'digestEnabled': false,
          'language': 'en',
          'timezone': 'UTC',
        },
      };

      const updated = ParentPreferencesEntity(
        id: 'pref-67890',
        channelPreferences: {'email': true, 'push': true},
        eventPreferences: {'attendance': false, 'reports': true},
        muteAll: false,
        digestEnabled: false,
        language: 'en',
        timezone: 'UTC',
      );

      final result = await privacyRepo.updatePreferences(updated);

      expect(mockApiClient.lastPatchPath, '/parent/preferences');
      expect(
        mockApiClient.lastPatchData?['eventPreferences']['attendance'],
        isFalse,
      );
      expect(result.shareAttendanceData, isFalse);
      expect(result.shareLearningProgress, isTrue);
    });

    test('PrivacyPreferences: API failure throws exception', () async {
      mockApiClient.shouldThrowPatch = true;
      const dummy = ParentPreferencesEntity(
        id: '1',
        channelPreferences: {},
        eventPreferences: {},
        muteAll: false,
        digestEnabled: false,
        language: 'en',
        timezone: 'UTC',
      );
      expect(
        () => privacyRepo.updatePreferences(dummy),
        throwsA(isA<DioException>()),
      );
    });

    // ──────────────────────────────────────────────
    // 3. Communication Preferences Tests
    // ──────────────────────────────────────────────
    test(
      'CommunicationPreferences: response mapping & preference loading',
      () async {
        mockApiClient.getResponse = {
          'success': true,
          'message': 'Notification preferences fetched',
          'data': {
            '_id': 'pref-12345',
            'user': 'user-67890',
            'channelPreferences': {
              'email': true,
              'sms': false,
              'whatsapp': true,
              'push': true,
              'in-app': true,
            },
            'eventPreferences': {
              'admissions': true,
              'enrollment': false,
              'attendance': true,
              'assignment': true,
              'assessment': false,
              'certificate': true,
              'finance': false,
              'reports': true,
            },
            'muteAll': false,
            'digestEnabled': true,
          },
        };

        final prefs = await commRepo.getPreferences();

        expect(mockApiClient.lastGetPath, '/notifications/preferences');
        expect(prefs.id, 'pref-12345');
        expect(prefs.emailEnabled, isTrue);
        expect(prefs.smsEnabled, isFalse);
        expect(prefs.whatsappEnabled, isTrue);
        expect(prefs.pushEnabled, isTrue);
        expect(prefs.attendanceAlerts, isTrue);
      },
    );

    test('CommunicationPreferences: update sends POST payload', () async {
      mockApiClient.postResponse = {
        'success': true,
        'message': 'Notification preferences updated',
        'data': {
          '_id': 'pref-12345',
          'user': 'user-67890',
          'channelPreferences': {
            'email': false,
            'sms': true,
            'whatsapp': false,
            'push': true,
            'in-app': true,
          },
          'eventPreferences': {
            'attendance': false,
            'reports': false,
            'assignment': true,
            'admissions': true,
            'enrollment': true,
            'assessment': true,
            'certificate': true,
            'finance': true,
          },
          'muteAll': false,
          'digestEnabled': false,
        },
      };

      const entity = NotificationPreferencesEntity(
        id: 'pref-12345',
        userId: 'user-67890',
        emailEnabled: false,
        smsEnabled: true,
        whatsappEnabled: false,
        pushEnabled: true,
        inAppEnabled: true,
        admissionsAlerts: true,
        enrollmentAlerts: true,
        attendanceAlerts: false,
        assignmentAlerts: true,
        assessmentAlerts: true,
        certificateAlerts: true,
        financeAlerts: true,
        reportsAlerts: false,
        muteAll: false,
        digestEnabled: false,
      );

      final result = await commRepo.updatePreferences(entity);

      expect(mockApiClient.lastPostPath, '/notifications/preferences');
      final payload = mockApiClient.lastPostData as Map<String, dynamic>;
      expect(payload['channelPreferences']['email'], isFalse);
      expect(result.emailEnabled, isFalse);
    });

    test('CommunicationPreferences: API failure throws exception', () async {
      mockApiClient.shouldThrowPost = true;
      const entity = NotificationPreferencesEntity(
        id: '1',
        userId: '1',
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
      expect(
        () => commRepo.updatePreferences(entity),
        throwsA(isA<DioException>()),
      );
    });
  });
}
