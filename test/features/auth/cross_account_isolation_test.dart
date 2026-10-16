import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/assessments/presentation/controllers/assessments_controller.dart';
import 'package:truelearn/features/assessments/presentation/controllers/assessments_state.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:truelearn/features/assignments/presentation/controllers/assignments_state.dart';
import 'package:truelearn/features/auth/data/models/auth_response.dart';
import 'package:truelearn/features/auth/data/models/login_request.dart';
import 'package:truelearn/features/auth/data/models/password_prompt_status.dart';
import 'package:truelearn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truelearn/features/auth/data/services/google_sign_in_service.dart';
import 'package:truelearn/features/auth/domain/repositories/auth_repository.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_controller.dart';
import 'package:truelearn/features/auth/presentation/controllers/auth_state.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_controller.dart';
import 'package:truelearn/features/classes/presentation/controllers/classes_state.dart';
import 'package:truelearn/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:truelearn/features/dashboard/domain/entities/child_entity.dart';
import 'package:truelearn/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:truelearn/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/children_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/dashboard_state.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/parent_profile_controller.dart';
import 'package:truelearn/features/dashboard/presentation/controllers/parent_profile_state.dart';
import 'package:truelearn/features/progress/presentation/controllers/progress_controller.dart';
import 'package:truelearn/features/progress/presentation/controllers/progress_state.dart';

class FakeGoogleSignInService extends GoogleSignInService {
  String? idTokenToReturn;
  bool signOutCalled = false;

  @override
  Future<String?> getIdToken() async => idTokenToReturn;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class FakeDashboardRepository implements DashboardRepository {
  List<ChildEntity> linkedChildren = [];
  DashboardEntity? dashboardToReturn;

  @override
  Future<List<ChildEntity>> getLinkedChildren() async => linkedChildren;

  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    return dashboardToReturn ??
        const DashboardEntity(
          attendanceRate: 95.0,
          upcomingClassesCount: 2,
          enrolledBatches: [],
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  String? currentUserId;
  Map<String, dynamic> mockParentContext = {};
  bool logoutCalled = false;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    currentUserId = 'user_account_a';
    return const AuthResponse(
      accessToken: 'token_account_a',
      refreshToken: 'refresh_account_a',
      user: UserDto(
        id: 'user_account_a',
        name: 'Account A Parent',
        email: 'parent_a@example.com',
        role: 'parent',
      ),
    );
  }

  @override
  Future<AuthResponse> signInWithGoogle(String idToken) async {
    currentUserId = 'user_account_b';
    return const AuthResponse(
      accessToken: 'token_account_b',
      refreshToken: 'refresh_account_b',
      user: UserDto(
        id: 'user_account_b',
        name: 'Account B Google Parent',
        email: 'parent_b@gmail.com',
        role: 'parent',
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> getCurrentParentContext() async {
    return mockParentContext.isNotEmpty
        ? mockParentContext
        : {
            'data': {
              'user': {
                'id': currentUserId ?? 'user_1',
                'name': currentUserId == 'user_account_b'
                    ? 'Account B Google Parent'
                    : 'Account A Parent',
                'email': currentUserId == 'user_account_b'
                    ? 'parent_b@gmail.com'
                    : 'parent_a@example.com',
                'role': 'parent',
              },
            },
          };
  }

  @override
  Future<PasswordPromptStatus> getPasswordPromptStatus() async =>
      const PasswordPromptStatus(
        showPrompt: false,
        hasPassword: true,
        dontAskAgain: false,
        cooldownActive: false,
      );

  @override
  Future<void> logout() async {
    logoutCalled = true;
    currentUserId = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Account Data Isolation Regression Tests', () {
    late SecureStorageService storageService;
    late FakeGoogleSignInService fakeGoogleSignIn;
    late FakeAuthRepository fakeAuthRepo;
    late FakeDashboardRepository fakeDashboardRepo;
    late ProviderContainer container;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storageService = FlutterSecureStorageServiceImpl();
      fakeGoogleSignIn = FakeGoogleSignInService();
      fakeAuthRepo = FakeAuthRepository();
      fakeDashboardRepo = FakeDashboardRepository();

      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storageService),
          googleSignInServiceProvider.overrideWithValue(fakeGoogleSignIn),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          dashboardRepositoryProvider.overrideWithValue(fakeDashboardRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Account A login -> Logout -> Account B Google Sign-In guarantees 0 data leakage', () async {
      // 1. Account A logs in with Email/Password
      fakeDashboardRepo.linkedChildren = const [
        ChildEntity(
          studentId: 'child_account_a',
          firstName: 'ChildA',
          lastName: 'Student',
          grade: 'Grade 5',
        ),
      ];

      final loginSuccess = await container
          .read(authControllerProvider.notifier)
          .login(email: 'parent_a@example.com', password: 'password123');

      expect(loginSuccess, isTrue);
      final authA = container.read(authControllerProvider);
      expect(authA, isA<Authenticated>());
      expect((authA as Authenticated).user?.id, equals('user_account_a'));

      // Load Account A children and dashboard
      await container.read(childrenControllerProvider.notifier).loadChildren();
      final childrenStateA = container.read(childrenControllerProvider);
      expect(childrenStateA, isA<ChildrenLoaded>());
      expect(
        (childrenStateA as ChildrenLoaded).activeChildId,
        equals('child_account_a'),
      );
      expect(
        await storageService.getActiveChildId(),
        equals('child_account_a'),
      );

      await container
          .read(dashboardControllerProvider.notifier)
          .loadDashboard(childStudentId: 'child_account_a');
      final dashStateA = container.read(dashboardControllerProvider);
      expect(dashStateA, isA<DashboardLoaded>());
      expect(
        (dashStateA as DashboardLoaded).childStudentId,
        equals('child_account_a'),
      );

      // 2. Account A logs out
      await container.read(authControllerProvider.notifier).logout();

      // Verify that logout completely wipes state across all controllers and storage
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
      expect(
        container.read(childrenControllerProvider),
        isA<ChildrenInitial>(),
      );
      expect(
        container.read(dashboardControllerProvider),
        isA<DashboardInitial>(),
      );
      expect(
        container.read(parentProfileControllerProvider),
        isA<ParentProfileInitial>(),
      );
      expect(container.read(classesControllerProvider), isA<ClassesInitial>());
      expect(
        container.read(assignmentsControllerProvider),
        isA<AssignmentsInitial>(),
      );
      expect(
        container.read(progressControllerProvider),
        isA<ProgressInitial>(),
      );
      expect(
        container.read(assessmentsControllerProvider),
        isA<AssessmentsInitial>(),
      );

      // Storage must be cleared
      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getActiveChildId(), isNull);

      // 3. Account B logs in via Google Sign-In with 0 linked children
      fakeGoogleSignIn.idTokenToReturn = 'google_id_token_account_b';
      fakeDashboardRepo.linkedChildren = []; // Account B has NO children

      final googleResult = await container
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(googleResult, isNotNull);
      expect(googleResult!.success, isTrue);
      final authB = container.read(authControllerProvider);
      expect(authB, isA<Authenticated>());
      expect((authB as Authenticated).user?.id, equals('user_account_b'));
      expect(authB.user?.email, equals('parent_b@gmail.com'));

      // Fetch children under Account B
      await container.read(childrenControllerProvider.notifier).loadChildren();
      final childrenStateB = container.read(childrenControllerProvider);
      expect(childrenStateB, isA<ChildrenLoaded>());
      final loadedB = childrenStateB as ChildrenLoaded;

      // CRITICAL CHECK: Account B's child list is empty, activeChildId is null!
      expect(loadedB.children, isEmpty);
      expect(loadedB.activeChildId, isNull);
      expect(await storageService.getActiveChildId(), isNull);

      // Dashboard for Account B with no child must transition to DashboardNoChild
      await container
          .read(dashboardControllerProvider.notifier)
          .loadDashboard(childStudentId: loadedB.activeChildId);
      final dashStateB = container.read(dashboardControllerProvider);
      expect(dashStateB, isA<DashboardNoChild>());

      // Under no circumstances does Account A's child ID or metrics survive!
      expect(loadedB.activeChildId, isNot(equals('child_account_a')));
    });

    test('Racing requests from Account A are discarded and cannot overwrite Account B', () async {
      fakeDashboardRepo.linkedChildren = const [
        ChildEntity(studentId: 'child_a', firstName: 'ChildA'),
      ];

      await container
          .read(authControllerProvider.notifier)
          .login(email: 'a@example.com', password: 'pw');

      // Start loading children for Account A
      final childrenFuture = container
          .read(childrenControllerProvider.notifier)
          .loadChildren();

      // Immediately logout and switch to Account B
      await container.read(authControllerProvider.notifier).logout();

      fakeGoogleSignIn.idTokenToReturn = 'google_id_token_b';
      fakeDashboardRepo.linkedChildren = const [
        ChildEntity(studentId: 'child_b', firstName: 'ChildB'),
      ];
      await container.read(authControllerProvider.notifier).signInWithGoogle();

      // Await the old Account A request
      await childrenFuture;

      // The state must NOT have Account A's child!
      final state = container.read(childrenControllerProvider);
      if (state is ChildrenLoaded) {
        expect(state.activeChildId, isNot(equals('child_a')));
      } else {
        expect(state, isA<ChildrenInitial>());
      }
    });
  });
}
