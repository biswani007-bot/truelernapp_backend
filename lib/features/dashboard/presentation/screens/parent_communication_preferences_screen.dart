import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/notification_preferences_controller.dart';
import '../controllers/notification_preferences_state.dart';
import '../widgets/security_privacy_sub_app_bar.dart';

/// Screen 4 — Communication Preferences.
///
/// Features:
/// - Real backend integration with `GET /api/notifications/preferences` and `POST /api/notifications/preferences`
/// - Push Notifications group
/// - Email Notifications group
/// - WhatsApp Notifications group
/// - Real-time channel and event preference synchronization with the backend
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
      ref.read(notificationPreferencesControllerProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationPreferencesControllerProvider);

    ref.listen<NotificationPreferencesState>(
      notificationPreferencesControllerProvider,
      (prev, next) {
        if (next is NotificationPreferencesLoaded && next.feedbackMessage != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.feedbackMessage!,
                style: GoogleFonts.hankenGrotesk(fontSize: 13),
              ),
              backgroundColor: next.isError ? AppColors.error : const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          ref.read(notificationPreferencesControllerProvider.notifier).clearFeedback();
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
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFE0F2FE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SecurityPrivacySubAppBar(title: 'Communication Preferences'),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationPreferencesState state) {
    if (state is NotificationPreferencesLoading || state is NotificationPreferencesInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is NotificationPreferencesError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
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
                  ref.read(notificationPreferencesControllerProvider.notifier).loadPreferences(refresh: true);
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

    if (state is NotificationPreferencesLoaded) {
      final prefs = state.preferences;
      final notifier = ref.read(notificationPreferencesControllerProvider.notifier);

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what notifications and updates you want to receive.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // Group 1: Push Notifications
                _buildSectionHeader(
                  icon: Icons.notifications_none_rounded,
                  title: 'Push Notifications',
                ),
                const SizedBox(height: 10),
                _buildGroupCard([
                  _buildSwitchRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'Push Notifications Master',
                    subtitle: 'Enable or disable all mobile push alerts',
                    value: prefs.pushEnabled,
                    showDivider: true,
                    onChanged: (val) => notifier.updateChannelPreference(push: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.calendar_today_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Class reminders',
                    subtitle: 'Upcoming and live class alerts',
                    value: prefs.pushEnabled && prefs.attendanceAlerts,
                    showDivider: true,
                    onChanged: (val) => notifier.updateEventPreference(attendance: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.assignment_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Assignments',
                    subtitle: 'New homework and submission updates',
                    value: prefs.pushEnabled && prefs.assignmentAlerts,
                    showDivider: true,
                    onChanged: (val) => notifier.updateEventPreference(assignment: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.campaign_outlined,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Announcements',
                    subtitle: 'Important school & platform updates',
                    value: prefs.pushEnabled && prefs.admissionsAlerts,
                    showDivider: false,
                    onChanged: (val) => notifier.updateEventPreference(admissions: val),
                  ),
                ]),
                const SizedBox(height: 24),

                // Group 2: Email Notifications
                _buildSectionHeader(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email Notifications',
                ),
                const SizedBox(height: 10),
                _buildGroupCard([
                  _buildSwitchRow(
                    icon: Icons.alternate_email_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Email Notifications Master',
                    subtitle: 'Receive updates via email',
                    value: prefs.emailEnabled,
                    showDivider: true,
                    onChanged: (val) => notifier.updateChannelPreference(email: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.summarize_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Class session summaries',
                    subtitle: 'Post-session teacher review summaries',
                    value: prefs.emailEnabled && prefs.attendanceAlerts,
                    showDivider: true,
                    onChanged: (val) => notifier.updateEventPreference(attendance: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.analytics_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Weekly progress reports',
                    subtitle: 'Academic progress and scorecards',
                    value: prefs.emailEnabled && prefs.reportsAlerts,
                    showDivider: false,
                    onChanged: (val) => notifier.updateEventPreference(reports: val),
                  ),
                ]),
                const SizedBox(height: 24),

                // Group 3: WhatsApp Notifications
                _buildSectionHeader(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'WhatsApp Notifications',
                ),
                const SizedBox(height: 10),
                _buildGroupCard([
                  _buildSwitchRow(
                    icon: Icons.chat_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'WhatsApp Alerts Master',
                    subtitle: 'Receive urgent notices on WhatsApp',
                    value: prefs.whatsappEnabled,
                    showDivider: true,
                    onChanged: (val) => notifier.updateChannelPreference(whatsapp: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.alarm_outlined,
                    iconColor: const Color(0xFF14B8A6),
                    title: 'Class reminders',
                    subtitle: 'Live class link reminders on WhatsApp',
                    value: prefs.whatsappEnabled && prefs.attendanceAlerts,
                    showDivider: true,
                    onChanged: (val) => notifier.updateEventPreference(attendance: val),
                  ),
                  _buildSwitchRow(
                    icon: Icons.announcement_outlined,
                    iconColor: const Color(0xFFF97316),
                    title: 'Important announcements',
                    subtitle: 'Timetable revisions and urgent notices',
                    value: prefs.whatsappEnabled && prefs.admissionsAlerts,
                    showDivider: false,
                    onChanged: (val) => notifier.updateEventPreference(admissions: val),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
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
    required bool showDivider,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
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
              const SizedBox(width: 10),
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
            indent: 66,
            endIndent: 16,
          ),
      ],
    );
  }
}
