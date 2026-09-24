import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../classes/data/repositories/classes_repository_impl.dart';
import '../../../classes/domain/entities/class_entity.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
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
class DashboardRepositoryImpl implements DashboardRepository, AddChildRepository {
  const DashboardRepositoryImpl({
    required this.apiClient,
    this.classesRepository,
  });

  final ApiClient apiClient;
  final ClassesRepository? classesRepository;

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
    } else if (dataField is Map<String, dynamic> && dataField['children'] is List) {
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

  /// GET /api/parent/children/{childStudentId}/dashboard
  /// AND authoritative GET /api/parent/children/{childStudentId}/live-classes
  ///
  /// Returns dashboard summary metrics for the given child with authoritative
  /// resolution of "TODAY'S CLASS" from the live-classes endpoint.
  @override
  Future<DashboardEntity> getChildDashboard({
    required String childStudentId,
  }) async {
    final classesRepo = classesRepository ?? ClassesRepositoryImpl(apiClient: apiClient);

    // Concurrently fetch both Dashboard API and authoritative Live-Classes API
    final results = await Future.wait<dynamic>([
      apiClient.get<Map<String, dynamic>>(
        '/parent/children/$childStudentId/dashboard',
      ),
      _fetchLiveClassesSafe(classesRepo, childStudentId),
    ]);

    final dashboardResponse = results[0] as Response<Map<String, dynamic>>?;
    final liveClasses = results[1] as List<ClassEntity>?;

    final body = dashboardResponse?.data;
    if (body == null) return const DashboardEntity();

    final dataField = body['data'];
    if (dataField is! Map<String, dynamic>) return const DashboardEntity();

    final baseDto = DashboardDto.fromJson(dataField);

    // Authoritative today's class selection from liveClasses
    final ClassEntity? authoritativeTodayClass;
    if (liveClasses != null) {
      authoritativeTodayClass = selectTodayClass(liveClasses);
    } else {
      // If live-classes API failed, do not treat dashboard upcomingLiveClasses as authoritative
      authoritativeTodayClass = null;
    }

    return baseDto.toEntity(
      overrideFeaturedClass: authoritativeTodayClass,
      useOverride: true,
    );
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
        .where((c) => !c.isCompleted && !c.isMissed && !c.isCancelled)
        .toList();

    if (activeTodayClasses.isEmpty) return null;

    // Priority 1: Currently LIVE class
    final liveCandidates = activeTodayClasses.where((c) => c.isLive).toList();
    if (liveCandidates.isNotEmpty) {
      liveCandidates.sort((a, b) =>
          (a.scheduledStartTime?.toLocal() ?? DateTime(0))
              .compareTo(b.scheduledStartTime?.toLocal() ?? DateTime(0)));
      return liveCandidates.first;
    }

    // Priority 2: Otherwise today's UPCOMING class
    final upcomingCandidates = activeTodayClasses
        .where((c) => c.isUpcoming)
        .toList();

    if (upcomingCandidates.isNotEmpty) {
      upcomingCandidates.sort((a, b) =>
          (a.scheduledStartTime?.toLocal() ?? DateTime(0))
              .compareTo(b.scheduledStartTime?.toLocal() ?? DateTime(0)));

      // Prefer the next upcoming or ongoing session whose end time is in the future
      for (final cand in upcomingCandidates) {
        final endLocal = cand.scheduledEndTime?.toLocal() ??
            (cand.scheduledStartTime?.toLocal().add(Duration(minutes: cand.duration ?? 60)));
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
  );
});

/// Provider for [AddChildRepository].
final addChildRepositoryProvider = Provider<AddChildRepository>((ref) {
  return DashboardRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    classesRepository: ref.watch(classesRepositoryProvider),
  );
});
