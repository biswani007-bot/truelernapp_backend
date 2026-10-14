import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/class_entity.dart';

/// Class item card displaying a single scheduled session on SCR-13.
///
/// Governance:
/// - Parent observer view: shows class subject, title, timings, teacher, and status.
/// - Strictly observation-only: no "Join Class", "Meeting Room", or Jitsi actions.
/// - Status pills follow Figma design system:
///   - UPCOMING: Soft blue bg (#EFF6FF), text #1E60D4
///   - LIVE: Soft green bg (#ECFDF5), text #10B981
///   - COMPLETED: Neutral slate bg (#F1F5F9), text #64748B
class ClassCard extends StatelessWidget {
  const ClassCard({super.key, required this.session, this.onTap});

  final ClassEntity session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubject = session.subject != null && session.subject!.isNotEmpty;
    final timeRange = _formatTimeRange(
      session.scheduledStartTime,
      session.scheduledEndTime,
    );
    final status = session.status?.toUpperCase() ?? 'UPCOMING';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Subject tag + Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasSubject)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.subject!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  session.title.isNotEmpty ? session.title : 'Live Session',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Divider line
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Bottom row: Time / Schedule + Teacher
                Row(
                  children: [
                    // Time icon + text
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        timeRange,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Teacher avatar and name
                    if (session.teacherName != null &&
                        session.teacherName!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage: session.teacherAvatar != null
                                ? NetworkImage(session.teacherAvatar!)
                                : null,
                            child: session.teacherAvatar == null
                                ? Text(
                                    session.teacherName![0].toUpperCase(),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              session.teacherName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    Widget? leadingIcon;

    switch (status) {
      case 'LIVE':
        bg = AppColors.successBg;
        fg = AppColors.success;
        leadingIcon = Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        );
        break;
      case 'COMPLETED':
        bg = AppColors.surfaceSecondary;
        fg = AppColors.textSecondary;
        break;
      case 'CANCELLED':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        break;
      case 'UPCOMING':
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1E60D4);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?leadingIcon,
          Text(
            status,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Schedule TBA';
    final startTimeStr = _formatTime(start);
    if (end == null) return startTimeStr;
    final endTimeStr = _formatTime(end);
    return '$startTimeStr - $endTimeStr';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $ampm';
  }
}
