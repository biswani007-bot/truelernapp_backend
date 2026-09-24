import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/children/$childStudentId/live-classes',
    );

    final body = response.data;
    if (body == null) return [];

    // Unwrap standard envelope: { "success": true, "data": [...], "meta": {...} }
    final dataField = body['data'];
    if (dataField == null) return [];

    final List<dynamic> rawList;
    if (dataField is List) {
      rawList = dataField;
    } else if (dataField is Map<String, dynamic> && dataField['classes'] is List) {
      rawList = dataField['classes'] as List<dynamic>;
    } else if (dataField is Map<String, dynamic> && dataField['items'] is List) {
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
    final response = await apiClient.post<Map<String, dynamic>>(
      '/live-classes/$classId/token',
      data: <String, dynamic>{},
    );

    final body = response.data;
    final dataField = (body?['data'] as Map<String, dynamic>?) ?? body ?? <String, dynamic>{};
    final liveClassMap = dataField['liveClass'] as Map<String, dynamic>?;
    final childMap = dataField['child'] as Map<String, dynamic>?;

    return ClassJoinEntity(
      token: dataField['token']?.toString() ?? '',
      roomName: dataField['roomName']?.toString() ?? '',
      jitsiDomain: dataField['jitsiDomain']?.toString() ?? 'livetl.visital.in',
      serverUrl: dataField['serverUrl']?.toString() ?? 'https://livetl.visital.in',
      meetingUrl: dataField['meetingUrl']?.toString() ?? '',
      isModerator: dataField['isModerator'] == true,
      expiresAt: (dataField['expiresAt'] is num) ? (dataField['expiresAt'] as num).toInt() : null,
      childId: dataField['studentId']?.toString() ?? childMap?['id']?.toString() ?? childStudentId,
      childName: childMap?['name']?.toString(),
      classId: liveClassMap?['id']?.toString() ?? classId,
      classTitle: liveClassMap?['title']?.toString() ?? liveClassMap?['classTitle']?.toString(),
    );
  }
}

/// Provider for [ClassesRepository].
final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

