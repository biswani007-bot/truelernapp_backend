import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Dashboard hero greeting card.
///
/// Displays a warm greeting with the active child's first name.
/// Uses the brand primary gradient as background.
/// Child name comes from the verified API response — never hardcoded.
class DashboardHeaderCard extends StatelessWidget {
  const DashboardHeaderCard({
    super.key,
    this.parentName,
    this.childFirstName,
    this.childGrade,
  });

  /// Parent's display name from auth session. May be null.
  final String? parentName;

  /// Child's first name from /api/parent/children. May be null.
  final String? childFirstName;

  /// Child's grade/class label from /api/parent/children. May be null.
  final String? childGrade;

  @override
  Widget build(BuildContext context) {
    final greeting = parentName != null && parentName!.isNotEmpty
        ? 'Hi, ${parentName!.split(' ').first}! 👋'
        : 'Hi there! 👋';

    final childSubtitle = childFirstName != null && childFirstName!.isNotEmpty
        ? "Let's check on ${childFirstName!}'s learning today."
        : "Let's check on your child's learning today.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3578), Color(0xFF1E60D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textInverse,
                    fontSize: 23.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  childSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.85),
                  ),
                ),
                if (childGrade != null && childGrade!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      childGrade!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
