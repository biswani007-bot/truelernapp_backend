import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class_join_entity.dart';
import '../../domain/repositories/classes_repository.dart';
import '../models/class_dto.dart';

/// Concrete implementation of [ClassesRepository].
///
/// Uses the existing [ApiClient] which automatically attaches
/// `Authorization: Bearer <accessToken>` via the [AuthInterceptor].
///
/// Governance:
/// - Authoritative endpoint: GET /api/parent/children/{childStudentId}/live-classes
/// - Reuses existing ErrorHandler and Failure hierarchy.
/// - Defensive handling of empty list, empty envelope, and malformed structures.
class ClassesRepositoryImpl implements ClassesRepository {
  const ClassesRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ClassEntity>> getLiveClasses(String childStudentId) async {
    Object? liveError;
    Object? scheduleError;
    List<ClassEntity>? liveList;
    List<ClassEntity>? scheduleList;

    await Future.wait([
      (() async {
        try {
          liveList = await _fetchEndpoint(
            '/parent/children/$childStudentId/live-classes',
          );
        } catch (e) {
          liveError = e;
        }
      })(),
      (() async {
        try {
          scheduleList = await _fetchEndpoint(
            '/parent/children/$childStudentId/schedule',
          );
        } catch (e) {
          scheduleError = e;
        }
      })(),
    ]);

    // If both failed, rethrow so API errors are not converted into false empty schedules
    if (liveList == null && scheduleList == null) {
      throw liveError ?? scheduleError ?? Exception('Failed to load classes');
    }

    final safeLive = liveList ?? [];
    final safeSchedule = scheduleList ?? [];

    if (safeLive.isEmpty && safeSchedule.isEmpty) return [];

    final Map<String, ClassEntity> merged = {};
    for (final c in safeLive) {
      merged[c.id] = c;
    }
    for (final s in safeSchedule) {
      if (merged.containsKey(s.id)) {
        final existing = merged[s.id]!;
        final isUpcomingActive = s.isUpcomingAt();
        merged[s.id] = ClassEntity(
          id: existing.id,
          classCode: existing.classCode ?? s.classCode,
          title: existing.title.isNotEmpty ? existing.title : s.title,
          subject: existing.subject ?? s.subject,
          scheduledStartTime:
              s.scheduledStartTime ?? existing.scheduledStartTime,
          scheduledEndTime: s.scheduledEndTime ?? existing.scheduledEndTime,
          duration: s.duration ?? existing.duration,
          status: s.status ?? existing.status ?? 'SCHEDULED',
          effectiveStatus: isUpcomingActive
              ? 'upcoming'
              : existing.effectiveStatus,
          teacherName: existing.teacherName ?? s.teacherName,
          teacherAvatar: existing.teacherAvatar ?? s.teacherAvatar,
          meetingUrl: s.meetingUrl ?? existing.meetingUrl,
          roomName: s.roomName ?? existing.roomName,
        );
      } else {
        merged[s.id] = s;
      }
    }

    return merged.values.toList();
  }

  Future<List<ClassEntity>> _fetchEndpoint(String endpoint) async {
    final response = await apiClient.get<Map<String, dynamic>>(endpoint);

    final body = response.data;
    if (body == null) return [];

    // Unwrap standard envelope: { "success": true, "data": [...], "meta": {...} }
    final dataField = body['data'];
    if (dataField == null) return [];

    final List<dynamic> rawList;
    if (dataField is List) {
      rawList = dataField;
    } else if (dataField is Map<String, dynamic> &&
        dataField['classes'] is List) {
      rawList = dataField['classes'] as List<dynamic>;
    } else if (dataField is Map<String, dynamic> &&
        dataField['items'] is List) {
      rawList = dataField['items'] as List<dynamic>;
    } else {
      return [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((json) => ClassDto.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<ClassJoinEntity> joinLiveClass({
    required String childStudentId,
    required String classId,
  }) async {
    final payload = <String, dynamic>{
      if (childStudentId.isNotEmpty) 'studentId': childStudentId,
      if (childStudentId.isNotEmpty) 'childId': childStudentId,
    };

    dynamic response;
    try {
      response = await apiClient.post<Map<String, dynamic>>(
        '/live-classes/$classId/token',
        data: payload,
      );
    } catch (e) {
      // If live-classes endpoint indicates it's a demo session route or not found,
      // attempt documented demo token endpoint /parent/demo/$classId/token
      if (e is Failure &&
          (e.statusCode == 404 ||
              (e.statusCode == 403 &&
                  e.message.toLowerCase().contains('only instructors')))) {
        try {
          response = await apiClient.post<Map<String, dynamic>>(
            '/parent/demo/$classId/token',
            data: payload,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final body = response.data;
    final dataField =
        (body?['data'] as Map<String, dynamic>?) ??
        (body is Map<String, dynamic> ? body : null) ??
        <String, dynamic>{};
    final liveClassMap = dataField['liveClass'] as Map<String, dynamic>?;
    final childMap = dataField['child'] as Map<String, dynamic>?;

    return ClassJoinEntity(
      token: dataField['token']?.toString() ??
          dataField['jwtToken']?.toString() ??
          '',
      roomName: dataField['roomName']?.toString() ??
          dataField['room']?.toString() ??
          '',
      jitsiDomain: dataField['jitsiDomain']?.toString() ?? 'livetl.visital.in',
      serverUrl:
          dataField['serverUrl']?.toString() ?? 'https://livetl.visital.in',
      meetingUrl: dataField['meetingUrl']?.toString() ?? '',
      isModerator: dataField['isModerator'] == true,
      expiresAt: (dataField['expiresAt'] is num)
          ? (dataField['expiresAt'] as num).toInt()
          : null,
      childId:
          dataField['studentId']?.toString() ??
          childMap?['id']?.toString() ??
          childStudentId,
      childName: childMap?['name']?.toString(),
      classId: liveClassMap?['id']?.toString() ??
          dataField['classId']?.toString() ??
          dataField['demoId']?.toString() ??
          classId,
      classTitle:
          liveClassMap?['title']?.toString() ??
          liveClassMap?['classTitle']?.toString() ??
          dataField['courseName']?.toString(),
    );
  }
}

/// Provider for [ClassesRepository].
final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
