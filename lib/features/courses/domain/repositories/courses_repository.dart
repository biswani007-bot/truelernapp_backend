import '../entities/course_entity.dart';

/// Contract for fetching real, database-backed courses from TrueLern.
abstract class CoursesRepository {
  /// Calls GET /api/public/courses to retrieve published catalog courses.
  Future<List<CourseEntity>> getPublicCourses();

  /// Retrieves a specific course by its unique backend ID or slug.
  Future<CourseEntity?> getCourseById(String id);
}
