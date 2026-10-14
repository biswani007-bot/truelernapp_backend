import '../../../../core/network/api_client.dart';
import '../../domain/entities/login_methods_entity.dart';
import '../../domain/repositories/login_methods_repository.dart';
import '../models/login_methods_dto.dart';

class LoginMethodsRepositoryImpl implements LoginMethodsRepository {
  const LoginMethodsRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<LoginMethodsEntity> getLoginMethods() async {
    // 1. Fetch parent profile (contains email, phone, security status)
    final profileResponse = await apiClient.get<Map<String, dynamic>>(
      '/parent/profile',
    );
    if (profileResponse.data == null) {
      throw Exception('Empty response from /parent/profile');
    }

    final profileData =
        profileResponse.data!['data'] as Map<String, dynamic>? ??
        profileResponse.data!;

    // 2. Fetch parent preferences (contains communication channel preferences)
    Map<String, dynamic>? prefData;
    try {
      final prefResponse = await apiClient.get<Map<String, dynamic>>(
        '/parent/preferences',
      );
      if (prefResponse.data != null) {
        prefData =
            prefResponse.data!['data'] as Map<String, dynamic>? ??
            prefResponse.data!;
      }
    } catch (_) {
      // Preferences failure is non-fatal; fallback to profile data
    }

    final dto = LoginMethodsDto.fromProfileJson(
      profileData,
      prefJson: prefData,
    );
    return dto.toEntity();
  }
}
