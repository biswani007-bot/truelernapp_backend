import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../controllers/parent_preferences_controller.dart';
import '../controllers/parent_preferences_state.dart';
import '../widgets/security_privacy_sub_app_bar.dart';

/// Screen — Communication Preferences.
///
/// Backed by real API endpoints:
/// - `GET /api/parent/preferences` (fetches delivery channels, alert categories, digest, and mute settings)
/// - `PATCH /api/parent/preferences` (persists updated channel and event preferences)
class ParentCommunicationPreferencesScreen extends ConsumerStatefulWidget {
  const ParentCommunicationPreferencesScreen({super.key});

  @override
  ConsumerState<ParentCommunicationPreferencesScreen> createState() =>
      _ParentCommunicationPreferencesScreenState();
}

class _ParentCommunicationPreferencesScreenState
    extends ConsumerState<ParentCommunicationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(parentPreferencesControllerProvider.notifier)
          .loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentPreferencesControllerProvider);

    ref.listen<ParentPreferencesState>(
      parentPreferencesControllerProvider,
      (prev, next) {
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
          ref
              .read(parentPreferencesControllerProvider.notifier)
              .clearFeedback();
        }
      },
    );

    return Scaffold(
      key: const Key('parent_communication_preferences_screen'),
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
              const SecurityPrivacySubAppBar(
                title: 'Communication Preferences',
              ),
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
                'Failed to load communication preferences',
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
      final isUpdating = state.isUpdating;

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
                    'Manage your communication channels and alert notifications.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mute All Notice (if active)
                  if (prefs.muteAll) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_off_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'All notifications are currently muted.',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Master Controls
                  _buildSectionHeader(
                    icon: Icons.tune_rounded,
                    title: 'Account Alert Settings',
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard([
                    _buildSwitchRow(
                      icon: Icons.notifications_off_outlined,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Mute All Notifications',
                      subtitle: 'Temporarily pause all alert messages',
                      value: prefs.muteAll,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) => notifier.updateMuteAll(val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Daily Digest Mode',
                      subtitle: 'Combine updates into a daily digest',
                      value: prefs.digestEnabled,
                      disabled: isUpdating,
                      showDivider: false,
                      onChanged: (val) => notifier.updateDigestEnabled(val),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Group 1: Delivery Channels
                  _buildSectionHeader(
                    icon: Icons.campaign_rounded,
                    title: 'Delivery Channels',
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard([
                    _buildSwitchRow(
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFF10B981),
                      title: 'Push Notifications',
                      subtitle: 'Instant alerts on this device',
                      value: prefs.pushEnabled,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateChannelPreference(push: val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Email Notifications',
                      subtitle: 'Official statements & summaries via email',
                      value: prefs.emailEnabled,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateChannelPreference(email: val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.chat_outlined,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp Notifications',
                      subtitle: 'Urgent notices and class reminders on WhatsApp',
                      value: prefs.whatsappEnabled,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateChannelPreference(whatsapp: val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.sms_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'SMS Notifications',
                      subtitle: 'Critical security and verification SMS',
                      value: prefs.smsEnabled,
                      disabled: isUpdating,
                      showDivider: false,
                      onChanged: (val) =>
                          notifier.updateChannelPreference(sms: val),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Group 2: Alert Categories
                  _buildSectionHeader(
                    icon: Icons.category_rounded,
                    title: 'Alert Categories',
                  ),
                  const SizedBox(height: 10),
                  _buildGroupCard([
                    _buildSwitchRow(
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Class & Attendance Reminders',
                      subtitle: 'Upcoming class schedules and attendance notes',
                      value: prefs.attendanceAlerts,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateEventPreference(attendance: val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Assignments & Homework',
                      subtitle: 'New homework releases and graded submissions',
                      value: prefs.assignmentAlerts,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateEventPreference(assignment: val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.analytics_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Academic Progress & Reports',
                      subtitle: 'Periodic progress reports and mastery milestones',
                      value: prefs.reportsAlerts,
                      disabled: isUpdating,
                      showDivider: true,
                      onChanged: (val) =>
                          notifier.updateEventPreference(reports: val),
                    ),
                    _buildSwitchRow(
                      icon: Icons.campaign_outlined,
                      iconColor: const Color(0xFFEC4899),
                      title: 'Announcements & School News',
                      subtitle: 'Timetable announcements and school notices',
                      value: prefs.admissionsAlerts,
                      disabled: isUpdating,
                      showDivider: false,
                      onChanged: (val) =>
                          notifier.updateEventPreference(admissions: val),
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
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
    bool disabled = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: disabled ? null : onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF1E4ED8),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0xFFF1F5F9),
            indent: 64,
            endIndent: 16,
          ),
      ],
    );
  }
}
