import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../classes/data/repositories/classes_repository_impl.dart';
import '../../../classes/domain/entities/class_entity.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../classes/presentation/screens/parent_classes_screen.dart';
import '../../domain/entities/child_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/add_child_request_dto.dart';
import '../models/child_dto.dart';
import '../models/dashboard_dto.dart';

/// Concrete implementation of [DashboardRepository].
///
/// Uses the existing [ApiClient] which automatically attaches
/// `Authorization: Bearer <accessToken>` via the AuthInterceptor.
/// No manual token passing is done here.
class DashboardRepositoryImpl
    implements DashboardRepository, AddChildRepository {
  const DashboardRepositoryImpl({
    required this.apiClient,
    this.classesRepository,
    this.nowProvider,
  });

  final ApiClient apiClient;
  final ClassesRepository? classesRepository;
  final DateTime Function()? nowProvider;

  /// GET /api/parent/children
  ///
  /// Returns the list of children linked to the authenticated parent.
  /// Returns an empty list if the data array is empty.
  /// All JSON field access is null-safe.
  @override
  Future<List<ChildEntity>> getLinkedChildren() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/children',
    );

    final body = response.data;
    if (body == null) return [];

    // Unwrap standard envelope: { "success": true, "data": [...] }
    final dataField = body['data'];
    if (dataField == null) return [];

    // data may be a List directly or wrapped further
    final List<dynamic> rawList;
    if (dataField is List) {
      rawList = dataField;
    } else if (dataField is Map<String, dynamic> &&
        dataField['children'] is List) {
      rawList = dataField['children'] as List<dynamic>;
    } else {
      return [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((json) => ChildDto.fromJson(json).toEntity())
        .toList();
  }

  /// POST /api/parent/children
  ///
  /// Adds and links a new child to the authenticated parent account.
  @override
  Future<ChildEntity> addChild(AddChildRequestDto request) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/parent/children',
      data: request.toJson(),
    );

    final body = response.data;
    final Map<String, dynamic> childJson;
    if (body != null && body['data'] is Map<String, dynamic>) {
      childJson = body['data'] as Map<String, dynamic>;
    } else {
      childJson = body ?? <String, dynamic>{};
    }

    return ChildDto.fromJson(childJson).toEntity();
  }

  /// DELETE /api/parent/children/{childStudentId}
  ///
  /// Unlinks/removes the child relationship from the parent account.
  @override
  Future<void> unlinkChild({required String childStudentId}) async {
    await apiClient.delete<Map<String, dynamic>>(
      '/parent/children/$childStudentId',
    );
  }

  /// GET /api/parent/children/{childStudentId}/dashboard
  /// AND authoritative GET /api/parent/children/{childStudentId}/live-classes
  ///
  /// Returns dashboard summary metrics for the given child with authoritative
  /// resolution of "TODAY'S CLASS" from the live-classes endpoint.
  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    final classesRepo =
        classesRepository ?? ClassesRepositoryImpl(apiClient: apiClient);

    // Concurrently fetch Dashboard API, authoritative Live-Classes API, Progress API, and Program API
    final results = await Future.wait<dynamic>([
      apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/dashboard',
      ),
      _fetchLiveClassesSafe(classesRepo, childStudentId),
      _fetchProgressSafe(childStudentId),
      _fetchProgramProgressSafe(childStudentId),
    ]);

    final dashboardResponse = results[0] as Response<Map<String, dynamic>>?;
    final liveClasses = results[1] as List<ClassEntity>?;
    final progress = results[2] as double?;
    final programResult = results[3] as _ProgramProgressResult?;

    final body = dashboardResponse?.data;
    if (body == null) return const DashboardEntity();

    final dataField = body['data'];
    if (dataField is! Map<String, dynamic>) return const DashboardEntity();

    final baseDto = DashboardDto.fromJson(dataField);

    // Authoritative today's class selection from liveClasses with fallback to dashboard upcomingLiveClasses
    ClassEntity? authoritativeTodayClass;
    if (liveClasses != null && liveClasses.isNotEmpty) {
      authoritativeTodayClass = selectTodayClass(
        liveClasses,
        nowOverride: nowProvider?.call(),
      );
    }
    // Fallback to dashboard's own featured class if liveClasses didn't resolve one
    if (authoritativeTodayClass == null && baseDto.featuredClass != null) {
      final now = nowProvider?.call() ?? DateTime.now();
      final featStart = baseDto.featuredClass!.scheduledStartTime?.toLocal();
      if (featStart != null &&
          featStart.year == now.year &&
          featStart.month == now.month &&
          featStart.day == now.day &&
          !baseDto.featuredClass!.isCancelled &&
          (!baseDto.featuredClass!.isCompletedAt(now) ||
              baseDto.featuredClass!.isUpcomingAt(now))) {
        authoritativeTodayClass = baseDto.featuredClass;
      }
    }

    final Map<String, double> batchProgressMap = {};
    if (programResult?.progress != null) {
      if (programResult!.batchId != null) {
        batchProgressMap[programResult.batchId!] = programResult.progress!;
      }
      if (programResult.batchName != null) {
        batchProgressMap[programResult.batchName!] = programResult.progress!;
      }
    }

    return baseDto.toEntity(
      overrideFeaturedClass: authoritativeTodayClass,
      useOverride: true,
      progressPercentage: programResult?.progress ?? progress,
      batchProgressMap: batchProgressMap.isNotEmpty ? batchProgressMap : null,
    );
  }

  Future<_ProgramProgressResult?> _fetchProgramProgressSafe(
    String childStudentId,
  ) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/program',
      );
      final body = response.data;
      if (body != null && body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        final rawVal = data['progress'];
        double? prog;
        if (rawVal is num) prog = rawVal.toDouble();
        if (rawVal is String) prog = double.tryParse(rawVal);
        return _ProgramProgressResult(
          batchId: data['batchId']?.toString(),
          batchName: data['batchName']?.toString(),
          courseName: data['courseName']?.toString(),
          progress: prog,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<double?> _fetchProgressSafe(String childStudentId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/progress',
      );
      final body = response.data;
      if (body != null && body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        final rawVal = data['overallCompletion'];
        if (rawVal is num) return rawVal.toDouble();
        if (rawVal is String) return double.tryParse(rawVal);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ClassEntity>?> _fetchLiveClassesSafe(
    ClassesRepository classesRepo,
    String childStudentId,
  ) async {
    try {
      return await classesRepo.getLiveClasses(childStudentId);
    } catch (_) {
      return null;
    }
  }

  /// Selects "TODAY'S CLASS" using device LOCAL time from authoritative live classes.
  ///
  /// Priority:
  /// 1. Currently LIVE class
  /// 2. Otherwise today's UPCOMING class (next upcoming or ongoing)
  /// 3. Otherwise no today's class (null)
  static ClassEntity? selectTodayClass(
    List<ClassEntity> liveClasses, {
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();

    // 1. Filter classes strictly belonging to the device local calendar date of 'now'
    final todayClasses = <ClassEntity>[];
    for (final c in liveClasses) {
      final start = c.scheduledStartTime;
      if (start == null) continue;
      final startLocal = start.toLocal();
      if (startLocal.year == now.year &&
          startLocal.month == now.month &&
          startLocal.day == now.day) {
        todayClasses.add(c);
      }
    }

    if (todayClasses.isEmpty) return null;

    // Filter out terminal states (completed, missed, cancelled)
    final activeTodayClasses = todayClasses
        .where(
          (c) =>
              !c.isCancelled &&
              (!c.isCompletedAt(now) || c.isUpcomingAt(now)) &&
              !c.isMissedAt(now),
        )
        .toList();

    if (activeTodayClasses.isEmpty) return null;

    // Priority 1: Currently LIVE class
    final liveCandidates = activeTodayClasses.where((c) => c.isLive).toList();
    if (liveCandidates.isNotEmpty) {
      liveCandidates.sort(
        (a, b) => (a.scheduledStartTime?.toLocal() ?? DateTime(0)).compareTo(
          b.scheduledStartTime?.toLocal() ?? DateTime(0),
        ),
      );
      return liveCandidates.first;
    }

    // Priority 2: Otherwise today's UPCOMING class
    final upcomingCandidates = activeTodayClasses
        .where((c) => c.isUpcomingAt(now))
        .toList();

    if (upcomingCandidates.isNotEmpty) {
      upcomingCandidates.sort(
        (a, b) => (a.scheduledStartTime?.toLocal() ?? DateTime(0)).compareTo(
          b.scheduledStartTime?.toLocal() ?? DateTime(0),
        ),
      );

      // Prefer the next upcoming or ongoing session whose end time is in the future
      for (final cand in upcomingCandidates) {
        final endLocal =
            cand.scheduledEndTime?.toLocal() ??
            (cand.scheduledStartTime?.toLocal().add(
              Duration(minutes: cand.duration ?? 60),
            ));
        if (endLocal != null && endLocal.isAfter(now)) {
          return cand;
        }
      }
      return upcomingCandidates.first;
    }

    // Priority 3: Otherwise no today's class
    return null;
  }
}

/// Provider for [DashboardRepository].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    classesRepository: ref.watch(classesRepositoryProvider),
    nowProvider: () => ref.watch(currentDeviceDateProvider),
  );
});

/// Provider for [AddChildRepository].
final addChildRepositoryProvider = Provider<AddChildRepository>((ref) {
  return DashboardRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    classesRepository: ref.watch(classesRepositoryProvider),
    nowProvider: () => ref.watch(currentDeviceDateProvider),
  );
});

class _ProgramProgressResult {
  const _ProgramProgressResult({
    this.batchId,
    this.batchName,
    this.courseName,
    this.progress,
  });

  final String? batchId;
  final String? batchName;
  final String? courseName;
  final double? progress;
}
