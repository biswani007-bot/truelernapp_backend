import '../entities/assignment_entity.dart';
import '../entities/assignment_submission_entity.dart';

/// Contract for fetching and submitting child assignments.
abstract class AssignmentsRepository {
  Future<List<AssignmentEntity>> getAssignments({
    required String childStudentId,
  });

  Future<AssignmentEntity?> getAssignmentDetail({
    required String childStudentId,
    required String assignmentId,
  });

  Future<AssignmentSubmissionEntity> submitAssignment({
    required String childStudentId,
    required String assignmentId,
    required String fileName,
    required int fileSize,
    required String fileType,
    String? fileUrl,
    String? comments,
  });
}
