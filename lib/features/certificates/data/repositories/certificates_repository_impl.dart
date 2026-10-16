import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/repositories/certificates_repository.dart';
import '../models/certificate_dto.dart';

/// Concrete implementation of [CertificatesRepository] that consumes
/// `GET /api/parent/children/:studentId/certificates`.
class CertificatesRepositoryImpl implements CertificatesRepository {
  final ApiClient apiClient;

  const CertificatesRepositoryImpl({required this.apiClient});

  @override
  Future<List<CertificateEntity>> getCertificates({
    required String childStudentId,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/parent/children/$childStudentId/certificates',
    );

    final body = response.data;
    if (body != null && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (json) =>
                CertificateDto.fromJson(json)
                    .toEntity(childStudentId: childStudentId),
          )
          .toList();
    }

    return const [];
  }
}

/// Global provider for [CertificatesRepository].
final certificatesRepositoryProvider = Provider<CertificatesRepository>((ref) {
  return CertificatesRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
