import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/security_activity_entity.dart';
import '../../domain/repositories/security_activity_repository.dart';
import '../models/security_activity_dto.dart';

class SecurityActivityRepositoryImpl implements SecurityActivityRepository {
  const SecurityActivityRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<SecurityActivityEntity>> getActivityLogs() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/auth/activity',
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from /auth/activity');
    }

    final rawList = data['data'];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => SecurityActivityDto.fromJson(item).toEntity())
          .toList();
    }
    return [];
  }
}

final securityActivityRepositoryProvider =
    Provider<SecurityActivityRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SecurityActivityRepositoryImpl(apiClient: client);
});
