import '../entities/progress_entity.dart';

/// Abstract repository contract for academic progress operations.
abstract class ProgressRepository {
  /// Fetches progress metrics for a given child student ID.
  /// Calls GET /api/parent/children/:studentId/progress
  Future<ProgressEntity> getChildProgress({
    required String childStudentId,
    String? studentName,
    String? activeTrack,
  });

  /// Fetches course progress for a student.
  /// Calls GET /api/student/courses/:courseId/progress
  Future<double> getStudentCourseProgress({
    required String courseId,
  });
}
