import '../entities/class_entity.dart';
import '../entities/class_join_entity.dart';

/// Abstract repository contract for Parent Live Classes / Timetable operations.
///
/// Governance:
/// - Authoritative endpoint: GET /api/parent/children/{childStudentId}/live-classes
/// - Classroom access endpoint: POST /api/parent/children/{childStudentId}/live-classes/{classId}/join
/// - docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04, Item 7
/// - Prohibited: GET /api/live-classes (returns 403 for Parents)
abstract class ClassesRepository {
  /// Fetches the live class schedule for the given [childStudentId].
  ///
  /// Endpoint: GET /api/parent/children/{childStudentId}/live-classes
  /// Auth: Bearer token (injected automatically by AuthInterceptor)
  /// Returns: List of [ClassEntity]. Empty list if no classes scheduled.
  /// Throws: [Failure] subtypes on network/server errors.
  Future<List<ClassEntity>> getLiveClasses(String childStudentId);

  /// Requests real live classroom access credentials for an authorized child.
  ///
  /// Endpoint: POST /api/parent/children/{childStudentId}/live-classes/{classId}/join
  /// Auth: Bearer token (injected automatically by AuthInterceptor)
  /// Returns: [ClassJoinEntity] containing cryptographic Jitsi JWT and room details.
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  });
}

