import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Empty state widget for the Class Schedule (SCR-13).
///
/// Displayed when the verified API returns `HTTP 200` with an empty array `[]`.
/// Follows Figma typography, spacing, and neutral color tokens.
/// Does not invent fake classes.
class EmptyClassesWidget extends StatelessWidget {
  const EmptyClassesWidget({super.key, this.childName, this.onRefresh});

  /// Name of the active ward.
  final String? childName;

  /// Optional pull-to-refresh callback.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final title = childName != null && childName!.isNotEmpty
        ? 'No Classes Scheduled for $childName'
        : 'No Classes Scheduled';

    final subtitle = childName != null && childName!.isNotEmpty
        ? 'There are currently no live or upcoming sessions scheduled for $childName. Check back later or contact your academic counselor for updates.'
        : 'There are currently no live or upcoming sessions scheduled. New sessions will appear here as soon as they are assigned by teachers.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 19.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check for Updates'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTypography.titleSmall,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
