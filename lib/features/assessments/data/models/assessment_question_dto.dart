import '../../domain/entities/assessment_question_entity.dart';

/// Data Transfer Object for parsing assessment questions defensively.
class AssessmentQuestionDto {
  const AssessmentQuestionDto({
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

  final String id;
  final String assessmentId;
  final String questionText;
  final String? questionCode;
  final String? questionBankId;
  final String? category;
  final String? difficultyLevel;
  final int? marks;
  final String? type;
  final List<String> options;
  final String? correctAnswer;
  final int? displayOrder;

  factory AssessmentQuestionDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final rawAssessmentId =
        json['assessment']?.toString() ??
        json['assessmentId']?.toString() ??
        '';

    final qb = json['questionBank'] is Map<String, dynamic>
        ? json['questionBank'] as Map<String, dynamic>
        : null;

    final qbId =
        qb?['_id']?.toString() ??
        json['questionBankId']?.toString() ??
        (qb?['id']?.toString());

    final text =
        qb?['questionText']?.toString() ??
        json['questionText']?.toString() ??
        json['text']?.toString() ??
        'Question';

    final code =
        qb?['questionCode']?.toString() ?? json['questionCode']?.toString();

    final cat = qb?['category']?.toString() ?? json['category']?.toString();

    final diff =
        qb?['difficultyLevel']?.toString() ??
        json['difficultyLevel']?.toString();

    final marksVal =
        (json['marksOverride'] as num?)?.toInt() ??
        (qb?['marks'] as num?)?.toInt() ??
        (json['marks'] as num?)?.toInt();

    final qType = qb?['type']?.toString() ?? json['type']?.toString();

    final rawOptions = qb?['options'] ?? json['options'];
    final List<String> parsedOptions = [];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt != null) parsedOptions.add(opt.toString());
      }
    }
    if (parsedOptions.isEmpty &&
        (qType?.toLowerCase() == 'true-false' ||
            qType?.toLowerCase() == 'true_false' ||
            qType?.toLowerCase() == 'boolean')) {
      parsedOptions.addAll(['True', 'False']);
    }

    final answer =
        qb?['correctAnswer']?.toString() ?? json['correctAnswer']?.toString();

    final order =
        (json['displayOrder'] as num?)?.toInt() ??
        (json['order'] as num?)?.toInt();

    return AssessmentQuestionDto(
      id: rawId,
      assessmentId: rawAssessmentId,
      questionText: text,
      questionCode: code,
      questionBankId: qbId,
      category: cat,
      difficultyLevel: diff,
      marks: marksVal,
      type: qType,
      options: parsedOptions,
      correctAnswer: answer,
      displayOrder: order,
    );
  }

  AssessmentQuestionEntity toEntity() {
    return AssessmentQuestionEntity(
      id: id,
      assessmentId: assessmentId,
      questionText: questionText,
      questionCode: questionCode,
      questionBankId: questionBankId,
      category: category,
      difficultyLevel: difficultyLevel,
      marks: marks,
      type: type,
      options: options,
      correctAnswer: correctAnswer,
      displayOrder: displayOrder,
    );
  }
}
