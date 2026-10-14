import '../../domain/entities/progress_entity.dart';

/// DTO for parsing individual metric blocks (assessments, assignments, attendance).
class ProgressMetricDto {
  const ProgressMetricDto({
    this.total = 0,
    this.completed = 0,
    this.percentage = 0.0,
  });

  final int total;
  final int completed;
  final double percentage;

  factory ProgressMetricDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProgressMetricDto();

    final rawTotal = json['total'] ?? json['totalClasses'] ?? 0;
    final total = rawTotal is num ? rawTotal.toInt() : (int.tryParse('$rawTotal') ?? 0);

    final rawCompleted = json['completed'] ?? json['attended'] ?? 0;
    final completed = rawCompleted is num ? rawCompleted.toInt() : (int.tryParse('$rawCompleted') ?? 0);

    final rawPercentage = json['percentage'] ?? 0;
    final percentage = rawPercentage is num
        ? rawPercentage.toDouble()
        : (double.tryParse('$rawPercentage') ?? 0.0);

    return ProgressMetricDto(
      total: total,
      completed: completed,
      percentage: percentage,
    );
  }

  ProgressMetricEntity toEntity() {
    return ProgressMetricEntity(
      total: total,
      completed: completed,
      percentage: percentage,
    );
  }
}

/// DTO for parsing GET /api/parent/children/:studentId/progress response.
class ProgressDto {
  const ProgressDto({
    this.overallCompletion = 0.0,
    this.assessmentCompletion = const ProgressMetricDto(),
    this.assignmentCompletion = const ProgressMetricDto(),
    this.attendanceSummary = const ProgressMetricDto(),
  });

  final double overallCompletion;
  final ProgressMetricDto assessmentCompletion;
  final ProgressMetricDto assignmentCompletion;
  final ProgressMetricDto attendanceSummary;

  factory ProgressDto.fromJson(Map<String, dynamic> json) {
    // Top-level or inside "data"
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawOverall = data['overallCompletion'] ?? data['progress'] ?? 0;
    final overall = rawOverall is num
        ? rawOverall.toDouble()
        : (double.tryParse('$rawOverall') ?? 0.0);

    final assessment = ProgressMetricDto.fromJson(
      data['assessmentCompletion'] is Map<String, dynamic>
          ? data['assessmentCompletion'] as Map<String, dynamic>
          : null,
    );

    final assignment = ProgressMetricDto.fromJson(
      data['assignmentCompletion'] is Map<String, dynamic>
          ? data['assignmentCompletion'] as Map<String, dynamic>
          : null,
    );

    final attendance = ProgressMetricDto.fromJson(
      data['attendanceSummary'] is Map<String, dynamic>
          ? data['attendanceSummary'] as Map<String, dynamic>
          : null,
    );

    return ProgressDto(
      overallCompletion: overall,
      assessmentCompletion: assessment,
      assignmentCompletion: assignment,
      attendanceSummary: attendance,
    );
  }

  ProgressEntity toEntity({
    required String childStudentId,
    String? studentName,
    String? activeTrack,
  }) {
    return ProgressEntity(
      childStudentId: childStudentId,
      overallCompletion: overallCompletion,
      assessmentCompletion: assessmentCompletion.toEntity(),
      assignmentCompletion: assignmentCompletion.toEntity(),
      attendanceSummary: attendanceSummary.toEntity(),
      studentName: studentName,
      activeTrack: activeTrack,
    );
  }
}
