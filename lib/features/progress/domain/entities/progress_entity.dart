/// Represents completion statistics for a specific category (assessments, assignments, attendance).
class ProgressMetricEntity {
  const ProgressMetricEntity({
    this.total = 0,
    this.completed = 0,
    this.percentage = 0.0,
  });

  final int total;
  final int completed;
  final double percentage;

  int get totalClasses => total;
  int get attended => completed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressMetricEntity &&
          runtimeType == other.runtimeType &&
          total == other.total &&
          completed == other.completed &&
          percentage == other.percentage;

  @override
  int get hashCode => total.hashCode ^ completed.hashCode ^ percentage.hashCode;
}

/// Domain entity representing academic progress for a student.
class ProgressEntity {
  const ProgressEntity({
    required this.childStudentId,
    this.overallCompletion = 0.0,
    this.assessmentCompletion = const ProgressMetricEntity(),
    this.assignmentCompletion = const ProgressMetricEntity(),
    this.attendanceSummary = const ProgressMetricEntity(),
    this.activeTrack,
    this.studentName,
  });

  final String childStudentId;

  /// Overall completion percentage (0.0 to 100.0) from backend data.overallCompletion
  final double overallCompletion;

  /// Assessment completion stats from data.assessmentCompletion
  final ProgressMetricEntity assessmentCompletion;

  /// Assignment completion stats from data.assignmentCompletion
  final ProgressMetricEntity assignmentCompletion;

  /// Attendance summary stats from data.attendanceSummary
  final ProgressMetricEntity attendanceSummary;

  /// Optional active track or course name
  final String? activeTrack;

  /// Optional student name
  final String? studentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressEntity &&
          runtimeType == other.runtimeType &&
          childStudentId == other.childStudentId &&
          overallCompletion == other.overallCompletion &&
          assessmentCompletion == other.assessmentCompletion &&
          assignmentCompletion == other.assignmentCompletion &&
          attendanceSummary == other.attendanceSummary &&
          activeTrack == other.activeTrack &&
          studentName == other.studentName;

  @override
  int get hashCode =>
      childStudentId.hashCode ^
      overallCompletion.hashCode ^
      assessmentCompletion.hashCode ^
      assignmentCompletion.hashCode ^
      attendanceSummary.hashCode ^
      activeTrack.hashCode ^
      studentName.hashCode;
}
