import '../../../dashboard/domain/entities/dashboard_entity.dart';

/// Sealed state hierarchy for the dashboard data controller.
sealed class DashboardState {
  const DashboardState();
}

/// Initial — dashboard not yet loaded.
final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Fetching dashboard data for the active child.
final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard data successfully loaded for a specific child context.
final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.childStudentId,
    required this.dashboard,
  });

  final String childStudentId;
  final DashboardEntity dashboard;
}

/// Dashboard API call failed.
final class DashboardError extends DashboardState {
  const DashboardError({required this.message});

  final String message;
}

/// No active child context — cannot load dashboard.
/// This state is set when the parent has no linked children.
final class DashboardNoChild extends DashboardState {
  const DashboardNoChild();
}
