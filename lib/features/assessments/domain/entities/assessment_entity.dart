/// Domain entity representing an Assessment in TrueLern.
///
/// Models the contract verified from:
/// - GET /api/parent/children/:studentId/assessments (Parent role)
/// - GET /api/assessments (Student role)
/// - POST /api/assessments (Creation spec)
class AssessmentEntity {
  const AssessmentEntity({
    required this.id,
    required this.assessmentId,
    required this.title,
    this.description,
    this.type,
    this.maximumMarks,
    this.passingMarks,
    this.durationMinutes,
    required this.status,
    this.isPassed,
    this.score,
    this.percentage,
    this.feedback,
    this.startedAt,
    this.submittedAt,
    this.evaluatedAt,
    this.courseId,
    this.batchId,
    this.createdAt,
    this.dueDate,
  });

  /// Unique attempt/item ID (e.g. "6acccb0d633ddd744f43b38c" or "pending_6ac9f83db2191b5d3a4d3d8e").
  final String id;

  /// Underlying assessment ID (e.g. "6accca8d02ac1efa57e4fa54").
  final String assessmentId;

  /// Title of the assessment (e.g. "test234", "Future ").
  final String title;

  /// Description or notes (e.g. "Surprise test").
  final String? description;

  /// Type of assessment (e.g. "quiz", "module-test", "exam", "assignment").
  final String? type;

  /// Total / Maximum possible marks (e.g. 10, 100).
  final int? maximumMarks;

  /// Passing marks required (e.g. 4, 40).
  final int? passingMarks;

  /// Duration in minutes (e.g. 60, 15).
  final int? durationMinutes;

  /// Status of the assessment (e.g. "pass", "fail", "pending", "active", "completed", "submitted").
  final String status;

  /// Whether the assessment is passed according to the backend evaluation (e.g. true, false).
  final bool? isPassed;

  /// Score obtained if evaluated (e.g. 5, 15).
  final int? score;

  /// Percentage grade score (e.g. 50.0, 15.0).
  final double? percentage;

  /// Feedback comments from evaluator or system.
  final String? feedback;

  /// Assessment start timestamp.
  final DateTime? startedAt;

  /// Assessment submission timestamp.
  final DateTime? submittedAt;

  /// Assessment evaluation timestamp.
  final DateTime? evaluatedAt;

  /// Optional course reference ID.
  final String? courseId;

  /// Optional batch reference ID.
  final String? batchId;

  /// Creation date timestamp if provided.
  final DateTime? createdAt;

  /// Due date timestamp if provided.
  final DateTime? dueDate;

  /// Friendly display label for the assessment type.
  String get displayType {
    if (type == null || type!.trim().isEmpty) return 'Assessment';
    final lower = type!.trim().toLowerCase();
    if (lower == 'quiz') return 'Quiz';
    if (lower == 'exam') return 'Exam';
    if (lower == 'assignment') return 'Assignment';
    if (lower == 'test') return 'Test';
    if (lower == 'module-test') return 'Module Test';
    return type![0].toUpperCase() + type!.substring(1);
  }

  /// Whether the assessment is evaluated by the backend.
  bool get isEvaluated =>
      evaluatedAt != null ||
      status.toLowerCase() == 'pass' ||
      status.toLowerCase() == 'fail' ||
      (isPassed != null && score != null);

  /// Whether the evaluated result is a pass.
  bool get isPassedSuccessfully =>
      isPassed == true || status.toLowerCase() == 'pass';

  /// Whether the evaluated result requires a retake.
  bool get needsRetake =>
      (isPassed == false || status.toLowerCase() == 'fail') && isEvaluated;

  /// Whether the assessment was submitted and is pending teacher evaluation.
  bool get isSubmittedPendingEvaluation =>
      !isEvaluated &&
      (status.toLowerCase() == 'submitted' ||
          status.toLowerCase() == 'pending_evaluation' ||
          submittedAt != null);

  /// Whether the assessment is in a pending / not started state.
  bool get isPending => status.toLowerCase() == 'pending';

  /// Whether the assessment is currently active / in progress.
  bool get isActive =>
      status.toLowerCase() == 'active' || status.toLowerCase() == 'in_progress';

  /// Whether the assessment is completed or evaluated.
  bool get isCompleted =>
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'submitted' ||
      isEvaluated;

  /// Whether launching is allowed based on authoritative backend state.
  /// Evaluated assessments or submitted assessments cannot be launched again.
  bool get canLaunch =>
      !isEvaluated &&
      !isSubmittedPendingEvaluation &&
      status.toLowerCase() != 'completed' &&
      (isPending || isActive || status.toLowerCase() == 'published');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assessmentId == other.assessmentId &&
          status == other.status &&
          isPassed == other.isPassed &&
          score == other.score &&
          percentage == other.percentage;

  @override
  int get hashCode =>
      id.hashCode ^
      assessmentId.hashCode ^
      status.hashCode ^
      isPassed.hashCode ^
      score.hashCode ^
      percentage.hashCode;
}
