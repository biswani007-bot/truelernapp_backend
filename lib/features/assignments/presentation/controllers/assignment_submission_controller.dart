import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../../data/repositories/assignments_repository_impl.dart';

/// State of an assignment's submission workflow.
enum SubmissionFlowStatus {
  initial,
  loadingDetail,
  notStarted,
  localFileSelected,
  submitting,
  submitted,
  error,
}

class AssignmentSubmissionState {
  final String assignmentId;
  final String? childStudentId;
  final AssignmentEntity? assignment;
  final SubmissionFlowStatus status;
  final String? localFilePath;
  final String? localFileName;
  final int? localFileSize;
  final String? localFileType;
  final double uploadProgress;
  final String? errorMessage;
  final AssignmentSubmissionEntity? submission;

  const AssignmentSubmissionState({
    required this.assignmentId,
    this.childStudentId,
    this.assignment,
    this.status = SubmissionFlowStatus.initial,
    this.localFilePath,
    this.localFileName,
    this.localFileSize,
    this.localFileType,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.submission,
  });

  /// True if the assignment has already been submitted (either from backend or locally submitted).
  bool get isSubmitted =>
      status == SubmissionFlowStatus.submitted ||
      assignment?.status == AssignmentStatus.completed ||
      submission?.status == SubmissionStatus.submitted ||
      submission?.status == SubmissionStatus.late ||
      submission?.status == SubmissionStatus.graded;

  /// Display file name: local selection priority, then backend submitted file, then fallback.
  String? get displayFileName {
    if (localFileName != null && localFileName!.isNotEmpty) {
      return localFileName;
    }
    if (submission != null && submission!.files.isNotEmpty) {
      return submission!.files.first.fileName;
    }
    return null;
  }

  /// Display file size string: e.g. "2.4 MB".
  String? get displayFileSize {
    final size =
        localFileSize ??
        (submission != null && submission!.files.isNotEmpty
            ? submission!.files.first.fileSize
            : null);
    if (size == null || size <= 0) return null;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  AssignmentSubmissionState copyWith({
    String? assignmentId,
    String? childStudentId,
    AssignmentEntity? assignment,
    SubmissionFlowStatus? status,
    String? localFilePath,
    String? localFileName,
    int? localFileSize,
    String? localFileType,
    double? uploadProgress,
    String? errorMessage,
    AssignmentSubmissionEntity? submission,
    bool clearLocalFile = false,
  }) {
    return AssignmentSubmissionState(
      assignmentId: assignmentId ?? this.assignmentId,
      childStudentId: childStudentId ?? this.childStudentId,
      assignment: assignment ?? this.assignment,
      status: status ?? this.status,
      localFilePath: clearLocalFile
          ? null
          : (localFilePath ?? this.localFilePath),
      localFileName: clearLocalFile
          ? null
          : (localFileName ?? this.localFileName),
      localFileSize: clearLocalFile
          ? null
          : (localFileSize ?? this.localFileSize),
      localFileType: clearLocalFile
          ? null
          : (localFileType ?? this.localFileType),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
      submission: submission ?? this.submission,
    );
  }
}

class AssignmentSubmissionController
    extends Notifier<Map<String, AssignmentSubmissionState>> {
  @override
  Map<String, AssignmentSubmissionState> build() => {};

  AssignmentsRepository get _repo => ref.read(assignmentsRepositoryProvider);

  AssignmentSubmissionState getState(String assignmentId) {
    return state[assignmentId] ??
        AssignmentSubmissionState(assignmentId: assignmentId);
  }

  void _updateState(String assignmentId, AssignmentSubmissionState newState) {
    state = {...state, assignmentId: newState};
  }

  /// Initializes the controller with passed entity or loads it fresh.
  Future<void> init({
    required String assignmentId,
    required String? childStudentId,
    AssignmentEntity? initialAssignment,
  }) async {
    final effectiveChildId =
        childStudentId ?? initialAssignment?.childStudentId;
    AssignmentSubmissionState current = getState(assignmentId);

    // Reset state if it belonged to a different child to prevent data leakage
    if (current.childStudentId != null &&
        effectiveChildId != null &&
        current.childStudentId != effectiveChildId) {
      current = AssignmentSubmissionState(
        assignmentId: assignmentId,
        childStudentId: effectiveChildId,
        status: SubmissionFlowStatus.loadingDetail,
      );
      _updateState(assignmentId, current);
    }

    // Only accept initialAssignment if it belongs to the active child
    final safeInitial =
        (initialAssignment != null &&
            (initialAssignment.childStudentId == null ||
                initialAssignment.childStudentId == effectiveChildId))
        ? initialAssignment
        : null;

    final isSubmitted =
        safeInitial?.submission != null ||
        safeInitial?.status == AssignmentStatus.completed;

    final initialStatus = safeInitial == null
        ? SubmissionFlowStatus.loadingDetail
        : (isSubmitted
              ? SubmissionFlowStatus.submitted
              : (current.localFilePath != null
                    ? SubmissionFlowStatus.localFileSelected
                    : SubmissionFlowStatus.notStarted));

    _updateState(
      assignmentId,
      current.copyWith(
        assignmentId: assignmentId,
        childStudentId: effectiveChildId,
        assignment: safeInitial,
        submission: safeInitial?.submission ?? current.submission,
        status: initialStatus,
      ),
    );

    // If childStudentId is available, refresh assignment detail from backend
    if (effectiveChildId != null && effectiveChildId.isNotEmpty) {
      try {
        final detail = await _repo.getAssignmentDetail(
          childStudentId: effectiveChildId,
          assignmentId: assignmentId,
        );
        if (detail != null) {
          final cur = getState(assignmentId);
          _updateState(
            assignmentId,
            cur.copyWith(
              assignment: detail,
              childStudentId: effectiveChildId,
              submission: detail.submission ?? cur.submission,
              status:
                  detail.submission != null ||
                      detail.status == AssignmentStatus.completed
                  ? SubmissionFlowStatus.submitted
                  : (cur.localFilePath != null
                        ? SubmissionFlowStatus.localFileSelected
                        : SubmissionFlowStatus.notStarted),
            ),
          );
        } else {
          final cur = getState(assignmentId);
          _updateState(
            assignmentId,
            cur.copyWith(
              status: SubmissionFlowStatus.error,
              errorMessage:
                  'This assignment does not belong to the selected child.',
            ),
          );
        }
      } catch (e) {
        final cur = getState(assignmentId);
        if (cur.assignment == null) {
          _updateState(
            assignmentId,
            cur.copyWith(
              status: SubmissionFlowStatus.error,
              errorMessage: e is Failure
                  ? e.message
                  : 'Failed to load assignment details.',
            ),
          );
        }
      }
    }
  }

  /// Sets selected local file.
  void setLocalFile({
    required String assignmentId,
    required String path,
    required String name,
    required int size,
    required String type,
  }) {
    final cur = getState(assignmentId);
    _updateState(
      assignmentId,
      cur.copyWith(
        localFilePath: path,
        localFileName: name,
        localFileSize: size,
        localFileType: type,
        status: SubmissionFlowStatus.localFileSelected,
        errorMessage: null,
      ),
    );
  }

  /// Clears selected local file.
  void clearFile(String assignmentId) {
    final cur = getState(assignmentId);
    _updateState(
      assignmentId,
      cur.copyWith(
        clearLocalFile: true,
        status: SubmissionFlowStatus.notStarted,
        errorMessage: null,
      ),
    );
  }

  /// Submits the selected file to backend.
  Future<bool> submitNow({
    required String assignmentId,
    String? comments,
  }) async {
    final cur = getState(assignmentId);
    final fileName = cur.localFileName;
    final fileSize = cur.localFileSize ?? 0;
    final fileType = cur.localFileType ?? 'application/pdf';
    final childId = cur.childStudentId ?? cur.assignment?.childStudentId;

    if (fileName == null || fileName.isEmpty) {
      _updateState(
        assignmentId,
        cur.copyWith(
          status: SubmissionFlowStatus.error,
          errorMessage: 'Please select a file to upload before submitting.',
        ),
      );
      return false;
    }

    _updateState(
      assignmentId,
      cur.copyWith(
        status: SubmissionFlowStatus.submitting,
        uploadProgress: 0.25,
        errorMessage: null,
      ),
    );

    try {
      _updateState(
        assignmentId,
        getState(assignmentId).copyWith(uploadProgress: 0.65),
      );

      AssignmentSubmissionEntity submission;
      if (childId != null && childId.isNotEmpty) {
        submission = await _repo.submitAssignment(
          childStudentId: childId,
          assignmentId: assignmentId,
          fileName: fileName,
          fileSize: fileSize,
          fileType: fileType,
          comments: comments,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        submission = AssignmentSubmissionEntity(
          submittedAt: DateTime.now(),
          status: SubmissionStatus.submitted,
          files: [
            SubmissionFileEntity(
              fileName: fileName,
              fileSize: fileSize,
              fileType: fileType,
            ),
          ],
        );
      }

      final latest = getState(assignmentId);
      _updateState(
        assignmentId,
        latest.copyWith(
          uploadProgress: 1.0,
          status: SubmissionFlowStatus.submitted,
          submission: submission,
          assignment: latest.assignment?.copyWith(
            status: AssignmentStatus.completed,
            submission: submission,
          ),
        ),
      );
      return true;
    } catch (e) {
      final latest = getState(assignmentId);
      String errorMsg = 'Submission failed. Please try again.';
      if (e is Failure) {
        errorMsg = e.message;
      } else if (e is Exception) {
        final str = e.toString();
        if (str.startsWith('Exception: ')) {
          errorMsg = str.replaceFirst('Exception: ', '');
        } else {
          errorMsg = str;
        }
      }
      _updateState(
        assignmentId,
        latest.copyWith(
          status: SubmissionFlowStatus.localFileSelected,
          errorMessage: errorMsg,
        ),
      );
      return false;
    }
  }
}

/// Global provider for all assignment submission states.
final assignmentSubmissionControllerProvider =
    NotifierProvider<
      AssignmentSubmissionController,
      Map<String, AssignmentSubmissionState>
    >(AssignmentSubmissionController.new);

/// Provider exposing submission state for a specific assignment ID.
final singleAssignmentSubmissionProvider =
    Provider.family<AssignmentSubmissionState, String>((ref, assignmentId) {
      final map = ref.watch(assignmentSubmissionControllerProvider);
      return map[assignmentId] ??
          AssignmentSubmissionState(assignmentId: assignmentId);
    });
