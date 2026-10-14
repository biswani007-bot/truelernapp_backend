import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../domain/entities/security_activity_entity.dart';
import '../controllers/security_activity_controller.dart';
import '../controllers/security_activity_state.dart';
import '../widgets/security_privacy_sub_app_bar.dart';

/// Screen — Recent Security Activity.
///
/// Backed by real API: `GET /api/auth/activity` (returns authentication and security audit logs).
class ParentRecentSecurityActivityScreen extends ConsumerStatefulWidget {
  const ParentRecentSecurityActivityScreen({super.key});

  @override
  ConsumerState<ParentRecentSecurityActivityScreen> createState() =>
      _ParentRecentSecurityActivityScreenState();
}

class _ParentRecentSecurityActivityScreenState
    extends ConsumerState<ParentRecentSecurityActivityScreen> {
  final List<String> _filters = const ['All', 'Logins', 'Devices', 'Security'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(securityActivityControllerProvider.notifier)
          .loadActivityLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityActivityControllerProvider);

    return Scaffold(
      key: const Key('parent_recent_security_activity_screen'),
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
              const SecurityPrivacySubAppBar(title: 'Recent Security Activity'),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(securityActivityControllerProvider.notifier)
                        .loadActivityLogs(forceRefresh: true);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'View your login history and account security events.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFilterChips(state),
                            const SizedBox(height: 24),
                            _buildBody(context, state),
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
    );
  }

  Widget _buildFilterChips(SecurityActivityState state) {
    final selected = state is SecurityActivityLoaded
        ? state.selectedFilter
        : 'All';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = selected.toLowerCase() == filter.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  ref
                      .read(securityActivityControllerProvider.notifier)
                      .setFilter(filter);
                }
              },
              selectedColor: const Color(0xFF1E4ED8),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.hankenGrotesk(
                color: isSelected ? Colors.white : const Color(0xFF434655),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1E4ED8)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SecurityActivityState state) {
    if (state is SecurityActivityLoading || state is SecurityActivityInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state is SecurityActivityError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load security activity',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1B23),
              ),
            ),
            const SizedBox(height: 6),
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
                    .read(securityActivityControllerProvider.notifier)
                    .loadActivityLogs(forceRefresh: true);
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
      );
    }

    if (state is SecurityActivityLoaded) {
      final items = state.filteredActivities;

      if (items.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                'No Activity Recorded',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.selectedFilter == 'All'
                    ? 'No security events have been logged for this account yet.'
                    : 'No "${state.selectedFilter}" events found in your recent history.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }

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
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: Color(0xFFF1F5F9),
            indent: 64,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final activity = items[index];
            return _buildActivityTile(activity);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActivityTile(SecurityActivityEntity activity) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity.iconData,
              color: activity.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.displayTitle,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.displayDescription,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.formattedTimestamp,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
