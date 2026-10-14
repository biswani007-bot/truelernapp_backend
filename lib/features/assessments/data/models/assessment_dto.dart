import '../../domain/entities/assessment_entity.dart';

/// Data Transfer Object for parsing assessment payloads defensively.
class AssessmentDto {
  const AssessmentDto({
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

  final String id;
  final String assessmentId;
  final String title;
  final String? description;
  final String? type;
  final int? maximumMarks;
  final int? passingMarks;
  final int? durationMinutes;
  final String status;
  final bool? isPassed;
  final int? score;
  final double? percentage;
  final String? feedback;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? evaluatedAt;
  final String? courseId;
  final String? batchId;
  final DateTime? createdAt;
  final DateTime? dueDate;

  factory AssessmentDto.fromJson(Map<String, dynamic> json) {
    // Determine IDs: in child assessments, "assessmentId" is the core ID and "id" is the status key
    final rawId = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final rawAssessmentId =
        json['assessmentId']?.toString() ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        '';

    final maxMarks =
        (json['maximumMarks'] as num?)?.toInt() ??
        (json['totalMarks'] as num?)?.toInt() ??
        (json['marks'] as num?)?.toInt();

    final passMarks = (json['passingMarks'] as num?)?.toInt();

    final duration =
        (json['duration'] as num?)?.toInt() ??
        (json['durationMinutes'] as num?)?.toInt();

    final scoreVal =
        (json['scoreObtained'] as num?)?.toInt() ??
        (json['marksObtained'] as num?)?.toInt() ??
        (json['score'] as num?)?.toInt() ??
        (json['marksAwarded'] as num?)?.toInt();

    final percentageVal = (json['percentage'] as num?)?.toDouble();

    final bool? isPassedVal = json['isPassed'] is bool
        ? json['isPassed'] as bool
        : (json['isPassed']?.toString() == 'true'
              ? true
              : (json['isPassed']?.toString() == 'false' ? false : null));

    DateTime? parsedCreated;
    if (json['createdAt'] != null) {
      parsedCreated = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? parsedDue;
    if (json['dueDate'] != null) {
      parsedDue = DateTime.tryParse(json['dueDate'].toString());
    }

    DateTime? parsedStarted;
    if (json['startedAt'] != null) {
      parsedStarted = DateTime.tryParse(json['startedAt'].toString());
    }

    DateTime? parsedSubmitted;
    if (json['submittedAt'] != null) {
      parsedSubmitted = DateTime.tryParse(json['submittedAt'].toString());
    }

    DateTime? parsedEvaluated;
    if (json['evaluatedAt'] != null) {
      parsedEvaluated = DateTime.tryParse(json['evaluatedAt'].toString());
    }

    final courseVal = json['course'] is Map
        ? (json['course'] as Map)['_id']?.toString()
        : (json['course'] ?? json['courseId'])?.toString();

    final batchVal = json['batch'] is Map
        ? (json['batch'] as Map)['_id']?.toString()
        : (json['batch'] ?? json['batchId'])?.toString();

    return AssessmentDto(
      id: rawId,
      assessmentId: rawAssessmentId,
      title: (json['title']?.toString() ?? 'Assessment').trim(),
      description: (json['description'] ?? json['notes'])?.toString(),
      type: json['type']?.toString(),
      maximumMarks: maxMarks,
      passingMarks: passMarks,
      durationMinutes: duration,
      status: (json['status']?.toString() ?? 'pending').toLowerCase().trim(),
      isPassed: isPassedVal,
      score: scoreVal,
      percentage: percentageVal,
      feedback: json['feedback']?.toString(),
      startedAt: parsedStarted,
      submittedAt: parsedSubmitted,
      evaluatedAt: parsedEvaluated,
      courseId: courseVal,
      batchId: batchVal,
      createdAt: parsedCreated,
      dueDate: parsedDue,
    );
  }

  AssessmentEntity toEntity() {
    return AssessmentEntity(
      id: id,
      assessmentId: assessmentId,
      title: title,
      description: description,
      type: type,
      maximumMarks: maximumMarks,
      passingMarks: passingMarks,
      durationMinutes: durationMinutes,
      status: status,
      isPassed: isPassed,
      score: score,
      percentage: percentage,
      feedback: feedback,
      startedAt: startedAt,
      submittedAt: submittedAt,
      evaluatedAt: evaluatedAt,
      courseId: courseId,
      batchId: batchId,
      createdAt: createdAt,
      dueDate: dueDate,
    );
  }
}
