import '../entities/class_entity.dart';
import '../entities/class_summary_entity.dart';

/// Contract for fetching post-class session summary data.
abstract class ClassSummaryRepository {
  Future<ClassSummaryEntity> getClassSummary({
    required String childStudentId,
    required String classId,
    ClassEntity? session,
  });
}
