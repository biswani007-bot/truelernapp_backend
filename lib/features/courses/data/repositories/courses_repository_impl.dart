import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/courses_repository.dart';

/// Implementation of [CoursesRepository] calling real backend API.
/// Endpoint: GET /api/public/courses
class CoursesRepositoryImpl implements CoursesRepository {
  const CoursesRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<CourseEntity>> getPublicCourses() async {
    final response = await apiClient.get<dynamic>('/public/courses');
    final rawData = response.data;
    final List<dynamic> list;

    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData['courses'] is List) {
        list = rawData['courses'] as List;
      } else if (rawData['programs'] is List) {
        list = rawData['programs'] as List;
      } else {
        list = const [];
      }
    } else if (rawData is List) {
      list = rawData;
    } else {
      list = const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => CourseEntity.fromJson(json))
        .where((c) => c.courseName.isNotEmpty)
        .toList();
  }

  @override
  Future<CourseEntity?> getCourseById(String id) async {
    final courses = await getPublicCourses();
    try {
      return courses.firstWhere((c) => c.id == id || c.slug == id);
    } catch (_) {
      return null;
    }
  }
}

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// Global provider for real public courses.
final publicCoursesProvider = FutureProvider<List<CourseEntity>>((ref) async {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.getPublicCourses();
});
