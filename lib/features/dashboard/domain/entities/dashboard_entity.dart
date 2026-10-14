import '../../../classes/domain/entities/class_entity.dart';

/// Represents an enrolled batch / course summary for the active child.
class EnrolledBatchEntity {
  const EnrolledBatchEntity({
    required this.id,
    required this.batchName,
    this.batchCode,
    this.courseName,
    this.instructor,
    this.progressPercentage,
  });

  final String id;
  final String batchName;
  final String? batchCode;
  final String? courseName;
  final String? instructor;
  final double? progressPercentage;

  EnrolledBatchEntity copyWith({
    String? id,
    String? batchName,
    String? batchCode,
    String? courseName,
    String? instructor,
    double? progressPercentage,
  }) {
    return EnrolledBatchEntity(
      id: id ?? this.id,
      batchName: batchName ?? this.batchName,
      batchCode: batchCode ?? this.batchCode,
      courseName: courseName ?? this.courseName,
      instructor: instructor ?? this.instructor,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

/// Domain entity for Parent Dashboard summary metrics.
///
/// Source: GET /api/parent/children/{childStudentId}/dashboard
/// Governance: docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04, Item 2
class DashboardEntity {
  const DashboardEntity({
    this.studentName,
    this.attendanceRate,
    this.upcomingClassesCount,
    this.pendingAssignmentsCount,
    this.totalBalanceDue,
    this.activeTopic,
    this.featuredClass,
    this.enrolledBatches = const [],
    this.overallProgress,
  });

  /// Name of the student (for student-mode greeting). Null for generic parent view.
  final String? studentName;

  /// Attendance percentage for the active child (0.0–100.0). Null if not available.
  final double? attendanceRate;

  /// Count of scheduled upcoming live classes. Null if not available.
  final int? upcomingClassesCount;

  /// Count of assignments pending submission. Null if not available.
  final int? pendingAssignmentsCount;

  /// Outstanding tuition balance due. Null if not available.
  final double? totalBalanceDue;

  /// Active curriculum topic / course headline.
  final String? activeTopic;

  /// Upcoming featured live class session.
  final ClassEntity? featuredClass;

  /// List of batches the child is actively enrolled in.
  final List<EnrolledBatchEntity> enrolledBatches;

  /// Overall completion percentage (0.0–100.0). Null if not available.
  final double? overallProgress;

  /// Returns true if the entity has at least one non-null metric.
  bool get hasData =>
      attendanceRate != null ||
      upcomingClassesCount != null ||
      pendingAssignmentsCount != null ||
      totalBalanceDue != null ||
      featuredClass != null ||
      overallProgress != null ||
      enrolledBatches.isNotEmpty;

  DashboardEntity copyWith({
    String? studentName,
    double? attendanceRate,
    int? upcomingClassesCount,
    int? pendingAssignmentsCount,
    double? totalBalanceDue,
    String? activeTopic,
    ClassEntity? featuredClass,
    bool clearFeaturedClass = false,
    List<EnrolledBatchEntity>? enrolledBatches,
    double? overallProgress,
  }) {
    return DashboardEntity(
      studentName: studentName ?? this.studentName,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      upcomingClassesCount: upcomingClassesCount ?? this.upcomingClassesCount,
      pendingAssignmentsCount:
          pendingAssignmentsCount ?? this.pendingAssignmentsCount,
      totalBalanceDue: totalBalanceDue ?? this.totalBalanceDue,
      activeTopic: activeTopic ?? this.activeTopic,
      featuredClass: clearFeaturedClass
          ? null
          : (featuredClass ?? this.featuredClass),
      enrolledBatches: enrolledBatches ?? this.enrolledBatches,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }
}
