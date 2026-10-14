import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../widgets/parent_hamburger_drawer.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// Parent Security & Privacy Screen — PURE FRONTEND ONLY.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Security & Privacy` (Node 104:314).
/// Displays the exact Figma design:
/// - Header with Back button and Title "Security & Privacy"
/// - Gradient background (Lavender -> Sky Blue -> White)
/// - SECURITY Section:
///   - Login Methods (WhatsApp, Email, PIN, Biometric)
///   - Biometric Login (Fingerprint or Face ID + Toggle switch)
///   - Login & Devices (Manage active sessions)
///   - Recent Security Activity (View login history)
/// - PRIVACY Section:
///   - Personal Information (Name, Email, WhatsApp)
///   - Privacy Preferences (Data sharing & visibility)
///   - Communication Preferences (Notifications & alerts)
///   - Data & Privacy (Download data or delete account)
/// - Legal Documents Group:
///   - Privacy Policy
///   - Terms & Conditions
///
/// STRICT RULES:
/// - Zero backend calls / Zero API calls / Pure static frontend
/// - No bottom navigation bar (matching Figma Node 104:314)
class ParentSecurityPrivacyScreen extends StatefulWidget {
  const ParentSecurityPrivacyScreen({super.key});

  @override
  State<ParentSecurityPrivacyScreen> createState() =>
      _ParentSecurityPrivacyScreenState();
}

class _ParentSecurityPrivacyScreenState
    extends State<ParentSecurityPrivacyScreen> {
  // Local state for the Biometric switch shown in Figma (Node 104:361)
  bool _biometricEnabled = true;

  // Icon assets downloaded directly from Figma MCP asset server
  static const _svgBackArrow = 'assets/icons/sec_back_arrow.svg';
  static const _svgChevronRight = 'assets/icons/sec_chevron_right.svg';
  static const _svgLoginMethods = 'assets/icons/sec_login_methods.svg';
  static const _svgBiometric = 'assets/icons/sec_biometric.svg';
  static const _svgLoginDevices = 'assets/icons/sec_login_devices.svg';
  static const _svgSecurityActivity = 'assets/icons/sec_security_activity.svg';
  static const _svgPersonalInfo = 'assets/icons/sec_personal_info.svg';
  static const _svgPrivacyPref = 'assets/icons/sec_privacy_pref.svg';
  static const _svgCommPref = 'assets/icons/sec_comm_pref.svg';
  static const _svgDataPrivacy = 'assets/icons/sec_data_privacy.svg';
  static const _svgPrivacyPolicy = 'assets/icons/sec_privacy_policy.svg';
  static const _svgTerms = 'assets/icons/sec_terms.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_security_privacy_screen'),
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
              // Header - Top Navigation (Node 104:315)
              _buildTopHeader(context),

              // Main Content ScrollView (Node 104:322)
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── SECURITY SECTION (Node 104:323) ──
                        _buildSectionTitle('SECURITY'),
                        const SizedBox(height: 12),
                        _buildCardGroup([
                          _buildSettingRow(
                            iconPath: _svgLoginMethods,
                            title: 'Login Methods',
                            subtitle: 'WhatsApp, Email, PIN, Biometric',
                            showDivider: true,
                            onTap: () {
                              context.push(AppRoutePaths.parentLoginMethods);
                            },
                          ),
                          _buildBiometricRow(),
                          _buildSettingRow(
                            iconPath: _svgLoginDevices,
                            title: 'Login & Devices',
                            subtitle: 'Manage active sessions',
                            showDivider: true,
                            onTap: () {
                              context.push(AppRoutePaths.parentLoginDevices);
                            },
                          ),
                          _buildSettingRow(
                            iconPath: _svgSecurityActivity,
                            title: 'Recent Security Activity',
                            subtitle: 'View login history',
                            showDivider: false,
                            onTap: () {
                              context.push(
                                AppRoutePaths.parentRecentSecurityActivity,
                              );
                            },
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ── PRIVACY SECTION (Node 104:388) ──
                        _buildSectionTitle('PRIVACY'),
                        const SizedBox(height: 12),
                        _buildCardGroup([
                          _buildSettingRow(
                            iconPath: _svgPersonalInfo,
                            title: 'Personal Information',
                            subtitle: 'Name, Email, WhatsApp',
                            showDivider: true,
                            onTap: () {
                              context.push(AppRoutePaths.parentPersonalInfo);
                            },
                          ),
                          _buildSettingRow(
                            iconPath: _svgPrivacyPref,
                            title: 'Privacy Preferences',
                            subtitle: 'Data sharing & visibility',
                            showDivider: true,
                            onTap: () {
                              context.push(
                                AppRoutePaths.parentPrivacyPreferences,
                              );
                            },
                          ),
                          _buildSettingRow(
                            iconPath: _svgCommPref,
                            title: 'Communication Preferences',
                            subtitle: 'Notifications & alerts',
                            showDivider: true,
                            onTap: () {
                              context.push(
                                AppRoutePaths.parentCommunicationPreferences,
                              );
                            },
                          ),
                          _buildSettingRow(
                            iconPath: _svgDataPrivacy,
                            title: 'Data & Privacy',
                            subtitle: 'Download data or delete account',
                            showDivider: false,
                            onTap: () {
                              context.push(AppRoutePaths.parentDataPrivacy);
                            },
                          ),
                        ]),

                        const SizedBox(height: 8),

                        // ── Legal Documents Group (Node 104:441) ──
                        _buildCardGroup([
                          _buildSettingRow(
                            iconPath: _svgPrivacyPolicy,
                            title: 'Privacy Policy',
                            subtitle: null,
                            showDivider: true,
                            onTap: () {
                              context.push(AppRoutePaths.parentPrivacyPolicy);
                            },
                          ),
                          _buildSettingRow(
                            iconPath: _svgTerms,
                            title: 'Terms & Conditions',
                            subtitle: null,
                            showDivider: false,
                            onTap: () {
                              context.push(AppRoutePaths.parentTermsConditions);
                            },
                          ),
                        ]),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header Top Navigation matching Figma Node 104:315
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 16, right: 40, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (Node 104:316)
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutePaths.parentDashboard);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                _svgBackArrow,
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0037B1),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Centered Title (Node 104:320 / 104:321)
          Expanded(
            child: Center(
              child: Text(
                'Security & Privacy',
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

  /// Section Title matching Figma Nodes 104:325 & 104:390
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
          letterSpacing: 0.8,
          color: const Color(0xFF434655),
        ),
      ),
    );
  }

  /// White rounded card grouping matching Figma Nodes 104:326, 104:391, 104:441
  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }

  /// Standard setting row with icon, title, subtitle, divider, chevron
  Widget _buildSettingRow({
    required String iconPath,
    required String title,
    required String? subtitle,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFE2E1ED), width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            // Icon in rounded square background (Node 104:329)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0037B1),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Title & optional Subtitle
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
                  if (subtitle != null) ...[
                    Text(
                      subtitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        color: const Color(0xFF747686),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chevron Right (Node 104:337)
            SvgPicture.asset(
              _svgChevronRight,
              width: 7.4,
              height: 12,
              colorFilter: const ColorFilter.mode(
                Color(0xFF747686),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Biometric Login Row with custom Switch matching Figma Nodes 104:351 - 104:363
  Widget _buildBiometricRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E1ED), width: 1)),
      ),
      child: Row(
        children: [
          // Biometric Fingerprint Icon (Node 104:353)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                _svgBiometric,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0037B1),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title & Subtitle (Node 104:357 - 104:360)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Biometric Login',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
                Text(
                  'Fingerprint or Face ID',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                    color: const Color(0xFF747686),
                  ),
                ),
              ],
            ),
          ),

          // Switch toggle matching Figma Node 104:361 (44x24 pill)
          GestureDetector(
            onTap: () {
              setState(() {
                _biometricEnabled = !_biometricEnabled;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                color: _biometricEnabled
                    ? const Color(0xFF1E4ED8)
                    : const Color(0xFFC4C5D7),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _biometricEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
