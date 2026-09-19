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

    // 2. Upcoming classes count & Featured Class (Today's Class)
    int? upcomingCount = parseInt(json['upcomingClassesCount']);
    ClassEntity? featured;
    if (json['upcomingLiveClasses'] is List) {
      final list = json['upcomingLiveClasses'] as List;
      upcomingCount ??= list.length;

      final now = DateTime.now();
      final List<_DashboardClassCandidate> todayCandidates = [];

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final startStr = item['startDate'] as String?;
        final startDt = startStr != null ? DateTime.tryParse(startStr) : null;
        if (startDt == null) continue;

        final localStart = startDt.toLocal();
        final isToday = localStart.year == now.year &&
            localStart.month == now.month &&
            localStart.day == now.day;

        if (!isToday) continue;

        final duration = parseInt(item['duration']) ?? 60;
        final endDt = startDt.add(Duration(minutes: duration));

        String? teacherName;
        final rawTeacher = item['instructor'] ?? item['teacher'];
        if (rawTeacher is Map) {
          final resolvedName = rawTeacher['name']?.toString() ??
              ([rawTeacher['firstName'], rawTeacher['lastName']]
                  .where((s) => s != null && s.toString().trim().isNotEmpty)
                  .join(' '));
          teacherName = resolvedName.isNotEmpty ? resolvedName : null;
        } else if (rawTeacher != null) {
          teacherName = rawTeacher.toString();
        }

        final entity = ClassEntity(
          id: (item['id'] ?? item['_id'] ?? '').toString(),
          title: (item['classTitle'] ?? item['title'] ?? 'Live Class').toString(),
          subject: item['courseName']?.toString() ?? item['subject']?.toString(),
          teacherName: teacherName,
          scheduledStartTime: startDt,
          scheduledEndTime: endDt,
          status: item['effectiveStatus']?.toString() ?? item['status']?.toString() ?? 'UPCOMING',
        );

        todayCandidates.add(_DashboardClassCandidate(
          entity: entity,
          startLocal: localStart,
          endLocal: endDt.toLocal(),
        ));
      }

      if (todayCandidates.isNotEmpty) {
        // Sort today's classes chronologically by start time
        todayCandidates.sort((a, b) => a.startLocal.compareTo(b.startLocal));

        // Prefer the current ongoing or next upcoming class today
        for (final cand in todayCandidates) {
          if (cand.endLocal.isAfter(now)) {
            featured = cand.entity;
            break;
          }
        }
        // If all classes today have ended, show the latest completed session today
        featured ??= todayCandidates.last.entity;
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

class _DashboardClassCandidate {
  const _DashboardClassCandidate({
    required this.entity,
    required this.startLocal,
    required this.endLocal,
  });

  final ClassEntity entity;
  final DateTime startLocal;
  final DateTime endLocal;
}

