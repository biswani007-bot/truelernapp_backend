import 'assignment_attachment_entity.dart';
import 'assignment_submission_entity.dart';

export 'assignment_attachment_entity.dart';

/// Status enum for assignments.
enum AssignmentStatus { pending, completed, overdue }

/// Domain entity representing an assignment in TrueLern.
class AssignmentEntity {
  final String id;
  final String title;
  final String
  topic; // e.g. "Practical Thinking", "Communication", "Time Management"
  final AssignmentStatus status;
  final String? dueDate; // e.g. "Due: Feb 20"
  final String? overdueDate; // e.g. "Was due: Feb 10"
  final int? score;
  final int? totalMarks;
  final int? passingMarks;
  final String? difficultyLevel;
  final int? maxAttempts;
  final int? totalAttemptsUsed;
  final String? grade; // e.g. "A"
  final String? feedback;
  final String? buttonText; // e.g. "Open Assignment", "Submit Late"
  final bool isLateSubmissionAllowed;
  final String? childStudentId;
  final String? description;
  final String? instructions;
  final bool canSubmit;
  final String? classId;
  final String? classTitle;
  final List<AssignmentAttachmentEntity> attachments;
  final AssignmentSubmissionEntity? submission;

  const AssignmentEntity({
    required this.id,
    required this.title,
    required this.topic,
    required this.status,
    this.dueDate,
    this.overdueDate,
    this.score,
    this.totalMarks,
    this.passingMarks,
    this.difficultyLevel,
    this.maxAttempts,
    this.totalAttemptsUsed,
    this.grade,
    this.feedback,
    this.buttonText,
    this.isLateSubmissionAllowed = false,
    this.childStudentId,
    this.description,
    this.instructions,
    this.canSubmit = true,
    this.classId,
    this.classTitle,
    this.attachments = const [],
    this.submission,
  });

  /// Strips HTML tags (e.g., <p>text</p> -> text) for clean presentation.
  String? get cleanDescription {
    final text = description ?? instructions;
    if (text == null || text.trim().isEmpty) return null;
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  AssignmentEntity copyWith({
    String? id,
    String? title,
    String? topic,
    AssignmentStatus? status,
    String? dueDate,
    String? overdueDate,
    int? score,
    int? totalMarks,
    int? passingMarks,
    String? difficultyLevel,
    int? maxAttempts,
    int? totalAttemptsUsed,
    String? grade,
    String? feedback,
    String? buttonText,
    bool? isLateSubmissionAllowed,
    String? childStudentId,
    String? description,
    String? instructions,
    bool? canSubmit,
    String? classId,
    String? classTitle,
    List<AssignmentAttachmentEntity>? attachments,
    AssignmentSubmissionEntity? submission,
  }) {
    return AssignmentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      overdueDate: overdueDate ?? this.overdueDate,
      score: score ?? this.score,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      totalAttemptsUsed: totalAttemptsUsed ?? this.totalAttemptsUsed,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      buttonText: buttonText ?? this.buttonText,
      isLateSubmissionAllowed:
          isLateSubmissionAllowed ?? this.isLateSubmissionAllowed,
      childStudentId: childStudentId ?? this.childStudentId,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      canSubmit: canSubmit ?? this.canSubmit,
      classId: classId ?? this.classId,
      classTitle: classTitle ?? this.classTitle,
      attachments: attachments ?? this.attachments,
      submission: submission ?? this.submission,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          topic == other.topic &&
          status == other.status &&
          dueDate == other.dueDate &&
          overdueDate == other.overdueDate &&
          score == other.score &&
          totalMarks == other.totalMarks &&
          passingMarks == other.passingMarks &&
          difficultyLevel == other.difficultyLevel &&
          grade == other.grade &&
          feedback == other.feedback &&
          buttonText == other.buttonText &&
          isLateSubmissionAllowed == other.isLateSubmissionAllowed;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      topic.hashCode ^
      status.hashCode ^
      dueDate.hashCode ^
      overdueDate.hashCode ^
      score.hashCode ^
      totalMarks.hashCode ^
      passingMarks.hashCode ^
      difficultyLevel.hashCode ^
      grade.hashCode ^
      feedback.hashCode ^
      buttonText.hashCode ^
      isLateSubmissionAllowed.hashCode;
}
