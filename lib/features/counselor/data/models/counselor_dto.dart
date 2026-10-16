import '../../domain/entities/counselor_entity.dart';

/// DTO for parsing counselor JSON data from `GET /api/counselling`.
class CounselorDto {
  const CounselorDto({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.designation,
    this.specialization,
    this.status,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? designation;
  final String? specialization;
  final String? status;

  factory CounselorDto.fromJson(Map<String, dynamic> json) {
    // 1. Resolve ID
    final resolvedId =
        (json['_id'] ??
                json['id'] ??
                json['counsellorId'] ??
                json['counselorId'] ??
                '')
            .toString();

    // 2. Resolve Name
    String resolvedName = '';
    final firstName = json['firstName'] as String?;
    final lastName = json['lastName'] as String?;
    if (firstName != null || lastName != null) {
      resolvedName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    } else if (json['name'] is String) {
      resolvedName = (json['name'] as String).trim();
    } else if (json['fullName'] is String) {
      resolvedName = (json['fullName'] as String).trim();
    }

    if (resolvedName.isEmpty) {
      resolvedName = 'Academic Counselor';
    }

    // 3. Resolve Contact Info
    final email = (json['email'] ?? json['contactEmail']) as String?;
    final phone =
        (json['phone'] ?? json['phoneNumber'] ?? json['contactPhone'])
            as String?;

    // 4. Resolve Avatar / Image
    final avatar =
        (json['avatar'] ??
                json['profilePicture'] ??
                json['photo'] ??
                json['image'])
            as String?;

    // 5. Resolve Designation & Specialization
    final designation =
        (json['designation'] ??
                (json['role'] is String ? json['role'] as String? : null) ??
                json['title'])
            as String?;
    final specialization =
        (json['specialization'] ?? json['department'] ?? json['domain'])
            as String?;

    final status = json['status']?.toString();

    return CounselorDto(
      id: resolvedId,
      name: resolvedName,
      email: email,
      phone: phone,
      avatar: avatar,
      designation: designation,
      specialization: specialization,
      status: status,
    );
  }

  CounselorEntity toEntity() {
    return CounselorEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatar: avatar,
      designation: designation,
      specialization: specialization,
      status: status,
    );
  }
}
