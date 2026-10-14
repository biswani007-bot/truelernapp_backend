import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../controllers/login_methods_controller.dart';
import '../controllers/login_methods_state.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Login Methods Screen connected to real TrueLern Backend API.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Login Methods` (Node 104:462).
/// Displays:
/// - Header with Back button and centered Title "Login Methods"
/// - Gradient background (Lavender -> Sky Blue -> White)
/// - Method 1: WhatsApp (real parent phone from API) with green accent border & "Verified" badge
/// - Method 2: Email (real parent email from API) with green accent border & "Verified" badge
/// - Method 3: PIN (Security PIN) with neutral accent border & "Unavailable" badge (No server PIN API)
/// - Method 4: Biometrics (Face ID / Fingerprint) with blue accent border & "Device Only" badge
/// - Footer Note: Lock icon & "TrueLern uses secure verification. No passwords required."
class ParentLoginMethodsScreen extends ConsumerStatefulWidget {
  const ParentLoginMethodsScreen({super.key});

  @override
  ConsumerState<ParentLoginMethodsScreen> createState() =>
      _ParentLoginMethodsScreenState();
}

class _ParentLoginMethodsScreenState
    extends ConsumerState<ParentLoginMethodsScreen> {
  static const _svgBackArrow = 'assets/icons/login_back_arrow.svg';
  static const _svgWhatsApp = 'assets/icons/login_whatsapp.svg';
  static const _svgEmail = 'assets/icons/login_email.svg';
  static const _svgBiometric = 'assets/icons/login_biometric.svg';
  static const _svgLock = 'assets/icons/login_lock.svg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginMethodsControllerProvider.notifier).loadLoginMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginMethodsControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutePaths.parentSecurityPrivacy);
        }
      },
      child: Scaffold(
        key: const Key('parent_login_methods_screen'),
        drawer: const ParentHamburgerDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF3E8FF), // rgb(243, 232, 255)
                Color(0xFFE0F2FE), // rgb(224, 242, 254)
                Color(0xFFFFFFFF), // rgb(255, 255, 255)
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header (Transactional - No Shell Nav) (Node 104:523)
                _buildTopHeader(context),

                // Main Content ScrollView (Node 104:463)
                Expanded(
                  child: AppRefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(loginMethodsControllerProvider.notifier)
                          .loadLoginMethods(isRefresh: true);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 24),

                              if (state is LoginMethodsLoading) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1E4ED8),
                                  ),
                                ),
                              ] else if (state is LoginMethodsError) ...[
                                _buildErrorCard(state.message),
                                const SizedBox(height: 16),
                              ],

                              // Method 1: WhatsApp (Node 104:465)
                              _buildMethodCard(
                                iconPath: _svgWhatsApp,
                                iconWidth: 20,
                                iconHeight: 20,
                                title: 'WhatsApp',
                                subtitle: state is LoginMethodsLoaded
                                    ? (state.methods.phone.isNotEmpty
                                          ? state.methods.phone
                                          : 'Not configured')
                                    : (state is LoginMethodsLoading
                                          ? 'Loading...'
                                          : 'Not configured'),
                                accentColor: const Color(0xFF10B981),
                                badgeText:
                                    state is LoginMethodsLoaded &&
                                        state.methods.phone.isNotEmpty
                                    ? 'Verified'
                                    : 'Active',
                                badgeTextColor: const Color(0xFF10B981),
                                badgeBgColor: const Color(0x1A10B981),
                                badgeBorderColor: const Color(0x3310B981),
                              ),

                              const SizedBox(height: 12),

                              // Method 2: Email (Node 104:478)
                              _buildMethodCard(
                                iconPath: _svgEmail,
                                iconWidth: 20,
                                iconHeight: 16,
                                title: 'Email',
                                subtitle: state is LoginMethodsLoaded
                                    ? (state.methods.email.isNotEmpty
                                          ? state.methods.email
                                          : 'Not configured')
                                    : (state is LoginMethodsLoading
                                          ? 'Loading...'
                                          : 'Not configured'),
                                accentColor: const Color(0xFF10B981),
                                badgeText:
                                    state is LoginMethodsLoaded &&
                                        state.methods.email.isNotEmpty
                                    ? 'Verified'
                                    : 'Active',
                                badgeTextColor: const Color(0xFF10B981),
                                badgeBgColor: const Color(0x1A10B981),
                                badgeBorderColor: const Color(0x3310B981),
                              ),

                              const SizedBox(height: 12),

                              // Method 3: PIN
                              _buildMethodCard(
                                iconPath: _svgLock,
                                iconWidth: 16,
                                iconHeight: 20,
                                title: 'PIN',
                                subtitle: 'Security PIN (No server API)',
                                accentColor: const Color(0xFF9CA3AF),
                                badgeText: 'Unavailable',
                                badgeTextColor: const Color(0xFF6B7280),
                                badgeBgColor: const Color(0x1A9CA3AF),
                                badgeBorderColor: const Color(0x339CA3AF),
                              ),

                              const SizedBox(height: 12),

                              // Method 4: Biometrics (Node 104:504)
                              _buildMethodCard(
                                iconPath: _svgBiometric,
                                iconWidth: 18,
                                iconHeight: 20,
                                title: 'Biometrics',
                                subtitle:
                                    'Face ID / Fingerprint (Local Device)',
                                accentColor: const Color(0xFF3B82F6),
                                badgeText: 'Device Only',
                                badgeTextColor: const Color(0xFF3B82F6),
                                badgeBgColor: const Color(0x1A3B82F6),
                                badgeBorderColor: const Color(0x333B82F6),
                              ),

                              const SizedBox(height: 32),

                              // Footer Note (Node 104:518)
                              _buildFooterNote(),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Error banner with retry button
  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load login methods',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: const Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref
                .read(loginMethodsControllerProvider.notifier)
                .loadLoginMethods(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Top header matching Figma Node 104:523
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 16, right: 56, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (Node 104:525)
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutePaths.parentSecurityPrivacy);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                _svgBackArrow,
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0037B1),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Centered Title (Node 104:529)
          Expanded(
            child: Center(
              child: Text(
                'Login Methods',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 25.5,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single login method card matching Figma Nodes 104:465, 104:478, 104:504
  Widget _buildMethodCard({
    required String iconPath,
    required double iconWidth,
    required double iconHeight,
    required String title,
    required String subtitle,
    required Color accentColor,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required Color badgeBorderColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor.withValues(alpha: 0.8), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Neumorphic Icon Container (Node 104:467)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD9D9D9),
                  offset: Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: iconWidth,
                height: iconHeight,
                colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                    color: const Color(0xFF434655),
                  ),
                ),
              ],
            ),
          ),

          // Pill Badge (Node 104:475)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: badgeBorderColor, width: 1),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer note matching Figma Node 104:518
  Widget _buildFooterNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          _svgLock,
          width: 12,
          height: 15.75,
          colorFilter: const ColorFilter.mode(
            Color(0xFF747686),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'TrueLern uses secure verification. No passwords\nrequired.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: const Color(0xFF747686),
            ),
          ),
        ),
      ],
    );
  }
}
