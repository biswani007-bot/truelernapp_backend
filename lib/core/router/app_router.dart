import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assignments/presentation/screens/assignment_submission_screen.dart';
import '../../features/assignments/presentation/screens/assignment_submitted_screen.dart';
import '../../features/assignments/presentation/screens/assignments_screen.dart';
import '../../features/assignments/domain/entities/assignment_entity.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/controllers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/password_setup_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_interests_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_account_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_child_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_location_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/classes/domain/entities/class_entity.dart';
import '../../features/classes/domain/entities/class_join_entity.dart';
import '../../features/classes/presentation/screens/class_details_screen.dart';
import '../../features/classes/presentation/screens/class_preview_screen.dart';
import '../../features/classes/presentation/screens/class_summary_screen.dart';
import '../../features/classes/presentation/screens/current_program_screen.dart';
import '../../features/classes/presentation/screens/topic_detail_screen.dart';
import '../../features/classes/presentation/screens/joining_class_screen.dart';
import '../../features/classes/presentation/screens/live_classroom_screen.dart';
import '../../features/classes/presentation/screens/parent_classes_screen.dart';
import '../../features/dashboard/presentation/screens/parent_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/parent_profile_screen.dart';
import '../../features/dashboard/presentation/screens/parent_my_child_screen.dart';
import '../../features/dashboard/presentation/screens/parent_security_privacy_screen.dart';
import '../../features/dashboard/presentation/screens/parent_login_methods_screen.dart';
import '../../features/dashboard/presentation/screens/parent_login_devices_screen.dart';
import '../../features/dashboard/presentation/screens/parent_recent_security_activity_screen.dart';
import '../../features/dashboard/presentation/screens/parent_personal_info_screen.dart';
import '../../features/dashboard/presentation/screens/parent_privacy_preferences_screen.dart';
import '../../features/dashboard/presentation/screens/parent_communication_preferences_screen.dart';
import '../../features/dashboard/presentation/screens/parent_data_privacy_screen.dart';
import '../../features/dashboard/presentation/screens/parent_privacy_policy_screen.dart';
import '../../features/dashboard/presentation/screens/parent_terms_conditions_screen.dart';
import '../../features/dashboard/presentation/screens/parent_invoices_screen.dart';
import '../../features/dashboard/presentation/screens/parent_invoice_detail_screen.dart';
import '../../features/dashboard/presentation/screens/parent_payment_successful_screen.dart';
import '../../features/dashboard/presentation/screens/parent_messages_screen.dart';
import '../../features/dashboard/presentation/screens/parent_notifications_screen.dart';
import '../../features/dashboard/presentation/screens/parent_account_settings_screen.dart';
import '../../features/assessments/domain/entities/assessment_attempt_details_entity.dart';
import '../../features/assessments/presentation/screens/parent_assessments_screen.dart';
import '../../features/assessments/presentation/screens/assessment_runner_screen.dart';
import '../../features/dashboard/presentation/screens/parent_learning_progress_screen.dart';
import '../../features/dashboard/presentation/screens/parent_shell_screen.dart';
import '../../features/dashboard/presentation/screens/demo_booking_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/demo_session_booked_screen.dart';
import '../../features/dashboard/domain/entities/demo_booking_entity.dart';
import '../../features/certificates/presentation/screens/certificates_screen.dart';
import '../../features/counselor/presentation/screens/counselor_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'route_names.dart';

/// Minimal placeholder for authorized-but-not-yet-implemented tabs.
///
/// Explicitly designated as a routing placeholder. NOT a feature screen.
class CoreRouterPlaceholderScreen extends StatelessWidget {
  const CoreRouterPlaceholderScreen({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.foundation_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Notifier coordinating authentication state changes with [GoRouter] redirect triggers.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, next) => notifyListeners(),
    );
  }

  final Ref _ref;

  /// Pure deterministic redirect guard enforcing TrueLern authentication boundaries.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final location = state.matchedLocation;
    final isRoot = location == AppRoutePaths.root;
    final isSplash = location == AppRoutePaths.splash || isRoot;
    final isOnboarding = location == AppRoutePaths.onboarding;
    final isOnboardingFlow = location.startsWith('/onboarding');
    final isLogin = location == AppRoutePaths.login;
    final isAuthenticated = authState is Authenticated;

    // 1. Splash lifecycle: allow initialization to complete uninterrupted
    if (authState is AuthInitial || authState is AuthCheckingSession) {
      return null;
    }

    // 2. Unauthenticated access prevention:
    // If not authenticated and attempting to access any protected area, redirect to /login.
    final isPublicOrOnboarding =
        isLogin || isSplash || isOnboarding || isOnboardingFlow;

    if (!isAuthenticated && !isPublicOrOnboarding) {
      return AppRoutePaths.login;
    }

    // 3. Authenticated bounce:
    // If authenticated user is on /login or /splash or /onboarding (carousel), redirect appropriately.
    // Allow password setup, onboarding flow, and demo dashboard to proceed uninterrupted.
    if (isAuthenticated && (isLogin || isSplash || isOnboarding)) {
      switch (authState.destination) {
        case AuthDestination.passwordSetup:
          return AppRoutePaths.passwordSetup;
        case AuthDestination.onboardingChild:
          return AppRoutePaths.onboardingChild;
        case AuthDestination.onboardingInterests:
          return AppRoutePaths.onboardingInterests;
        case AuthDestination.demoBookingDashboard:
          return AppRoutePaths.demoBookingDashboard;
        case AuthDestination.studentDashboard:
          return AppRoutePaths.parentDashboard;
      }
    }

    return null;
  }
}

/// Provider exposing [RouterNotifier].
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Global root navigator key for full-screen routes outside the persistent shell
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final dashboardNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'dashboardNav',
);
final classesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'classesNav');
final assignmentsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'assignmentsNav',
);
final profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileNav');

/// Global provider for application [GoRouter].
///
/// Uses StatefulShellRoute for the Parent Shell to support persistent
/// bottom navigation with independent branch navigation stacks.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    debugLogDiagnostics: false,
    routes: [
      // 0. Root Route (Clean redirect to splash on startup)
      GoRoute(
        path: AppRoutePaths.root,
        redirect: (context, state) => AppRoutePaths.splash,
      ),

      // 0b. Parent Base Route (Clean redirect to parent dashboard)
      GoRoute(
        path: AppRoutePaths.parent,
        redirect: (context, state) => AppRoutePaths.parentDashboard,
      ),

      // 1. Splash / Bootstrap Route
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 1b. Onboarding Pre-login Route (Nodes 71:150, 71:179, 71:208)
      GoRoute(
        path: AppRoutePaths.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 2. Authentication Route
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // 2b. Password Setup Route (Screen B)
      GoRoute(
        path: AppRoutePaths.passwordSetup,
        name: AppRouteNames.passwordSetup,
        builder: (context, state) => const PasswordSetupScreen(),
      ),

      // 2d. Onboarding Step 1: Interests (Screen D / Figma Node 382:605)
      GoRoute(
        path: AppRoutePaths.onboardingInterests,
        name: AppRouteNames.onboardingInterests,
        builder: (context, state) => const OnboardingInterestsScreen(),
      ),

      // 2e. Onboarding Step 2: Account Details (Screen E / Figma Node 382:651)
      GoRoute(
        path: AppRoutePaths.onboardingAccount,
        name: AppRouteNames.onboardingAccount,
        builder: (context, state) => const OnboardingAccountScreen(),
      ),

      // 2f. Onboarding Step 3: Child Details (Screen C / Figma Node 382:693)
      GoRoute(
        path: AppRoutePaths.onboardingChild,
        name: AppRouteNames.onboardingChild,
        builder: (context, state) => const OnboardingChildScreen(),
      ),

      // 2g. Onboarding Step 4: Location (Screen F / Figma Node 382:731)
      GoRoute(
        path: AppRoutePaths.onboardingLocation,
        name: AppRouteNames.onboardingLocation,
        builder: (context, state) => const OnboardingLocationScreen(),
      ),

      // 2c. Demo Booking Dashboard Route (Node 72:477)
      GoRoute(
        path: AppRoutePaths.demoBookingDashboard,
        name: AppRouteNames.demoBookingDashboard,
        builder: (context, state) {
          final courseId =
              state.uri.queryParameters['courseId'] ??
              (state.extra is String ? state.extra as String : null);
          return DemoBookingDashboardScreen(courseId: courseId);
        },
      ),

      // 2b. Parent Alias Route (redirects /parent to /parent/dashboard)
      GoRoute(
        path: AppRoutePaths.parent,
        redirect: (context, state) => AppRoutePaths.parentDashboard,
      ),

      // 3. Parent Experience Shell (StatefulShellRoute for persistent bottom nav)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return ParentShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard Tab
          StatefulShellBranch(
            navigatorKey: dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.parentDashboard,
                name: AppRouteNames.parentDashboard,
                builder: (context, state) => const ParentDashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Classes Tab (SCR-13 Class Schedule)
          StatefulShellBranch(
            navigatorKey: classesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.parentClasses,
                name: AppRouteNames.parentClasses,
                builder: (context, state) => const ParentClassesScreen(),
              ),
            ],
          ),

          // Branch 2: Assignments Tab
          StatefulShellBranch(
            navigatorKey: assignmentsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.parentAssignments,
                name: AppRouteNames.parentAssignments,
                builder: (context, state) => const AssignmentsScreen(),
              ),
            ],
          ),

          // Branch 3: Profile Tab (Figma Node 76:1711)
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.parentProfile,
                name: AppRouteNames.parentProfile,
                builder: (context, state) => const ParentProfileScreen(),
              ),
              GoRoute(
                path: AppRoutePaths.myChildren,
                name: AppRouteNames.myChildren,
                builder: (context, state) => const ParentMyChildScreen(),
              ),
            ],
          ),
        ],
      ),

      // Standalone full-screen Parent routes outside bottom navigation shell (Figma Node 104:106 & 104:314)
      GoRoute(
        path: AppRoutePaths.parentInvoices,
        name: AppRouteNames.parentInvoices,
        builder: (context, state) => const ParentInvoicesScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.paymentSuccessful,
        name: AppRouteNames.paymentSuccessful,
        builder: (context, state) => const ParentPaymentSuccessfulScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.demoSessionBooked,
        name: AppRouteNames.demoSessionBooked,
        builder: (context, state) {
          final booking = state.extra is DemoBookingEntity
              ? state.extra as DemoBookingEntity
              : null;
          return DemoSessionBookedScreen(booking: booking);
        },
      ),
      GoRoute(
        path: AppRoutePaths.invoiceDetails,
        name: AppRouteNames.invoiceDetails,
        builder: (context, state) => const ParentInvoiceDetailScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentSecurityPrivacy,
        name: AppRouteNames.parentSecurityPrivacy,
        builder: (context, state) => const ParentSecurityPrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentLoginMethods,
        name: AppRouteNames.parentLoginMethods,
        builder: (context, state) => const ParentLoginMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentLoginDevices,
        name: AppRouteNames.parentLoginDevices,
        builder: (context, state) => const ParentLoginDevicesScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentRecentSecurityActivity,
        name: AppRouteNames.parentRecentSecurityActivity,
        builder: (context, state) => const ParentRecentSecurityActivityScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentPersonalInfo,
        name: AppRouteNames.parentPersonalInfo,
        builder: (context, state) => const ParentPersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentPrivacyPreferences,
        name: AppRouteNames.parentPrivacyPreferences,
        builder: (context, state) => const ParentPrivacyPreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentCommunicationPreferences,
        name: AppRouteNames.parentCommunicationPreferences,
        builder: (context, state) =>
            const ParentCommunicationPreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentDataPrivacy,
        name: AppRouteNames.parentDataPrivacy,
        builder: (context, state) => const ParentDataPrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentPrivacyPolicy,
        name: AppRouteNames.parentPrivacyPolicy,
        builder: (context, state) => const ParentPrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentTermsConditions,
        name: AppRouteNames.parentTermsConditions,
        builder: (context, state) => const ParentTermsConditionsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentMessages,
        name: AppRouteNames.parentMessages,
        builder: (context, state) => const ParentMessagesScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.notifications,
        name: AppRouteNames.notifications,
        builder: (context, state) => const ParentNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.accountSettings,
        name: AppRouteNames.accountSettings,
        builder: (context, state) => const ParentAccountSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.assessments,
        name: AppRouteNames.assessments,
        builder: (context, state) => const ParentAssessmentsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.assessmentRunner,
        name: AppRouteNames.assessmentRunner,
        builder: (context, state) {
          if (state.extra is AssessmentAttemptDetailsEntity) {
            return AssessmentRunnerScreen(
              attemptDetails: state.extra as AssessmentAttemptDetailsEntity,
            );
          }
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AssessmentRunnerScreen(
            attemptDetails:
                extra['attemptDetails'] as AssessmentAttemptDetailsEntity?,
            assessmentId: extra['assessmentId'] as String? ?? '',
            assessmentTitle: extra['assessmentTitle'] as String?,
            studentId: extra['studentId'] as String?,
            studentName: extra['studentName'] as String?,
            redirectUrl: extra['redirectUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.achievements,
        name: AppRouteNames.achievements,
        builder: (context, state) => const ParentAssessmentsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.learningProgress,
        name: AppRouteNames.learningProgress,
        builder: (context, state) => const ParentLearningProgressScreen(),
        routes: [
          GoRoute(
            path: 'classes',
            name: AppRouteNames.progressClasses,
            builder: (context, state) => const ParentClassesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.parentCertificates,
        name: AppRouteNames.parentCertificates,
        builder: (context, state) => const ParentCertificatesScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.parentCounselor,
        name: AppRouteNames.parentCounselor,
        builder: (context, state) => const ParentCounselorScreen(),
      ),
      // Full-screen Current Program Route (literal 'program' registered BEFORE ':classId' to prevent path parameter collision)
      GoRoute(
        path: AppRoutePaths.currentProgram,
        name: AppRouteNames.currentProgram,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CurrentProgramScreen(),
      ),
      // Full-screen Topic Detail Route
      GoRoute(
        path: AppRoutePaths.topicDetail,
        name: AppRouteNames.topicDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final topicTitle = extra is String
              ? extra
              : (extra is Map ? extra['topicTitle']?.toString() : null);
          final topicId = extra is Map ? extra['topicId']?.toString() : null;
          return TopicDetailScreen(topicTitle: topicTitle, topicId: topicId);
        },
      ),
      // Full-screen Class Details Route with sub-routes
      GoRoute(
        path: AppRoutePaths.classDetails,
        name: AppRouteNames.classDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final classId = state.pathParameters['classId'] ?? '';
          final session = state.extra is ClassEntity
              ? state.extra as ClassEntity
              : null;
          return ClassDetailsScreen(classId: classId, session: session);
        },
        routes: [
          GoRoute(
            path: 'preview',
            name: AppRouteNames.classPreview,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              final session = state.extra is ClassEntity
                  ? state.extra as ClassEntity
                  : null;
              return ClassPreviewScreen(classId: classId, session: session);
            },
          ),
          GoRoute(
            path: 'joining',
            name: AppRouteNames.joiningClass,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              ClassEntity? session;
              String? childStudentId;

              if (state.extra is ClassEntity) {
                session = state.extra as ClassEntity;
              } else if (state.extra is Map<String, dynamic>) {
                final map = state.extra as Map<String, dynamic>;
                session = map['session'] as ClassEntity?;
                childStudentId = map['childStudentId'] as String?;
              }

              return JoiningClassScreen(
                classId: classId,
                session: session,
                childStudentId: childStudentId,
              );
            },
          ),
          GoRoute(
            path: 'live',
            name: AppRouteNames.liveClassroom,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              ClassEntity? session;
              ClassJoinEntity? joinData;

              String? childStudentId;
              if (state.extra is ClassEntity) {
                session = state.extra as ClassEntity;
              } else if (state.extra is Map<String, dynamic>) {
                final map = state.extra as Map<String, dynamic>;
                session = map['session'] as ClassEntity?;
                joinData = map['joinData'] as ClassJoinEntity?;
                childStudentId = map['childStudentId'] as String?;
              }

              return LiveClassroomScreen(
                classId: classId,
                session: session,
                joinData: joinData,
                childStudentId: childStudentId,
              );
            },
          ),
          GoRoute(
            path: 'summary',
            name: AppRouteNames.classSummary,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              ClassEntity? session;
              String? childStudentId;
              if (state.extra is ClassEntity) {
                session = state.extra as ClassEntity;
              } else if (state.extra is Map<String, dynamic>) {
                final map = state.extra as Map<String, dynamic>;
                session = map['session'] as ClassEntity?;
                childStudentId = map['childStudentId'] as String?;
              }
              return ClassSummaryScreen(
                classId: classId,
                session: session,
                childStudentId: childStudentId,
              );
            },
          ),
        ],
      ),
      // Full-screen Assignment Details Route with sub-routes
      GoRoute(
        path: AppRoutePaths.assignmentDetails,
        name: AppRouteNames.assignmentDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final assignmentId = state.pathParameters['assignmentId'] ?? '';
          final assignment = state.extra is AssignmentEntity
              ? state.extra as AssignmentEntity
              : null;
          return AssignmentSubmissionScreen(
            assignmentId: assignmentId,
            assignment: assignment,
            showAllStatesOverview: false,
          );
        },
        routes: [
          GoRoute(
            path: 'submission',
            name: AppRouteNames.assignmentSubmission,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final assignmentId = state.pathParameters['assignmentId'] ?? '';
              final assignment = state.extra is AssignmentEntity
                  ? state.extra as AssignmentEntity
                  : null;
              return AssignmentSubmissionScreen(
                assignmentId: assignmentId,
                assignment: assignment,
                showAllStatesOverview: false,
              );
            },
          ),
          GoRoute(
            path: 'submitted',
            name: AppRouteNames.assignmentSubmitted,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final assignmentId = state.pathParameters['assignmentId'] ?? '';
              final assignment = state.extra is AssignmentEntity
                  ? state.extra as AssignmentEntity
                  : null;
              return AssignmentSubmittedScreen(
                assignmentId: assignmentId,
                assignment: assignment,
              );
            },
          ),
        ],
      ),
    ],
  );
});
