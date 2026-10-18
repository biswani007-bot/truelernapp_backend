import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/assignment_submission_entity.dart';

/// Data Transfer Object for assignment representations.
class AssignmentDto {
  final String id;
  final String title;
  final String? topic;
  final String status;
  final String? dueDate;
  final String? overdueDate;
  final int? score;
  final int? totalMarks;
  final int? passingMarks;
  final String? difficultyLevel;
  final int? maxAttempts;
  final int? totalAttemptsUsed;
  final String? grade;
  final String? feedback;
  final String? buttonText;
  final bool? isLateSubmissionAllowed;
  final String? description;
  final String? instructions;
  final bool? canSubmit;
  final String? classId;
  final String? classTitle;
  final List<AssignmentAttachmentEntity> attachments;
  final AssignmentSubmissionEntity? submission;

  const AssignmentDto({
    required this.id,
    required this.title,
    this.topic,
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
    this.isLateSubmissionAllowed,
    this.description,
    this.instructions,
    this.canSubmit,
    this.classId,
    this.classTitle,
    this.attachments = const [],
    this.submission,
  });

  factory AssignmentDto.fromJson(Map<String, dynamic> json) {
    AssignmentSubmissionEntity? submissionEntity;
    if (json['submission'] is Map<String, dynamic>) {
      submissionEntity = AssignmentSubmissionEntity.fromJson(
        json['submission'] as Map<String, dynamic>,
      );
    }

    String? formattedDueDate =
        json['dueDate']?.toString() ?? json['due']?.toString();
    if (formattedDueDate != null && formattedDueDate.contains('T')) {
      final parsedDate = DateTime.tryParse(formattedDueDate);
      if (parsedDate != null) {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        formattedDueDate =
            'Due: ${months[parsedDate.month - 1]} ${parsedDate.day}';
      }
    }

    String? parsedClassId =
        json['classId']?.toString() ?? json['courseId']?.toString();
    String? parsedClassTitle =
        json['className']?.toString() ??
        json['classTitle']?.toString() ??
        json['courseTitle']?.toString();
    if (json['class'] is Map<String, dynamic>) {
      final classMap = json['class'] as Map<String, dynamic>;
      parsedClassId ??=
          classMap['id']?.toString() ?? classMap['_id']?.toString();
      parsedClassTitle ??=
          classMap['title']?.toString() ?? classMap['name']?.toString();
    }

    final int? parsedScore =
        (json['score'] as num?)?.toInt() ??
        (json['marks'] as num?)?.toInt() ??
        (json['marksAwarded'] as num?)?.toInt() ??
        submissionEntity?.marksAwarded ??
        (json['submission'] is Map<String, dynamic>
            ? ((json['submission']['marksAwarded'] as num?)?.toInt() ??
                  (json['submission']['marks'] as num?)?.toInt() ??
                  (json['submission']['score'] as num?)?.toInt())
            : null);

    final String? parsedGrade =
        json['grade']?.toString() ??
        submissionEntity?.grade ??
        (json['submission'] is Map<String, dynamic>
            ? json['submission']['grade']?.toString()
            : null);

    final String? parsedFeedback =
        json['feedback']?.toString() ??
        submissionEntity?.feedback ??
        (json['submission'] is Map<String, dynamic>
            ? json['submission']['feedback']?.toString()
            : null);

    final List<AssignmentAttachmentEntity> parsedAttachments = [];
    if (json['attachments'] is List) {
      for (final item in (json['attachments'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedAttachments.add(AssignmentAttachmentEntity.fromJson(item));
        } else if (item is String && item.trim().isNotEmpty) {
          final trimmed = item.trim();
          final uri = Uri.tryParse(trimmed);
          final name = (uri != null && uri.pathSegments.isNotEmpty)
              ? uri.pathSegments.last
              : 'Attachment';
          parsedAttachments.add(
            AssignmentAttachmentEntity(
              id: name,
              fileName: name,
              fileUrl: trimmed,
              fileSize: 0,
              fileType: name.toLowerCase().endsWith('.pdf')
                  ? 'application/pdf'
                  : 'application/octet-stream',
            ),
          );
        }
      }
    }

    return AssignmentDto(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Assignment',
      topic:
          json['topic']?.toString() ??
          json['subject']?.toString() ??
          json['type']?.toString() ??
          'Academics',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      dueDate: formattedDueDate,
      overdueDate:
          json['overdueDate']?.toString() ?? json['wasDue']?.toString(),
      score: parsedScore,
      totalMarks:
          (json['totalMarks'] as num?)?.toInt() ??
          (json['maxMarks'] as num?)?.toInt() ??
          100,
      passingMarks:
          (json['passingMarks'] as num?)?.toInt() ??
          (json['passMarks'] as num?)?.toInt(),
      difficultyLevel:
          json['difficultyLevel']?.toString() ?? json['difficulty']?.toString(),
      maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
      totalAttemptsUsed:
          (json['totalAttemptsUsed'] as num?)?.toInt() ??
          (json['attemptsUsed'] as num?)?.toInt(),
      grade: parsedGrade,
      feedback: parsedFeedback,
      buttonText: json['buttonText']?.toString(),
      isLateSubmissionAllowed:
          json['lateSubmissionAllowed'] as bool? ??
          json['isLateSubmissionAllowed'] as bool? ??
          false,
      description: json['description']?.toString(),
      instructions: json['instructions']?.toString(),
      canSubmit: json['canSubmit'] as bool? ?? true,
      classId: parsedClassId,
      classTitle: parsedClassTitle,
      attachments: parsedAttachments,
      submission: submissionEntity,
    );
  }

  AssignmentEntity toEntity({String? childStudentId}) {
    final hasSubmission = submission != null;
    final isSubmittedOrCompleted =
        hasSubmission ||
        status == 'completed' ||
        status == 'submitted' ||
        status == 'evaluated' ||
        status == 'graded' ||
        status == 'accepted';

    final parsedStatus = isSubmittedOrCompleted
        ? AssignmentStatus.completed
        : switch (status) {
            'overdue' || 'late' || 'missed' => AssignmentStatus.overdue,
            _ => AssignmentStatus.pending,
          };

    final buttonLabel =
        buttonText ??
        (parsedStatus == AssignmentStatus.completed
            ? 'View Submission'
            : (parsedStatus == AssignmentStatus.overdue
                  ? 'Submit Late'
                  : 'Open Assignment'));

    return AssignmentEntity(
      id: id,
      title: title,
      topic: topic ?? 'General',
      status: parsedStatus,
      dueDate: dueDate,
      overdueDate: overdueDate,
      score: score,
      totalMarks: totalMarks,
      passingMarks: passingMarks,
      difficultyLevel: difficultyLevel,
      maxAttempts: maxAttempts,
      totalAttemptsUsed: totalAttemptsUsed,
      grade: grade,
      feedback: feedback,
      buttonText: buttonLabel,
      isLateSubmissionAllowed: isLateSubmissionAllowed ?? false,
      childStudentId: childStudentId,
      description: description,
      instructions: instructions,
      canSubmit: canSubmit ?? true,
      classId: classId,
      classTitle: classTitle,
      attachments: attachments,
      submission: submission,
    );
  }
}
