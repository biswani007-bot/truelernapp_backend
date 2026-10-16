import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable TrueLern pull-to-refresh indicator.
///
/// Wraps Flutter's native [RefreshIndicator] with the standardized
/// TrueLern primary brand color (#0037B1) and consistent styling.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor = Colors.white,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
