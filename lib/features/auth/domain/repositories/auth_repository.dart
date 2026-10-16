import '../../data/models/auth_response.dart';
import '../../data/models/login_request.dart';
import '../../data/models/password_prompt_status.dart';

/// Contract for authentication operations.
abstract interface class AuthRepository {
  /// Submits credentials to POST /api/auth/login.
  /// Throws [Failure] on error.
  Future<AuthResponse> login(LoginRequest request);

  /// Exchanges a verified Google ID Token with TrueLern backend at POST /api/auth/mobile/google.
  Future<AuthResponse> signInWithGoogle(String idToken);

  /// Checks if a persisted access token exists in secure storage.
  Future<String?> checkPersistedSession();

  /// Retrieves password prompt eligibility status from GET /api/parent/security/password-prompt-status.
  Future<PasswordPromptStatus> getPasswordPromptStatus();

  /// Sets up parent account password via POST /api/parent/security/setup-password.
  Future<bool> setupPassword({
    required String password,
    required String confirmPassword,
  });

  /// Dismisses password prompt via POST /api/parent/security/dismiss-password-prompt.
  Future<bool> dismissPasswordPrompt({required String action});

  /// Retrieves current authenticated parent context from GET /api/auth/mobile/me.
  Future<Map<String, dynamic>> getCurrentParentContext();

  /// Retrieves active parent demo or lead status from GET /api/parent/demo.
  Future<Map<String, dynamic>?> getParentDemo({String? studentId});

  /// Retrieves parent state machine status from GET /api/parent/status.
  Future<Map<String, dynamic>?> getParentStatus({String? studentId});

  /// Retrieves child dashboard from GET /api/parent/children/{childStudentId}/dashboard.
  Future<Map<String, dynamic>?> getChildDashboard(String childStudentId);

  /// Clears secure storage and terminates active session.
  Future<void> logout();
}
