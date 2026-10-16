import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/dashboard_entity.dart';

/// 2x2 Bento Grid matching Figma Node 76:3646 (Section - Child Progress Snapshot).
///
/// Bento Cards:
/// 1. Overall Progress / Score (76:3647): Trend icon, percentage, linear progress bar.
/// 2. Attendance (76:3659): Calendar/Fact-check icon, attendance %, weekly delta tag.
/// 3. Assignments (76:3671): Homework icon, pending count, 'Pending' label.
/// 4. Current Topic / Focus (76:3682): Speech bubble icon, active topic headline.
class BentoSnapshotGrid extends StatelessWidget {
  const BentoSnapshotGrid({
    super.key,
    required this.dashboard,
    this.activeTopic = 'Speaking With Confidence',
  });

  final DashboardEntity dashboard;
  final String activeTopic;

  @override
  Widget build(BuildContext context) {
    final assignmentsPending = dashboard.pendingAssignmentsCount != null
        ? '${dashboard.pendingAssignmentsCount}'
        : '0';

    final attendancePercentage = dashboard.attendanceRate != null
        ? '${dashboard.attendanceRate!.round()}%'
        : '0%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Card 1: Counselor - White bg, border #E2E1ED, 16px radius
            Expanded(
              child: _BentoCard(
                key: const Key('bento_counselor_card'),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E1ED),
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFF434655),
                label: 'Counselor',
                value: 'Guidance',
                onTap: () => context.push(AppRoutePaths.parentCounselor),
                footer: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 13,
                      color: Color(0xFF0037B1),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Academic Support',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Attendance (76:3659) - White bg, border #E2E1ED, 16px radius, +2% this week
            Expanded(
              child: _BentoCard(
                key: const Key('bento_attendance_card'),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E1ED),
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF434655),
                label: 'Attendance',
                value: attendancePercentage,
                footer: Text(
                  '+2% this week',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Assignments (76:3671) - Lavender tint rgba(138,76,252,0.1), border rgba(138,76,252,0.2)
            Expanded(
              child: _BentoCard(
                key: const Key('bento_assignments_card'),
                backgroundColor: const Color(0x1A8A4CFC),
                borderColor: const Color(0x338A4CFC),
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF8A4CFC),
                label: 'Assignments',
                labelColor: const Color(0xFF8A4CFC),
                value: assignmentsPending,
                valueColor: const Color(0xFF8A4CFC),
                footer: Text(
                  'Pending',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF434655),
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Card 4: Current Topic (76:3682) - Cyan tint rgba(34,211,238,0.1), border rgba(34,211,238,0.2)
            Expanded(
              child: _BentoCard(
                key: const Key('bento_topic_card'),
                backgroundColor: const Color(0x1A22D3EE),
                borderColor: const Color(0x3322D3EE),
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFF22D3EE),
                label: 'Current Topic',
                labelColor: const Color(0xFF22D3EE),
                value: activeTopic,
                isTopicText: true,
                footer: const SizedBox.shrink(),
                onTap: () =>
                    context.push(AppRoutePaths.topicDetail, extra: activeTopic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    required this.value,
    this.valueColor,
    required this.footer,
    this.isTopicText = false,
    this.onTap,
  });

  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String value;
  final Color? valueColor;
  final Widget footer;
  final bool isTopicText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000), // rgba(0,0,0,0.05)
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: labelColor ?? const Color(0xFF434655),
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isTopicText)
              Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A1B23),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                value,
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF1A1B23),
                  height: 1.0,
                ),
              ),
            footer,
          ],
        ),
      ),
    );
  }
}
