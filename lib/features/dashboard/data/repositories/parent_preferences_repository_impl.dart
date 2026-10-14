import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/parent_preferences_entity.dart';
import '../../domain/repositories/parent_preferences_repository.dart';
import '../models/parent_preferences_dto.dart';

class ParentPreferencesRepositoryImpl implements ParentPreferencesRepository {
  final ApiClient apiClient;

  ParentPreferencesRepositoryImpl({required this.apiClient});

  @override
  Future<ParentPreferencesEntity> getPreferences() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/preferences',
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from /parent/preferences');
    }

    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      return ParentPreferencesDto.fromJson(payload).toEntity();
    } else {
      throw Exception('Unexpected data format from /parent/preferences');
    }
  }

  @override
  Future<ParentPreferencesEntity> updatePreferences(
    ParentPreferencesEntity preferences,
  ) async {
    final dto = ParentPreferencesDto.fromEntity(preferences);
    final response = await apiClient.patch<Map<String, dynamic>>(
      '/parent/preferences',
      data: dto.toJson(),
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from /parent/preferences update');
    }

    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      return ParentPreferencesDto.fromJson(payload).toEntity();
    } else {
      return preferences;
    }
  }
}

final parentPreferencesRepositoryProvider =
    Provider<ParentPreferencesRepository>((ref) {
      final client = ref.watch(apiClientProvider);
      return ParentPreferencesRepositoryImpl(apiClient: client);
    });
