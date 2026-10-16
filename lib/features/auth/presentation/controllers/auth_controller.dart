import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../assessments/presentation/controllers/assessments_controller.dart';
import '../../../assignments/presentation/controllers/assignment_submission_controller.dart';
import '../../../assignments/presentation/controllers/assignments_controller.dart';
import '../../../certificates/presentation/controllers/certificates_controller.dart';
import '../../../classes/presentation/controllers/class_summary_controller.dart';
import '../../../classes/presentation/controllers/classes_controller.dart';
import '../../../counselor/presentation/controllers/counselor_controller.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../dashboard/presentation/controllers/demo_slots_controller.dart';
import '../../../dashboard/presentation/controllers/login_methods_controller.dart';
import '../../../dashboard/presentation/controllers/notification_preferences_controller.dart';
import '../../../dashboard/presentation/controllers/parent_preferences_controller.dart';
import '../../../dashboard/presentation/controllers/parent_profile_controller.dart';
import '../../../dashboard/presentation/controllers/security_activity_controller.dart';
import '../../../dashboard/presentation/controllers/user_devices_controller.dart';
import '../../../messages/presentation/controllers/messages_controller.dart';
import '../../../notifications/presentation/controllers/parent_notifications_controller.dart';
import '../../../progress/presentation/controllers/progress_controller.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/login_request.dart';
import '../../data/models/password_prompt_status.dart';
import '../../data/services/google_sign_in_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';

/// Failure categories for Google Sign-In distinguishing cancellation, invalid tokens,
/// unregistered users, disabled accounts, conflict, and server/network errors.
enum GoogleAuthFailureType {
  none,
  cancelled,
  unregisteredUser, // HTTP 404 / NOT_FOUND
  invalidToken, // HTTP 401 / AUTH_TOKEN_INVALID
  tokenExpired, // HTTP 401 / AUTH_TOKEN_EXPIRED
  accountDisabled, // HTTP 403 / FORBIDDEN
  accountConflict, // HTTP 409 / CONFLICT
  networkError, // NetworkFailure / TimeoutFailure
  serverError, // HTTP 500+
  unknownError,
}

/// Result returned after Google Sign-In containing navigation guidance.
/// Result returned after Google Sign-In containing navigation guidance.
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.success,
    required this.requiresPasswordSetup,
    this.requiresOnboarding = false,
    this.destination = AuthDestination.studentDashboard,
    this.failureType = GoogleAuthFailureType.none,
    this.message,
    this.statusCode,
    this.errorCode,
    this.demoData,
  });

  final bool success;
  final bool requiresPasswordSetup;
  final bool requiresOnboarding;
  final AuthDestination destination;
  final GoogleAuthFailureType failureType;
  final String? message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? demoData;

  /// Authoritative lead or demo identifier extracted across all backend JSON representations.
  String? get resolvedLeadId {
    if (demoData == null) return null;
    final rawLead = demoData?['lead'];
    final rawDemo = demoData?['demoSession'];
    return demoData?['leadId']?.toString() ??
        demoData?['demoId']?.toString() ??
        demoData?['id']?.toString() ??
        demoData?['_id']?.toString() ??
        (rawLead is Map
            ? (rawLead['_id']?.toString() ?? rawLead['leadNumber']?.toString())
            : null) ??
        (rawDemo is Map ? rawDemo['_id']?.toString() : null);
  }

  /// Authoritative course name extracted across all backend JSON representations.
  String? get resolvedCourseName {
    if (demoData == null) return null;
    final rawLead = demoData?['lead'];
    final rawDemo = demoData?['demoSession'];
    return demoData?['interestedCourse']?.toString() ??
        demoData?['courseName']?.toString() ??
        (rawLead is Map ? rawLead['interestedCourse']?.toString() : null) ??
        (rawDemo is Map && rawDemo['course'] is Map
            ? rawDemo['course']['name']?.toString()
            : null);
  }
}

/// Helper model encapsulating resolved authoritative navigation state.
class AuthoritativeAuthResolution {
  const AuthoritativeAuthResolution({
    required this.destination,
    required this.resolvedTargetDestination,
    required this.requiresPasswordSetup,
    required this.requiresOnboarding,
    this.user,
    this.demoData,
  });

  final AuthDestination destination;
  final AuthDestination resolvedTargetDestination;
  final bool requiresPasswordSetup;
  final bool requiresOnboarding;
  final UserDto? user;
  final Map<String, dynamic>? demoData;

  /// Authoritative lead or demo identifier extracted across all backend JSON representations.
  String? get resolvedLeadId {
    if (demoData == null) return null;
    final rawLead = demoData?['lead'];
    final rawDemo = demoData?['demoSession'];
    return demoData?['leadId']?.toString() ??
        demoData?['demoId']?.toString() ??
        demoData?['id']?.toString() ??
        demoData?['_id']?.toString() ??
        (rawLead is Map
            ? (rawLead['_id']?.toString() ?? rawLead['leadNumber']?.toString())
            : null) ??
        (rawDemo is Map ? rawDemo['_id']?.toString() : null);
  }

  /// Authoritative course name extracted across all backend JSON representations.
  String? get resolvedCourseName {
    if (demoData == null) return null;
    final rawLead = demoData?['lead'];
    final rawDemo = demoData?['demoSession'];
    return demoData?['interestedCourse']?.toString() ??
        demoData?['courseName']?.toString() ??
        (rawLead is Map ? rawLead['interestedCourse']?.toString() : null) ??
        (rawDemo is Map && rawDemo['course'] is Map
            ? rawDemo['course']['name']?.toString()
            : null);
  }
}

/// Controller managing authentication state and login operations.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  GoogleSignInService get _googleSignInService =>
      ref.read(googleSignInServiceProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  /// Checks if a valid session exists in secure storage.
  /// Resolves authoritative backend destination to resume exact user screen state.
  Future<bool> checkSession() async {
    state = const AuthCheckingSession();
    try {
      final token = await _repository.checkPersistedSession();
      if (token != null && token.isNotEmpty) {
        final decoded = decodeJwt(token);
        final role = decoded?['role'] as String?;
        final userId = decoded?['userId'] as String? ?? '';
        final fallbackUser = UserDto(id: userId, role: role);

        try {
          final resolution = await resolveAuthoritativeDestination(
            fallbackUser: fallbackUser,
          );
          state = Authenticated(
            accessToken: token,
            user: resolution.user ?? fallbackUser,
            requiresPasswordSetup: resolution.requiresPasswordSetup,
            requiresOnboarding: resolution.requiresOnboarding,
            destination: resolution.destination,
            resolvedTargetDestination: resolution.resolvedTargetDestination,
            demoData: resolution.demoData,
          );
          return true;
        } catch (error) {
          final failure = ErrorHandler.handle(error);
          if (failure.statusCode == 401) {
            clearAuthenticatedSession();
            await _repository.logout();
            state = const Unauthenticated();
            return false;
          }
          state = AuthFailureState(
            message: failure.message,
            statusCode: failure.statusCode,
          );
          return false;
        }
      }
    } catch (_) {
      // Storage failure defaults to unauthenticated
    }

    state = const Unauthenticated();
    return false;
  }

  static Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return json.decode(payload) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Authoritatively determines the post-login destination based on live backend state:
  /// 1. Password prompt requirement (/parent/security/password-prompt-status)
  /// 2. Role (Student -> Student Dashboard)
  /// 3. Children list (/auth/mobile/me):
  ///    - Empty -> Step 1 (OnboardingChildScreen)
  ///    - Exists -> checks child course enrollments (/parent/children/{id}/dashboard & /parent/status):
  ///      - If enrolled -> Student Dashboard
  ///      - If not enrolled -> checks demo booking status (/parent/demo):
  ///        - If demo scheduled/requested -> DemoBookingDashboardScreen
  ///        - If no demo found -> Step 2 (OnboardingInterestsScreen)
  Future<AuthoritativeAuthResolution> resolveAuthoritativeDestination({
    UserDto? fallbackUser,
  }) async {
    // 1. Check whether backend requires password setup for this account
    bool requiresPasswordSetup = false;
    try {
      final promptStatus = await _repository.getPasswordPromptStatus();
      requiresPasswordSetup = promptStatus.showPrompt;
    } catch (_) {
      requiresPasswordSetup = false;
    }

    // 2. Retrieve authenticated account context via GET /api/auth/mobile/me
    final meContext = await _repository.getCurrentParentContext();
    UserDto? resolvedUser = fallbackUser;
    final data = meContext['data'];
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        resolvedUser = UserDto.fromJson(data['user'] as Map<String, dynamic>);
      }
    }

    final role = (resolvedUser?.role ?? fallbackUser?.role ?? '').toLowerCase();
    if (role == 'student') {
      return AuthoritativeAuthResolution(
        destination: requiresPasswordSetup
            ? AuthDestination.passwordSetup
            : AuthDestination.studentDashboard,
        resolvedTargetDestination: AuthDestination.studentDashboard,
        requiresPasswordSetup: requiresPasswordSetup,
        requiresOnboarding: false,
        user: resolvedUser,
      );
    }

    // 3. Parent: linked children evaluation
    final children = (data is Map<String, dynamic>) ? data['children'] : null;
    if (children is! List || children.isEmpty) {
      // Defensive check: if children array is not present in /auth/mobile/me,
      // verify if parent has an existing demo lead registered at parent level.
      Map<String, dynamic>? parentDemo;
      try {
        parentDemo = await _repository.getParentDemo();
      } catch (_) {
        parentDemo = null;
      }
      if (parentDemo != null && parentDemo.isNotEmpty) {
        return AuthoritativeAuthResolution(
          destination: requiresPasswordSetup
              ? AuthDestination.passwordSetup
              : AuthDestination.demoBookingDashboard,
          resolvedTargetDestination: AuthDestination.demoBookingDashboard,
          requiresPasswordSetup: requiresPasswordSetup,
          requiresOnboarding: false,
          user: resolvedUser,
          demoData: parentDemo,
        );
      }

      return AuthoritativeAuthResolution(
        destination: requiresPasswordSetup
            ? AuthDestination.passwordSetup
            : AuthDestination.onboardingChild,
        resolvedTargetDestination: AuthDestination.onboardingChild,
        requiresPasswordSetup: requiresPasswordSetup,
        requiresOnboarding: true,
        user: resolvedUser,
      );
    }

    // 4. Parent with linked children:
    // Determine whether the child is an actively enrolled student or a demo applicant.
    String? firstChildStudentId;
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        final id = child['studentId']?.toString() ?? child['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          firstChildStudentId = id;
          break;
        }
      }
    }

    bool isEnrolled = false;
    if (firstChildStudentId != null) {
      try {
        final dashboardData = await _repository.getChildDashboard(
          firstChildStudentId,
        );
        if (dashboardData != null) {
          final batches = dashboardData['enrolledBatches'];
          if (batches is List && batches.isNotEmpty) {
            isEnrolled = true;
          }
        }
      } catch (_) {
        // Fall through to status check
      }
    }

    // Secondary verification via /parent/status state machine if available
    try {
      var parentStatus = await _repository.getParentStatus(
        studentId: firstChildStudentId,
      );
      parentStatus ??= await _repository.getParentStatus();
      if (parentStatus != null) {
        final stateCode = parentStatus['state']?.toString().toUpperCase();
        final action = parentStatus['action']?.toString().toLowerCase();
        if (stateCode == 'STATE_5' || action == 'dashboard') {
          isEnrolled = true;
        }
      }
    } catch (_) {
      // Ignore secondary error
    }

    if (isEnrolled) {
      return AuthoritativeAuthResolution(
        destination: requiresPasswordSetup
            ? AuthDestination.passwordSetup
            : AuthDestination.studentDashboard,
        resolvedTargetDestination: AuthDestination.studentDashboard,
        requiresPasswordSetup: requiresPasswordSetup,
        requiresOnboarding: false,
        user: resolvedUser,
      );
    }

    // 5. Child is not enrolled in courses. Check for scheduled demo session or lead
    // A. Query child-scoped demo first
    Map<String, dynamic>? demoData;
    if (firstChildStudentId != null) {
      try {
        demoData = await _repository.getParentDemo(
          studentId: firstChildStudentId,
        );
      } catch (_) {
        demoData = null;
      }
    }

    // B. Fallback to parent-level demo query without studentId
    // Onboarding Step 4 submits leads via /api/public/lead matching by parent email.
    // The Lead document in MongoDB has lead.email == parent.email, but lead.student
    // may not yet be linked to the child's ObjectId. Parent-level GET /api/parent/demo
    // searches by parent.email and authoritatively finds scheduled demos/leads.
    if (demoData == null || demoData.isEmpty) {
      try {
        demoData = await _repository.getParentDemo();
      } catch (_) {
        demoData = null;
      }
    }

    // C. Fallback to /parent/status state machine if demoData is still empty
    if (demoData == null || demoData.isEmpty) {
      try {
        var parentStatus = await _repository.getParentStatus(
          studentId: firstChildStudentId,
        );
        final childStateCode = parentStatus?['state']?.toString().toUpperCase();
        if (parentStatus == null || childStateCode == 'STATE_2') {
          final parentLevelStatus = await _repository.getParentStatus();
          if (parentLevelStatus != null) {
            parentStatus = parentLevelStatus;
          }
        }

        if (parentStatus != null) {
          final stateCode = parentStatus['state']?.toString().toUpperCase();
          final action = parentStatus['action']?.toString().toLowerCase();
          if (stateCode == 'STATE_2' ||
              stateCode == 'STATE_3' ||
              stateCode == 'STATE_4' ||
              action == 'schedule_demo' ||
              action == 'join_demo' ||
              action == 'payment') {
            demoData = parentStatus;
          }
        }
      } catch (_) {
        // Status check fallback
      }
    }

    if (demoData != null && demoData.isNotEmpty) {
      return AuthoritativeAuthResolution(
        destination: requiresPasswordSetup
            ? AuthDestination.passwordSetup
            : AuthDestination.demoBookingDashboard,
        resolvedTargetDestination: AuthDestination.demoBookingDashboard,
        requiresPasswordSetup: requiresPasswordSetup,
        requiresOnboarding: false,
        user: resolvedUser,
        demoData: demoData,
      );
    }

    // 6. Child exists in DB (from Step 1) but parent hasn't submitted a demo request (Step 2)
    return AuthoritativeAuthResolution(
      destination: requiresPasswordSetup
          ? AuthDestination.passwordSetup
          : AuthDestination.onboardingInterests,
      resolvedTargetDestination: AuthDestination.onboardingInterests,
      requiresPasswordSetup: requiresPasswordSetup,
      requiresOnboarding: true,
      user: resolvedUser,
    );
  }

  /// Submits credentials to POST /api/auth/login.
  ///
  /// Strictly adheres to TrueLern security rules:
  /// - Only enters [Authenticated] upon receiving HTTP 200 with valid tokens from server.
  /// - On server error (e.g. HTTP 500) or invalid credentials, enters [AuthFailureState] and stays on login.
  Future<bool> login({required String email, required String password}) async {
    clearAuthenticatedSession();
    state = const AuthSubmitting();
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );

      final resolution = await resolveAuthoritativeDestination(
        fallbackUser: response.user,
      );

      state = Authenticated(
        accessToken: response.accessToken,
        user: resolution.user ?? response.user,
        requiresPasswordSetup: resolution.requiresPasswordSetup,
        requiresOnboarding: resolution.requiresOnboarding,
        destination: resolution.destination,
        resolvedTargetDestination: resolution.resolvedTargetDestination,
        demoData: resolution.demoData,
      );
      return true;
    } catch (error) {
      final failure = ErrorHandler.handle(error);
      state = AuthFailureState(
        message: failure.message,
        statusCode: failure.statusCode,
      );
      return false;
    }
  }

  /// Initiates native Google Sign-In with Play Services, exchanges verified ID token with
  /// TrueLern backend at POST /api/auth/mobile/google, retrieves account context via
  /// GET /api/auth/mobile/me, and evaluates password setup requirements and demo/onboarding status.
  Future<GoogleAuthResult?> signInWithGoogle() async {
    clearAuthenticatedSession();
    state = const AuthSubmitting();
    try {
      final idToken = await _googleSignInService.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        // User cancelled the native Google account picker dialog
        state = const Unauthenticated();
        return null;
      }

      // Exchange ID token with TrueLern server
      final authResponse = await _repository.signInWithGoogle(idToken);

      // Resolve authoritative destination from server
      final resolution = await resolveAuthoritativeDestination(
        fallbackUser: authResponse.user,
      );

      state = Authenticated(
        accessToken: authResponse.accessToken,
        user: resolution.user ?? authResponse.user,
        requiresPasswordSetup: resolution.requiresPasswordSetup,
        requiresOnboarding: resolution.requiresOnboarding,
        destination: resolution.destination,
        resolvedTargetDestination: resolution.resolvedTargetDestination,
        demoData: resolution.demoData,
      );

      return GoogleAuthResult(
        success: true,
        requiresPasswordSetup: resolution.requiresPasswordSetup,
        requiresOnboarding: resolution.requiresOnboarding,
        destination: resolution.destination,
        demoData: resolution.demoData,
      );
    } catch (error) {
      final failure = ErrorHandler.handle(error);
      final statusCode = failure.statusCode;
      final errorCode = failure.errorCode;
      final rawMsg = failure.message;

      GoogleAuthFailureType failureType = GoogleAuthFailureType.unknownError;
      String userMessage = rawMsg;

      if (failure is NetworkFailure || failure is TimeoutFailure) {
        failureType = GoogleAuthFailureType.networkError;
        userMessage = 'Network connection unavailable. Please check your internet connection.';
      } else if (statusCode == 404 ||
          errorCode == 'NOT_FOUND' ||
          rawMsg.contains('No TrueLern account found') ||
          rawMsg.toLowerCase().contains('not registered')) {
        failureType = GoogleAuthFailureType.unregisteredUser;
        userMessage = rawMsg;
      } else if (statusCode == 401) {
        if (errorCode == 'AUTH_TOKEN_EXPIRED' ||
            rawMsg.toLowerCase().contains('expired')) {
          failureType = GoogleAuthFailureType.tokenExpired;
          userMessage =
              'Your Google session has expired. Please sign in again.';
        } else {
          failureType = GoogleAuthFailureType.invalidToken;
          userMessage =
              'Google verification failed. Please try signing in again.';
        }
      } else if (statusCode == 403 || errorCode == 'FORBIDDEN') {
        failureType = GoogleAuthFailureType.accountDisabled;
        userMessage = 'This account is disabled or unauthorized for Parent access. Please contact your school administrator.';
      } else if (statusCode == 409 || errorCode == 'CONFLICT') {
        failureType = GoogleAuthFailureType.accountConflict;
        userMessage = 'This TrueLern account is linked to another login method. Please sign in using email and password.';
      } else if ((statusCode ?? 0) >= 500) {
        failureType = GoogleAuthFailureType.serverError;
        userMessage = 'TrueLern service is temporarily unavailable. Please try again later.';
      }

      state = AuthFailureState(message: userMessage, statusCode: statusCode);

      return GoogleAuthResult(
        success: false,
        requiresPasswordSetup: false,
        requiresOnboarding: false,
        destination: AuthDestination.studentDashboard,
        failureType: failureType,
        message: userMessage,
        statusCode: statusCode,
        errorCode: errorCode,
      );
    }
  }

  /// Marks password setup completed on active authenticated state.
  void markPasswordSetupCompleted() {
    final current = state;
    if (current is Authenticated) {
      state = Authenticated(
        accessToken: current.accessToken,
        user: current.user,
        requiresPasswordSetup: false,
        requiresOnboarding: current.requiresOnboarding,
        destination: current.resolvedTargetDestination,
        resolvedTargetDestination: current.resolvedTargetDestination,
        demoData: current.demoData,
      );
    }
  }

  /// Submits new password for OAuth account via POST /api/parent/security/setup-password.
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    try {
      return await _repository.setupPassword(
        password: password,
        confirmPassword: confirmPassword,
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Dismisses password prompt via POST /api/parent/security/dismiss-password-prompt.
  Future<bool> dismissPasswordPrompt({required String action}) async {
    try {
      return await _repository.dismissPasswordPrompt(action: action);
    } catch (_) {
      return false;
    }
  }

  /// Checks password prompt eligibility directly.
  Future<PasswordPromptStatus?> getPasswordPromptStatus() async {
    try {
      return await _repository.getPasswordPromptStatus();
    } catch (_) {
      return null;
    }
  }

  /// Clears any transient failure state back to [Unauthenticated].
  void resetError() {
    if (state is AuthFailureState) {
      state = const Unauthenticated();
    }
  }

  /// Sets a frontend-only demo session for UI prototype flows without backend/network calls.
  void setDemoSession() {
    clearAuthenticatedSession();
    state = const Authenticated(
      accessToken: 'static_demo_token_prototype',
      destination: AuthDestination.studentDashboard,
      resolvedTargetDestination: AuthDestination.studentDashboard,
    );
  }

  /// Updates the cached user profile name and email in the authenticated state.
  void updateUserProfile({String? name, String? email}) {
    final current = state;
    if (current is Authenticated) {
      final currentUser = current.user;
      final updatedUser = UserDto(
        id: currentUser?.id ?? '',
        name: name ?? currentUser?.name,
        email: email ?? currentUser?.email,
        role: currentUser?.role,
      );
      state = Authenticated(
        accessToken: current.accessToken,
        user: updatedUser,
        requiresPasswordSetup: current.requiresPasswordSetup,
        requiresOnboarding: current.requiresOnboarding,
        destination: current.destination,
        resolvedTargetDestination: current.resolvedTargetDestination,
        demoData: current.demoData,
      );
    }
  }

  /// Completely resets in-memory controllers, active child, cached metrics,
  /// and invalidates account-scoped Riverpod providers to guarantee total
  /// isolation between authenticated sessions (e.g., Account A vs Account B).
  void clearAuthenticatedSession() {
    // 1. Explicitly reset all stateful account-scoped controllers
    ref.read(childrenControllerProvider.notifier).reset();
    ref.read(dashboardControllerProvider.notifier).reset();
    ref.read(parentProfileControllerProvider.notifier).reset();
    ref.read(classesControllerProvider.notifier).reset();
    ref.read(classSummaryControllerProvider.notifier).reset();
    ref.read(assignmentsControllerProvider.notifier).reset();
    ref.read(assignmentSubmissionControllerProvider.notifier).reset();
    ref.read(progressControllerProvider.notifier).reset();
    ref.read(assessmentsControllerProvider.notifier).reset();
    ref.read(certificatesControllerProvider.notifier).reset();
    ref.read(counselorControllerProvider.notifier).reset();
    ref.read(messagesControllerProvider.notifier).reset();
    ref.read(parentNotificationsControllerProvider.notifier).reset();
    ref.read(userDevicesControllerProvider.notifier).reset();
    ref.read(securityActivityControllerProvider.notifier).reset();
    ref.read(parentPreferencesControllerProvider.notifier).reset();
    ref.read(notificationPreferencesControllerProvider.notifier).reset();
    ref.read(loginMethodsControllerProvider.notifier).reset();
    ref.read(demoSlotsControllerProvider.notifier).reset();

    // 2. Invalidate child dashboard metrics family provider to clear cache
    ref.invalidate(childDashboardMetricsProvider);
  }

  /// Terminates session and clears persisted tokens and all account-specific in-memory state.
  Future<void> logout() async {
    clearAuthenticatedSession();
    try {
      await _googleSignInService.signOut();
    } catch (_) {}
    try {
      await _repository.logout();
    } catch (_) {}
    try {
      await _storage.clearAuthSession();
    } catch (_) {}
    state = const Unauthenticated();
  }
}

/// Global provider for [AuthController].
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
