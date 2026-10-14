/// Domain entity representing a verified assessment launch session.
///
/// Backed by: GET /api/parent/children/:studentId/assessments/:assessmentId/session
class AssessmentSessionEntity {
  const AssessmentSessionEntity({
    required this.studentId,
    required this.assessmentId,
    this.studentName,
    this.studentCode,
    this.assessmentTitle,
    this.description,
    this.durationMinutes,
    this.maximumMarks,
    this.passingMarks,
    this.proxyToken,
  });

  final String studentId;
  final String assessmentId;
  final String? studentName;
  final String? studentCode;
  final String? assessmentTitle;
  final String? description;
  final int? durationMinutes;
  final int? maximumMarks;
  final int? passingMarks;
  final String? proxyToken;
}
