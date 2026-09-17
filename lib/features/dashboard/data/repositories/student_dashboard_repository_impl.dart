import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../classes/domain/entities/class_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/student_dashboard_repository.dart';

/// Concrete implementation of [StudentDashboardRepository].
///
/// Composes Student Dashboard data directly from verified Student-authorized endpoints:
/// - GET /api/live-classes
/// - GET /api/assignments
/// - GET /api/attendance/summary
///
/// Authentication: Bearer token (Student role) attached automatically via AuthInterceptor.
class StudentDashboardRepositoryImpl implements StudentDashboardRepository {
  const StudentDashboardRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<DashboardEntity> getStudentDashboard() async {
    // Fetch live-classes, assignments, and attendance summary concurrently
    final results = await Future.wait([
      _fetchLiveClasses(),
      _fetchAssignments(),
      _fetchAttendanceSummary(),
    ]);

    final liveClassesResult = results[0] as _LiveClassesResult;
    final assignmentsResult = results[1] as _AssignmentsResult;
    final attendanceResult = results[2] as _AttendanceResult;

    // If all three calls failed with an error, propagate failure to controller
    if (liveClassesResult.error != null &&
        assignmentsResult.error != null &&
        attendanceResult.error != null) {
      throw const ServerFailure('Failed to load student dashboard data from backend');
    }

    return DashboardEntity(
      studentName: attendanceResult.studentName,
      attendanceRate: attendanceResult.attendancePercentage,
      upcomingClassesCount: liveClassesResult.upcomingClassesCount,
      pendingAssignmentsCount: assignmentsResult.pendingCount,
      totalBalanceDue: 0.0,
      activeTopic: liveClassesResult.featuredClass?.title ??
          (liveClassesResult.enrolledBatches.isNotEmpty
              ? liveClassesResult.enrolledBatches.first.batchName
              : null),
      featuredClass: liveClassesResult.featuredClass,
      enrolledBatches: liveClassesResult.enrolledBatches,
    );
  }

  /// Fetches and parses GET /api/live-classes
  Future<_LiveClassesResult> _fetchLiveClasses() async {
    try {
      final response = await apiClient.get<dynamic>('/live-classes');
      final dynamic body = response.data;
      if (body == null) return const _LiveClassesResult();

      final dynamic dataField = (body is Map) ? (body['data'] ?? body) : body;
      if (dataField is! List) return const _LiveClassesResult();

      final classesList = dataField.whereType<Map<String, dynamic>>().toList();
      if (classesList.isEmpty) return const _LiveClassesResult(upcomingClassesCount: 0);

      // Extract unique enrolled batches from live class records
      final Map<String, EnrolledBatchEntity> uniqueBatches = {};
      for (final item in classesList) {
        final batchObj = item['batch'];
        if (batchObj is Map<String, dynamic>) {
          final batchId = (batchObj['_id'] ??
                  batchObj['id'] ??
                  batchObj['batchName'] ??
                  batchObj['name'] ??
                  '')
              .toString();
          if (batchId.isNotEmpty && !uniqueBatches.containsKey(batchId)) {
            final courseObj = item['course'];
            final courseName = courseObj is Map<String, dynamic>
                ? (courseObj['courseName'] ?? courseObj['name'] ?? '').toString()
                : null;

            final teacherObj = item['teacher'];
            String? instructor;
            if (teacherObj is Map<String, dynamic>) {
              final first = teacherObj['firstName'] as String? ?? '';
              final last = teacherObj['lastName'] as String? ?? '';
              final full = '$first $last'.trim();
              instructor = full.isNotEmpty ? full : teacherObj['name'] as String?;
            } else if (teacherObj is String) {
              instructor = teacherObj;
            }

            uniqueBatches[batchId] = EnrolledBatchEntity(
              id: batchId,
              batchName: (batchObj['batchName'] ?? batchObj['name'] ?? 'Batch').toString(),
              batchCode: batchObj['batchCode']?.toString(),
              courseName: courseName,
              instructor: instructor,
            );
          }
        }
      }

      // Identify the featured (upcoming or next scheduled) class
      final now = DateTime.now();
      ClassEntity? featured;
      final parsedClasses = <_ClassCandidate>[];

      for (final item in classesList) {
        final classId = (item['_id'] ?? item['id'] ?? '').toString();
        final title = (item['classTitle'] ?? item['title'] ?? 'Live Session').toString();
        final startDateStr = item['startDate'] as String?;
        final endDateStr = item['endDate'] as String?;
        final startTime = startDateStr != null ? DateTime.tryParse(startDateStr) : null;
        final endTime = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
        final status = (item['status'] ?? 'scheduled').toString();

        final teacherObj = item['teacher'];
        String? teacherName;
        if (teacherObj is Map<String, dynamic>) {
          final first = teacherObj['firstName'] as String? ?? '';
          final last = teacherObj['lastName'] as String? ?? '';
          final full = '$first $last'.trim();
          teacherName = full.isNotEmpty ? full : teacherObj['name'] as String?;
        } else if (teacherObj is String) {
          teacherName = teacherObj;
        }

        final courseObj = item['course'];
        final courseName = courseObj is Map<String, dynamic>
            ? (courseObj['courseName'] ?? courseObj['name'] ?? '').toString()
            : null;

        final candidate = ClassEntity(
          id: classId,
          title: title,
          subject: courseName,
          scheduledStartTime: startTime,
          scheduledEndTime: endTime,
          status: status,
          teacherName: teacherName,
          meetingUrl: item['meetingLink'] as String?,
          roomName: item['classCode'] as String?,
        );

        parsedClasses.add(_ClassCandidate(entity: candidate, startTime: startTime));
      }

      // Sort upcoming classes by start time closest to now (or upcoming in future)
      parsedClasses.sort((a, b) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

      // Find first class that is now or in the future
      for (final cand in parsedClasses) {
        if (cand.startTime != null && cand.startTime!.isAfter(now.subtract(const Duration(hours: 2)))) {
          featured = cand.entity;
          break;
        }
      }
      // Fallback to first class if all are in past
      featured ??= parsedClasses.isNotEmpty ? parsedClasses.first.entity : null;

      return _LiveClassesResult(
        featuredClass: featured,
        upcomingClassesCount: parsedClasses.length,
        enrolledBatches: uniqueBatches.values.toList(),
      );
    } catch (e) {
      return _LiveClassesResult(error: e);
    }
  }

  /// Fetches and parses GET /api/assignments
  Future<_AssignmentsResult> _fetchAssignments() async {
    try {
      final response = await apiClient.get<dynamic>('/assignments');
      final dynamic body = response.data;
      if (body == null) return const _AssignmentsResult();

      final dynamic dataField = (body is Map) ? (body['data'] ?? body) : body;
      if (dataField is! List) return const _AssignmentsResult();

      // Count assignments that are published
      final assignments = dataField.whereType<Map<String, dynamic>>().toList();
      return _AssignmentsResult(pendingCount: assignments.length);
    } catch (e) {
      return _AssignmentsResult(error: e);
    }
  }

  /// Fetches and parses GET /api/attendance/summary
  Future<_AttendanceResult> _fetchAttendanceSummary() async {
    try {
      final response = await apiClient.get<dynamic>('/attendance/summary');
      final dynamic body = response.data;
      if (body == null) return const _AttendanceResult();

      final dynamic dataField = (body is Map) ? (body['data'] ?? body) : body;
      final Map<String, dynamic>? firstSummary = (dataField is List && dataField.isNotEmpty)
          ? (dataField.first is Map<String, dynamic> ? dataField.first as Map<String, dynamic> : null)
          : (dataField is Map<String, dynamic> ? dataField : null);

      if (firstSummary == null) return const _AttendanceResult();

      // Parse attendance percentage
      final rawPct = firstSummary['attendancePercentage'];
      double? attendancePercentage;
      if (rawPct is num) {
        attendancePercentage = rawPct.toDouble();
      } else if (rawPct is String) {
        attendancePercentage = double.tryParse(rawPct);
      }

      // Parse student details
      String? studentName;
      final studentObj = firstSummary['student'];
      if (studentObj is Map<String, dynamic>) {
        final first = studentObj['firstName'] as String? ?? '';
        final last = studentObj['lastName'] as String? ?? '';
        final full = '$first $last'.trim();
        if (full.isNotEmpty) {
          studentName = full;
        }
      }

      return _AttendanceResult(
        attendancePercentage: attendancePercentage,
        studentName: studentName,
      );
    } catch (e) {
      return _AttendanceResult(error: e);
    }
  }
}

class _LiveClassesResult {
  const _LiveClassesResult({
    this.featuredClass,
    this.upcomingClassesCount,
    this.enrolledBatches = const [],
    this.error,
  });

  final ClassEntity? featuredClass;
  final int? upcomingClassesCount;
  final List<EnrolledBatchEntity> enrolledBatches;
  final Object? error;
}

class _ClassCandidate {
  const _ClassCandidate({required this.entity, this.startTime});
  final ClassEntity entity;
  final DateTime? startTime;
}

class _AssignmentsResult {
  const _AssignmentsResult({this.pendingCount, this.error});
  final int? pendingCount;
  final Object? error;
}

class _AttendanceResult {
  const _AttendanceResult({
    this.attendancePercentage,
    this.studentName,
    this.error,
  });

  final double? attendancePercentage;
  final String? studentName;
  final Object? error;
}

/// Riverpod provider for [StudentDashboardRepository].
final studentDashboardRepositoryProvider = Provider<StudentDashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StudentDashboardRepositoryImpl(apiClient: apiClient);
});
