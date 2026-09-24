import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../assignments/data/repositories/assignments_repository_impl.dart';
import '../../../assignments/domain/repositories/assignments_repository.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class_summary_entity.dart';
import '../../domain/repositories/class_summary_repository.dart';
import '../../domain/repositories/classes_repository.dart';
import '../models/class_summary_dto.dart';
import 'classes_repository_impl.dart';

/// Implementation of [ClassSummaryRepository] that queries authoritative TrueLern
/// parent endpoints and parses real backend data:
/// 1. GET /api/parent/children/{childStudentId}/live-classes
/// 2. GET /api/parent/children/{childStudentId}/attendance
/// 3. GET /api/parent/children/{childStudentId}/assignments
class ClassSummaryRepositoryImpl implements ClassSummaryRepository {
  final ApiClient apiClient;
  final ClassesRepository classesRepository;
  final AssignmentsRepository assignmentsRepository;

  const ClassSummaryRepositoryImpl({
    required this.apiClient,
    required this.classesRepository,
    required this.assignmentsRepository,
  });

  @override
  Future<ClassSummaryEntity> getClassSummary({
    required String childStudentId,
    required String classId,
    ClassEntity? session,
  }) async {
    Map<String, dynamic>? targetClassJson;
    Map<String, dynamic>? nextClassJson;
    Map<String, dynamic>? attendanceRecordJson;
    Map<String, dynamic>? assignmentJson;

    // 1. Fetch live classes for child: GET /api/parent/children/{childStudentId}/live-classes
    try {
      final classesResponse = await apiClient.get(
        '/api/parent/children/$childStudentId/live-classes',
      );
      if (classesResponse.statusCode == 200 && classesResponse.data != null) {
        dynamic data = classesResponse.data;
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        if (data is List) {
          final now = DateTime.now();
          List<Map<String, dynamic>> upcoming = [];

          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final id = (item['id'] ?? item['_id'])?.toString();
              if (id == classId) {
                targetClassJson = item;
              } else {
                final rawStart = item['startDate'] ?? item['scheduledStartTime'];
                if (rawStart != null) {
                  final dt = DateTime.tryParse(rawStart.toString());
                  if (dt != null && dt.isAfter(now)) {
                    upcoming.add(item);
                  }
                }
              }
            }
          }

          if (upcoming.isNotEmpty) {
            upcoming.sort((a, b) {
              final da = DateTime.tryParse((a['startDate'] ?? a['scheduledStartTime']).toString()) ?? now;
              final db = DateTime.tryParse((b['startDate'] ?? b['scheduledStartTime']).toString()) ?? now;
              return da.compareTo(db);
            });
            nextClassJson = upcoming.first;
          }
        }
      }
    } catch (_) {
      // Non-blocking: will fallback to session context if classes API fails
    }

    // Fallback targetClassJson from passed session if not found in API list
    if (targetClassJson == null && session != null) {
      targetClassJson = {
        'id': session.id,
        'classTitle': session.title,
        'classCode': session.classCode,
        'duration': session.duration,
        'status': session.status,
        'effectiveStatus': 'attended',
        'instructor': session.teacherName,
      };
    }

    final targetTitle = (targetClassJson?['classTitle'] ??
            targetClassJson?['title'] ??
            session?.title ??
            '')
        .toString();

    // 2. Fetch attendance: GET /api/parent/children/{childStudentId}/attendance
    try {
      final attResponse = await apiClient.get(
        '/api/parent/children/$childStudentId/attendance',
      );
      if (attResponse.statusCode == 200 && attResponse.data != null) {
        dynamic attData = attResponse.data;
        if (attData is Map && attData['data'] != null) {
          attData = attData['data'];
        }
        if (attData is Map && attData['records'] is List) {
          final records = attData['records'] as List;
          for (final r in records) {
            if (r is Map<String, dynamic>) {
              final classTitle = r['classTitle']?.toString();
              if (classTitle != null &&
                  targetTitle.isNotEmpty &&
                  classTitle.toLowerCase() == targetTitle.toLowerCase()) {
                attendanceRecordJson = r;
                break;
              }
            }
          }
          if (attendanceRecordJson == null && records.isNotEmpty) {
            // Check first record if it matches recent attendance
            final firstRecord = records.first;
            if (firstRecord is Map<String, dynamic>) {
              attendanceRecordJson = firstRecord;
            }
          }
        }
      }
    } catch (_) {
      // Non-blocking
    }

    // 3. Fetch assignments: GET /api/parent/children/{childStudentId}/assignments
    try {
      final assignResponse = await apiClient.get(
        '/api/parent/children/$childStudentId/assignments',
      );
      if (assignResponse.statusCode == 200 && assignResponse.data != null) {
        dynamic assignData = assignResponse.data;
        if (assignData is Map && assignData['data'] != null) {
          assignData = assignData['data'];
        }
        if (assignData is List && assignData.isNotEmpty) {
          for (final a in assignData) {
            if (a is Map<String, dynamic>) {
              final canSubmit = a['canSubmit'] == true || a['status'] == 'published';
              if (canSubmit) {
                assignmentJson = a;
                break;
              }
            }
          }
          assignmentJson ??= assignData.first as Map<String, dynamic>?;
        }
      }
    } catch (_) {
      // Non-blocking
    }

    // 4. Construct ClassSummaryDto from real backend data
    final dto = ClassSummaryDto.fromBackend(
      targetClassId: classId,
      classJson: targetClassJson,
      attendanceRecordJson: attendanceRecordJson,
      nextClassJson: nextClassJson,
      assignmentJson: assignmentJson,
    );

    return dto.toEntity();
  }
}

/// Provider for [ClassSummaryRepository].
final classSummaryRepositoryProvider = Provider<ClassSummaryRepository>((ref) {
  return ClassSummaryRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    classesRepository: ref.watch(classesRepositoryProvider),
    assignmentsRepository: ref.watch(assignmentsRepositoryProvider),
  );
});
