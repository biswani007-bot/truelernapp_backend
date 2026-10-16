import '../../data/models/auth_response.dart';

/// Sealed hierarchy representing all UI authentication states.
sealed class AuthState {
  const AuthState();
}

/// Initial uninitialized state.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Active during app startup while checking local secure session.
final class AuthCheckingSession extends AuthState {
  const AuthCheckingSession();
}

/// Active while a login request is in-flight.
final class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

/// Destination routes determined by authoritative backend state.
enum AuthDestination {
  passwordSetup,
  onboardingChild,
  onboardingInterests,
  demoBookingDashboard,
  studentDashboard,
}

/// Active when genuine authentication has succeeded against the backend.
final class Authenticated extends AuthState {
  const Authenticated({
    required this.accessToken,
    this.user,
    this.requiresPasswordSetup = false,
    this.requiresOnboarding = false,
    this.destination = AuthDestination.studentDashboard,
    this.resolvedTargetDestination = AuthDestination.studentDashboard,
    this.demoData,
  });

  final String accessToken;
  final UserDto? user;
  final bool requiresPasswordSetup;
  final bool requiresOnboarding;
  final AuthDestination destination;
  final AuthDestination resolvedTargetDestination;
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

/// Active when unauthenticated and ready for user input on Login.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Active when a login request fails (HTTP 500, 401, timeout, or network drop).
final class AuthFailureState extends AuthState {
  const AuthFailureState({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}
