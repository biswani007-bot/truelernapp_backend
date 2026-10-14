import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../controllers/parent_profile_controller.dart';
import '../controllers/parent_profile_state.dart';

/// Parent Hamburger Drawer — Default State.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Hamburger Drawer — Default` (Node 76:1249).
/// Displays the exact Figma design:
/// - Navigation Drawer container (Node 76:1251):
///   - Width: 332px, Background: #FAF8FF, Corner radius: top-right & bottom-right 24px
///   - Drop shadow: rgba(0,0,0,0.25)
/// - Top Logo Section (Node 76:1253):
///   - Brand TrueLern logo (197x86)
/// - Profile Card (Node 76:1255):
///   - Background: #F3F2FE, Border: 1px solid #EDEDF9, Rounded 12px
///   - Avatar: Circular 48x48 with 2px #1E4ED8 blue border
///   - Title: "Hi, PPs" (16px Bold #1A1B23)
///   - Subtitle: "Parent" (12px Medium #434655)
/// - Menu Groups (Node 76:1277):
///   - LEARNING: My Classes, Assignments, My Programs, Learning Progress (ACTIVE #1E4ED8)
///   - MY GROWTH: Assessments, Certificates
///   - COMMUNICATION: Messages, Notifications
///   - ACCOUNT: My Profile, Account Settings, Security & Privacy
/// - Footer Section (Node 76:1366):
///   - Divider top: #EDEDF9
///   - Support Card (Node 76:1367): rgba(234, 221, 255, 0.5), Border #D2BBFF, "Need help?", "Our support team is here for you.", "Contact Support" button (#712AE2)
///   - Sign Out Button (Node 76:1373): Red #BA1A1A icon & text
///
/// STRICT RULES:
/// - Zero backend calls / Zero API calls / Pure static frontend
/// - 100% exact visual match to Figma Node 76:1249
class ParentHamburgerDrawer extends ConsumerWidget {
  const ParentHamburgerDrawer({
    super.key,
    this.activeItem,
    this.onTabSelected,
    this.onLogout,
  });

  final String? activeItem;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onLogout;

  static const String _imgLogo = 'assets/images/truelern_brand_logo.png';
  static const String _imgAvatar = 'assets/images/drawer_profile_avatar.png';

  static const String _svgClasses = 'assets/icons/drawer_classes.svg';
  static const String _svgAssignments = 'assets/icons/drawer_assignments.svg';
  static const String _svgPrograms = 'assets/icons/drawer_programs.svg';
  static const String _svgLearningProgress =
      'assets/icons/drawer_learning_progress.svg';

  static const String _svgAssessments = 'assets/icons/drawer_assessments.svg';
  static const String _svgCertificates = 'assets/icons/drawer_certificates.svg';

  static const String _svgMessages = 'assets/icons/drawer_messages.svg';
  static const String _svgNotifications =
      'assets/icons/drawer_notifications.svg';

  static const String _svgProfile = 'assets/icons/drawer_profile.svg';
  static const String _svgSettings = 'assets/icons/drawer_settings.svg';
  static const String _svgSecurity = 'assets/icons/drawer_security.svg';

  static const String _svgSignOut = 'assets/icons/drawer_sign_out.svg';

  /// Resolves the current matched route path from [GoRouter].
  static String resolveCurrentPath(BuildContext context) {
    try {
      final router = GoRouter.of(context);
      final uriPath = router.routerDelegate.currentConfiguration.uri.path;
      if (uriPath.isNotEmpty) return uriPath;
    } catch (_) {}
    try {
      final state = GoRouterState.of(context);
      final location = state.matchedLocation;
      if (location.isNotEmpty) return location;
    } catch (_) {}
    return '';
  }

  /// Maps the current route path (including child/nested routes) to the
  /// corresponding Hamburger Drawer item label.
  static String getDrawerActiveItemForPath(String path) {
    // 1. My Programs: /parent/classes/program (must precede /parent/classes)
    if (path.startsWith(AppRoutePaths.currentProgram)) {
      return 'My Programs';
    }
    // 2. My Classes: /parent/classes and subroutes (:classId, preview, joining, live, summary)
    if (path.startsWith(AppRoutePaths.parentClasses)) {
      return 'My Classes';
    }
    // 3. Assignments: /parent/assignments and subroutes (:assignmentId, submission, submitted)
    if (path.startsWith(AppRoutePaths.parentAssignments)) {
      return 'Assignments';
    }
    // 4. Learning Progress: /parent/progress
    if (path.startsWith(AppRoutePaths.learningProgress)) {
      return 'Learning Progress';
    }
    // 5. Assessments: /parent/assessments
    if (path.startsWith(AppRoutePaths.assessments) ||
        path.startsWith(AppRoutePaths.achievements)) {
      return 'Assessments';
    }
    // 5b. Certificates: /parent/certificates
    if (path.startsWith(AppRoutePaths.parentCertificates)) {
      return 'Certificates';
    }
    // 6. Messages: /parent/messages
    if (path.startsWith(AppRoutePaths.parentMessages)) {
      return 'Messages';
    }
    // 7. Notifications: /parent/notifications
    if (path.startsWith(AppRoutePaths.notifications)) {
      return 'Notifications';
    }
    // 9. Account Settings: /parent/settings
    if (path.startsWith(AppRoutePaths.accountSettings)) {
      return 'Account Settings';
    }
    // 10. Security & Privacy: /parent/security-privacy and subroutes
    //     (Login Methods: /parent/security/login-methods, Login & Devices: /parent/security/login-devices)
    if (path.startsWith(AppRoutePaths.parentSecurityPrivacy) ||
        path.startsWith(AppRoutePaths.parentLoginMethods) ||
        path.startsWith(AppRoutePaths.parentLoginDevices)) {
      return 'Security & Privacy';
    }
    // 11. My Profile: /parent/profile and child routes (My Child: /parent/children, Invoices: /parent/invoices)
    if (path.startsWith(AppRoutePaths.parentProfile) ||
        path.startsWith(AppRoutePaths.myChildren) ||
        path.startsWith(AppRoutePaths.parentInvoices) ||
        path.startsWith(AppRoutePaths.paymentSuccessful)) {
      return 'My Profile';
    }
    return '';
  }

  void _navigate(
    BuildContext context,
    String destinationRoute,
    String itemLabel,
    String currentPath,
    String effectiveActiveItem,
  ) {
    Navigator.of(context).pop();

    // Prevent redundant navigation if already at the destination
    if (effectiveActiveItem == itemLabel && currentPath == destinationRoute) {
      return;
    }

    context.go(destinationRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = resolveCurrentPath(context);
    final effectiveActiveItem = (activeItem != null && activeItem!.isNotEmpty)
        ? activeItem!
        : getDrawerActiveItemForPath(currentPath);

    final profileState = ref.watch(parentProfileControllerProvider);
    final authState = ref.watch(authControllerProvider);

    if (profileState is ParentProfileInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(parentProfileControllerProvider.notifier).loadProfile();
      });
    }

    final String displayName;
    final String displayEmail;
    if (profileState is ParentProfileLoaded) {
      displayName = profileState.profile.fullName;
      displayEmail = profileState.profile.email;
    } else if (authState is Authenticated && authState.user != null) {
      displayName =
          (authState.user!.name != null && authState.user!.name!.isNotEmpty)
          ? authState.user!.name!
          : 'Parent';
      displayEmail = authState.user!.email ?? '';
    } else {
      displayName = 'Parent';
      displayEmail = '';
    }

    return Drawer(
      key: const Key('parent_hamburger_drawer'),
      width: 332,
      backgroundColor: const Color(0xFFFAF8FF),
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Brand TrueLern Logo (Node 76:1253)
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Image.asset(
                  _imgLogo,
                  width: 197,
                  height: 86,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 8),

              // Header Section — Profile Card (Node 76:1254 & 76:1255)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEDEDF9),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000), // rgba(0,0,0,0.05)
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar with 2px blue border (Node 76:1256)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1E4ED8),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9999),
                          child: Image.asset(
                            _imgAvatar,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text Container (Node 76:1257)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              key: const Key('drawer_parent_name'),
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 24 / 16,
                                color: const Color(0xFF1A1B23),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              displayEmail.isNotEmpty ? displayEmail : 'Parent',
                              key: const Key('drawer_parent_email'),
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 16 / 12,
                                color: const Color(0xFF434655),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Menu Groups (Node 76:1277)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group 1: LEARNING (Node 76:1278)
                    _buildSectionHeader('LEARNING'),
                    _buildMenuItem(
                      context: context,
                      label: 'My Classes',
                      iconSvg: _svgClasses,
                      iconWidth: 22,
                      iconHeight: 16,
                      isActive: effectiveActiveItem == 'My Classes',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.parentClasses,
                        'My Classes',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'Assignments',
                      iconSvg: _svgAssignments,
                      iconWidth: 18,
                      iconHeight: 20,
                      isActive:
                          effectiveActiveItem == 'Assignments' ||
                          effectiveActiveItem == 'Assignment',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.parentAssignments,
                        'Assignments',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'My Programs',
                      iconSvg: _svgPrograms,
                      iconWidth: 16,
                      iconHeight: 16,
                      isActive: effectiveActiveItem == 'My Programs',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.currentProgram,
                        'My Programs',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'Learning Progress',
                      iconSvg: _svgLearningProgress,
                      iconWidth: 20,
                      iconHeight: 20,
                      isActive: effectiveActiveItem == 'Learning Progress',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.learningProgress,
                        'Learning Progress',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Group 2: MY GROWTH (Node 76:1306)
                    _buildSectionHeader('MY GROWTH'),
                    _buildMenuItem(
                      context: context,
                      label: 'Assessments',
                      iconSvg: _svgAssessments,
                      iconWidth: 18,
                      iconHeight: 18,
                      isActive: effectiveActiveItem == 'Assessments',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.assessments,
                        'Assessments',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'Certificates',
                      iconSvg: _svgCertificates,
                      iconWidth: 16,
                      iconHeight: 21,
                      isActive: effectiveActiveItem == 'Certificates',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.parentCertificates,
                        'Certificates',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Group 3: COMMUNICATION (Node 76:1322)
                    _buildSectionHeader('COMMUNICATION'),
                    _buildMenuItem(
                      context: context,
                      label: 'Messages',
                      iconSvg: _svgMessages,
                      iconWidth: 20,
                      iconHeight: 20,
                      isActive: effectiveActiveItem == 'Messages',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.parentMessages,
                        'Messages',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'Notifications',
                      iconSvg: _svgNotifications,
                      iconWidth: 16,
                      iconHeight: 20,
                      isActive: effectiveActiveItem == 'Notifications',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.notifications,
                        'Notifications',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Group 4: ACCOUNT (Node 76:1344)
                    _buildSectionHeader('ACCOUNT'),
                    _buildMenuItem(
                      context: context,
                      label: 'My Profile',
                      iconSvg: _svgProfile,
                      iconWidth: 16,
                      iconHeight: 16,
                      isActive:
                          effectiveActiveItem == 'My Profile' ||
                          effectiveActiveItem == 'Profile',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.parentProfile,
                        'My Profile',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'Account Settings',
                      iconSvg: _svgSettings,
                      iconWidth: 20,
                      iconHeight: 20,
                      isActive: effectiveActiveItem == 'Account Settings',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.accountSettings,
                        'Account Settings',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      label: 'Security & Privacy',
                      iconSvg: _svgSecurity,
                      iconWidth: 16,
                      iconHeight: 21,
                      isActive: effectiveActiveItem == 'Security & Privacy',
                      onTap: () => _navigate(
                        context,
                        AppRoutePaths.parentSecurityPrivacy,
                        'Security & Privacy',
                        currentPath,
                        effectiveActiveItem,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Footer Section (Node 76:1366)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 17, 24, 24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFEDEDF9), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Support Card (Node 76:1367)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: const Color(
                          0x80EADDFF,
                        ), // rgba(234, 221, 255, 0.5)
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD2BBFF),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need help?',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 24 / 16,
                              color: const Color(0xFF25005A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Our support team is here for you.',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 20 / 14,
                              color: const Color(0xFF434655),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // "Contact Support" Button (Node 76:1371)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              // Static frontend feedback
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF712AE2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 1,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Contact Support',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Button - Sign Out (Node 76:1373)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (onLogout != null) {
                          onLogout?.call();
                        } else {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          ref
                              .read(parentProfileControllerProvider.notifier)
                              .reset();
                          if (context.mounted) {
                            context.go(AppRoutePaths.login);
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              _svgSignOut,
                              width: 15,
                              height: 15,
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFBA1A1A),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFBA1A1A),
                                letterSpacing: 0.1,
                                height: 20 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF747686),
          letterSpacing: 0.6,
          height: 16 / 12,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String label,
    required String iconSvg,
    required double iconWidth,
    required double iconHeight,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        key: Key('drawer_item_${label.toLowerCase().replaceAll(' ', '_')}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E4ED8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: SvgPicture.asset(
                    iconSvg,
                    width: iconWidth,
                    height: iconHeight,
                    fit: BoxFit.contain,
                    colorFilter: isActive
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : const ColorFilter.mode(
                            Color(0xFF434655),
                            BlendMode.srcIn,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    color: isActive
                        ? const Color(0xFFFBFAFF)
                        : const Color(0xFF434655),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
