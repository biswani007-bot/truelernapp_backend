/// Type-safe route name constants for TrueLern GoRouter navigation.
///
/// Corresponds to authoritative blueprint:
/// docs/project-source-of-truth/18-PARENT-FLUTTER-IMPLEMENTATION-BLUEPRINT.md
/// and 16-PARENT-MASTER-NAVIGATION-FLOW.md.
abstract final class AppRouteNames {
  // Bootstrap & Public Flows
  static const String root = 'root';
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String verifyOtp = 'verifyOtp';
  static const String passwordSetup = 'passwordSetup';
  static const String onboardingInterests = 'onboardingInterests';
  static const String onboardingAccount = 'onboardingAccount';
  static const String onboardingChild = 'onboardingChild';
  static const String onboardingLocation = 'onboardingLocation';
  static const String demoBookingDashboard = 'demoBookingDashboard';

  // Parent App Shell & Core Tabs
  static const String parentShell = 'parent';
  static const String parentDashboard = 'parentDashboard';
  static const String parentClasses = 'parentClasses';
  static const String parentAssignments = 'parentAssignments';
  static const String parentInvoices = 'parentInvoices';
  static const String parentProfile = 'parentProfile';

  // Detail & Secondary Routes
  static const String myChildren = 'myChildren';
  static const String classDetails = 'classDetails';
  static const String classPreview = 'classPreview';
  static const String joiningClass = 'joiningClass';
  static const String liveClassroom = 'liveClassroom';
  static const String classSummary = 'classSummary';
  static const String assignmentDetails = 'assignmentDetails';
  static const String assignmentSubmission = 'assignmentSubmission';
  static const String assignmentSubmitted = 'assignmentSubmitted';
  static const String invoiceDetails = 'invoiceDetails';
  static const String notifications = 'notifications';
  static const String accountSettings = 'accountSettings';
  static const String currentProgram = 'currentProgram';
  static const String topicDetail = 'topicDetail';
  static const String parentSecurityPrivacy = 'parentSecurityPrivacy';
  static const String parentLoginMethods = 'parentLoginMethods';
  static const String parentLoginDevices = 'parentLoginDevices';
  static const String parentRecentSecurityActivity =
      'parentRecentSecurityActivity';
  static const String parentPersonalInfo = 'parentPersonalInfo';
  static const String parentPrivacyPreferences = 'parentPrivacyPreferences';
  static const String parentCommunicationPreferences =
      'parentCommunicationPreferences';
  static const String parentDataPrivacy = 'parentDataPrivacy';
  static const String parentPrivacyPolicy = 'parentPrivacyPolicy';
  static const String parentTermsConditions = 'parentTermsConditions';
  static const String paymentSuccessful = 'paymentSuccessful';
  static const String parentMessages = 'parentMessages';
  static const String achievements = 'achievements';
  static const String assessments = 'assessments';
  static const String assessmentRunner = 'assessmentRunner';
  static const String learningProgress = 'learningProgress';
  static const String parentCertificates = 'parentCertificates';
  static const String parentCounselor = 'parentCounselor';
  static const String progressClasses = 'progressClasses';
  static const String demoSessionBooked = 'demoSessionBooked';
  static const String demoClassWaiting = 'demoClassWaiting';
  static const String demoClassPreJoin = 'demoClassPreJoin';
  static const String demoWaitingForAdmin = 'demoWaitingForAdmin';
}

/// Standardized path constants.
///
/// Note: StatefulShellRoute branches use top-level absolute paths
/// (each branch root must start with '/').
abstract final class AppRoutePaths {
  static const String root = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';
  static const String passwordSetup = '/auth/password-setup';
  static const String onboardingInterests = '/onboarding/interests';
  static const String onboardingAccount = '/onboarding/account';
  static const String onboardingChild = '/onboarding/child';
  static const String onboardingLocation = '/onboarding/location';
  static const String demoBookingDashboard = '/demo-booking-dashboard';

  // Parent Tab Paths — top-level absolute paths for StatefulShellRoute branches
  static const String parent = '/parent';
  static const String parentDashboard = '/parent/dashboard';
  static const String parentClasses = '/parent/classes';
  static const String parentAssignments = '/parent/assignments';
  static const String parentInvoices = '/parent/invoices';
  static const String parentProfile = '/parent/profile';

  // Detail Paths
  static const String myChildren = '/parent/children';
  static const String classDetails = '/parent/classes/:classId';
  static const String classPreview = '/parent/classes/:classId/preview';
  static const String joiningClass = '/parent/classes/:classId/joining';
  static const String liveClassroom = '/parent/classes/:classId/live';
  static const String classSummary = '/parent/classes/:classId/summary';
  static const String currentProgram = '/parent/classes/program';
  static const String topicDetail = '/parent/classes/program/topic';
  static const String assignmentDetails = '/parent/assignments/:assignmentId';
  static const String assignmentSubmission =
      '/parent/assignments/:assignmentId/submission';
  static const String assignmentSubmitted =
      '/parent/assignments/:assignmentId/submitted';
  static const String invoiceDetails = '/parent/invoices/:invoiceId';
  static const String notifications = '/parent/notifications';
  static const String accountSettings = '/parent/settings';
  static const String parentSecurityPrivacy = '/parent/security-privacy';
  static const String parentLoginMethods = '/parent/security/login-methods';
  static const String parentLoginDevices = '/parent/security/login-devices';
  static const String parentRecentSecurityActivity =
      '/parent/security/recent-activity';
  static const String parentPersonalInfo = '/parent/security/personal-info';
  static const String parentPrivacyPreferences =
      '/parent/security/privacy-preferences';
  static const String parentCommunicationPreferences =
      '/parent/security/communication-preferences';
  static const String parentDataPrivacy = '/parent/security/data-privacy';
  static const String parentPrivacyPolicy = '/parent/security/privacy-policy';
  static const String parentTermsConditions =
      '/parent/security/terms-conditions';
  static const String paymentSuccessful = '/parent/payment-successful';
  static const String parentMessages = '/parent/messages';
  static const String achievements = '/parent/achievements';
  static const String assessments = '/parent/assessments';
  static const String assessmentRunner = '/parent/assessments/runner';
  static const String learningProgress = '/parent/progress';
  static const String parentCertificates = '/parent/certificates';
  static const String parentCounselor = '/parent/counselor';
  static const String progressClasses = '/parent/progress/classes';
  static const String demoSessionBooked = '/parent/demo-booked';
  static const String demoClassWaiting = '/parent/demo-class/waiting';
  static const String demoClassPreJoin = '/parent/demo-class/pre-join';
  static const String demoWaitingForAdmin = '/parent/demo-class/waiting-for-admin';
}
