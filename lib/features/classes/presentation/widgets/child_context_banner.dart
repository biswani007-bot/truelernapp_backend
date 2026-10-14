import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/domain/entities/child_entity.dart';

/// Child context banner displayed at the top of SCR-13.
///
/// Shows the currently active child's name, grade, and an affordance
/// to switch between linked children (if more than one is linked).
class ChildContextBanner extends StatelessWidget {
  const ChildContextBanner({
    super.key,
    required this.activeChild,
    required this.children,
    required this.onChildSelected,
  });

  final ChildEntity activeChild;
  final List<ChildEntity> children;
  final ValueChanged<String> onChildSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Child avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: activeChild.avatar != null
                ? NetworkImage(activeChild.avatar!)
                : null,
            child: activeChild.avatar == null
                ? Text(
                    activeChild.firstName.isNotEmpty
                        ? activeChild.firstName[0].toUpperCase()
                        : 'C',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Child name & grade label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        activeChild.displayName,
                        style: AppTypography.bodyMediumEmphasis.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (children.length > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${children.length} wards',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activeChild.grade != null && activeChild.grade!.isNotEmpty
                      ? activeChild.grade!
                      : 'Live Classes Schedule',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Switch button if multiple children
          if (children.length > 1)
            PopupMenuButton<String>(
              key: const Key('switch_child_menu_button'),
              tooltip: 'Switch Child',
              icon: const Icon(
                Icons.unfold_more_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onSelected: onChildSelected,
              itemBuilder: (context) {
                return children.map((c) {
                  final isCurrent = c.studentId == activeChild.studentId;
                  return PopupMenuItem<String>(
                    value: c.studentId,
                    child: Row(
                      children: [
                        Icon(
                          isCurrent
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.displayName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
    );
  }
}
