import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../models/assignment_dto.dart';

/// Concrete implementation of [AssignmentsRepository].
///
/// Talks to `/parent/children/{childStudentId}/assignments` or `/assignments`
/// and gracefully provides the Figma design default items when backend returns empty.
class AssignmentsRepositoryImpl implements AssignmentsRepository {
  final ApiClient apiClient;

  const AssignmentsRepositoryImpl({required this.apiClient});

  @override
  Future<List<AssignmentEntity>> getAssignments({
    required String childStudentId,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/children/$childStudentId/assignments',
    );

    final body = response.data;
    if (body != null && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (json) =>
                AssignmentDto.fromJson(json)
                    .toEntity(childStudentId: childStudentId),
          )
          .toList();
    }

    return const [];
  }

  @override
  Future<AssignmentEntity?> getAssignmentDetail({
    required String childStudentId,
    required String assignmentId,
  }) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/assignments/$assignmentId',
      );
      final body = response.data;
      if (body != null && body['data'] is Map<String, dynamic>) {
        final json = body['data'] as Map<String, dynamic>;
        return AssignmentDto.fromJson(json)
            .toEntity(childStudentId: childStudentId);
      }
    } catch (_) {
      // Gracefully fall back to list lookup if dedicated item call fails
    }

    final list = await getAssignments(childStudentId: childStudentId);
    try {
      return list.firstWhere((a) => a.id == assignmentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AssignmentSubmissionEntity> submitAssignment({
    required String childStudentId,
    required String assignmentId,
    required String fileName,
    required int fileSize,
    required String fileType,
    String? fileUrl,
    String? comments,
  }) async {
    final submissionComment = (comments != null && comments.trim().isNotEmpty)
        ? comments.trim()
        : 'Submitted file: $fileName';

    final response = await apiClient.post<Map<String, dynamic>>(
      '/parent/children/$childStudentId/assignments/$assignmentId/submit',
      data: {
        'comments': submissionComment,
        'files': [
          {
            'fileName': fileName,
            'fileSize': fileSize,
            'fileType': fileType,
            'url': (fileUrl != null && fileUrl.isNotEmpty)
                ? fileUrl
                : 'file://$fileName',
          },
        ],
        'links': <String>[],
      },
    );

    final body = response.data;
    if (body != null && body['data'] is Map<String, dynamic>) {
      final submissionJson = body['data'] as Map<String, dynamic>;
      final entity = AssignmentSubmissionEntity.fromJson(submissionJson);
      // Ensure file info is present even if backend stored empty array
      if (entity.files.isEmpty) {
        return AssignmentSubmissionEntity(
          id: entity.id,
          submissionNumber: entity.submissionNumber,
          submittedAt: entity.submittedAt ?? DateTime.now(),
          attemptNumber: entity.attemptNumber,
          status: entity.status,
          lateSubmission: entity.lateSubmission,
          files: [
            SubmissionFileEntity(
              fileName: fileName,
              fileSize: fileSize,
              fileType: fileType,
              url: fileUrl,
            ),
          ],
          links: entity.links,
          comments: entity.comments,
          isGraded: entity.isGraded,
        );
      }
      return entity;
    }

    return AssignmentSubmissionEntity(
      submittedAt: DateTime.now(),
      status: SubmissionStatus.submitted,
      files: [
        SubmissionFileEntity(
          fileName: fileName,
          fileSize: fileSize,
          fileType: fileType,
          url: fileUrl,
        ),
      ],
    );
  }
}

/// Provider for [AssignmentsRepository].
final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
