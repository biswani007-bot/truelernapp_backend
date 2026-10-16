import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/counseling_request_entity.dart';
import '../../domain/entities/counselor_entity.dart';
import '../../domain/repositories/counselor_repository.dart';
import '../models/counseling_request_dto.dart';
import '../models/counselor_dto.dart';

/// Concrete implementation of [CounselorRepository] backed by TrueLern API.
class CounselorRepositoryImpl implements CounselorRepository {
  const CounselorRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<CounselorEntity>> getCounselors() async {
    try {
      final response = await apiClient.get<dynamic>('/counselling');
      final data = response.data;

      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => CounselorDto.fromJson(item).toEntity())
            .toList();
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => CounselorDto.fromJson(item).toEntity())
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load active counselors: $e');
    }
  }

  @override
  Future<List<CounselingRequestEntity>> getMyRequests() async {
    try {
      final response = await apiClient.get<dynamic>('/counselling/my-requests');
      final data = response.data;

      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => CounselingRequestDto.fromJson(item).toEntity())
            .toList();
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => CounselingRequestDto.fromJson(item).toEntity())
            .toList();
      }

      return [];
    } catch (_) {
      // If user profile has no requests yet or endpoint returns 404, return empty list gracefully
      return [];
    }
  }
}

/// Riverpod provider for [CounselorRepository].
final counselorRepositoryProvider = Provider<CounselorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CounselorRepositoryImpl(apiClient: apiClient);
});
