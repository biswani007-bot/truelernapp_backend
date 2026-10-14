import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Shows outstanding tuition balance from the dashboard API response.
///
/// Data source: dashboardEntity.totalBalanceDue
/// If null: "Balance information not available"
/// If 0.00: "No outstanding balance"
/// If > 0: Shows amount with error/alert color
///
/// The "View Invoices" CTA is a visual placeholder — the Invoices feature
/// is not implemented in this action.
class FinanceAlertCard extends StatelessWidget {
  const FinanceAlertCard({super.key, required this.totalBalanceDue});

  /// Outstanding balance from API. Null means not available from API.
  final double? totalBalanceDue;

  @override
  Widget build(BuildContext context) {
    final hasData = totalBalanceDue != null;
    final hasBalance = hasData && totalBalanceDue! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasBalance ? AppColors.errorBg : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBalance
              ? AppColors.error.withValues(alpha: 0.3)
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
              color: hasBalance
                  ? AppColors.error.withValues(alpha: 0.12)
                  : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 24,
              color: hasBalance ? AppColors.errorDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasBalance
                      ? '₹${totalBalanceDue!.toStringAsFixed(2)} outstanding'
                      : hasData
                      ? 'No outstanding balance'
                      : 'Balance not available',
                  style: AppTypography.titleSmall.copyWith(
                    color: hasBalance
                        ? AppColors.errorDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (hasBalance)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'View',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
