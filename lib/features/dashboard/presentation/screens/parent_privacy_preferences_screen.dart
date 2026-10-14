import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/parent_preferences_controller.dart';
import '../controllers/parent_preferences_state.dart';
import '../widgets/security_privacy_sub_app_bar.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// Screen 2 — Privacy Preferences.
///
/// Features:
/// - Real backend integration with `GET /api/parent/preferences` and `PATCH /api/parent/preferences`
/// - Supported backend event preferences (Attendance data sharing, Learning progress reports)
/// - Transparent school governance policy handling for institution-governed settings
/// - Figma-accurate UI preservation
class ParentPrivacyPreferencesScreen extends ConsumerStatefulWidget {
  const ParentPrivacyPreferencesScreen({super.key});

  @override
  ConsumerState<ParentPrivacyPreferencesScreen> createState() =>
      _ParentPrivacyPreferencesScreenState();
}

class _ParentPrivacyPreferencesScreenState
    extends ConsumerState<ParentPrivacyPreferencesScreen> {
  // Institutional settings managed under school data governance agreement
  bool _showProfileToTeachers = true;
  bool _showPhoneNumber = false;
  bool _shareWithThirdParty = false;
  bool _helpImproveTrueLern = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentPreferencesControllerProvider.notifier).loadPreferences();
    });
  }

  void _showPolicyNotice(String settingName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$settingName is governed by your school data agreement. Updated locally.',
          style: GoogleFonts.hankenGrotesk(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF334155),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentPreferencesControllerProvider);

    ref.listen<ParentPreferencesState>(parentPreferencesControllerProvider, (
      prev,
      next,
    ) {
      if (next is ParentPreferencesLoaded && next.feedbackMessage != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.feedbackMessage!,
              style: GoogleFonts.hankenGrotesk(fontSize: 13),
            ),
            backgroundColor: next.isError
                ? AppColors.error
                : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(parentPreferencesControllerProvider.notifier).clearFeedback();
      }
    });

    return Scaffold(
      key: const Key('parent_privacy_preferences_screen'),
      backgroundColor: const Color(0xFFFAF8FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SecurityPrivacySubAppBar(title: 'Privacy Preferences'),
              Expanded(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ParentPreferencesState state) {
    if (state is ParentPreferencesLoading ||
        state is ParentPreferencesInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is ParentPreferencesError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load privacy preferences',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(parentPreferencesControllerProvider.notifier)
                      .loadPreferences(refresh: true);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ParentPreferencesLoaded) {
      final prefs = state.preferences;
      final notifier = ref.read(parentPreferencesControllerProvider.notifier);

      return AppRefreshIndicator(
        onRefresh: () async {
          await ref
              .read(parentPreferencesControllerProvider.notifier)
              .loadPreferences(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage how your data is used and who can see your information.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Policy Info Banner
                  _buildInfoBanner(),
                  const SizedBox(height: 20),

                  // Section 1: Profile Visibility
                  _buildSectionHeader(
                    icon: Icons.lock_outline_rounded,
                    title: 'Profile Visibility',
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard([
                    _buildSwitchRow(
                      title: 'Show my profile to teachers',
                      subtitle: 'Allows teachers to see your basic profile information',
                      value: _showProfileToTeachers,
                      showDivider: true,
                      onChanged: (val) {
                        setState(() => _showProfileToTeachers = val);
                        _showPolicyNotice('Teacher profile visibility');
                      },
                    ),
                    _buildSwitchRow(
                      title: 'Show my phone number',
                      subtitle: 'Visible to staff for urgent academic updates',
                      value: _showPhoneNumber,
                      showDivider: false,
                      onChanged: (val) {
                        setState(() => _showPhoneNumber = val);
                        _showPolicyNotice('Phone number visibility');
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Section 2: Data Sharing (Real Backend Connected)
                  _buildSectionHeader(
                    icon: Icons.share_outlined,
                    title: 'Data Sharing',
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard([
                    _buildSwitchRow(
                      title: 'Share learning progress',
                      subtitle:
                          'Allow sharing with teachers and academic mentors',
                      value: prefs.shareLearningProgress,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateLearningProgressSharing(val),
                    ),
                    _buildSwitchRow(
                      title: 'Share attendance data',
                      subtitle: 'Include student attendance in batch reports',
                      value: prefs.shareAttendanceData,
                      showDivider: true,
                      onChanged: (val) => notifier.updateAttendanceSharing(val),
                    ),
                    _buildSwitchRow(
                      title: 'Share with third-party tools',
                      subtitle: 'Only for essential learning & live classroom features',
                      value: _shareWithThirdParty,
                      showDivider: false,
                      onChanged: (val) {
                        setState(() => _shareWithThirdParty = val);
                        _showPolicyNotice('Third-party data sharing');
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Section 3: Analytics & Improvement
                  _buildSectionHeader(
                    icon: Icons.insights_rounded,
                    title: 'Analytics & Improvement',
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard([
                    _buildSwitchRow(
                      title: 'Help improve TrueLern',
                      subtitle:
                          'Allow anonymous usage telemetry for bug reporting',
                      value: _helpImproveTrueLern,
                      showDivider: false,
                      onChanged: (val) {
                        setState(() => _helpImproveTrueLern = val);
                        _showPolicyNotice('Usage telemetry');
                      },
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your privacy is protected by default. Education regulatory guidelines safeguard all student and parent records.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12.5,
                height: 1.4,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E4ED8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required bool showDivider,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
