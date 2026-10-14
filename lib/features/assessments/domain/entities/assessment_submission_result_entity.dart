/// Domain entity representing the verified submission outcome of an assessment attempt.
///
/// Backed by POST /api/assessments/:assessmentId/submit
class AssessmentSubmissionResultEntity {
  const AssessmentSubmissionResultEntity({
    required this.isSuccess,
    required this.status,
    this.attemptId,
    this.score,
    this.totalMarksObtained,
    this.maximumMarks,
    this.passingMarks,
    this.percentage,
    this.grade,
    this.isPassed,
    this.timeTakenSeconds,
    this.submittedAt,
    this.message,
    this.isPendingEvaluation = false,
  });

  final bool isSuccess;
  final String status;
  final String? attemptId;
  final int? score;
  final int? totalMarksObtained;
  final int? maximumMarks;
  final int? passingMarks;
  final double? percentage;
  final String? grade;
  final bool? isPassed;
  final int? timeTakenSeconds;
  final DateTime? submittedAt;
  final String? message;
  final bool isPendingEvaluation;

  int get finalScore => totalMarksObtained ?? score ?? 0;
  bool get isPassedSuccessfully =>
      isPassed == true || status.toLowerCase() == 'pass';
}
