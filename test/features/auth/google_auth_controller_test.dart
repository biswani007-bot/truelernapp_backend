import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/error/failures.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/data/services/google_sign_in_service.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';

class MockGoogleSignInService implements GoogleSignInService {
  String? mockToken;
  bool signOutCalled = false;

  @override
  Future<String?> getIdToken() async => mockToken;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class MockAuthRepository implements AuthRepository {
  String? persistedToken;
  Failure? failureToThrow;
  bool signInWithGoogleCalled = false;
  bool setupPasswordCalled = false;
  bool dismissPromptCalled = false;
  bool promptStatusShowPrompt = false;

  Map<String, dynamic> mockParentContext = {};

  @override
  Future<String?> checkPersistedSession() async => persistedToken;

  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async {
    signInWithGoogleCalled = true;
    if (failureToThrow != null) throw failureToThrow!;
    return const AuthResponse(
      accessToken: 'google_jwt_token',
      user: UserDto(
        id: 'user_google_123',
        name: 'Google Parent',
        email: 'parent@google.com',
        role: 'parent',
      ),
    );
  }

  @override
  Future<PasswordPromptStatus> getPasswordPromptStatus() async =>
      PasswordPromptStatus(
        showPrompt: promptStatusShowPrompt,
        hasPassword: !promptStatusShowPrompt,
        dontAskAgain: false,
        cooldownActive: false,
      );

  @override
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    setupPasswordCalled = true;
    if (failureToThrow != null) throw failureToThrow!;
    return true;
  }

  @override
  Future<bool> dismissPasswordPrompt({required String action}) async {
    dismissPromptCalled = true;
    if (failureToThrow != null) throw failureToThrow!;
    return true;
  }

  Map<String, dynamic>? mockDemoData;
  Map<String, dynamic>? mockParentStatusData;
  Map<String, dynamic>? mockChildDashboardData = {
    'enrolledBatches': [
      {'id': 'batch_1', 'batchName': 'Batch Alpha'},
    ],
  };

  Map<String, dynamic>? mockChildDemoData;
  Map<String, dynamic>? mockParentLevelDemoData;

  @override
  Future<Map<String, dynamic>?> getParentDemo({String? studentId}) async {
    if (studentId != null && studentId.isNotEmpty) {
      return mockChildDemoData ?? mockDemoData;
    }
    return mockParentLevelDemoData ?? mockDemoData;
  }

  @override
  Future<Map<String, dynamic>?> getParentStatus({String? studentId}) async =>
      mockParentStatusData;

  @override
  Future<Map<String, dynamic>?> getChildDashboard(
    String childStudentId,
  ) async => mockChildDashboardData;

  @override
  Future<Map<String, dynamic>> getCurrentParentContext() async =>
      mockParentContext;

  @override
  Future<void> logout() async {
    persistedToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAuthRepository mockRepo;
  late MockGoogleSignInService mockGoogleService;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockRepo = MockAuthRepository();
    mockGoogleService = MockGoogleSignInService();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        googleSignInServiceProvider.overrideWithValue(mockGoogleService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Google Sign-In & Password Setup Tests', () {
    test(
      'signInWithGoogle returns null when user cancels account picker',
      () async {
        mockGoogleService.mockToken = null;

        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(result, isNull);
        expect(container.read(authControllerProvider), isA<Unauthenticated>());
        expect(mockRepo.signInWithGoogleCalled, isFalse);
      },
    );

    test('signInWithGoogle completes authentication when ID token returned without password setup required', () async {
      mockGoogleService.mockToken = 'valid_google_id_token_123';
      mockRepo.promptStatusShowPrompt = false;

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.requiresPasswordSetup, isFalse);
      expect(mockRepo.signInWithGoogleCalled, isTrue);

      final state = container.read(authControllerProvider);
      expect(state, isA<Authenticated>());
      final auth = state as Authenticated;
      expect(auth.accessToken, 'google_jwt_token');
      expect(auth.user?.email, 'parent@google.com');
    });

    test('signInWithGoogle flags requiresPasswordSetup when backend prompt is active', () async {
      mockGoogleService.mockToken = 'valid_google_id_token_123';
      mockRepo.promptStatusShowPrompt = true;

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.requiresPasswordSetup, isTrue);

      final state = container.read(authControllerProvider);
      expect(state, isA<Authenticated>());
    });

    test('signInWithGoogle detects existing user with enrolled children and bypasses onboarding', () async {
      mockGoogleService.mockToken = 'valid_google_id_token_123';
      mockRepo.promptStatusShowPrompt = false;
      mockRepo.mockParentContext = {
        'status': 'success',
        'data': {
          'user': {
            'id': 'user_123',
            'name': 'Existing Parent',
            'email': 'existing@truelern.com',
            'role': 'parent',
          },
          'parent': {'id': 'par_123', 'status': 'active'},
          'children': [
            {'studentId': 'stu_123', 'name': 'Child One'},
          ],
        },
      };

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.requiresPasswordSetup, isFalse);
      expect(result.requiresOnboarding, isFalse);

      final state = container.read(authControllerProvider) as Authenticated;
      expect(state.requiresOnboarding, isFalse);
      expect(state.requiresPasswordSetup, isFalse);
    });

    test('signInWithGoogle detects new user without enrolled children and sets requiresOnboarding', () async {
      mockGoogleService.mockToken = 'valid_google_id_token_123';
      mockRepo.promptStatusShowPrompt = true;
      mockRepo.mockParentContext = {
        'status': 'success',
        'data': {
          'user': {
            'id': 'user_new',
            'name': 'New Parent',
            'email': 'new@truelern.com',
            'role': 'parent',
          },
          'children': [],
        },
      };

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.requiresPasswordSetup, isTrue);
      expect(result.requiresOnboarding, isTrue);

      final state = container.read(authControllerProvider) as Authenticated;
      expect(state.requiresOnboarding, isTrue);
      expect(state.requiresPasswordSetup, isTrue);

      // Verify markPasswordSetupCompleted transitions requiresPasswordSetup to false
      container
          .read(authControllerProvider.notifier)
          .markPasswordSetupCompleted();
      final updated = container.read(authControllerProvider) as Authenticated;
      expect(updated.requiresPasswordSetup, isFalse);
      expect(updated.requiresOnboarding, isTrue);
    });

    test('Scenario B: signInWithGoogle detects existing student and bypasses onboarding even if children array is absent or empty', () async {
      mockGoogleService.mockToken = 'valid_google_id_token_123';
      mockRepo.promptStatusShowPrompt = false;
      mockRepo.mockParentContext = {
        'status': 'success',
        'data': {
          'user': {
            'id': 'student_123',
            'name': 'Existing Student',
            'email': 'student@truelern.com',
            'role': 'student',
          },
          'children': [],
        },
      };

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.requiresPasswordSetup, isFalse);
      expect(result.requiresOnboarding, isFalse);

      final state = container.read(authControllerProvider) as Authenticated;
      expect(state.requiresOnboarding, isFalse);
      expect(state.requiresPasswordSetup, isFalse);
    });

    test('Scenario C: signInWithGoogle flags requiresPasswordSetup for existing parent with enrolled children, keeping requiresOnboarding false', () async {
      mockGoogleService.mockToken = 'valid_google_id_token_123';
      mockRepo.promptStatusShowPrompt = true;
      mockRepo.mockParentContext = {
        'status': 'success',
        'data': {
          'user': {
            'id': 'parent_existing_456',
            'name': 'Existing Parent 2',
            'email': 'existing2@truelern.com',
            'role': 'parent',
          },
          'children': [
            {'studentId': 'child_existing_789', 'name': 'Active Ward'},
          ],
        },
      };

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.requiresPasswordSetup, isTrue);
      expect(result.requiresOnboarding, isFalse);

      final state = container.read(authControllerProvider) as Authenticated;
      expect(state.requiresPasswordSetup, isTrue);
      expect(state.requiresOnboarding, isFalse);

      // Verify that completing password setup retains requiresOnboarding = false
      container
          .read(authControllerProvider.notifier)
          .markPasswordSetupCompleted();
      final updated = container.read(authControllerProvider) as Authenticated;
      expect(updated.requiresPasswordSetup, isFalse);
      expect(updated.requiresOnboarding, isFalse);
    });

    test(
      'setupPassword invokes repository setupPassword successfully',
      () async {
        final success = await container
            .read(authControllerProvider.notifier)
            .setupPassword(
              password: 'StrongP@ss123',
              confirmPassword: 'StrongP@ss123',
            );

        expect(success, isTrue);
        expect(mockRepo.setupPasswordCalled, isTrue);
      },
    );

    test(
      'dismissPasswordPrompt invokes repository dismissPasswordPrompt',
      () async {
        final success = await container
            .read(authControllerProvider.notifier)
            .dismissPasswordPrompt(action: 'maybe_later');

        expect(success, isTrue);
        expect(mockRepo.dismissPromptCalled, isTrue);
      },
    );

    test('signInWithGoogle handles unregistered Google email (HTTP 404 NOT_FOUND) correctly without unauthorized navigation', () async {
      mockGoogleService.mockToken = 'valid_google_token_unregistered';
      mockRepo.failureToThrow = const ServerFailure(
        'No TrueLern account found for this Google email. Please register first or contact your school administrator.',
        statusCode: 404,
        errorCode: 'NOT_FOUND',
      );

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(
        result.failureType,
        equals(GoogleAuthFailureType.unregisteredUser),
      );
      expect(result.statusCode, equals(404));
      expect(result.message, contains('No TrueLern account found'));

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthFailureState>());
      expect((state as AuthFailureState).statusCode, equals(404));
    });

    test('signInWithGoogle handles invalid Google token (HTTP 401 AUTH_TOKEN_INVALID)', () async {
      mockGoogleService.mockToken = 'corrupt_token';
      mockRepo.failureToThrow = const AuthFailure(
        'Google verification failed: Invalid Compact JWS',
        401,
        'AUTH_TOKEN_INVALID',
      );

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.failureType, equals(GoogleAuthFailureType.invalidToken));
      expect(result.statusCode, equals(401));
    });

    test('signInWithGoogle handles expired Google token (HTTP 401 AUTH_TOKEN_EXPIRED)', () async {
      mockGoogleService.mockToken = 'expired_token';
      mockRepo.failureToThrow = const AuthFailure(
        'Token has expired',
        401,
        'AUTH_TOKEN_EXPIRED',
      );

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.failureType, equals(GoogleAuthFailureType.tokenExpired));
      expect(result.statusCode, equals(401));
    });

    test('signInWithGoogle handles disabled or unauthorized account (HTTP 403 FORBIDDEN)', () async {
      mockGoogleService.mockToken = 'disabled_token';
      mockRepo.failureToThrow = const AuthFailure(
        'Account is disabled or non-parent role',
        403,
        'FORBIDDEN',
      );

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.failureType, equals(GoogleAuthFailureType.accountDisabled));
      expect(result.statusCode, equals(403));
    });

    test(
      'signInWithGoogle handles account conflict (HTTP 409 CONFLICT)',
      () async {
        mockGoogleService.mockToken = 'conflict_token';
        mockRepo.failureToThrow = const ServerFailure(
          'TrueLern account already linked to different Google account',
          statusCode: 409,
          errorCode: 'CONFLICT',
        );

        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(result, isNotNull);
        expect(result!.success, isFalse);
        expect(
          result.failureType,
          equals(GoogleAuthFailureType.accountConflict),
        );
        expect(result.statusCode, equals(409));
      },
    );

    test('signInWithGoogle handles network failure gracefully', () async {
      mockGoogleService.mockToken = 'valid_token';
      mockRepo.failureToThrow = const NetworkFailure();

      final result = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.failureType, equals(GoogleAuthFailureType.networkError));
    });

    test(
      'signInWithGoogle handles server failure (HTTP 500) gracefully',
      () async {
        mockGoogleService.mockToken = 'valid_token';
        mockRepo.failureToThrow = const ServerFailure(
          'Internal server error',
          statusCode: 500,
        );

        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(result, isNotNull);
        expect(result!.success, isFalse);
        expect(result.failureType, equals(GoogleAuthFailureType.serverError));
      },
    );

    group('Authoritative Post-Login Destination Resolution Tests', () {
      test('Same Google Account with scheduled demo resolves to demoBookingDashboard and restores after process restart', () async {
        mockGoogleService.mockToken = 'valid_google_id_token_yahoo';
        mockRepo.promptStatusShowPrompt = false;
        mockRepo.mockParentContext = {
          'status': 'success',
          'data': {
            'user': {
              'id': 'parent_yahoo_1',
              'name': 'Yahoo Parent',
              'email': 'yahoo@google.com',
              'role': 'parent',
            },
            'children': [
              {'studentId': 'student_yahoo_6', 'firstName': 'Yahoo', 'age': 6},
            ],
          },
        };
        // Child is NOT enrolled in any course batches
        mockRepo.mockChildDashboardData = {'enrolledBatches': []};
        // Active demo session scheduled
        mockRepo.mockDemoData = {
          'leadId': 'lead_yahoo_123',
          'status': 'demo_scheduled',
          'interestedCourse': 'Junior Foundation, Ages 6 to 10',
        };

        // 1. Initial Google Sign-In
        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(result, isNotNull);
        expect(result!.success, isTrue);
        expect(
          result.destination,
          equals(AuthDestination.demoBookingDashboard),
        );
        expect(result.requiresOnboarding, isFalse);
        expect(result.demoData?['leadId'], equals('lead_yahoo_123'));

        // 2. Simulated process kill & restart: new container with persisted token
        final restartRepo = MockAuthRepository()
          ..persistedToken = 'google_jwt_token'
          ..promptStatusShowPrompt = false
          ..mockParentContext = mockRepo.mockParentContext
          ..mockChildDashboardData = {'enrolledBatches': []}
          ..mockDemoData = mockRepo.mockDemoData;

        final restartContainer = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(restartRepo)],
        );
        addTearDown(restartContainer.dispose);

        final restored = await restartContainer
            .read(authControllerProvider.notifier)
            .checkSession();

        expect(restored, isTrue);
        final restoredState =
            restartContainer.read(authControllerProvider) as Authenticated;
        expect(
          restoredState.destination,
          equals(AuthDestination.demoBookingDashboard),
        );
        expect(restoredState.demoData?['leadId'], equals('lead_yahoo_123'));
      });

      test('Child-scoped demo query returns null (unlinked lead.student), but parent-level demo query finds scheduled demo lead -> resolves to demoBookingDashboard', () async {
        mockGoogleService.mockToken = 'valid_google_id_token_fallback';
        mockRepo.promptStatusShowPrompt = false;
        mockRepo.mockParentContext = {
          'status': 'success',
          'data': {
            'user': {
              'id': 'parent_yahoo_789',
              'name': 'Yahoo Parent',
              'email': 'yahoo@google.com',
              'role': 'parent',
            },
            'children': [
              {'studentId': 'student_yahoo_6', 'firstName': 'Yahoo', 'age': 6},
            ],
          },
        };
        // Not enrolled
        mockRepo.mockChildDashboardData = {'enrolledBatches': []};
        // Child-scoped query returns null (lead.student was not set yet)
        mockRepo.mockChildDemoData = null;
        // Parent-level query finds the lead by email
        mockRepo.mockParentLevelDemoData = {
          'leadId': 'LED-1034',
          'status': 'demo_scheduled',
          'interestedCourse': 'Junior Foundation, Ages 6 to 10',
        };

        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(result, isNotNull);
        expect(result!.success, isTrue);
        expect(
          result.destination,
          equals(AuthDestination.demoBookingDashboard),
        );
        expect(result.resolvedLeadId, equals('LED-1034'));
        expect(
          result.resolvedCourseName,
          equals('Junior Foundation, Ages 6 to 10'),
        );
      });

      test('Parent with child where server returns STATE_2 (schedule_demo) resolves to demoBookingDashboard', () async {
        mockGoogleService.mockToken = 'valid_token';
        mockRepo.promptStatusShowPrompt = false;
        mockRepo.mockParentContext = {
          'status': 'success',
          'data': {
            'user': {'id': 'parent_state2', 'role': 'parent'},
            'children': [
              {'studentId': 'child_state2', 'name': 'Charlie'},
            ],
          },
        };
        mockRepo.mockChildDashboardData = {'enrolledBatches': []};
        mockRepo.mockDemoData = {};
        mockRepo.mockParentStatusData = {
          'state': 'STATE_2',
          'description': 'Child exists, no active demo',
          'action': 'schedule_demo',
        };

        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(
          result!.destination,
          equals(AuthDestination.demoBookingDashboard),
        );
        expect(result.requiresOnboarding, isFalse);
      });

      test('Parent with unenrolled child and no demo scheduled resumes onboardingInterests', () async {
        mockGoogleService.mockToken = 'valid_token';
        mockRepo.promptStatusShowPrompt = false;
        mockRepo.mockParentContext = {
          'status': 'success',
          'data': {
            'user': {'id': 'parent_step1', 'role': 'parent'},
            'children': [
              {'studentId': 'child_step1', 'name': 'Bob'},
            ],
          },
        };
        mockRepo.mockChildDashboardData = {'enrolledBatches': []};
        mockRepo.mockDemoData = null; // No demo booked yet

        final result = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(
          result!.destination,
          equals(AuthDestination.onboardingInterests),
        );
        expect(result.requiresOnboarding, isTrue);
      });

      test(
        'Parent with enrolled child goes directly to studentDashboard',
        () async {
          mockGoogleService.mockToken = 'valid_token';
          mockRepo.promptStatusShowPrompt = false;
          mockRepo.mockParentContext = {
            'status': 'success',
            'data': {
              'user': {'id': 'parent_enrolled', 'role': 'parent'},
              'children': [
                {'studentId': 'child_enrolled', 'name': 'Alice'},
              ],
            },
          };
          mockRepo.mockChildDashboardData = {
            'enrolledBatches': [
              {'id': 'batch_robotics_1', 'batchName': 'Robotics Grade 4'},
            ],
          };

          final result = await container
              .read(authControllerProvider.notifier)
              .signInWithGoogle();

          expect(result!.destination, equals(AuthDestination.studentDashboard));
          expect(result.requiresOnboarding, isFalse);
        },
      );
    });
  });
}
