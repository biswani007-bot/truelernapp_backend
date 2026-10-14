import 'assessment_question_entity.dart';

/// Domain entity representing a prepared assessment attempt ready for native test-taking.
///
/// Combines verified assessment session, detail metadata, and question specifications.
class AssessmentAttemptDetailsEntity {
  const AssessmentAttemptDetailsEntity({
    required this.assessmentId,
    required this.assessmentTitle,
    required this.studentId,
    required this.studentName,
    required this.attemptId,
    required this.startedAt,
    required this.questions,
    this.description,
    this.instructions,
    this.durationMinutes,
    this.maximumMarks,
    this.passingMarks,
    this.initialAnswers = const {},
    this.isResumed = false,
  });

  final String assessmentId;
  final String assessmentTitle;
  final String studentId;
  final String studentName;
  final String attemptId;
  final DateTime startedAt;
  final List<AssessmentQuestionEntity> questions;
  final String? description;
  final String? instructions;
  final int? durationMinutes;
  final int? maximumMarks;
  final int? passingMarks;
  final Map<String, dynamic> initialAnswers;
  final bool isResumed;

  int get totalQuestions => questions.length;
}
