import '../../../classes/domain/entities/class_entity.dart';
import '../../domain/entities/dashboard_entity.dart';

/// Data Transfer Object for dashboard summary metrics.
///
/// Governance: docs/project-source-of-truth/03-API-SOURCE-OF-TRUTH.md — Folder 04, Item 2
/// Endpoint: GET /api/parent/children/{childStudentId}/dashboard
/// Response envelope: { "success": true, "data": { attendance, upcomingLiveClasses, enrolledBatches, feeOverview, ... } }
class DashboardDto {
  const DashboardDto({
    this.attendanceRate,
    this.upcomingClassesCount,
    this.pendingAssignmentsCount,
    this.totalBalanceDue,
    this.activeTopic,
    this.featuredClass,
    this.enrolledBatches = const [],
  });

  final double? attendanceRate;
  final int? upcomingClassesCount;
  final int? pendingAssignmentsCount;
  final double? totalBalanceDue;
  final String? activeTopic;
  final ClassEntity? featuredClass;
  final List<EnrolledBatchEntity> enrolledBatches;

  /// Parses dashboard metrics from the `data` payload of the API response.
  ///
  /// All fields are treated defensively with full null safety.
  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    // 1. Attendance percentage
    double? attendanceRate = parseDouble(json['attendanceRate']);
    if (attendanceRate == null && json['attendance'] is Map<String, dynamic>) {
      final att = json['attendance'] as Map<String, dynamic>;
      attendanceRate = parseDouble(att['attendancePercentage']);
    }

    // 2. Upcoming classes count & Featured Class
    int? upcomingCount = parseInt(json['upcomingClassesCount']);
    ClassEntity? featured;
    if (json['upcomingLiveClasses'] is List) {
      final list = json['upcomingLiveClasses'] as List;
      upcomingCount ??= list.length;
      if (list.isNotEmpty && list.first is Map<String, dynamic>) {
        final first = list.first as Map<String, dynamic>;
        final startStr = first['startDate'] as String?;
        final startDt = startStr != null ? DateTime.tryParse(startStr) : null;
        final duration = parseInt(first['duration']) ?? 60;
        final endDt = startDt?.add(Duration(minutes: duration));

        featured = ClassEntity(
          id: (first['id'] ?? first['_id'] ?? '').toString(),
          title: (first['classTitle'] ?? first['title'] ?? 'Live Class').toString(),
          subject: first['courseName'] as String?,
          teacherName: first['instructor'] as String?,
          scheduledStartTime: startDt,
          scheduledEndTime: endDt,
          status: first['status'] as String? ?? 'UPCOMING',
        );
      }
    }

    // 3. Pending assignments count
    final pendingCount = parseInt(json['pendingAssignmentsCount']) ??
        parseInt(json['assignmentsCount']);

    // 4. Total balance due
    double? balanceDue = parseDouble(json['totalBalanceDue']);
    if (balanceDue == null && json['feeOverview'] is Map<String, dynamic>) {
      final fee = json['feeOverview'] as Map<String, dynamic>;
      balanceDue = parseDouble(fee['totalDue']);
    }

    // 5. Enrolled Batches
    final List<EnrolledBatchEntity> batches = [];
    String? topic;
    if (json['enrolledBatches'] is List) {
      final bList = json['enrolledBatches'] as List;
      for (final item in bList) {
        if (item is Map<String, dynamic>) {
          final bName = (item['batchName'] ?? '').toString();
          final cName = (item['courseName'] ?? '').toString();
          batches.add(EnrolledBatchEntity(
            id: (item['id'] ?? item['_id'] ?? '').toString(),
            batchName: bName,
            batchCode: item['batchCode'] as String?,
            courseName: cName.isNotEmpty ? cName : null,
            instructor: item['instructor'] as String?,
          ));
          topic ??= cName.isNotEmpty ? cName : (bName.isNotEmpty ? bName : null);
        }
      }
    }

    return DashboardDto(
      attendanceRate: attendanceRate,
      upcomingClassesCount: upcomingCount,
      pendingAssignmentsCount: pendingCount,
      totalBalanceDue: balanceDue,
      activeTopic: topic,
      featuredClass: featured,
      enrolledBatches: batches,
    );
  }

  /// Converts DTO to domain entity.
  DashboardEntity toEntity() => DashboardEntity(
        attendanceRate: attendanceRate,
        upcomingClassesCount: upcomingClassesCount,
        pendingAssignmentsCount: pendingAssignmentsCount,
        totalBalanceDue: totalBalanceDue,
        activeTopic: activeTopic,
        featuredClass: featuredClass,
        enrolledBatches: enrolledBatches,
      );
}
