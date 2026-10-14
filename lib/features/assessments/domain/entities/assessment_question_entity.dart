/// Domain entity representing a question within an assessment.
///
/// Verified from:
/// - GET /api/assessments/:assessmentId/questions
class AssessmentQuestionEntity {
  const AssessmentQuestionEntity({
    required this.id,
    required this.assessmentId,
    required this.questionText,
    this.questionCode,
    this.questionBankId,
    this.category,
    this.difficultyLevel,
    this.marks,
    this.type,
    this.options = const [],
    this.correctAnswer,
    this.displayOrder,
  });

  /// Unique question link ID.
  final String id;

  /// Associated assessment ID.
  final String assessmentId;

  /// The question prompt / text.
  final String questionText;

  /// Optional question bank code (e.g. "QB-1791621262314-0009").
  final String? questionCode;

  /// Question bank ID used for submission payload matching.
  final String? questionBankId;

  /// Subject category (e.g. "GK", "Science").
  final String? category;

  /// Difficulty level (e.g. "easy", "medium", "hard").
  final String? difficultyLevel;

  /// Marks awarded for this question (e.g. 5).
  final int? marks;

  /// Type of question (e.g. "MCQ", "Subjective", "true-false").
  final String? type;

  /// List of option choices for multiple choice questions.
  final List<String> options;

  /// Correct answer text if returned by server.
  final String? correctAnswer;

  /// Ordering position in the assessment.
  final int? displayOrder;

  /// Canonical ID to send when submitting answers for this question.
  String get effectiveQuestionId =>
      (questionBankId != null && questionBankId!.isNotEmpty)
      ? questionBankId!
      : id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentQuestionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assessmentId == other.assessmentId;

  @override
  int get hashCode => id.hashCode ^ assessmentId.hashCode;
}
