import '../entities/counseling_request_entity.dart';
import '../entities/counselor_entity.dart';

/// Abstract repository defining contracts for the Counselor feature.
abstract class CounselorRepository {
  /// Fetches the active counsellors list.
  ///
  /// Backed by `GET /api/counselling`.
  Future<List<CounselorEntity>> getCounselors();

  /// Fetches existing counselling requests / appointments for the authenticated user.
  ///
  /// Backed by `GET /api/counselling/my-requests`.
  Future<List<CounselingRequestEntity>> getMyRequests();

  /// Submits a new counselling session request.
  ///
  /// Backed by `POST /api/counselling`.
  Future<CounselingRequestEntity> submitRequest({
    required String counsellorId,
    required String studentId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required String reason,
  });
}
