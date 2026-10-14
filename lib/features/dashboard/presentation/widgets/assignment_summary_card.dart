import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Shows the pending assignments count from the dashboard API response.
///
/// Data source: dashboardEntity.pendingAssignmentsCount
/// If null: displays "—" (API did not return this value)
/// If 0: shows "No pending assignments"
/// If > 0: shows count with warning color
class AssignmentSummaryCard extends StatelessWidget {
  const AssignmentSummaryCard({super.key, required this.pendingCount});

  /// Pending assignments count from API. Null means not available from API.
  final int? pendingCount;

  @override
  Widget build(BuildContext context) {
    final hasData = pendingCount != null;
    final hasPending = hasData && pendingCount! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.warningBg : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasPending
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 24,
              color: hasPending
                  ? AppColors.warningDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignments',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPending
                      ? '${pendingCount!} pending ${pendingCount == 1 ? 'assignment' : 'assignments'}'
                      : hasData
                      ? 'No pending assignments'
                      : 'Not available',
                  style: AppTypography.titleSmall.copyWith(
                    color: hasPending
                        ? AppColors.warningDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (hasPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pendingCount!}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
