/// Represents an attached file metadata in an assignment submission.
class SubmissionFileEntity {
  final String fileName;
  final int fileSize;
  final String fileType;
  final String? url;

  const SubmissionFileEntity({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.url,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileSize': fileSize,
    'fileType': fileType,
    if (url != null) 'url': url,
  };

  factory SubmissionFileEntity.fromJson(Map<String, dynamic> json) {
    return SubmissionFileEntity(
      fileName:
          json['fileName']?.toString() ??
          json['name']?.toString() ??
          'attachment.pdf',
      fileSize:
          (json['fileSize'] as num?)?.toInt() ??
          (json['size'] as num?)?.toInt() ??
          0,
      fileType:
          json['fileType']?.toString() ??
          json['mimeType']?.toString() ??
          'application/pdf',
      url: json['url']?.toString(),
    );
  }
}

/// Represents submission status of an assignment.
enum SubmissionStatus { notStarted, draft, submitted, late, graded }

/// Domain entity representing a submission record for an assignment.
class AssignmentSubmissionEntity {
  final String? id;
  final String? submissionNumber;
  final DateTime? submittedAt;
  final int attemptNumber;
  final SubmissionStatus status;
  final bool lateSubmission;
  final List<SubmissionFileEntity> files;
  final List<String> links;
  final String? comments;
  final bool isGraded;
  final String? rawStatus;
  final int? marksAwarded;
  final String? grade;
  final String? feedback;

  const AssignmentSubmissionEntity({
    this.id,
    this.submissionNumber,
    this.submittedAt,
    this.attemptNumber = 1,
    required this.status,
    this.lateSubmission = false,
    this.files = const [],
    this.links = const [],
    this.comments,
    this.isGraded = false,
    this.rawStatus,
    this.marksAwarded,
    this.grade,
    this.feedback,
  });

  factory AssignmentSubmissionEntity.fromJson(Map<String, dynamic> json) {
    final rawStatusString =
        json['status']?.toString() ?? json['submissionStatus']?.toString();
    final statusStr = rawStatusString?.toLowerCase();

    final rawMarks =
        json['marksAwarded'] ??
        json['marks'] ??
        json['score'] ??
        (json['evaluation'] is Map<String, dynamic>
            ? (json['evaluation']['marksAwarded'] ??
                  json['evaluation']['marks'] ??
                  json['evaluation']['score'])
            : null);
    final int? marksAwarded = (rawMarks as num?)?.toInt();

    final rawGrade =
        json['grade'] ??
        (json['evaluation'] is Map<String, dynamic>
            ? json['evaluation']['grade']
            : null);
    final String? grade = rawGrade?.toString();

    final rawFeedback =
        json['feedback'] ??
        (json['evaluation'] is Map<String, dynamic>
            ? json['evaluation']['feedback']
            : null);
    final String? feedback = rawFeedback?.toString();

    final bool isGraded =
        json['isGraded'] == true ||
        statusStr == 'graded' ||
        statusStr == 'evaluated' ||
        marksAwarded != null ||
        (grade != null && grade.isNotEmpty);

    final status = switch (statusStr) {
      'submitted' || 'under_review' || 'in_review' || 'pending_review' =>
        isGraded ? SubmissionStatus.graded : SubmissionStatus.submitted,
      'late' || 'submitted_late' =>
        isGraded ? SubmissionStatus.graded : SubmissionStatus.late,
      'draft' => SubmissionStatus.draft,
      'graded' || 'evaluated' => SubmissionStatus.graded,
      _ => isGraded ? SubmissionStatus.graded : SubmissionStatus.submitted,
    };

    final filesList =
        (json['files'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((f) => SubmissionFileEntity.fromJson(f))
            .toList() ??
        [];

    final linksList =
        (json['links'] as List?)?.map((l) => l.toString()).toList() ?? [];

    DateTime? submittedDate;
    final rawDate =
        json['submittedAt'] ??
        json['submitted_at'] ??
        json['createdAt'] ??
        json['created_at'] ??
        json['submissionDate'] ??
        json['submittedDate'];

    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) {
        submittedDate = parsed.toLocal();
      }
    }

    return AssignmentSubmissionEntity(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      submissionNumber: json['submissionNumber']?.toString(),
      submittedAt: submittedDate,
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
      status: status,
      lateSubmission:
          json['lateSubmission'] == true ||
          statusStr == 'late' ||
          statusStr == 'submitted_late',
      files: filesList,
      links: linksList,
      comments: json['comments']?.toString(),
      isGraded: isGraded,
      rawStatus: rawStatusString,
      marksAwarded: marksAwarded,
      grade: grade,
      feedback: feedback,
    );
  }
}
