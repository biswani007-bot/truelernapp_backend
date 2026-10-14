import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/program_details_entity.dart';

/// Fetches the authoritative program details for a given child ID.
///
/// Source: GET /api/parent/children/{childStudentId}/program
final programDetailsProvider =
    FutureProvider.family<ProgramDetailsEntity?, String>((
      ref,
      childStudentId,
    ) async {
      if (childStudentId.isEmpty) return null;
      final apiClient = ref.watch(apiClientProvider);
      try {
        final response = await apiClient.get<Map<String, dynamic>>(
          '/parent/children/$childStudentId/program',
        );
        final body = response.data;
        if (body == null) return null;
        final data = body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body;
        return ProgramDetailsEntity.fromJson(data);
      } catch (_) {
        return null;
      }
    });
