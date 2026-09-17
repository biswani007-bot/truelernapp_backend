import '../entities/dashboard_entity.dart';

/// Abstract repository contract for Student-specific Dashboard operations.
///
/// Unlike Parent Dashboard (which requires parent credentials and a childStudentId),
/// Student Dashboard uses the authenticated Student session directly and composes
/// data from verified Student-authorized endpoints:
/// - GET /api/live-classes
/// - GET /api/assignments
/// - GET /api/attendance/summary
abstract class StudentDashboardRepository {
  /// Fetches and composes the student dashboard metrics.
  ///
  /// Auth: Bearer token (Student role, injected by AuthInterceptor)
  /// Returns: [DashboardEntity] with student metrics.
  Future<DashboardEntity> getStudentDashboard();
}
