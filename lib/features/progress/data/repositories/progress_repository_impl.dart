import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../models/progress_dto.dart';

/// Provider for [ProgressRepository].
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProgressRepositoryImpl(apiClient: apiClient);
});

/// Implementation of [ProgressRepository] consuming real backend endpoints.
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ProgressEntity> getChildProgress({
    required String childStudentId,
    String? studentName,
    String? activeTrack,
  }) async {
    // Concurrently fetch base progress along with authoritative program, attendance,
    // assessments, and assignments data.
    final results = await Future.wait<dynamic>([
      _fetchProgressSafe(childStudentId),
      _fetchProgramSafe(childStudentId),
      _fetchAttendanceSafe(childStudentId),
      _fetchAssessmentsSafe(childStudentId),
      _fetchAssignmentsSafe(childStudentId),
    ]);

    final progressDto = results[0] as ProgressDto?;
    final programData = results[1] as _ProgramData?;
    final attendanceData = results[2] as _AttendanceData?;
    final assessmentsData = results[3] as _AssessmentsData?;
    final assignmentsData = results[4] as _AssignmentsData?;

    // If all requests failed, throw so the error state is appropriately presented
    if (progressDto == null &&
        programData == null &&
        attendanceData == null &&
        assessmentsData == null &&
        assignmentsData == null) {
      throw Exception('Failed to load progress data: Empty response');
    }

    // 1. Overall Completion & Track Name
    // Prefer authoritative course curriculum progress from GET /parent/children/:id/program,
    // consistent with Dashboard and My Child.
    final double overallCompletion =
        programData?.progress ?? progressDto?.overallCompletion ?? 0.0;

    final String? resolvedTrack =
        (activeTrack != null && activeTrack.isNotEmpty)
        ? activeTrack
        : programData?.courseName;

    // 2. Attendance Summary
    // Prefer authoritative attendance summary from GET /parent/children/:id/attendance.
    final ProgressMetricEntity attendanceSummary;
    if (attendanceData != null) {
      attendanceSummary = ProgressMetricEntity(
        total: attendanceData.totalSessions,
        completed: attendanceData.presentCount,
        percentage: attendanceData.attendancePercentage,
      );
    } else if (progressDto != null) {
      attendanceSummary = progressDto.attendanceSummary.toEntity();
    } else {
      attendanceSummary = const ProgressMetricEntity();
    }

    // 3. Assessment Completion
    // Prefer evaluated assessment statistics from GET /parent/children/:id/assessments
    // or from program data.
    final ProgressMetricEntity assessmentCompletion;
    if (assessmentsData != null && assessmentsData.total > 0) {
      assessmentCompletion = ProgressMetricEntity(
        total: assessmentsData.total,
        completed: assessmentsData.evaluated,
        percentage: assessmentsData.percentage,
      );
    } else if (programData != null &&
        programData.totalAssessments != null &&
        programData.totalAssessments! > 0) {
      final total = programData.totalAssessments!;
      final completed = programData.completedAssessments ?? 0;
      final pct = total > 0 ? (completed / total * 100.0) : 0.0;
      assessmentCompletion = ProgressMetricEntity(
        total: total,
        completed: completed,
        percentage: pct,
      );
    } else if (progressDto != null) {
      assessmentCompletion = progressDto.assessmentCompletion.toEntity();
    } else {
      assessmentCompletion = const ProgressMetricEntity();
    }

    // 4. Assignment Completion
    // Prefer assignments statistics from GET /parent/children/:id/assignments
    // or from program data.
    final ProgressMetricEntity assignmentCompletion;
    if (assignmentsData != null && assignmentsData.total > 0) {
      assignmentCompletion = ProgressMetricEntity(
        total: assignmentsData.total,
        completed: assignmentsData.submitted,
        percentage: assignmentsData.percentage,
      );
    } else if (programData != null &&
        programData.totalAssignments != null &&
        programData.totalAssignments! > 0) {
      final total = programData.totalAssignments!;
      final completed = programData.completedAssignments ?? 0;
      final pct = total > 0 ? (completed / total * 100.0) : 0.0;
      assignmentCompletion = ProgressMetricEntity(
        total: total,
        completed: completed,
        percentage: pct,
      );
    } else if (progressDto != null) {
      assignmentCompletion = progressDto.assignmentCompletion.toEntity();
    } else {
      assignmentCompletion = const ProgressMetricEntity();
    }

    return ProgressEntity(
      childStudentId: childStudentId,
      overallCompletion: overallCompletion,
      assessmentCompletion: assessmentCompletion,
      assignmentCompletion: assignmentCompletion,
      attendanceSummary: attendanceSummary,
      studentName: studentName,
      activeTrack: resolvedTrack,
    );
  }

  Future<ProgressDto?> _fetchProgressSafe(String childStudentId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/progress',
      );
      final data = response.data;
      if (data == null) return null;
      return ProgressDto.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<_ProgramData?> _fetchProgramSafe(String childStudentId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/program',
      );
      final body = response.data;
      if (body == null) return null;
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;

      final rawProg = data['progress'];
      double? prog;
      if (rawProg is num) prog = rawProg.toDouble();
      if (rawProg is String) prog = double.tryParse(rawProg);

      final totalAss = (data['totalAssignments'] as num?)?.toInt();
      final compAss = (data['completedAssignments'] as num?)?.toInt();
      final totalAssess = (data['totalAssessments'] as num?)?.toInt();
      final compAssess = (data['completedAssessments'] as num?)?.toInt();

      return _ProgramData(
        courseName: data['courseName']?.toString(),
        progress: prog,
        totalAssignments: totalAss,
        completedAssignments: compAss,
        totalAssessments: totalAssess,
        completedAssessments: compAssess,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_AttendanceData?> _fetchAttendanceSafe(String childStudentId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/attendance',
      );
      final body = response.data;
      if (body == null) return null;
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;

      final summary = data['summary'] is Map<String, dynamic>
          ? data['summary'] as Map<String, dynamic>
          : null;
      if (summary == null) return null;

      final rawTotal = summary['totalSessions'] ?? summary['totalClasses'] ?? 0;
      final total = rawTotal is num
          ? rawTotal.toInt()
          : (int.tryParse('$rawTotal') ?? 0);

      final rawPresent = summary['presentCount'] ?? summary['attended'] ?? 0;
      final present = rawPresent is num
          ? rawPresent.toInt()
          : (int.tryParse('$rawPresent') ?? 0);

      final rawPct =
          summary['attendancePercentage'] ?? summary['percentage'] ?? 0;
      final pct = rawPct is num
          ? rawPct.toDouble()
          : (double.tryParse('$rawPct') ?? 0.0);

      return _AttendanceData(
        totalSessions: total,
        presentCount: present,
        attendancePercentage: pct,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_AssessmentsData?> _fetchAssessmentsSafe(String childStudentId) async {
    try {
      final response = await apiClient.get<dynamic>(
        '/parent/children/$childStudentId/assessments',
      );
      final body = response.data;
      if (body == null) return null;
      final rawList = body is Map<String, dynamic> && body['data'] is List
          ? body['data'] as List
          : (body is List ? body : null);
      if (rawList == null) return null;

      final total = rawList.length;
      int evaluated = 0;
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final evaluatedAt = item['evaluatedAt'];
          final status = item['status']?.toString().toLowerCase();
          final isEvaluated =
              (evaluatedAt != null && evaluatedAt.toString().isNotEmpty) ||
              status == 'pass' ||
              status == 'fail' ||
              status == 'completed' ||
              status == 'evaluated' ||
              status == 'graded';
          if (isEvaluated) {
            evaluated++;
          }
        }
      }

      final pct = total > 0 ? (evaluated / total * 100.0) : 0.0;
      return _AssessmentsData(
        total: total,
        evaluated: evaluated,
        percentage: pct,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_AssignmentsData?> _fetchAssignmentsSafe(String childStudentId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/assignments',
      );
      final body = response.data;
      if (body == null) return null;
      final rawList = body['data'] is List ? body['data'] as List : null;
      if (rawList == null) return null;

      final total = rawList.length;
      int submitted = 0;
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final submission = item['submission'];
          final status = item['status']?.toString().toLowerCase();
          final isSubmitted =
              submission != null ||
              status == 'submitted' ||
              status == 'completed' ||
              status == 'graded';
          if (isSubmitted) {
            submitted++;
          }
        }
      }

      final pct = total > 0 ? (submitted / total * 100.0) : 0.0;
      return _AssignmentsData(
        total: total,
        submitted: submitted,
        percentage: pct,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double> getStudentCourseProgress({required String courseId}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/student/courses/$courseId/progress',
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Failed to load student course progress: Empty response');
    }

    final map = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;

    final rawProg = map['progress'] ?? map['overallCompletion'] ?? 0;
    if (rawProg is num) return rawProg.toDouble();
    return double.tryParse('$rawProg') ?? 0.0;
  }
}

class _ProgramData {
  const _ProgramData({
    this.courseName,
    this.progress,
    this.totalAssignments,
    this.completedAssignments,
    this.totalAssessments,
    this.completedAssessments,
  });

  final String? courseName;
  final double? progress;
  final int? totalAssignments;
  final int? completedAssignments;
  final int? totalAssessments;
  final int? completedAssessments;
}

class _AttendanceData {
  const _AttendanceData({
    required this.totalSessions,
    required this.presentCount,
    required this.attendancePercentage,
  });

  final int totalSessions;
  final int presentCount;
  final double attendancePercentage;
}

class _AssessmentsData {
  const _AssessmentsData({
    required this.total,
    required this.evaluated,
    required this.percentage,
  });

  final int total;
  final int evaluated;
  final double percentage;
}

class _AssignmentsData {
  const _AssignmentsData({
    required this.total,
    required this.submitted,
    required this.percentage,
  });

  final int total;
  final int submitted;
  final double percentage;
}
