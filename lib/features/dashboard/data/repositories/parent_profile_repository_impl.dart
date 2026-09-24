import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/parent_profile_entity.dart';
import '../../domain/repositories/parent_profile_repository.dart';
import '../models/parent_profile_dto.dart';

class ParentProfileRepositoryImpl implements ParentProfileRepository {
  ParentProfileRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ParentProfileEntity> getParentProfile() async {
    final response = await apiClient.get<Map<String, dynamic>>('/parent/profile');
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from /parent/profile');
    }
    final rawData = data['data'];
    if (rawData is Map<String, dynamic>) {
      return ParentProfileDto.fromJson(rawData).toEntity();
    }
    return ParentProfileDto.fromJson(data).toEntity();
  }

  @override
  Future<ParentProfileEntity> updateParentProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) async {
    final payload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
    };
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (city != null) payload['city'] = city;
    if (state != null) payload['state'] = state;
    if (country != null) payload['country'] = country;
    if (postalCode != null) payload['postalCode'] = postalCode;

    final response = await apiClient.patch<Map<String, dynamic>>(
      '/parent/profile',
      data: payload,
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from PATCH /parent/profile');
    }
    final rawData = data['data'];
    if (rawData is Map<String, dynamic>) {
      return ParentProfileDto.fromJson(rawData).toEntity();
    }
    return ParentProfileDto.fromJson(data).toEntity();
  }
}

final parentProfileRepositoryProvider = Provider<ParentProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ParentProfileRepositoryImpl(apiClient: apiClient);
});
