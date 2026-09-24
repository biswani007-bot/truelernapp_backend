import '../entities/parent_profile_entity.dart';

abstract class ParentProfileRepository {
  Future<ParentProfileEntity> getParentProfile();
  Future<ParentProfileEntity> updateParentProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  });
}
