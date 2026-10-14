import '../../data/models/add_child_request_dto.dart';
import '../entities/child_entity.dart';
import '../entities/dashboard_entity.dart';

/// Abstract repository contract for Dashboard domain operations.
///
/// Governance: All methods map strictly to verified Postman endpoints.
/// docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04
abstract class DashboardRepository {
  /// Fetches the list of children linked to the authenticated parent.
  ///
  /// Endpoint: GET /api/parent/children
  /// Auth: Bearer token (injected by AuthInterceptor)
  /// Returns: List of [ChildEntity]. Empty list if no children linked.
  /// Throws: [Failure] subtypes on network/server errors.
  Future<List<ChildEntity>> getLinkedChildren();

  /// Fetches dashboard summary metrics for the given [childStudentId].
  ///
  /// Endpoint: GET /api/parent/children/{childStudentId}/dashboard
  /// Auth: Bearer token (injected by AuthInterceptor)
  /// Throws: [Failure] subtypes on network/server errors.
  Future<DashboardEntity> getChildDashboard({required String childStudentId});
}

/// Abstract contract for linking and unlinking children for a parent account.
///
/// Endpoints:
/// - POST /api/parent/children
/// - DELETE /api/parent/children/{childStudentId}
abstract class AddChildRepository {
  /// Adds and links a new child to the authenticated parent account.
  Future<ChildEntity> addChild(AddChildRequestDto request);

  /// Unlinks/removes a child from the authenticated parent account.
  Future<void> unlinkChild({required String childStudentId});
}
